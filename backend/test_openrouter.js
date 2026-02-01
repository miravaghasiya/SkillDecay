import dotenv from 'dotenv';
dotenv.config();

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

async function listModels() {
    try {
        const response = await fetch("https://openrouter.ai/api/v1/models", {
            headers: {
                "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
                "Content-Type": "application/json"
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        const freeModels = data.data
            .filter(m => m.id.endsWith(':free'))
            .map(m => m.id);

        console.log("✅ Available Free Models:");
        console.log(freeModels.join('\n'));

        if (freeModels.length === 0) {
            console.log("⚠️ No free models found. Check your OpenRouter data settings.");
        }

    } catch (error) {
        console.error("❌ Error fetching models:", error.message);
    }
}

listModels();
