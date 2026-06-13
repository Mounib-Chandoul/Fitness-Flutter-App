import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotifsPage extends StatefulWidget {
  const NotifsPage({super.key});

  @override
  State<NotifsPage> createState() => _NotifsPageState();
}

class Notification {
  final String id;
  final String title;
  final String message;
  final String time;
  final String type; // 'purchase', 'achievement', 'message'

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'time': time,
    'type': type,
  };

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    time: json['time'] ?? '',
    type: json['type'] ?? 'message',
  );
}

class _NotifsPageState extends State<NotifsPage> {
  late Future<List<Notification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<Notification>> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifJson = prefs.getStringList('notifications') ?? [];
      return notifJson
          .map((json) => Notification.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      return [];
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifJson = prefs.getStringList('notifications') ?? [];
      notifJson.removeWhere(
        (json) => Notification.fromJson(jsonDecode(json)).id == id,
      );
      await prefs.setStringList('notifications', notifJson);
      setState(() {
        _notificationsFuture = _loadNotifications();
      });
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D09),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF07120C), Color(0xFF050D09)],
                ),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 24,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF07120C), Color(0xFF050D09)],
                  ),
                ),
                child: FutureBuilder<List<Notification>>(
                  future: _notificationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1CFF4D),
                        ),
                      );
                    }

                    final notifications = snapshot.data ?? [];

                    if (notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return _buildNotificationCard(notif, () {
                          _deleteNotification(notif.id);
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildNotificationCard(Notification notif, VoidCallback onDelete) {
  // Get icon based on notification type
  IconData getIcon(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_cart;
      case 'achievement':
        return Icons.emoji_events;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color getTypeColor(String type) {
    switch (type) {
      case 'purchase':
        return const Color(0xFF1CFF4D);
      case 'achievement':
        return Colors.amber;
      case 'message':
        return Colors.blue;
      default:
        return Colors.white70;
    }
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    getIcon(notif.type),
                    color: getTypeColor(notif.type),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notif.title,
                      style: TextStyle(
                        color: getTypeColor(notif.type),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          notif.message,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(notif.time, style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    ),
  );
}
