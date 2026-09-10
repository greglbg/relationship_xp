import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/couple/couple_setup_screen.dart';
import '../screens/home/home_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text('Unable to load your profile.')),
              );
            }

            final data = profileSnapshot.data?.data();

            if (data == null) {
              return const Scaffold(
                body: Center(child: Text('Profile not found.')),
              );
            }

            final displayName = data['displayName'] as String?;
            final coupleId = data['coupleId'] as String?;

            if (displayName == null || displayName.trim().isEmpty) {
              return const ProfileSetupScreen();
            }

            if (coupleId == null || coupleId.trim().isEmpty) {
              return const CoupleSetupScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}
