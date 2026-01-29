import 'package:cloud_firestore/cloud_firestore.dart';

class Skill {
  final String? id;
  final String userId;
  final String name;
  final String category;
  final String difficultyLevel; // 'Beginner', 'Intermediate', 'Advanced'
  final DateTime lastPracticed;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Skill({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.difficultyLevel,
    required this.lastPracticed,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert Skill to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'lastPracticed': Timestamp.fromDate(lastPracticed),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Skill from Firestore document
  factory Skill.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Skill(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      difficultyLevel: data['difficultyLevel'] ?? 'Beginner',
      lastPracticed: (data['lastPracticed'] as Timestamp).toDate(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy with updated fields
  Skill copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? difficultyLevel,
    DateTime? lastPracticed,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Skill(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
