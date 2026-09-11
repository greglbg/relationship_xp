import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
                  'No activities are waiting '
                  'for your review.',
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

              final xp = (data['xp'] as num?)?.toInt() ?? 0;

              final photoPath = data['photoPath'] as String? ?? '';

              final legacyPhotoUrl = data['photoUrl'] as String? ?? '';

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
                      if (photoPath.isNotEmpty ||
                          legacyPhotoUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ReviewPhoto(
                          photoPath: photoPath,
                          legacyPhotoUrl: legacyPhotoUrl,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.handshake_outlined),
                              const SizedBox(height: 8),
                              Text(
                                'Review in good faith. '
                                'Approvals and requests '
                                'for changes should '
                                'reflect whether the '
                                'activity meets the '
                                'agreed expectations, '
                                'not be used to punish, '
                                'pressure, or control '
                                'your partner.',
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
                        'Requesting changes gives '
                        'no penalty and removes '
                        'no XP.',
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

class ReviewPhoto extends StatelessWidget {
  const ReviewPhoto({
    required this.photoPath,
    required this.legacyPhotoUrl,
    super.key,
  });

  final String photoPath;
  final String legacyPhotoUrl;

  Future<String> getPhotoUrl() async {
    if (photoPath.trim().isNotEmpty) {
      try {
        return await FirebaseStorage.instance.ref(photoPath).getDownloadURL();
      } on FirebaseException {
        if (legacyPhotoUrl.trim().isNotEmpty) {
          return legacyPhotoUrl;
        }

        rethrow;
      }
    }

    if (legacyPhotoUrl.trim().isNotEmpty) {
      return legacyPhotoUrl;
    }

    throw FirebaseException(
      plugin: 'firebase_storage',
      code: 'photo-not-available',
      message: 'The photo is no longer available.',
    );
  }

  Future<void> showFullPhoto(BuildContext context, String photoUrl) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Photo is no longer available.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getPhotoUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return Container(
            height: 120,
            alignment: Alignment.center,
            child: const Text(
              'Photo is no longer available.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final photoUrl = snapshot.data!;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showFullPhoto(context, photoUrl);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              photoUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Photo is no longer available.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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
            'Please explain what would make '
            'this activity approvable.';
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
              'Give your partner constructive '
              'guidance about what they can '
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
                    'Example: Please add a photo '
                    'showing the finished result.',
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
