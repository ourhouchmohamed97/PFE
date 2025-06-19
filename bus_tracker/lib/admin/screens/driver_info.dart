import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverDetailPage extends StatelessWidget {
  final String driverUid;
  final String? notificationDocId;
  

  const DriverDetailPage({
    Key? key,
    required this.driverUid,
    this.notificationDocId,
  }) : super(key: key);

  Future<Map<String, dynamic>?> _fetchDriverDetails() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(driverUid).get();
    return doc.data();
  }

 Future<void> _approveDriver(BuildContext context) async {
  final driverDoc = await FirebaseFirestore.instance.collection('users').doc(driverUid).get();
  final driverData = driverDoc.data();
  final companyId = driverData?['companyId'] ?? '';

  await FirebaseFirestore.instance
      .collection('users')
      .doc(driverUid)
      .update({'status': 'approved'});

  await FirebaseFirestore.instance.collection('notifications').add({
    'title': 'Account Approved',
    'description': 'Your driver account has been approved.',
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': false,
    'targetUserUid': driverUid,
    'iconData': Icons.check_circle.codePoint,
    'iconColor': Colors.green.value,
    'iconFontFamily': Icons.check_circle.fontFamily,
    'iconFontPackage': Icons.check_circle.fontPackage,
    'companyId': companyId,
  });

  if (notificationDocId != null) {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationDocId)
        .update({'isRead': true});
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Driver approved")),
  );

  Navigator.of(context).pop(true);
}


Future<void> _rejectDriver(BuildContext context) async {
  final driverDoc = await FirebaseFirestore.instance.collection('users').doc(driverUid).get();
  final driverData = driverDoc.data();
  final companyId = driverData?['companyId'] ?? '';
  await FirebaseFirestore.instance
      .collection('users')
      .doc(driverUid)
      .update({'status': 'rejected'});

  // Send notification to the driver
  await FirebaseFirestore.instance.collection('notifications').add({
    'title': 'Account Rejected',
    'description': 'Your driver account has been rejected.',
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': false,
    'targetUserUid': driverUid,
    'iconData': Icons.cancel.codePoint,
    'iconColor': Colors.red,
    'iconFontFamily': Icons.cancel.fontFamily,
    'iconFontPackage': Icons.cancel.fontPackage,
    'companyId': companyId,
  });

  if (notificationDocId != null) {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationDocId)
        .update({'isRead': true});
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Driver rejected")),
  );

  Navigator.of(context).pop(false);
}

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchDriverDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Driver not found'));
          }

          final driver = snapshot.data!;
          final name = driver['name'] ?? 'Not specified';
          final email = driver['email'] ?? 'Not specified';
          final phone = driver['phone'] ?? 'Not specified';
          final status = driver['status'] ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'D',
                    style: TextStyle(
                      fontSize: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                  style: TextStyle(
                    color: status == 'approved'
                        ? Colors.green
                        : status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Divider(height: 40),
                _buildInfoRow('Email', email),
                _buildInfoRow('Phone', phone),
                // Add more fields as needed

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        onPressed: status == 'approved'
                            ? null
                            : () => _approveDriver(context),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        onPressed: status == 'rejected'
                            ? null
                            : () => _rejectDriver(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
