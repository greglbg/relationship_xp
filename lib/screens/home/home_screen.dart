import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../game/xp_system.dart';
import '../awards/award_brownie_points_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> openAwardScreen(BuildContext context, String coupleId) async {
    final awardCreated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AwardBrowniePointsScreen(coupleId: coupleId),
      ),
    );

    if (awardCreated == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Brownie points awarded!')));
    }
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load your profile.'));
          }

          final data = snapshot.data?.data();

          if (data == null) {
            return const Center(child: Text('Profile not found.'));
          }

          final displayName = data['displayName'] as String? ?? 'Adventurer';

          final individualXp = data['individualXp'] as int? ?? 0;
          final coupleId = data['coupleId'] as String?;

          final level = XpSystem.levelForXp(individualXp);
          final xpIntoLevel = XpSystem.xpIntoCurrentLevel(individualXp);
          final xpNeeded = XpSystem.xpNeededForNextLevel(individualXp);
          final progress = XpSystem.levelProgress(individualXp);

          return SafeArea(
            child: Padding(
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
                    'Celebrate the little things that make your relationship stronger.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  PlayerCard(
                    level: level,
                    totalXp: individualXp,
                    xpIntoLevel: xpIntoLevel,
                    xpNeeded: xpNeeded,
                    progress: progress,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: coupleId == null
                        ? null
                        : () => openAwardScreen(context, coupleId),
                    icon: const Icon(Icons.favorite),
                    label: const Text('Award Brownie Points'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Celebrate something your partner did.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpNeeded,
    required this.progress,
    super.key,
  });

  final int level;
  final int totalXp;
  final int xpIntoLevel;
  final int xpNeeded;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Player Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$level',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
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
            const SizedBox(height: 8),
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
