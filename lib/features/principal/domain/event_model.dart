import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantay_eskwela/core/validators/input_validators.dart';

/// Event model for school events.
class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final String postedBy;
  final String postedByName;
  final bool requiresConsent;
  final bool isActive;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.postedBy,
    required this.postedByName,
    this.requiresConsent = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EventModel(
      id: doc.id,
      title: InputValidators.sanitize(data['title'] as String? ?? ''),
      description: InputValidators.sanitize(data['description'] as String? ?? ''),
      location: InputValidators.sanitize(data['location'] as String? ?? ''),
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      postedBy: data['postedBy'] as String? ?? '',
      postedByName: InputValidators.sanitize(data['postedByName'] as String? ?? ''),
      requiresConsent: data['requiresConsent'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': InputValidators.sanitize(title),
      'description': InputValidators.sanitize(description),
      'location': InputValidators.sanitize(location),
      'eventDate': Timestamp.fromDate(eventDate),
      'postedBy': postedBy,
      'postedByName': InputValidators.sanitize(postedByName),
      'requiresConsent': requiresConsent,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
