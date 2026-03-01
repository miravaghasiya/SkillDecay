import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import OpenAI from "openai";
import admin from "firebase-admin";
import { readFile } from "fs/promises";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

/* =========================================================
   FIREBASE
========================================================= */

let db = null;

try {
  const serviceAccount = JSON.parse(
    await readFile(new URL("./serviceAccountKey.json", import.meta.url))
  );

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  db = admin.firestore();
  console.log("✅ Firebase Admin Initialized");
} catch (e) {
  console.warn("⚠️ Firebase not initialized:", e.message);
}

/* =========================================================
   OPENROUTER CONFIG (OPTIMIZED)
========================================================= */

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

// Faster model first
const PRIMARY_MODEL = "arcee-ai/trinity-large-preview:free";

// More powerful fallback
const FALLBACK_MODEL = "openai/gpt-oss-120b:free";

const openai = new OpenAI({
  baseURL: "https://openrouter.ai/api/v1",
  apiKey: OPENROUTER_API_KEY,
  defaultHeaders: {
    "HTTP-Referer": "http://localhost:3000",
    "X-Title": "Skill Decay Detector",
    "Content-Type": "application/json",
  },
});

/* =========================================================
   QUIZ CACHE (INSTANT REPEAT LOADS)
========================================================= */

const quizCache = new Map();

/* =========================================================
   FALLBACK QUIZ
========================================================= */

function getFallbackQuiz(skillTitle, category, level) {
  return [
    {
      question: `Which concept is fundamental in ${skillTitle}?`,
      options: ["Core principles", "UI only", "Marketing", "None"],
      correctIndex: 0,
      explanation: "Understanding fundamentals is essential.",
      topic: "Fundamentals",
    },
    {
      question: `Best way to improve ${skillTitle}?`,
      options: ["Practice projects", "Watching videos only", "Reading only", "Skipping"],
      correctIndex: 0,
      explanation: "Hands-on projects improve retention.",
      topic: "Practice",
    },
    {
      question: `Why is ${skillTitle} important in ${category}?`,
      options: ["Core role", "Optional", "Deprecated", "Irrelevant"],
      correctIndex: 0,
      explanation: `${skillTitle} plays a key role.`,
      topic: "Importance",
    },
    {
      question: `How to prevent forgetting ${skillTitle}?`,
      options: ["Spaced repetition", "One-time study", "Never review", "Guess"],
      correctIndex: 0,
      explanation: "Regular practice prevents decay.",
      topic: "Retention",
    },
    {
      question: `What accelerates mastery in ${skillTitle}?`,
      options: ["Real projects", "Memorization only", "No practice", "Random learning"],
      correctIndex: 0,
      explanation: "Projects build deep understanding.",
      topic: "Growth",
    },
  ];
}

/* =========================================================
   PROMPT BUILDER
========================================================= */

function buildPrompt(skillTitle, category, level, previous = []) {
  return `
You are an expert technical instructor.

Generate 5 multiple choice questions.

Skill: ${skillTitle}
Category: ${category}
User Level: ${level}

Avoid repeating:
${previous.join(", ") || "None"}

Rules:
- Technical
- Practical
- Skill specific
- 4 options
- Provide correctIndex (0-3)
- Provide explanation
- Return ONLY JSON

Format:
{
  "questions":[
    {
      "question":"",
      "options":["","","",""],
      "correctIndex":0,
      "explanation":"",
      "topic":""
    }
  ]
}
`;
}

/* =========================================================
   MODEL CALL
========================================================= */

async function callModel(model, prompt, timeoutMs = 30000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    console.log(`🔄 Calling OpenRouter [${model}]...`);

    const completion = await openai.chat.completions.create(
      {
        model,
        messages: [
          {
            role: "system",
            content:
              "You are an expert instructor. Always return clean JSON only.",
          },
          { role: "user", content: prompt },
        ],
        temperature: 0.6,
        max_tokens: 500, // reduced for speed
      },
      { signal: controller.signal }
    );

    const content = completion?.choices?.[0]?.message?.content;

    if (!content) throw new Error("Empty AI response");

    return content;
  } finally {
    clearTimeout(timeout);
  }
}

/* =========================================================
   SAFE JSON PARSER
========================================================= */

function safeParse(content) {
  let cleaned = content.trim();

  if (cleaned.startsWith("```")) {
    cleaned = cleaned.replace(/```json|```/g, "").trim();
  }

  const match = cleaned.match(/\{[\s\S]*\}/);

  if (!match) throw new Error("No JSON found");

  return JSON.parse(match[0]);
}

/* =========================================================
   GENERATE QUIZ ROUTE
========================================================= */

app.post("/generate-quiz", async (req, res) => {
  const { skillTitle, category, userLevel, previousQuestions = [] } = req.body;

  const cacheKey = `${skillTitle}_${userLevel}`;

  if (quizCache.has(cacheKey)) {
    console.log("⚡ Serving quiz from cache");
    return res.json(quizCache.get(cacheKey));
  }

  const start = Date.now();

  console.log(`🎯 Request: Generate quiz for ${skillTitle} (${userLevel})`);

  const prompt = buildPrompt(
    skillTitle,
    category,
    userLevel,
    previousQuestions
  );

  try {
    let content;
    let usedModel = PRIMARY_MODEL;

    try {
      content = await callModel(PRIMARY_MODEL, prompt);
    } catch (err) {
      console.warn(`⚠️ Primary failed: ${err.message}. Trying fallback...`);
      usedModel = FALLBACK_MODEL;
      content = await callModel(FALLBACK_MODEL, prompt);
    }

    const parsed = safeParse(content);

    const questions = parsed.questions || parsed;

    if (!Array.isArray(questions)) throw new Error("Invalid AI format");

    const finalQuestions = questions.slice(0, 5);

    // store cache
    quizCache.set(cacheKey, finalQuestions);

    const time = ((Date.now() - start) / 1000).toFixed(2);

    console.log(
      `✅ AI Success | Model: ${usedModel} | Time: ${time}s`
    );

    res.json(finalQuestions);
  } catch (err) {
    const time = ((Date.now() - start) / 1000).toFixed(2);

    console.error(`❌ GENERATION ERROR after ${time}s:`, err.message);

    console.log("🛡️ Serving fallback quiz");

    res.json(getFallbackQuiz(skillTitle, category, userLevel));
  }
});

/* =========================================================
   SAVE SESSION
========================================================= */

app.post("/save-session", async (req, res) => {
  try {
    const {
      userId,
      skillId,
      score,
      totalQuestions,
      questions,
      userAnswers,
    } = req.body;

    if (!db) return res.json({ success: false });

    const weakTopics = [];

    questions.forEach((q, i) => {
      if (userAnswers[i] !== q.correctIndex)
        weakTopics.push(q.topic || "General");
    });

    await db.collection("practice_sessions").add({
      userId,
      skillId,
      score,
      totalQuestions,
      questions,
      userAnswers,
      weakTopics,
      date: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Session saved for user ${userId}`);

    res.json({ success: true });
  } catch (e) {
    console.error("SAVE ERROR:", e.message);
    res.status(500).json({ error: "Save failed" });
  }
});

/* ========================================================= */

const PORT = process.env.PORT || 3000;

app.listen(PORT, () =>
  console.log(`🚀 Server running on port ${PORT}`)
);