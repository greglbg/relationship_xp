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
      final firestore = FirebaseFirestore.instance;

      final inviteReference = firestore
          .collection('coupleInvites')
          .doc(inviteCode);

      final inviteSnapshot = await inviteReference.get();

      if (!inviteSnapshot.exists) {
        throw Exception('That invite code could not be found.');
      }

      final inviteData = inviteSnapshot.data();

      if (inviteData == null) {
        throw Exception('That invitation could not be loaded.');
      }

      final coupleId = inviteData['coupleId'] as String?;

      if (coupleId == null || coupleId.trim().isEmpty) {
        throw Exception('That invitation does not contain a valid couple.');
      }

      final coupleReference = firestore.collection('couples').doc(coupleId);

      final userReference = firestore.collection('users').doc(user.uid);

      final batch = firestore.batch();

      batch.update(coupleReference, {
        'memberIds': FieldValue.arrayUnion([user.uid]),
      });

      batch.update(userReference, {'coupleId': coupleId});

      await batch.commit();

      if (!mounted) {
        return;
      }

      // The join screen was pushed on top of CoupleSetupScreen.
      // AuthGate reacts to the Firestore changes and changes the root
      // application state to HomeScreen. Popping this route removes the
      // old JoinCoupleScreen so the new AuthGate destination is visible.
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (error.code == 'permission-denied') {
          errorMessage =
              'Firebase did not allow this couple to be joined. '
              'Please check the invite code and try again.';
        } else {
          errorMessage = error.message ?? 'Unable to join the couple.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
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
      appBar: AppBar(title: const Text('Join Couple')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join your partner',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the invite code your partner generated.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: inviteCodeController,
                enabled: !isLoading,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Invite Code',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: isLoading
                    ? null
                    : (_) {
                        joinCouple();
                      },
              ),
              const SizedBox(height: 24),
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
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.group_add),
                label: Text(isLoading ? 'Joining...' : 'Join Couple'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
