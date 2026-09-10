import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../game/xp_system.dart';
import '../claims/pending_reviews_screen.dart';
import '../claims/resubmit_claim_screen.dart';
import '../claims/submit_claim_screen.dart';
import '../history/activity_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? lastSyncedName;
  String? lastSyncedCoupleId;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> syncDisplayNameToCouple({
    required String coupleId,
    required String userId,
    required String displayName,
  }) async {
    if (lastSyncedName == displayName && lastSyncedCoupleId == coupleId) {
      return;
    }

    lastSyncedName = displayName;
    lastSyncedCoupleId = coupleId;

    try {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .update({'memberNames.$userId': displayName});
    } on FirebaseException {
      // The dashboard can still work with a fallback name,
      // so a failed name sync should not block Home.
    }
  }

  Future<void> openSubmitClaimScreen(
    BuildContext context,
    String coupleId,
  ) async {
    final claimSubmitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SubmitClaimScreen(coupleId: coupleId),
      ),
    );

    if (claimSubmitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity submitted for partner review.')),
      );
    }
  }

  void openPendingReviewsScreen(BuildContext context, String coupleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PendingReviewsScreen(coupleId: coupleId),
      ),
    );
  }

  void openActivityHistoryScreen(BuildContext context, String coupleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivityHistoryScreen(coupleId: coupleId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relationship XP'),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileSnapshot.hasError) {
            return const Center(child: Text('Unable to load your profile.'));
          }

          final profileData = profileSnapshot.data?.data();

          if (profileData == null) {
            return const Center(child: Text('Profile not found.'));
          }

          final displayName =
              profileData['displayName'] as String? ?? 'Adventurer';

          final coupleId = profileData['coupleId'] as String?;

          if (coupleId == null || coupleId.trim().isEmpty) {
            return const Center(child: Text('Couple information not found.'));
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                return const Center(
                  child: Text('Couple information not found.'),
                );
              }

              final memberIds = List<String>.from(
                coupleData['memberIds'] ?? [],
              );

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

              if (memberNames[user.uid] != displayName) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  syncDisplayNameToCouple(
                    coupleId: coupleId,
                    userId: user.uid,
                    displayName: displayName,
                  );
                });
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('couples')
                    .doc(coupleId)
                    .collection('claims')
                    .snapshots(),
                builder: (context, claimsSnapshot) {
                  if (claimsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (claimsSnapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load activity XP.'),
                    );
                  }

                  final claims = claimsSnapshot.data?.docs ?? [];

                  final xpByMember = <String, int>{
                    for (final memberId in memberIds) memberId: 0,
                  };

                  for (final claim in claims) {
                    final data = claim.data();

                    if (data['status'] != 'approved') {
                      continue;
                    }

                    final submittedByUserId =
                        data['submittedByUserId'] as String?;

                    final xp = data['xp'] as int? ?? 0;

                    if (submittedByUserId == null) {
                      continue;
                    }

                    if (!xpByMember.containsKey(submittedByUserId)) {
                      continue;
                    }

                    xpByMember[submittedByUserId] =
                        (xpByMember[submittedByUserId] ?? 0) + xp;
                  }

                  final yourXp = xpByMember[user.uid] ?? 0;

                  final yourLevel = XpSystem.levelForXp(yourXp);

                  final yourXpIntoLevel = XpSystem.xpIntoCurrentLevel(yourXp);

                  final yourXpNeeded = XpSystem.xpNeededForNextLevel(yourXp);

                  final yourProgress = XpSystem.levelProgress(yourXp);

                  String? partnerId;

                  for (final memberId in memberIds) {
                    if (memberId != user.uid) {
                      partnerId = memberId;
                      break;
                    }
                  }

                  final partnerXp = partnerId == null
                      ? 0
                      : xpByMember[partnerId] ?? 0;

                  final partnerLevel = XpSystem.levelForXp(partnerXp);

                  final partnerXpIntoLevel = XpSystem.xpIntoCurrentLevel(
                    partnerXp,
                  );

                  final partnerXpNeeded = XpSystem.xpNeededForNextLevel(
                    partnerXp,
                  );

                  final partnerProgress = XpSystem.levelProgress(partnerXp);

                  final partnerName = partnerId == null
                      ? 'Partner'
                      : memberNames[partnerId] ?? 'Partner';

                  var coupleXp = 0;
                  var coupleLevel = 0;

                  for (final memberId in memberIds) {
                    final memberXp = xpByMember[memberId] ?? 0;

                    coupleXp += memberXp;
                    coupleLevel += XpSystem.levelForXp(memberXp);
                  }

                  return SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome, $displayName!',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Celebrate the little things that make your '
                            'relationship stronger.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 32),
                          CoupleSummaryCard(
                            coupleLevel: coupleLevel,
                            coupleXp: coupleXp,
                          ),
                          const SizedBox(height: 16),
                          PartnerProgressCard(
                            name: displayName,
                            label: 'You',
                            level: yourLevel,
                            totalXp: yourXp,
                            xpIntoLevel: yourXpIntoLevel,
                            xpNeeded: yourXpNeeded,
                            progress: yourProgress,
                          ),
                          const SizedBox(height: 16),
                          PartnerProgressCard(
                            name: partnerName,
                            label: 'Partner',
                            level: partnerLevel,
                            totalXp: partnerXp,
                            xpIntoLevel: partnerXpIntoLevel,
                            xpNeeded: partnerXpNeeded,
                            progress: partnerProgress,
                          ),
                          const SizedBox(height: 24),
                          ActivityUpdatesCard(
                            coupleId: coupleId,
                            userId: user.uid,
                          ),
                          const SizedBox(height: 32),
                          OutlinedButton.icon(
                            onPressed: () =>
                                openActivityHistoryScreen(context, coupleId),
                            icon: const Icon(Icons.history),
                            label: const Text('Activity History'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () =>
                                openPendingReviewsScreen(context, coupleId),
                            icon: const Icon(Icons.rate_review_outlined),
                            label: const Text('Pending Reviews'),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () =>
                                openSubmitClaimScreen(context, coupleId),
                            icon: const Icon(Icons.add_task),
                            label: const Text('Submit Activity'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Approved activities earn XP. Activities '
                            'that need changes carry no penalty.',
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
          );
        },
      ),
    );
  }
}

class CoupleSummaryCard extends StatelessWidget {
  const CoupleSummaryCard({
    required this.coupleLevel,
    required this.coupleXp,
    super.key,
  });

  final int coupleLevel;
  final int coupleXp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.favorite_outline, size: 32),
            const SizedBox(height: 12),
            Text(
              'Couple Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$coupleLevel',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$coupleXp total couple XP',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your Couple Level is the sum of both partner levels.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerProgressCard extends StatelessWidget {
  const PartnerProgressCard({
    required this.name,
    required this.label,
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpNeeded,
    required this.progress,
    super.key,
  });

  final String name;
  final String label;
  final int level;
  final int totalXp;
  final int xpIntoLevel;
  final int xpNeeded;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(label, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Level', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '$level',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              '$xpIntoLevel / $xpNeeded XP to next level',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '$totalXp total XP',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityUpdatesCard extends StatelessWidget {
  const ActivityUpdatesCard({
    required this.coupleId,
    required this.userId,
    super.key,
  });

  final String coupleId;
  final String userId;

  Future<void> openResubmitScreen({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> claim,
  }) async {
    final data = claim.data();

    final resubmitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ResubmitClaimScreen(
          coupleId: coupleId,
          claimId: claim.id,
          title: data['title'] as String? ?? '',
          xp: data['xp'] as int? ?? 25,
          photoPath: data['photoPath'] as String? ?? '',
          photoUrl: data['photoUrl'] as String? ?? '',
          reviewMessage:
              data['reviewMessage'] as String? ??
              'Your partner requested an update.',
        ),
      ),
    );

    if (resubmitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity updated and sent back for review.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('claims')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final reviewedClaims =
            snapshot.data?.docs.where((doc) {
              final data = doc.data();

              if (data['submittedByUserId'] != userId) {
                return false;
              }

              final status = data['status'];

              return status == 'approved' || status == 'changes_requested';
            }).toList() ??
            [];

        reviewedClaims.sort((a, b) {
          final aTime = a.data()['reviewedAt'] as Timestamp?;

          final bTime = b.data()['reviewedAt'] as Timestamp?;

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

        if (reviewedClaims.isEmpty) {
          return const SizedBox.shrink();
        }

        final latestClaim = reviewedClaims.first;
        final data = latestClaim.data();

        final title = data['title'] as String? ?? 'Activity';

        final xp = data['xp'] as int? ?? 0;

        final status = data['status'] as String?;

        final reviewMessage = data['reviewMessage'] as String?;

        final approved = status == 'approved';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      approved
                          ? Icons.celebration_outlined
                          : Icons.tips_and_updates_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        approved
                            ? 'Activity Approved!'
                            : 'Activity Needs Changes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (approved)
                  Text(
                    'Your partner approved this activity. '
                    'You earned $xp XP!',
                  )
                else ...[
                  const Text('Your partner left some constructive feedback:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reviewMessage?.trim().isNotEmpty == true
                          ? reviewMessage!
                          : 'Your partner requested an update.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'There is no penalty. Make the requested update '
                    'and send the activity back for another review.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      openResubmitScreen(context: context, claim: latestClaim);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Update & Resubmit'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
