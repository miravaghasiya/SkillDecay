import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import OpenAI from 'openai';
import admin from 'firebase-admin';
import { readFile } from 'fs/promises';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// ---------- Firebase ----------
let db = null;
try {
    const serviceAccount = JSON.parse(
        await readFile(new URL('./serviceAccountKey.json', import.meta.url))
    );

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });

    db = admin.firestore();
    console.log("✅ Firebase Admin Initialized");
} catch (e) {
    console.warn("⚠️ Firebase not initialized:", e.message);
}

// ---------- OpenRouter ----------
const openai = new OpenAI({
    baseURL: "https://openrouter.ai/api/v1",
    apiKey: process.env.OPENROUTER_API_KEY,
    defaultHeaders: {
        "HTTP-Referer": "http://localhost:3000",
        "X-Title": "Skill Decay Detector",
    }
});

// ---------- GENERATE QUIZ ----------
app.post('/generate-quiz', async (req, res) => {
    try {
        const { skillId, skillTitle, category, userLevel } = req.body;

        let masteryPercent = 20;
        let previousQuestions = [];
        let weakTopics = [];

        // RAG: Retrieve context from Firestore (History & Weak Topics)
        if (db && skillId) {
            try {
                const skillDoc = await db.collection('skills').doc(skillId).get();
                if (skillDoc.exists) {
                    masteryPercent = skillDoc.data().masteryPercent || 20;
                    weakTopics = skillDoc.data().weakTopics || [];
                }

                const history = await db.collection('practice_sessions')
                    .where('skillId', '==', skillId)
                    .orderBy('date', 'desc')
                    .limit(10)
                    .get();

                history.forEach(doc => {
                    (doc.data().questions || []).forEach(q =>
                        previousQuestions.push(q.question)
                    );
                });
            } catch (e) {
                console.error("DB Fetch Error:", e);
            }
        }

        console.log(`🎯 Generating quiz for ${skillTitle} (${userLevel}). Mastery: ${masteryPercent}%`);

        const prompt = `
You are an adaptive quiz generator.

Skill: ${skillTitle}
Category: ${category}
User Level: ${userLevel}
Mastery: ${masteryPercent}%

Avoid repeating:
${previousQuestions.slice(0, 20).join(' | ')}

Focus on weak topics:
${weakTopics.join(', ')}

Generate EXACTLY 12 MCQs.

Return ONLY valid JSON array:
[
 { "question": "...",
   "options": ["A","B","C","D"],
   "correctIndex": 1,
   "topic": "..."
 }
]
`;

        // Multi-Model Failover Strategy
        const models = [
            "nvidia/nemotron-3-nano-30b-a3b:free",
            "deepseek/deepseek-r1-0528:free",
            "arcee-ai/trinity-large-preview:free",

        ];

        let completion;
        let lastError;
        let successModel = '';

        for (const model of models) {
            try {
                console.log(`🔄 Trying model: ${model}`);
                completion = await openai.chat.completions.create({
                    model: model,
                    messages: [{ role: "user", content: prompt }],
                });

                if (completion && completion.choices && completion.choices.length > 0) {
                    successModel = model;
                    console.log(`✅ Success with model: ${model}`);
                    break;
                }
            } catch (err) {
                console.warn(`⚠️ Failed with model ${model}: ${err.message}`);
                lastError = err;
            }
        }

        if (!completion || !completion.choices || completion.choices.length === 0) {
            throw lastError || new Error("All models failed to respond.");
        }

        let content = completion.choices[0]?.message?.content;
        if (!content) throw new Error("No content from LLM");

        // Clean markdown
        content = content.replace(/```json/g, '').replace(/```/g, '').trim();

        let quiz;
        try {
            const jsonMatch = content.match(/\[[\s\S]*\]/);
            if (jsonMatch) {
                quiz = JSON.parse(jsonMatch[0]);
            } else {
                quiz = JSON.parse(content);
            }
        } catch (jsonErr) {
            console.error("JSON Parse Error:", jsonErr);
            throw new Error("Failed to parse LLM response as JSON");
        }

        if (!Array.isArray(quiz)) throw new Error("Invalid format: Expected output to be an array");

        res.json(quiz.slice(0, 12));

    } catch (e) {
        console.error("====== GENERATION ERROR ======");
        console.error(e.message);

        return res.status(500).json({
            error: "Quiz Generation Failed",
            details: "All AI models are busy. Please try again."
        });
    }
});

// ---------- SAVE SESSION ----------
app.post('/save-session', async (req, res) => {
    try {
        const {
            userId,
            skillId,
            score,
            totalQuestions,
            questions,
            userAnswers,
            difficultyLevel
        } = req.body;

        if (!db) return res.json({ success: false });

        // 1️⃣ Identify weak topics
        const weakTopicsSet = new Set();
        questions.forEach((q, i) => {
            if (userAnswers[i] !== q.correctIndex) {
                weakTopicsSet.add(q.topic || "General");
            }
        });
        const weakTopics = [...weakTopicsSet];

        // 2️⃣ Save session
        await db.collection('practice_sessions').add({
            userId,
            skillId,
            score: (score / totalQuestions) * 100,
            totalQuestions,
            questions: questions.map(q => ({
                question: q.question,
                topic: q.topic,
                correctIndex: q.correctIndex,
            })),
            userAnswers,
            weakTopics,
            date: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 3️⃣ Recalculate mastery
        const sessions = await db.collection('practice_sessions')
            .where('skillId', '==', skillId)
            .orderBy('date', 'desc')
            .limit(5)
            .get();

        let scores = [];
        sessions.forEach(doc => scores.push(doc.data().score));

        const avg = scores.reduce((a, b) => a + b, 0) / scores.length;

        let diffMult = 0.3;
        if (difficultyLevel === 'Intermediate') diffMult = 0.6;
        if (difficultyLevel === 'Advanced') diffMult = 0.9;

        const consistency = 85;
        let mastery =
            (avg * 0.6) +
            (consistency * 0.2) +
            (diffMult * 100 * 0.2);

        mastery = Math.min(100, Math.max(0, mastery));

        // 4️⃣ Update skill
        await db.collection('skills').doc(skillId).update({
            masteryPercent: mastery,
            lastPracticed: admin.firestore.FieldValue.serverTimestamp(),
            weakTopics: weakTopics,
        });

        res.json({ success: true, masteryPercent: mastery });
    } catch (e) {
        console.error("SAVE ERROR:", e.message);
        res.status(500).json({ error: "Save failed" });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on ${PORT}`));
