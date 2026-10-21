class MeetupItem {
  final String id;
  final String title;
  final String category;
  final String categoryEmoji;
  final String hostName;
  final String hostMajor;
  final String hostAvatar;
  final bool isHostVerified;
  final String time;
  final String location;
  final String? cost;
  final int slotsLeft;
  final int totalSlots;
  final int confirmedCount;
  final List<String> tags;
  final String? imageUrl;
  final String? hostPerk;
  final String? description;
  final List<String> attendeeInitials;
  bool isJoined;
  bool isBookmarked;

  MeetupItem({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryEmoji,
    required this.hostName,
    required this.hostMajor,
    required this.hostAvatar,
    this.isHostVerified = true,
    required this.time,
    required this.location,
    this.cost,
    required this.slotsLeft,
    required this.totalSlots,
    required this.confirmedCount,
    required this.tags,
    this.imageUrl,
    this.hostPerk,
    this.description,
    this.attendeeInitials = const [],
    this.isJoined = false,
    this.isBookmarked = false,
  });
}

class ChatMessage {
  final String id;
  final String senderName;
  final String? senderMajor;
  final String avatarUrl;
  final String text;
  final String time;
  final bool isSelf;
  final bool isHost;
  final String? bookingSlip;
  final Map<String, int>? reactions;

  ChatMessage({
    required this.id,
    required this.senderName,
    this.senderMajor,
    required this.avatarUrl,
    required this.text,
    required this.time,
    this.isSelf = false,
    this.isHost = false,
    this.bookingSlip,
    this.reactions,
  });
}

class PollOption {
  final String text;
  int votes;
  bool isSelected;

  PollOption({
    required this.text,
    required this.votes,
    this.isSelected = false,
  });
}
