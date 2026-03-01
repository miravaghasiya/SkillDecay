import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class CoachMessage {
  final String role; // 'user' | 'ai'
  final String text;
  final DateTime timestamp;

  CoachMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

class CoachService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<String> sendMessage(
    String message,
    List<CoachMessage> history,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ai-coach'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'history': history
                  .map((m) => {'role': m.role, 'text': m.text})
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? _fallbackResponse(message);
      }
    } catch (_) {
      // Backend unavailable – use local fallback
    }
    // Simulate realistic delay
    await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(700)));
    return _fallbackResponse(message);
  }

  String _fallbackResponse(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('practice') || msg.contains('today')) {
      return "Based on your current skill decay patterns, I recommend focusing on your 🔴 urgent skills first — especially any that haven't been practiced in 7+ days. Even a 10-minute focused session can reset your decay curve significantly. Shall I suggest a specific practice routine?";
    }
    if (msg.contains('retention') || msg.contains('remember') || msg.contains('forget')) {
      return "Great question on retention! 🧠 The forgetting curve shows we lose ~70% of new info within 24 hours. The key to beating it:\n\n1. **Spaced repetition** – revisit at 1, 3, 7, 14 day intervals\n2. **Active recall** – test yourself rather than re-reading\n3. **Interleaving** – mix related skills in a single session\n\nYour app's decay detector is already built around these principles!";
    }
    if (msg.contains('routine') || msg.contains('schedule') || msg.contains('plan')) {
      return "Here's a personalized routine I'd suggest based on skill decay science:\n\n🌅 **Morning (10 min)** – Quick recall test on your most decayed skill\n🌞 **Afternoon (15 min)** – Active practice session\n🌙 **Evening (5 min)** – Review and mark progress\n\nConsistency beats duration. A daily 30-minute habit is more effective than a 3-hour weekly session. Want me to tailor this further?";
    }
    if (msg.contains('doing') || msg.contains('progress') || msg.contains('overall')) {
      return "You're making solid progress! 🌟 Here's what I can tell:\n\n• Skills practiced recently show strong retention\n• Your streak indicates consistent engagement — keep it up!\n• Focus on moving any 🔴 urgent skills to 🟡 decaying status as a priority\n\nThe most important thing is showing up daily. Would you like tips on improving any specific skill category?";
    }
    if (msg.contains('motivation') || msg.contains('difficult') || msg.contains('hard') || msg.contains('struggle')) {
      return "Feeling the challenge is a sign you're growing! 💪 Here's what research says:\n\n• **Difficulty is desirable** – struggling with a concept means your brain is forming stronger connections\n• **Break it down** – if a skill feels overwhelming, split it into 3–5 micro-skills\n• **Celebrate small wins** – each session completed, no matter how short, is a victory\n\nWhat specific area are you finding most challenging? I can suggest targeted approaches!";
    }
    if (msg.contains('tip') || msg.contains('improve') || msg.contains('better')) {
      return "Here are my top evidence-based tips to accelerate your learning: 🚀\n\n1. **Teach what you learn** – explaining concepts solidifies memory by ~50%\n2. **Use the Pomodoro technique** – 25 min focus, 5 min break\n3. **Practice retrieval, not re-study** – quiz yourself rather than rereading notes\n4. **Sleep matters** – memory consolidation happens during deep sleep\n5. **Connect concepts** – link new knowledge to what you already know\n\nWhich skill area should we apply these to first?";
    }

    // Generic thoughtful response
    final responses = [
      "That's a thoughtful question! 🤔 Learning is deeply personal, and the best approach depends on your unique patterns. Based on the spaced repetition principles built into this app, the most impactful thing you can do right now is identify your highest-decay skills and give them focused attention today. What would you like to explore further?",
      "Great point to bring up! 🌟 Your learning journey is unique. I'd recommend looking at your Practice streak and Skills sections to identify where you need the most attention. Remember: consistency in small doses beats sporadic large sessions. Is there a specific skill or area you'd like coaching on?",
      "I love that curiosity! 💡 The science of learning tells us that the key metrics to watch are: practice frequency, time since last session, and recall accuracy. Your Skill Decay Detector tracks these automatically. Want me to walk you through how to interpret your progress data for maximum impact?",
    ];
    return responses[Random().nextInt(responses.length)];
  }
}
