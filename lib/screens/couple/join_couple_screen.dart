import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinCoupleScreen extends StatefulWidget {
  const JoinCoupleScreen({super.key});

  @override
  State<JoinCoupleScreen> createState() => _JoinCoupleScreenState();
}

class _JoinCoupleScreenState extends State<JoinCoupleScreen> {
  final inviteCodeController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> joinCouple() async {
    final user = FirebaseAuth.instance.currentUser;
    final inviteCode = inviteCodeController.text.trim();

    if (user == null) {
      setState(() {
        errorMessage = 'No signed-in user was found.';
      });
      return;
    }

    if (inviteCode.isEmpty) {
      setState(() {
        errorMessage = 'Please enter an invite code.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final inviteReference = FirebaseFirestore.instance
          .collection('coupleInvites')
          .doc(inviteCode);

      final inviteSnapshot = await inviteReference.get();

      if (!inviteSnapshot.exists) {
        setState(() {
          errorMessage = 'That invite code was not found.';
        });
        return;
      }

      final inviteData = inviteSnapshot.data();
      final coupleId = inviteData?['coupleId'] as String?;

      if (coupleId == null || coupleId.trim().isEmpty) {
        setState(() {
          errorMessage = 'That invite code is invalid.';
        });
        return;
      }

      final coupleReference = FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId);

      final userReference = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final batch = FirebaseFirestore.instance.batch();

      batch.update(coupleReference, {
        'memberIds': FieldValue.arrayUnion([user.uid]),
      });

      batch.update(userReference, {'coupleId': coupleId});

      await batch.commit();
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          if (error.code == 'permission-denied') {
            errorMessage = 'Unable to join this couple. The invite may already have been used.';
          } else {
            errorMessage = error.message ?? 'Unable to join the couple.';
          }
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
    inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Your Partner')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join your partner\'s team',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the invite code your partner shared with you.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: inviteCodeController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Invite code',
                  hintText: 'Enter your partner\'s invite code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: isLoading ? null : joinCouple,
                icon: const Icon(Icons.group_add),
                label: Text(isLoading ? 'Joining...' : 'Join Couple'),
              ),
              const SizedBox(height: 16),
              Text(
                'Invite codes are case-sensitive, so enter the code exactly as it was shared.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
