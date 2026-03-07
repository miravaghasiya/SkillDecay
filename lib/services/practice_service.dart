import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'skill_service.dart';
import 'notification_service.dart';

class PracticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SkillService _skillService = SkillService();

  CollectionReference _userPracticeSessions(String userId) {
    return _firestore.collection('users').doc(userId).collection('practice_sessions');
  }

  CollectionReference _userQuizResults(String userId) {
    return _firestore.collection('users').doc(userId).collection('quiz_results');
  }

  /// Marks a skill as practiced by updating its lastPracticed date and creating a session record.
  Future<void> markPracticeComplete(String userId, String skillId, {double? newMastery}) async {
    try {
      // 1. Update the skill itself
      final skill = await _skillService.getSkill(userId, skillId);
      if (skill != null) {
        final updatedSkill = skill.copyWith(
          lastPracticed: DateTime.now(),
          updatedAt: DateTime.now(),
          mastery: newMastery ?? skill.mastery,
        );
        await _skillService.updateSkill(userId, skillId, updatedSkill);
        await NotificationService.instance.cancelDailyReminder();
        await NotificationService.instance.scheduleDecayAlert(updatedSkill.name);
      }

      // 2. Create a practice session record
      await _userPracticeSessions(userId).add({
        'skillId': skillId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'quiz',
      });
      
      debugPrint('Practice marked complete for skill $skillId');
    } catch (e) {
      debugPrint('Error marking practice complete: $e');
      rethrow;
    }
  }

  /// Saves the results of a quiz session.
  Future<void> saveQuizResult({
    required String userId,
    required String skillId,
    required int score,
    required int totalQuestions,
    required String difficultyLevel,
  }) async {
    try {
      await _userQuizResults(userId).add({
        'skillId': skillId,
        'score': score,
        'totalQuestions': totalQuestions,
        'difficultyLevel': difficultyLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Quiz result saved for skill $skillId');
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
      rethrow;
    }
  }
}
