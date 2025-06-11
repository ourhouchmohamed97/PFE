import 'package:bus_tracker/core/models/notifications_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? companyId;
  List<NotificationItem> _notifications = [];
  String _filter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyIdAndNotifications();
  }

  Future<void> _loadCompanyIdAndNotifications() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = userDoc.data()!;
      final fetchedCompanyId = data['companyId'] as String?;

      if (fetchedCompanyId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        companyId = fetchedCompanyId;
      });

      _listenNotifications(); // now filters by user email
    } catch (e) {
      print('Error loading companyId or notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenNotifications() {
    final user = _auth.currentUser;
    if (companyId == null || user == null) return;

    _firestore
        .collection('notifications')
        .where('targetUserEmail', isEqualTo: user.email) // <-- filter by current admin
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc))
          .toList();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    });
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
      setState(() {
        notification.isRead = true;
      });
    }
  }

  Future<void> _approveDriver(NotificationItem notification) async {
    try {
      final driverEmail = notification.driverEmail;

      if (driverEmail == null) {
        print('Driver email missing in notification');
        return;
      }

      final adminsQuery = await _firestore
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: 'admin')
          .get();

      for (var adminDoc in adminsQuery.docs) {
        final adminEmail = adminDoc.data()['email'];

        await _firestore.collection('notifications').add({
          'title': 'Driver Account Approved',
          'description': 'Driver account ($driverEmail) has been approved.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'targetUserEmail': adminEmail,
          'iconData': Icons.thumb_up.codePoint,
          'iconColor': 0xFF4CAF50,
          'iconFontFamily': Icons.thumb_up.fontFamily,
          'iconFontPackage': Icons.thumb_up.fontPackage,
          'driverEmail': driverEmail,
          'companyId': companyId,
        });
      }
    } catch (e) {
      print('Error approving driver: $e');
    }
  }

  Future<void> _rejectDriver(NotificationItem notification) async {
    // Add rejection logic here
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
              onChanged: (value) {
                setState(() {
                  _filter = value!;
                });
              },
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
                      return ListTile(
                        leading: Icon(
                          IconData(
                            notification.iconData as int,
                            fontFamily: notification.iconFontFamily,
                            fontPackage: notification.iconFontPackage,
                          ),
                          color: notification.iconColor,
                        ),
                        title: Text(notification.title),
                        subtitle: Text(
                          '${notification.description}\n${_formatTimestamp(notification.timestamp)}',
                        ),
                        trailing: notification.title ==
                                'New Driver Registration Request'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    tooltip: 'Approve',
                                    onPressed: () async {
                                      await _approveDriver(notification);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    tooltip: 'Reject',
                                    onPressed: () async {
                                      await _rejectDriver(notification);
                                    },
                                  ),
                                ],
                              )
                            : Icon(
                                notification.isRead
                                    ? Icons.check
                                    : Icons.mark_email_unread,
                                color: notification.isRead
                                    ? Colors.green
                                    : Colors.red,
                              ),
                        onTap: () => _markAsRead(notification),
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
