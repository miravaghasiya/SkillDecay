import axios from 'axios';

const BASE_URL = 'http://localhost:3000';

async function testGenerateQuiz() {
    console.log('Testing /generate-quiz...');
    try {
        const response = await axios.post(`${BASE_URL}/generate-quiz`, {
            skillId: 'test_skill_123', // Mock ID
            skillTitle: 'Flutter State Management',
            category: 'Mobile Development',
            userLevel: 'Beginner'
        });

        console.log('Quiz Generated Successfully!');
        console.log('Number of questions:', response.data.length);
        if (response.data.length > 0) {
            console.log('Sample Question:', response.data[0]);
        }

        if (response.data.length !== 12) {
            console.warn(`WARNING: Expected 12 questions, got ${response.data.length}`);
        }

        return response.data;
    } catch (error) {
        console.error('Test Failed:', error.response ? error.response.data : error.message);
    }
}

async function testSaveSession() {
    console.log('\nTesting /save-session...');
    try {
        const mockQuestions = Array.from({ length: 12 }, (_, i) => ({
            question: `Q${i}`, options: ["A", "B", "C", "D"], correctIndex: 0, topic: "Test"
        }));

        const mockAnswers = {};
        mockQuestions.forEach((_, i) => mockAnswers[i] = 0); // All correct

        const response = await axios.post(`${BASE_URL}/save-session`, {
            userId: 'test_user_123',
            skillId: 'test_skill_123',
            score: 12,
            totalQuestions: 12,
            questions: mockQuestions,
            userAnswers: mockAnswers,
            difficultyLevel: 'Beginner'
        });

        console.log('Session Saved:', response.data);
    } catch (error) {
        console.error('Test Failed:', error.response ? error.response.data : error.message);
    }
}

(async () => {
    await testGenerateQuiz();
    await testSaveSession();
})();
