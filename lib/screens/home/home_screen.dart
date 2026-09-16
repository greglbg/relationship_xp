import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../game/xp_system.dart';
import '../claims/pending_reviews_screen.dart';
import '../claims/resubmit_claim_screen.dart';
import '../claims/submit_claim_screen.dart';
import '../history/activity_history_screen.dart';

// Keep these values aligned with the secure Cloud Functions XP cap.
const int individualLevelCap = 50;
const int individualXpCap = 122500;
const String individualXpCapReason = 'individual_level_cap';

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

  int readMemberXp(
    QuerySnapshot<Map<String, dynamic>>? progressSnapshot,
    String memberId,
  ) {
    if (progressSnapshot == null) {
      return 0;
    }

    for (final document in progressSnapshot.docs) {
      if (document.id != memberId) {
        continue;
      }

      final totalXp = document.data()['totalXp'];

      if (totalXp is num && totalXp >= 0) {
        return totalXp.toInt();
      }

      return 0;
    }

    return 0;
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

              String? partnerId;

              for (final memberId in memberIds) {
                if (memberId != user.uid) {
                  partnerId = memberId;
                  break;
                }
              }

              final partnerName = partnerId == null
                  ? 'Partner'
                  : memberNames[partnerId] ?? 'Partner';

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('couples')
                    .doc(coupleId)
                    .collection('memberProgress')
                    .snapshots(),
                builder: (context, progressSnapshot) {
                  if (progressSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (progressSnapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load XP progress.'),
                    );
                  }

                  final yourXp = readMemberXp(progressSnapshot.data, user.uid);

                  final partnerXp = partnerId == null
                      ? 0
                      : readMemberXp(progressSnapshot.data, partnerId);

                  final yourLevel = XpSystem.levelForXp(yourXp);

                  final yourXpIntoLevel = yourXp >= individualXpCap
                      ? 0
                      : XpSystem.xpIntoCurrentLevel(yourXp);

                  final yourXpNeeded = yourXp >= individualXpCap
                      ? 0
                      : XpSystem.xpNeededForNextLevel(yourXp);

                  final yourProgress = yourXp >= individualXpCap
                      ? 1.0
                      : XpSystem.levelProgress(yourXp);

                  final partnerLevel = XpSystem.levelForXp(partnerXp);

                  final partnerXpIntoLevel = partnerXp >= individualXpCap
                      ? 0
                      : XpSystem.xpIntoCurrentLevel(partnerXp);

                  final partnerXpNeeded = partnerXp >= individualXpCap
                      ? 0
                      : XpSystem.xpNeededForNextLevel(partnerXp);

                  final partnerProgress = partnerXp >= individualXpCap
                      ? 1.0
                      : XpSystem.levelProgress(partnerXp);

                  var coupleXp = 0;
                  var coupleLevel = 0;

                  for (final memberId in memberIds) {
                    final memberXp = readMemberXp(
                      progressSnapshot.data,
                      memberId,
                    );

                    coupleXp += memberXp;
                    coupleLevel += XpSystem.levelForXp(memberXp);
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('couples')
                        .doc(coupleId)
                        .collection('claims')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, pendingSnapshot) {
                      if (pendingSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (pendingSnapshot.hasError) {
                        return const Center(
                          child: Text('Unable to load pending reviews.'),
                        );
                      }

                      var pendingReviewCount = 0;

                      final pendingClaims = pendingSnapshot.data?.docs ?? [];

                      for (final claim in pendingClaims) {
                        final data = claim.data();

                        final submittedByUserId =
                            data['submittedByUserId'] as String?;

                        if (submittedByUserId != null &&
                            submittedByUserId != user.uid) {
                          pendingReviewCount++;
                        }
                      }

                      return SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome, $displayName!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Celebrate the little things '
                                'that make your relationship '
                                'stronger.',
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
                                onPressed: () {
                                  openActivityHistoryScreen(context, coupleId);
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('Activity History'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  openPendingReviewsScreen(context, coupleId);
                                },
                                icon: Icon(
                                  pendingReviewCount > 0
                                      ? Icons.mark_email_unread_outlined
                                      : Icons.rate_review_outlined,
                                ),
                                label: Text(
                                  pendingReviewCount > 0
                                      ? 'Pending Reviews '
                                            '($pendingReviewCount)'
                                      : 'Pending Reviews',
                                ),
                              ),
                              if (pendingReviewCount > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  pendingReviewCount == 1
                                      ? '1 activity is waiting '
                                            'for your review.'
                                      : '$pendingReviewCount '
                                            'activities are '
                                            'waiting for your '
                                            'review.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () {
                                  openSubmitClaimScreen(context, coupleId);
                                },
                                icon: const Icon(Icons.add_task),
                                label: const Text('Submit Activity'),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Approved activities earn XP. '
                                'Activities that need changes '
                                'carry no penalty.',
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
              'Your Couple Level is the sum of '
              'both partner levels.',
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
                    Text(
                      totalXp >= individualXpCap ? 'MAX LEVEL' : 'Level',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
              totalXp >= individualXpCap
                  ? 'Maximum level reached'
                  : '$xpIntoLevel / $xpNeeded XP to next level',
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
          xp: (data['xp'] as num?)?.toInt() ?? 25,
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
          .where('submittedByUserId', isEqualTo: userId)
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

        final baseXp =
            (data['baseXp'] as num?)?.toInt() ??
            (data['xp'] as num?)?.toInt() ??
            0;

        final awardedXp =
            (data['awardedXp'] as num?)?.toInt() ??
            (data['xp'] as num?)?.toInt() ??
            0;

        final status = data['status'] as String?;

        final reviewMessage = data['reviewMessage'] as String?;

        final approved = status == 'approved';

        final reachedXpCap = data['capReason'] == individualXpCapReason;

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
                    reachedXpCap
                        ? awardedXp > 0
                              ? 'Your partner approved this activity. '
                                    'You earned $awardedXp XP and reached '
                                    'the Level 50 maximum!'
                              : 'Your partner approved this activity. '
                                    'You are already at the Level 50 '
                                    'maximum, so no additional XP was awarded.'
                        : awardedXp > 0
                        ? 'Your partner approved this activity. '
                              'You earned $awardedXp XP!'
                        : 'Your partner approved this activity. '
                              'This approval adds 0 XP.',
                  )
                else ...[
                  const Text(
                    'Your partner left some '
                    'constructive feedback:',
                  ),
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
                          : 'Your partner requested '
                                'an update.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'There is no penalty. Make the '
                    'requested update and send the '
                    'activity back for another '
                    'review.',
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
                if (approved && awardedXp == 0 && baseXp > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Normal activity value: '
                    '$baseXp XP',
                    style: Theme.of(context).textTheme.bodySmall,
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
