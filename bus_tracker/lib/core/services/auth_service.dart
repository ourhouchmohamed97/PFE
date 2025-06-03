import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    String? adminEmail,
    String? companyName,
    String? businessType,
  }) async {
    try {
      // 1. Create Firebase Auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        return 'Account creation failed. Please try again.';
      }

      // 2. Send email verification
      await user.sendEmailVerification();

      // 3. Prepare user data
      final userData = {
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': phoneNumber,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      };

      if (role == 'admin') {
        // 4. Create a new company document and get its ID
        final companyRef = _firestore.collection('companies').doc();
        final companyId = companyRef.id;

        // 5. Create company data
        await companyRef.set({
          'companyId': companyId,
          'companyName': companyName ?? '',
          'businessType': businessType ?? '',
          'adminUid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 6. Add companyId to user data
        userData['companyId'] = companyId;
      } else if (role == 'driver') {
        if (adminEmail == null || adminEmail.isEmpty) {
          return 'Admin email is required for driver registration.';
        }

        // Look up the admin user
        final adminSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: adminEmail)
            .where('role', isEqualTo: 'admin')
            .limit(1)
            .get();

        if (adminSnapshot.docs.isEmpty) {
          return 'No admin found with this email.';
        }

        final adminDoc = adminSnapshot.docs.first;
        final adminData = adminDoc.data();
        final adminUid = adminDoc.id;
        final companyId = adminData['companyId'];

        userData.addAll({
          'adminEmail': adminEmail,
          'companyId': companyId,
          'status': 'pending', // To be approved
        });

        // 7. Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set(userData);

        // 8. Send notification to admin
        await _firestore.collection('notifications').add({
          'title': 'New Driver Registration Request',
          'description': '$name requested to join your company.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'companyId': companyId,
          'targetAdminUid': adminUid,
          'driverEmail': email, // add this field here
          'iconData': Icons.person_add.codePoint,
          'iconColor': 0xFFFF9800,
          'iconFontFamily': Icons.person_add.fontFamily,
          'iconFontPackage': Icons.person_add.fontPackage,
        });
      }

      // 9. Save user data for admin
      if (role == 'admin') {
        await _firestore.collection('users').doc(user.uid).set(userData);
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      print('Unexpected error: $e');
      return 'An unknown error occurred. Please try again.';
    }
  }
}
