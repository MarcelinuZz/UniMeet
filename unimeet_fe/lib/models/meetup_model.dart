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
  final DateTime? dateTime;

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
    this.dateTime,
  });

  static String formatRelativeTime(dynamic dateTimeVal, [String? rawTimeString]) {
    DateTime? dt;
    if (dateTimeVal is DateTime) {
      dt = dateTimeVal.toLocal();
    } else if (dateTimeVal is String && dateTimeVal.trim().isNotEmpty) {
      dt = DateTime.tryParse(dateTimeVal.trim())?.toLocal();
    }

    String timeWindow = '';
    if (rawTimeString != null && rawTimeString.trim().isNotEmpty) {
      timeWindow = rawTimeString.trim().replaceFirst(
        RegExp(r'^(Today|Yesterday|Tomorrow|Hari Ini|Besok|Kemarin)\s*([•,·\-|]\s*)?', caseSensitive: false),
        '',
      ).trim();
    }

    if (dt == null) {
      return timeWindow.isNotEmpty ? timeWindow : (rawTimeString ?? 'Today');
    }

    if (timeWindow.isEmpty) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      timeWindow = '$hour:$minute WIB';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = target.difference(today).inDays;

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String datePrefix;
    if (diffDays == 0) {
      datePrefix = 'Today';
    } else if (diffDays == 1) {
      datePrefix = 'Tomorrow';
    } else if (diffDays == -1) {
      datePrefix = 'Yesterday';
    } else if (diffDays > 1 && diffDays < 7) {
      datePrefix = '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
    } else {
      datePrefix = '${dt.day} ${months[dt.month - 1]} ${dt.year != now.year ? dt.year : ''}'.trim();
    }

    return '$datePrefix • $timeWindow';
  }
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
