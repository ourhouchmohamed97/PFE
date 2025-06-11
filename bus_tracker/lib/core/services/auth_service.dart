import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String STATUS_PENDING = 'pending';
  static const String STATUS_APPROVED = 'approved';
  static const String STATUS_REJECTED = 'rejected';

  String _generateCompanyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    String? companyCode,
    String? companyName,
    String? businessType,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = result.user;
      if (user == null) return 'Account creation failed.';

      await user.sendEmailVerification();

      final userData = {
        'uid': user.uid,
        'name': name,
        'email': email.toLowerCase(),
        'phone': phoneNumber,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      };

      if (role == 'admin') {
        final companyRef = _firestore.collection('companies').doc();
        final companyId = companyRef.id;
        final newCompanyCode = _generateCompanyCode();

        await companyRef.set({
          'companyId': companyId,
          'companyName': companyName ?? '',
          'businessType': businessType ?? '',
          'adminUid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'companyCode': newCompanyCode,
        });

        await _firestore.collection('companyCodes').doc(newCompanyCode).set({
          'companyId': companyId,
          'adminUid': user.uid,
        });

        userData.addAll({
          'companyId': companyId,
          'companyCode': newCompanyCode,
          'status': STATUS_APPROVED,
        });
      } else if (role == 'driver') {
        if (companyCode == null || companyCode.trim().isEmpty) {
          return 'Company code is required for drivers.';
        }

        final codeSnap = await _firestore.collection('companyCodes').doc(companyCode).get();
        if (!codeSnap.exists) return 'Invalid company code.';

        final companyId = codeSnap['companyId'];
        final adminUid = codeSnap['adminUid'];

        userData.addAll({
          'companyId': companyId,
          'status': STATUS_PENDING,
          'isVerified': false,
        });

        await _firestore.collection('notifications').add({
          'title': 'New Driver Registration Request',
          'description': '$name requested to join your company.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'companyId': companyId,
          'targetAdminUid': adminUid,
          'driverEmail': email.toLowerCase(),
          'iconCodePoint': Icons.person_add.codePoint,
          'iconColor': 0xFFFF9800,
        });
      } else {
        return 'Invalid role.';
      }

      await _firestore.collection('users').doc(user.uid).set(userData);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Authentication error';
    } catch (e) {
      print('Unexpected error during registration: $e');
      return 'An unknown error occurred.';
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = result.user;
      if (user == null) return 'Login failed.';

      if (!user.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email before logging in.';
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) {
        await _auth.signOut();
        return 'User data not found.';
      }

      final status = userData['status'];

      if (userData['role'] == 'driver' && status == STATUS_PENDING) {
        await _auth.signOut();
        return 'Your account is pending approval from admin.';
      }

      if (status == STATUS_REJECTED) {
        await _auth.signOut();
        return 'Your registration was rejected.';
      }

      return null; // Login success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Authentication failed';
    } catch (e) {
      print('Unexpected error during login: $e');
      return 'An unknown error occurred.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
