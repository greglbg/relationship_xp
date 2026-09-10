import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final displayNameController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> saveProfile() async {
    final displayName = displayNameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (displayName.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a display name.';
      });
      return;
    }

    if (user == null) {
      setState(() {
        errorMessage = 'No signed-in user was found.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'displayName': displayName},
      );
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What should we call you?',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This will be your display name inside Relationship XP.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: displayNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading ? null : saveProfile,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
