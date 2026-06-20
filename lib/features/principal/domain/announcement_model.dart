import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

/// Announcement model for school-wide announcements.
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String postedBy; // Principal's user ID
  final String postedByName;
  final bool isActive;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.postedBy,
    required this.postedByName,
    this.isActive = true,
    required this.createdAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AnnouncementModel(
      id: doc.id,
      title: InputValidators.sanitize(data['title'] as String? ?? ''),
      content: InputValidators.sanitize(data['content'] as String? ?? ''),
      postedBy: data['postedBy'] as String? ?? '',
      postedByName: InputValidators.sanitize(data['postedByName'] as String? ?? ''),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': InputValidators.sanitize(title),
      'content': InputValidators.sanitize(content),
      'postedBy': postedBy,
      'postedByName': InputValidators.sanitize(postedByName),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
