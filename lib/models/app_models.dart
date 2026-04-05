import 'package:timezone/timezone.dart' as tz;

enum ProjectStatus {
  pending,
  accepted,
  inProgress,
  completed,
  rejected,
}

/// Server-tracked escrow for commission payments (integrate PSP for real money movement).
enum EscrowStatus {
  none,
  funded,
  released,
  refunded,
}

/// Simulated platform wallet — API tracks amounts until completion (no real funds until PSP).
class EscrowSimulation {
  final String mode;
  final String currency;
  final String phase;
  final double commissionTotal;
  final double heldInEscrow;
  final double releasedToArtist;
  final double refundedToPatron;
  final String releaseGoal;
  final String refundNote;
  final String disclaimer;

  const EscrowSimulation({
    this.mode = 'simulated',
    this.currency = 'PHP',
    required this.phase,
    this.commissionTotal = 0,
    this.heldInEscrow = 0,
    this.releasedToArtist = 0,
    this.refundedToPatron = 0,
    this.releaseGoal = '',
    this.refundNote = '',
    this.disclaimer = '',
  });

  factory EscrowSimulation.fromJson(Map<String, dynamic> json) {
    return EscrowSimulation(
      mode: (json['mode'] as String?) ?? 'simulated',
      currency: (json['currency'] as String?) ?? 'PHP',
      phase: (json['phase'] as String?) ?? 'awaiting_funding',
      commissionTotal: _readDouble(json['commissionTotal']),
      heldInEscrow: _readDouble(json['heldInEscrow']),
      releasedToArtist: _readDouble(json['releasedToArtist']),
      refundedToPatron: _readDouble(json['refundedToPatron']),
      releaseGoal: (json['releaseGoal'] as String?) ?? '',
      refundNote: (json['refundNote'] as String?) ?? '',
      disclaimer: (json['disclaimer'] as String?) ?? '',
    );
  }
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
  final String? artistAvatarUrl;
  final String? patronAvatarUrl;
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
  /// Server paths or URLs for artwork the artist submitted for review (see API `submissionImages`).
  final List<String> submissionImages;
  final double totalAmount;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;
  final DateTime? completedAt;
  /// Increments each time the artist moves accepted → in progress (submission round).
  final int submissionRound;
  final String? paymentMethod;
  final EscrowStatus escrowStatus;
  final DateTime? escrowFundedAt;
  final DateTime? escrowReleasedAt;
  /// Patron's choice when submitting the request (before actual payment / escrow fund).
  final String? preferredPaymentMethod;
  final EscrowSimulation? escrowSimulation;

  Project({
    this.id,
    this.patronId,
    this.artistId,
    this.artistUsername,
    this.artistAvatarUrl,
    this.patronAvatarUrl,
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
    this.submissionImages = const [],
    this.totalAmount = 0,
    this.createdAt,
    this.lastMessageAt,
    this.completedAt,
    this.submissionRound = 0,
    this.paymentMethod,
    this.escrowStatus = EscrowStatus.none,
    this.escrowFundedAt,
    this.escrowReleasedAt,
    this.preferredPaymentMethod,
    this.escrowSimulation,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'];
    return Project(
      id: json['id'] as int?,
      patronId: (json['patronId'] as num?)?.toInt(),
      artistId: (json['artistId'] as num?)?.toInt(),
      artistUsername: _optionalTrimmedString(json['artistUsername']),
      artistAvatarUrl: _optionalTrimmedString(json['artistAvatarUrl']),
      patronAvatarUrl: _optionalTrimmedString(json['patronAvatarUrl']),
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
      submissionImages: json['submissionImages'] is List
          ? (json['submissionImages'] as List).whereType<String>().toList()
          : const [],
      totalAmount: _readDouble(json['totalAmount']),
      createdAt: _readDateTime(json['createdAt']),
      lastMessageAt: _readDateTime(json['lastMessageAt']),
      completedAt: _readDateTime(json['completedAt']),
      submissionRound: (json['submissionRound'] as num?)?.toInt() ?? 0,
      paymentMethod: _optionalTrimmedString(json['paymentMethod']),
      escrowStatus: _escrowStatusFromString(json['escrowStatus'] as String?),
      escrowFundedAt: _readDateTime(json['escrowFundedAt']),
      escrowReleasedAt: _readDateTime(json['escrowReleasedAt']),
      preferredPaymentMethod: _optionalTrimmedString(json['preferredPaymentMethod']),
      escrowSimulation: json['escrowSimulation'] is Map<String, dynamic>
          ? EscrowSimulation.fromJson(json['escrowSimulation'] as Map<String, dynamic>)
          : json['escrowSimulation'] is Map
              ? EscrowSimulation.fromJson(
                  (json['escrowSimulation'] as Map).map((k, v) => MapEntry('$k', v)),
                )
              : null,
    );
  }
}

EscrowStatus _escrowStatusFromString(String? raw) {
  switch (raw) {
    case 'funded':
      return EscrowStatus.funded;
    case 'released':
      return EscrowStatus.released;
    case 'refunded':
      return EscrowStatus.refunded;
    default:
      return EscrowStatus.none;
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
  /// Profile photo URL for the other participant (HTTPS, data URL, or API-relative path).
  final String? otherUserAvatarUrl;
  final String? lastMessage;
  final tz.TZDateTime? lastMessageDate;
  final bool hasUnreadMessages;
  /// When set, this thread is the commission-scoped chat (not a generic DM).
  final int? commissionId;

  Conversation(
      {this.id,
      required this.name,
      this.otherUserAvatarUrl,
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
      otherUserAvatarUrl: _optionalTrimmedString(json['otherUserAvatarUrl']),
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

/// Maps API-stored names (create request / commission) to [PaymentMethodType].
PaymentMethodType paymentMethodTypeFromStoredName(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'paymaya':
      return PaymentMethodType.paymaya;
    case 'paypal':
      return PaymentMethodType.paypal;
    case 'stripe':
      return PaymentMethodType.stripe;
    case 'gcash':
    default:
      return PaymentMethodType.gcash;
  }
}

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
