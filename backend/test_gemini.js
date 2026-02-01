import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from 'dotenv';
dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

const models = [
    "gemini-pro",
    "gemini-1.5-flash",
    "gemini-1.0-pro",
    "gemini-1.5-flash-001",
    "gemini-1.5-pro"
];

async function testAll() {
    console.log("Starting Model Capabilities Test...");
    for (const modelName of models) {
        process.stdout.write(`Testing ${modelName.padEnd(20)}: `);
        try {
            const model = genAI.getGenerativeModel({ model: modelName });
            const result = await model.generateContent("Hi");
            console.log(`✅ SUCCESS`);
        } catch (error) {
            let msg = error.message;
            if (msg.includes("404")) msg = "404 Not Found";
            else if (msg.includes("403")) msg = "403 Forbidden";
            else if (msg.includes("400")) msg = "400 Bad Request";
            console.log(`❌ FAILED (${msg})`);
        }
    }
}

testAll();
