import fetch from 'node-fetch';
import dotenv from 'dotenv';
dotenv.config();

async function listFreeModels() {
    const apiKey = process.env.OPENROUTER_API_KEY;
    try {
        const response = await fetch("https://openrouter.ai/api/v1/models", {
            method: "GET",
            headers: { "Authorization": `Bearer ${apiKey}` }
        });

        if (response.ok) {
            const data = await response.json();
            const freeModels = data.data.filter(m => m.id.includes("free"));
            console.log("Free Models IDs:");
            freeModels.forEach(m => console.log(m.id));
        }
    } catch (error) {
        console.error(error);
    }
}

listFreeModels();
