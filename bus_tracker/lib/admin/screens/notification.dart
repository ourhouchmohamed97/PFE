import 'dart:async';

import 'package:bus_tracker/admin/screens/driver_info.dart';
import 'package:bus_tracker/core/models/notifications_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);
  static StreamSubscription? _notificationSubscription;

  static Future<void> cancelNotificationListener() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  String? companyId;
  String? userRole;
  List<NotificationItem> _notifications = [];
  String _filter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndListen();
  }

  Future<void> _loadUserDataAndListen() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final data = userDoc.data()!;
      companyId = data['companyId'] as String?;
      userRole = data['role'] as String?;

      _listenNotifications();
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _listenNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    Query query = _firestore.collection('notifications');

    if (userRole == 'admin') {
      query = query
          .where('targetAdminUid', isEqualTo: user.uid)
          .where('companyId', isEqualTo: companyId);
    } else {
      query = query.where('targetAdminUid', isEqualTo: user.uid);
    }

    _notificationsSubscription = query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        final notifications = snapshot.docs
            .map((doc) => NotificationItem.fromFirestore(doc))
            .toList();
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Notification listener error: $error');
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  List<NotificationItem> get filteredNotifications {
    if (_filter == 'All') return _notifications;
    if (_filter == 'Unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    if (_filter == 'Read') {
      return _notifications.where((n) => n.isRead).toList();
    }
    return _notifications;
  }

  Future<void> _markAllAsRead() async {
    for (var notification in _notifications) {
      if (!notification.isRead) {
        await _firestore
            .collection('notifications')
            .doc(notification.docId)
            .update({'isRead': true});
        notification.isRead = true;
      }
    }
    setState(() {});
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (!notification.isRead) {
      await _firestore
          .collection('notifications')
          .doc(notification.docId)
          .update({'isRead': true});
      setState(() => notification.isRead = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _filter,
              onChanged: (value) => setState(() => _filter = value!),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Unread', child: Text('Unread')),
                DropdownMenuItem(value: 'Read', child: Text('Read')),
              ],
            ),
          ),
          Expanded(
            child: filteredNotifications.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.builder(
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!notification.isRead) _markAsRead(notification);
                      });

                      return ListTile(
                        leading: Icon(
                          notification.iconData,
                          color: notification.iconColor,
                        ),
                        title: Text(notification.title),
                        subtitle: Text(
                          '${notification.description}\n${_formatTimestamp(notification.timestamp)}',
                        ),
                        trailing: notification.isRead
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.done, color: Colors.blue, size: 18),
                                  SizedBox(width: 2),
                                  Icon(Icons.done_all, color: Colors.blue, size: 18),
                                ],
                              )
                            : const Icon(Icons.done, color: Colors.grey, size: 18),
                        onTap: () async {
                          if (userRole == 'admin' &&
                              notification.title ==
                                  'New Driver Registration Request') {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DriverDetailPage(
                                  driverUid: notification.driverUid!,
                                  notificationDocId: notification.docId,
                                ),
                              ),
                            );
                            if (result != null && mounted) {
                              setState(() => notification.isRead = true);
                            }
                          } else {
                            await _markAsRead(notification);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}