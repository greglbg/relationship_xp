import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({required this.coupleId, super.key});

  final String coupleId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity History')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('couples')
            .doc(coupleId)
            .snapshots(),
        builder: (context, coupleSnapshot) {
          if (coupleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (coupleSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load couple information.'),
            );
          }

          final coupleData = coupleSnapshot.data?.data();

          if (coupleData == null) {
            return const Center(child: Text('Couple information not found.'));
          }

          final rawMemberNames =
              coupleData['memberNames'] as Map<String, dynamic>?;

          final memberNames = <String, String>{};

          if (rawMemberNames != null) {
            for (final entry in rawMemberNames.entries) {
              final value = entry.value;

              if (value is String && value.trim().isNotEmpty) {
                memberNames[entry.key] = value.trim();
              }
            }
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('couples')
                .doc(coupleId)
                .collection('claims')
                .snapshots(),
            builder: (context, claimsSnapshot) {
              if (claimsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (claimsSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to load activity history.'),
                );
              }

              final claims = claimsSnapshot.data?.docs.toList() ?? [];

              claims.sort((a, b) {
                final aTime = a.data()['createdAt'] as Timestamp?;
                final bTime = b.data()['createdAt'] as Timestamp?;

                if (aTime == null && bTime == null) {
                  return 0;
                }

                if (aTime == null) {
                  return 1;
                }

                if (bTime == null) {
                  return -1;
                }

                return bTime.compareTo(aTime);
              });

              if (claims.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No activities yet.\n\n'
                      'Your shared accomplishments will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: claims.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final claim = claims[index];
                  final data = claim.data();

                  final submittedByUserId =
                      data['submittedByUserId'] as String? ?? '';

                  final submittedByName =
                      memberNames[submittedByUserId] ?? 'Partner';

                  final isCurrentUser = user?.uid == submittedByUserId;

                  return ActivityHistoryCard(
                    title: data['title'] as String? ?? 'Untitled activity',
                    xp: data['xp'] as int? ?? 0,
                    status: data['status'] as String? ?? 'pending',
                    submittedByName: submittedByName,
                    isCurrentUser: isCurrentUser,
                    createdAt: data['createdAt'] as Timestamp?,
                    reviewMessage: data['reviewMessage'] as String?,
                    hasPhoto:
                        (data['photoPath'] as String?)?.trim().isNotEmpty ==
                        true,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ActivityHistoryCard extends StatelessWidget {
  const ActivityHistoryCard({
    required this.title,
    required this.xp,
    required this.status,
    required this.submittedByName,
    required this.isCurrentUser,
    required this.createdAt,
    required this.reviewMessage,
    required this.hasPhoto,
    super.key,
  });

  final String title;
  final int xp;
  final String status;
  final String submittedByName;
  final bool isCurrentUser;
  final Timestamp? createdAt;
  final String? reviewMessage;
  final bool hasPhoto;

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'changes_requested':
        return 'Needs Changes';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'changes_requested':
        return Icons.edit_note;
      case 'pending':
        return Icons.hourglass_top;
      default:
        return Icons.help_outline;
    }
  }

  String get xpLabel {
    if (status == 'approved') {
      return '+$xp XP earned';
    }

    return '$xp XP requested';
  }

  String formattedDate() {
    if (createdAt == null) {
      return 'Date unavailable';
    }

    final date = createdAt!.toDate();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final feedback = reviewMessage?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(xpLabel, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              isCurrentUser
                  ? 'Submitted by $submittedByName (You)'
                  : 'Submitted by $submittedByName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(formattedDate(), style: Theme.of(context).textTheme.bodySmall),
            if (hasPhoto) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.photo_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Photo attached'),
                ],
              ),
            ],
            if (status == 'changes_requested' &&
                feedback != null &&
                feedback.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Partner feedback',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(feedback),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
