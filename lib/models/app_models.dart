enum ProjectStatus { inquiry, inProgress, completed }

class Artist {
  final String name;
  final String location;
  final double rating;

  Artist({
    required this.name,
    required this.location,
    required this.rating,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      name: (json['name'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      rating: _readDouble(json['rating']),
    );
  }
}

class Project {
  final String title;
  final String clientName;
  final ProjectStatus status;
  final List<Milestone> milestones;

  Project({
    required this.title,
    required this.clientName,
    required this.status,
    this.milestones = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'];
    return Project(
      title: (json['title'] as String?) ?? '',
      clientName: (json['clientName'] as String?) ?? '',
      status: _projectStatusFromString((json['status'] as String?) ?? ''),
      milestones: rawMilestones is List
          ? rawMilestones
                .whereType<Map>()
                .map(
                  (entry) => Milestone.fromJson(
                    entry.map((k, v) => MapEntry('$k', v)),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class Milestone {
  final String title;
  final double amount;
  final bool isReleased;

  Milestone({
    required this.title,
    required this.amount,
    this.isReleased = false,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      title: (json['title'] as String?) ?? '',
      amount: _readDouble(json['amount']),
      isReleased: (json['isReleased'] as bool?) ?? false,
    );
  }
}

class Conversation {
  final int? id;
  final String name;
  final String? lastMessage;
  final DateTime? lastMessageDate;

  Conversation({this.id, required this.name, this.lastMessage, this.lastMessageDate});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int?,
      name: (json['name'] as String?) ?? '',
      lastMessage: json['lastMessage'] as String?,
      lastMessageDate: json['lastMessageDate'] != null
          ? DateTime.tryParse(json['lastMessageDate'] as String)
          : null,
    );
  }
}

class Message {
  final int? id;
  final int conversationId;
  final int senderId;
  final String content;
  final DateTime createdAt;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      conversationId: (json['conversationId'] as num?)?.toInt() ?? 0,
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      content: (json['content'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Review {
  final String reviewerName;
  final double rating;
  final String comment;

  Review({
    required this.reviewerName,
    required this.rating,
    required this.comment,
  });
}

enum PaymentMethodType { gcash, paymaya, paypal, stripe }

class PaymentMethod {
  final PaymentMethodType type;
  final String label;

  PaymentMethod({required this.type, required this.label});
}

ProjectStatus _projectStatusFromString(String raw) {
  switch (raw) {
    case 'inquiry':
      return ProjectStatus.inquiry;
    case 'inProgress':
      return ProjectStatus.inProgress;
    case 'completed':
      return ProjectStatus.completed;
    default:
      return ProjectStatus.inquiry;
  }
}

double _readDouble(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}
