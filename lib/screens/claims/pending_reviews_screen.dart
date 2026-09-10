import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PendingReviewsScreen extends StatelessWidget {
  const PendingReviewsScreen({required this.coupleId, super.key});

  final String coupleId;

  Future<void> approveClaim({
    required BuildContext context,
    required String claimId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('claims')
          .doc(claimId)
          .update({
            'status': 'approved',
            'reviewedByUserId': user.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Activity approved.')));
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Unable to approve this activity.'),
          ),
        );
      }
    }
  }

  Future<void> requestChanges({
    required BuildContext context,
    required String claimId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final reviewMessage = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return const FeedbackDialog();
      },
    );

    if (reviewMessage == null || reviewMessage.trim().isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('claims')
          .doc(claimId)
          .update({
            'status': 'changes_requested',
            'reviewMessage': reviewMessage.trim(),
            'reviewedByUserId': user.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Constructive feedback sent to your partner.'),
          ),
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to send feedback.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Reviews')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('couples')
            .doc(coupleId)
            .collection('claims')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load pending reviews.'));
          }

          final claims =
              snapshot.data?.docs.where((doc) {
                final data = doc.data();

                return data['submittedByUserId'] != user.uid;
              }).toList() ??
              [];

          if (claims.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No activities are waiting for your review.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final claim = claims[index];
              final data = claim.data();

              final title = data['title'] as String? ?? 'Untitled activity';

              final xp = data['xp'] as int? ?? 0;
              final photoUrl = data['photoUrl'] as String?;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$xp XP requested',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (photoUrl != null && photoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photoUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 220,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Unable to display proof photo.',
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.handshake_outlined),
                              const SizedBox(height: 8),
                              Text(
                                'Review in good faith. Approvals and requests '
                                'for changes should reflect whether the activity '
                                'meets the agreed expectations, not be used to '
                                'punish, pressure, or control your partner.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          approveClaim(context: context, claimId: claim.id);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          requestChanges(context: context, claimId: claim.id);
                        },
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Needs Changes'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Requesting changes gives no penalty and removes no XP.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final TextEditingController messageController = TextEditingController();

  String? validationMessage;

  void submitFeedback() {
    final message = messageController.text.trim();

    if (message.isEmpty) {
      setState(() {
        validationMessage =
            'Please explain what would make this activity approvable.';
      });
      return;
    }

    Navigator.of(context).pop(message);
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What would make this approvable?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Give your partner constructive guidance about what they can '
              'change, add, or clarify.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLength: 300,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'Example: Please add a photo showing the finished result.',
                border: const OutlineInputBorder(),
                errorText: validationMessage,
              ),
              onChanged: (_) {
                if (validationMessage != null) {
                  setState(() {
                    validationMessage = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: submitFeedback,
          child: const Text('Send Feedback'),
        ),
      ],
    );
  }
}
