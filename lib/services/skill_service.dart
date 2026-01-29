import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/skill.dart';

class SkillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'skills';

  // Add a new skill
  Future<String> addSkill(Skill skill) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(skill.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add skill: $e');
    }
  }

  // Get all skills for a user
  Stream<List<Skill>> getUserSkills(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList();
    });
  }

  // Get a single skill by ID
  Future<Skill?> getSkill(String skillId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(skillId).get();
      if (doc.exists) {
        return Skill.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get skill: $e');
    }
  }

  // Update a skill
  Future<void> updateSkill(String skillId, Skill skill) async {
    try {
      await _firestore.collection(_collection).doc(skillId).update(
            skill.copyWith(updatedAt: DateTime.now()).toMap(),
          );
    } catch (e) {
      throw Exception('Failed to update skill: $e');
    }
  }

  // Delete a skill
  Future<void> deleteSkill(String skillId) async {
    try {
      await _firestore.collection(_collection).doc(skillId).delete();
    } catch (e) {
      throw Exception('Failed to delete skill: $e');
    }
  }

  // Get skills by category
  Stream<List<Skill>> getSkillsByCategory(String userId, String category) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList();
    });
  }

  // Get skills by difficulty level
  Stream<List<Skill>> getSkillsByDifficulty(String userId, String difficultyLevel) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('difficultyLevel', isEqualTo: difficultyLevel)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList();
    });
  }
}
