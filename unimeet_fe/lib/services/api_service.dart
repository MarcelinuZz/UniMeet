import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/meetup_model.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  static const String baseUrl = 'http://localhost:3000/api/v1';

  // ==========================================
  // 1. REAL EVENTS (0 Mock Events)
  // ==========================================
  Future<List<MeetupItem>> fetchEvents({String? currentUserEmail}) async {
    try {
      final query = currentUserEmail != null && currentUserEmail.isNotEmpty
          ? '?userEmail=${Uri.encodeComponent(currentUserEmail)}'
          : '';
      final res = await http
          .get(Uri.parse('$baseUrl/events/feed$query'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List eventsJson = body['data'] is List
            ? body['data']
            : (body['data']?['events'] ?? body['events'] ?? []);
        return eventsJson.map((e) => _mapJsonToMeetup(e, currentUserEmail)).toList();
      }
    } catch (e) {
      debugPrint('ApiService fetchEvents error: $e');
    }
    return [];
  }

  Future<MeetupItem?> createEvent({
    required String hostEmail,
    required String title,
    required String description,
    required String category,
    required String timeString,
    required String location,
    required String campus,
    required String cost,
    required int maxParticipants,
    required String vibe,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'hostEmail': hostEmail,
          'title': title,
          'description': description,
          'category': category.toUpperCase(),
          'dateTime': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
          'timeString': timeString,
          'location': location,
          'campus': campus,
          'cost': cost,
          'maxParticipants': maxParticipants,
          'vibe': vibe,
          'campusVerifiedOnly': true,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = json.decode(res.body);
        final ev = body['event'] ?? body['data'] ?? body;
        return _mapJsonToMeetup(ev, hostEmail);
      }
    } catch (e) {
      debugPrint('ApiService createEvent error: $e');
    }
    return null;
  }

  Future<bool> joinEvent(String eventId, String userEmail) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/events/$eventId/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userEmail': userEmail}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService joinEvent error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchMySchedules(String email) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/events/my-schedules?email=$email'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService fetchMySchedules error: $e');
    }
    return {'upcomingCount': 0, 'pastCount': 0, 'upcoming': [], 'past': []};
  }

  Future<Map<String, dynamic>?> fetchEventDetails(String eventId, [String? userEmail]) async {
    try {
      final query = userEmail != null && userEmail.isNotEmpty ? '?email=$userEmail' : '';
      final res = await http
          .get(Uri.parse('$baseUrl/events/$eventId$query'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService fetchEventDetails error: $e');
    }
    return null;
  }

  MeetupItem _mapJsonToMeetup(Map<String, dynamic> json, [String? currentEmail]) {
    final host = json['host'] ?? {};
    final category = (json['category'] ?? 'SPORTS').toString().toLowerCase();
    String emoji = '🏸';
    if (category == 'gaming') emoji = '🎯';
    if (category == 'academic') emoji = '📚';
    if (category == 'tech') emoji = '☕';
    if (category == 'food') emoji = '🍔';

    final participants = json['participants'] as List? ?? [];
    final roster = json['roster'] as List? ?? participants;
    final initials = roster.map((r) {
      if (r is Map && r['avatar'] != null) return r['avatar'].toString();
      if (r is Map && r['user'] is Map && r['user']['avatarInitials'] != null) {
        return r['user']['avatarInitials'].toString();
      }
      return 'UM';
    }).toList();

    bool isJoined = json['isJoined'] == true;
    if (currentEmail != null && currentEmail.isNotEmpty) {
      final hostMail = (host['email'] ?? '').toString().toLowerCase();
      if (hostMail.isNotEmpty && hostMail == currentEmail.toLowerCase()) {
        isJoined = true;
      }
      for (final p in roster) {
        if (p is Map) {
          final pEmail = (p['email'] ?? (p['user'] is Map ? p['user']['email'] : null) ?? '')
              .toString()
              .toLowerCase();
          if (pEmail.isNotEmpty && pEmail == currentEmail.toLowerCase()) {
            isJoined = true;
          }
        }
      }
    }

    final maxSlots = json['maxParticipants'] ?? json['maxSlots'] ?? 6;
    final currentSlots = json['currentSlots'] ?? (participants.isNotEmpty ? participants.length : 1);

    return MeetupItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Meetup',
      category: category,
      categoryEmoji: emoji,
      hostName: host['name'] ?? 'Binusian Host',
      hostMajor: host['batch'] ?? host['major'] ?? "CS '24",
      hostAvatar: host['avatarUrl'] ??
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
      time: json['timeString'] ?? 'Today',
      location: json['location'] ?? 'BINUS Campus',
      cost: json['cost'] ?? 'Free',
      slotsLeft: (maxSlots - currentSlots) > 0 ? (maxSlots - currentSlots) : 0,
      totalSlots: maxSlots,
      confirmedCount: currentSlots,
      tags: ['#${category.toUpperCase()}', '#BINUSAnggrek', '#UniMeetVerified'],
      attendeeInitials: initials.isNotEmpty ? initials : ['UM'],
      description: json['description'] ?? '',
      isJoined: isJoined,
    );
  }

  // ==========================================
  // 2. REAL USERS & STUDENTS DIRECTORY
  // ==========================================
  Future<List<Map<String, dynamic>>> fetchDirectory({String? search}) async {
    try {
      final query = search != null && search.isNotEmpty ? '?search=$search' : '';
      final res = await http
          .get(Uri.parse('$baseUrl/users/directory$query'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService fetchDirectory error: $e');
    }
    return [];
  }

  // ==========================================
  // 3. FRIEND REQUESTS & REAL RELATIONS
  // ==========================================
  Future<List<Map<String, dynamic>>> fetchFriends(String userEmail) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/users/friends?user=$userEmail'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService fetchFriends error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchFriendRequests(String userEmail) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/users/friend-requests?user=$userEmail'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService fetchFriendRequests error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> getFriendshipStatus(String userEmail, String targetEmail) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/users/friendship-status?user=$userEmail&target=$targetEmail'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService getFriendshipStatus error: $e');
    }
    return {'status': 'NONE'};
  }

  Future<bool> sendFriendRequest(String senderEmail, String receiverEmail) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/friend-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sender': senderEmail, 'receiver': receiverEmail}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService sendFriendRequest error: $e');
      return false;
    }
  }

  Future<bool> respondFriendRequest(String requestId, String action) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/friend-request/respond'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'requestId': requestId, 'action': action}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService respondFriendRequest error: $e');
      return false;
    }
  }

  // ==========================================
  // 4. REAL 1-ON-1 DIRECT CHAT
  // ==========================================
  Future<Map<String, dynamic>> fetchDirectMessages(String userEmail, String partnerEmail) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/chat/direct/messages?user=$userEmail&partner=$partnerEmail'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService fetchDirectMessages error: $e');
    }
    return {
      'canChat': false,
      'status': 'ERROR',
      'reason': 'Unable to connect to chat server',
      'messages': [],
    };
  }

  Future<Map<String, dynamic>?> sendDirectMessage(
    String senderEmail,
    String receiverEmail,
    String content,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chat/direct/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender': senderEmail,
          'senderEmail': senderEmail,
          'receiver': receiverEmail,
          'receiverEmail': receiverEmail,
          'content': content,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return json.decode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService sendDirectMessage error: $e');
    }
    return null;
  }

  // ==========================================
  // 5. REAL EVENT GROUP CHAT
  // ==========================================
  Future<List<Map<String, dynamic>>> fetchEventMessages(String eventId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/chat/$eventId/messages'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService fetchEventMessages error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> sendEventMessage(
    String eventId,
    String senderEmail,
    String content,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chat/$eventId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': senderEmail,
          'senderEmail': senderEmail,
          'content': content,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return json.decode(res.body);
      } else {
        debugPrint('ApiService sendEventMessage failed (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      debugPrint('ApiService sendEventMessage error: $e');
    }
    return null;
  }
}
