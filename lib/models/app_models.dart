import 'package:timezone/timezone.dart' as tz;

enum ProjectStatus {
  pending,
  accepted,
  inProgress,
  completed,
  rejected,
}

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
  final int? id;
  final int? patronId;
  final int? artistId;
  /// Artist handle for patron "Sent" list and chat labels (from API).
  final String? artistUsername;
  final String title;
  final String clientName;
  final ProjectStatus status;
  final List<Milestone> milestones;
  final String description;
  final String? lastMessage;
  final bool hasUnreadMessages;
  final double budget;
  final String? deadline;
  final String specialRequirements;
  final bool isUrgent;
  final List<String> referenceImages;
  final double totalAmount;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;
  final DateTime? completedAt;
  /// Increments each time the artist moves accepted → in progress (submission round).
  final int submissionRound;

  Project({
    this.id,
    this.patronId,
    this.artistId,
    this.artistUsername,
    required this.title,
    required this.clientName,
    required this.status,
    this.milestones = const [],
    this.description = '',
    this.lastMessage,
    this.hasUnreadMessages = false,
    this.budget = 0,
    this.deadline,
    this.specialRequirements = '',
    this.isUrgent = false,
    this.referenceImages = const [],
    this.totalAmount = 0,
    this.createdAt,
    this.lastMessageAt,
    this.completedAt,
    this.submissionRound = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'];
    return Project(
      id: json['id'] as int?,
      patronId: (json['patronId'] as num?)?.toInt(),
      artistId: (json['artistId'] as num?)?.toInt(),
      artistUsername: _optionalTrimmedString(json['artistUsername']),
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
      description: (json['description'] as String?) ?? '',
      lastMessage: (json['lastMessage'] as String?) ??
          (json['messagePreview'] as String?),
      hasUnreadMessages: (json['hasUnreadMessages'] as bool?) ??
          (json['unreadMessages'] as bool?) ??
          (json['hasNewMessages'] as bool?) ??
          false,
      budget: _readDouble(json['budget']),
      deadline: (json['deadline'] as String?),
      specialRequirements: (json['specialRequirements'] as String?) ?? '',
      isUrgent: (json['isUrgent'] as bool?) ?? false,
      referenceImages: json['referenceImages'] is List
          ? (json['referenceImages'] as List).whereType<String>().toList()
          : const [],
      totalAmount: _readDouble(json['totalAmount']),
      createdAt: _readDateTime(json['createdAt']),
      lastMessageAt: _readDateTime(json['lastMessageAt']),
      completedAt: _readDateTime(json['completedAt']),
      submissionRound: (json['submissionRound'] as num?)?.toInt() ?? 0,
    );
  }
}

String? _optionalTrimmedString(dynamic v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

DateTime? _readDateTime(dynamic v) {
  if (v == null) return null;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
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

bool _conversationHasUnread(Map<String, dynamic> json) {
  final explicit = json['hasUnreadMessages'] as bool?;
  if (explicit != null) return explicit;
  final legacyUnread = json['unreadMessages'] as bool?;
  if (legacyUnread != null) return legacyUnread;
  final hasRead = json['hasRead'] as bool?;
  if (hasRead != null) return !hasRead;
  return false;
}

class Conversation {
  final int? id;
  final String name;
  final String? lastMessage;
  final tz.TZDateTime? lastMessageDate;
  final bool hasUnreadMessages;
  /// When set, this thread is the commission-scoped chat (not a generic DM).
  final int? commissionId;

  Conversation(
      {this.id,
      required this.name,
      this.lastMessage,
      this.lastMessageDate,
      this.hasUnreadMessages = false,
      this.commissionId});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final phLocation = tz.getLocation('Asia/Manila');
    final rawCid = json['commissionId'];
    final commissionId = rawCid is int
        ? rawCid
        : rawCid is num
            ? rawCid.toInt()
            : int.tryParse('$rawCid');
    return Conversation(
      id: json['id'] as int?,
      name: (json['name'] as String?) ?? '',
      lastMessage: json['lastMessage'] as String?,
      lastMessageDate: json['lastMessageDate'] != null
          ? tz.TZDateTime.from(
              DateTime.parse(json['lastMessageDate'] as String), phLocation)
          : null,
      hasUnreadMessages: _conversationHasUnread(json),
      commissionId: commissionId != null && commissionId > 0 ? commissionId : null,
    );
  }
}

class Message {
  final int? id;
  final int conversationId;
  final int senderId;
  final String content;
  final tz.TZDateTime createdAt;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final phLocation = tz.getLocation('Asia/Manila');
    return Message(
      id: json['id'] as int?,
      conversationId: (json['conversationId'] as num?)?.toInt() ?? 0,
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      content: (json['content'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? tz.TZDateTime.from(
              DateTime.parse(json['createdAt'] as String), phLocation)
          : tz.TZDateTime.now(phLocation),
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
    case 'pending':
    case 'inquiry':
      return ProjectStatus.pending;
    case 'accepted':
      return ProjectStatus.accepted;
    case 'inProgress':
      return ProjectStatus.inProgress;
    case 'completed':
      return ProjectStatus.completed;
    case 'rejected':
      return ProjectStatus.rejected;
    default:
      return ProjectStatus.pending;
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
