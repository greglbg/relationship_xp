import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AwardBrowniePointsScreen extends StatefulWidget {
  const AwardBrowniePointsScreen({required this.coupleId, super.key});

  final String coupleId;

  @override
  State<AwardBrowniePointsScreen> createState() =>
      _AwardBrowniePointsScreenState();
}

class _AwardBrowniePointsScreenState extends State<AwardBrowniePointsScreen> {
  final titleController = TextEditingController();

  int selectedXp = 25;
  bool isLoading = false;
  String? errorMessage;

  final List<int> xpOptions = [5, 10, 25, 50, 100];

  Future<void> awardPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    final title = titleController.text.trim();

    if (user == null) {
      setState(() {
        errorMessage = 'No signed-in user was found.';
      });
      return;
    }

    if (title.isEmpty) {
      setState(() {
        errorMessage = 'Please describe what your partner did.';
      });
      return;
    }

    if (title.length > 100) {
      setState(() {
        errorMessage = 'Please keep the description under 100 characters.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final coupleReference = FirebaseFirestore.instance
          .collection('couples')
          .doc(widget.coupleId);

      final coupleSnapshot = await coupleReference.get();
      final coupleData = coupleSnapshot.data();

      if (coupleData == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Couple information could not be found.',
        );
      }

      final memberIds = List<String>.from(
        coupleData['memberIds'] ?? <String>[],
      );

      final partnerIds = memberIds
          .where((memberId) => memberId != user.uid)
          .toList();

      if (partnerIds.isEmpty) {
        setState(() {
          errorMessage = 'Your partner has not joined this couple yet.';
        });
        return;
      }

      final partnerUserId = partnerIds.first;

      await coupleReference.collection('awards').add({
        'title': title,
        'xp': selectedXp,
        'awardedByUserId': user.uid,
        'recipientUserId': partnerUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          if (error.code == 'permission-denied') {
            errorMessage = 'You do not have permission to create this award.';
          } else {
            errorMessage = error.message ?? 'Unable to create the award.';
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
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Award Brownie Points')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What did your partner do?',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Celebrate something thoughtful, helpful, fun, or meaningful.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: titleController,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Example: Made dinner after a long day',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'How much XP?',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: xpOptions.map((xp) {
                  return ChoiceChip(
                    label: Text('$xp XP'),
                    selected: selectedXp == xp,
                    onSelected: isLoading
                        ? null
                        : (_) {
                            setState(() {
                              selectedXp = xp;
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: isLoading ? null : awardPoints,
                icon: const Icon(Icons.favorite),
                label: Text(isLoading ? 'Awarding...' : 'Award Brownie Points'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
