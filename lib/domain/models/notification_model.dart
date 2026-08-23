import 'package:intl/intl.dart';

class NotificationModel {
  final String? id;
  final String? title;
  final String? description;
  final String? createdAt;
  final String? event;
  final String? bookingId;

  NotificationModel({
    this.id,
    this.title,
    this.description,
    this.createdAt,
    this.event,
    this.bookingId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final msg = json['message']?.toString() ?? json['description']?.toString();
    final created = json['createdAt']?.toString() ?? json['created_at']?.toString();

    return NotificationModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: json['title']?.toString(),
      description: msg,
      createdAt: created,
      event: json['event']?.toString(),
      bookingId: json['bookingId']?.toString() ?? json['booking_id']?.toString(),
    );
  }

  String get formattedDate {
    if (createdAt == null || createdAt!.isEmpty) return "";
    try {
      final dateTime = DateTime.parse(createdAt!).toLocal();
      return DateFormat("dd-MM-yyyy hh:mm a").format(dateTime);
    } catch (_) {
      return createdAt!;
    }
  }
}
