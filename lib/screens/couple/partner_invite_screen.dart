import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PartnerInviteScreen extends StatefulWidget {
  const PartnerInviteScreen({required this.coupleId, super.key});

  final String coupleId;

  @override
  State<PartnerInviteScreen> createState() => _PartnerInviteScreenState();
}

class _PartnerInviteScreenState extends State<PartnerInviteScreen> {
  bool isLoading = false;
  bool isCancelling = false;
  String? errorMessage;

  Future<void> generateInviteCode() async {
    final user = FirebaseAuth.instance.currentUser;

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
      final inviteReference = FirebaseFirestore.instance
          .collection('coupleInvites')
          .doc();

      final batch = FirebaseFirestore.instance.batch();

      batch.set(inviteReference, {
        'coupleId': widget.coupleId,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(
        FirebaseFirestore.instance.collection('couples').doc(widget.coupleId),
        {'inviteCode': inviteReference.id},
      );

      await batch.commit();
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

  Future<void> cancelCoupleSetup() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        errorMessage = 'No signed-in user was found.';
      });
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel couple setup?'),
          content: const Text(
            'This will cancel this unfinished couple setup so you can '
            'create a different couple or join your partner instead.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Stay Here'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cancel Setup'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) {
      return;
    }

    setState(() {
      isCancelling = true;
      errorMessage = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      final coupleReference = firestore
          .collection('couples')
          .doc(widget.coupleId);

      final userReference = firestore.collection('users').doc(user.uid);

      final coupleSnapshot = await coupleReference.get();

      if (!coupleSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'This unfinished couple could not be found.',
        );
      }

      final coupleData = coupleSnapshot.data();
      final memberIds = List<String>.from(
        coupleData?['memberIds'] ?? <String>[],
      );

      if (memberIds.length != 1 || memberIds.first != user.uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message:
              'This couple setup can no longer be cancelled from this screen.',
        );
      }

      final batch = firestore.batch();

      batch.delete(coupleReference);

      batch.update(userReference, {'coupleId': FieldValue.delete()});

      await batch.commit();

      // No Navigator.pop() is needed here.
      //
      // AuthGate listens to the user's Firestore profile. Once coupleId is
      // removed, AuthGate automatically displays CoupleSetupScreen.
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isCancelling = false;
        });
      }
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final controlsDisabled = isLoading || isCancelling;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: controlsDisabled ? null : cancelCoupleSetup,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Cancel couple setup',
        ),
        title: const Text('Invite Your Partner'),
        actions: [
          IconButton(
            onPressed: controlsDisabled ? null : signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('couples')
              .doc(widget.coupleId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Unable to load your couple information.'),
              );
            }

            final data = snapshot.data?.data();

            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final inviteCode = data['inviteCode'] as String?;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bring your partner into the adventure',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate an invite code and share it with your partner.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            inviteCode == null
                                ? 'No invite code yet'
                                : 'Your invite code',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (inviteCode != null)
                            SelectableText(
                              inviteCode,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isCancelling)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Cancelling couple setup...'),
                        ],
                      ),
                    )
                  else if (inviteCode == null)
                    FilledButton.icon(
                      onPressed: isLoading ? null : generateInviteCode,
                      icon: const Icon(Icons.key),
                      label: Text(
                        isLoading ? 'Generating...' : 'Generate Invite Code',
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'Your partner will enter this code from their own account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
