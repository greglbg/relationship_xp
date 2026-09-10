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

      // Step 1:
      // Find the invitation document that matches the entered code.
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

      // Step 2:
      // Read the couple before trying to join it.
      final coupleSnapshot = await coupleReference.get();

      if (!coupleSnapshot.exists) {
        throw Exception(
          'The couple connected to this invite no longer exists.',
        );
      }

      final coupleData = coupleSnapshot.data();

      if (coupleData == null) {
        throw Exception('The couple information could not be loaded.');
      }

      final memberIds = List<String>.from(coupleData['memberIds'] ?? []);

      if (memberIds.contains(user.uid)) {
        // This user is already a member.
        // We only need to make sure their profile points to the couple.
        await firestore.collection('users').doc(user.uid).update({
          'coupleId': coupleId,
        });

        return;
      }

      if (memberIds.length >= 2) {
        throw Exception('This couple already has two members.');
      }

      // Step 3:
      // Add this user to the couple FIRST.
      //
      // We deliberately do this separately from the user profile update.
      // AuthGate watches the user profile, so we do not want it to see a
      // coupleId until Firestore has confirmed that this user is actually
      // a member of that couple.
      await coupleReference.update({
        'memberIds': FieldValue.arrayUnion([user.uid]),
      });

      // Step 4:
      // Confirm from Firebase that the couple now contains this user.
      final confirmedCoupleSnapshot = await coupleReference.get(
        const GetOptions(source: Source.server),
      );

      final confirmedCoupleData = confirmedCoupleSnapshot.data();

      if (confirmedCoupleData == null) {
        throw Exception('Unable to confirm the couple membership.');
      }

      final confirmedMemberIds = List<String>.from(
        confirmedCoupleData['memberIds'] ?? [],
      );

      if (!confirmedMemberIds.contains(user.uid)) {
        throw Exception('Firebase did not confirm the couple membership.');
      }

      // Step 5:
      // Now that membership definitely exists, update the user's profile.
      //
      // This is the change that AuthGate is watching.
      await firestore.collection('users').doc(user.uid).update({
        'coupleId': coupleId,
      });

      // We do not manually navigate to Home here.
      //
      // AuthGate will see the completed profile update and automatically
      // display the correct next screen.
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          if (error.code == 'permission-denied') {
            errorMessage =
                'Firebase did not allow this couple to be joined. '
                'Please check the invite code and try again.';
          } else {
            errorMessage = error.message ?? 'Unable to join the couple.';
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
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
