import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../game/bp_wallet.dart';
import '../../game/reward_purchase_service.dart';
import '../../theme/app_theme.dart';

class RewardShopScreen extends StatefulWidget {
  const RewardShopScreen({
    required this.coupleId,
    required this.userId,
    super.key,
  });

  final String coupleId;
  final String userId;

  @override
  State<RewardShopScreen> createState() => _RewardShopScreenState();
}

class _RewardShopScreenState extends State<RewardShopScreen> {
  String? _purchasingRewardId;

  static const List<_RewardDefinition> _rewards = [
    // ============================================================
    // COMMON — 50 BP
    // ============================================================

    _RewardDefinition(
      id: 'keeper_of_the_flame',
      name: 'Keeper of the Flame',
      description: 'Choose the movie or show for a shared viewing night.',
      priceBp: 50,
      tier: _RewardTier.common,
    ),
    _RewardDefinition(
      id: 'tavernmasters_choice',
      name: "Tavernmaster's Choice",
      description: 'Choose the snack or dessert for a shared treat.',
      priceBp: 50,
      tier: _RewardTier.common,
    ),
    _RewardDefinition(
      id: 'minstrels_request',
      name: "The Minstrel's Request",
      description: 'Choose the music or playlist during shared time.',
      priceBp: 50,
      tier: _RewardTier.common,
    ),

    // ============================================================
    // UNCOMMON — 100 BP
    // ============================================================
    _RewardDefinition(
      id: 'keeper_of_the_feast',
      name: 'Keeper of the Feast',
      description: 'Choose the meal or cuisine for a shared meal.',
      priceBp: 100,
      tier: _RewardTier.uncommon,
    ),
    _RewardDefinition(
      id: 'pathfinders_choice',
      name: "The Pathfinder's Choice",
      description: 'Choose a shared outing or activity.',
      priceBp: 100,
      tier: _RewardTier.uncommon,
    ),
    _RewardDefinition(
      id: 'quiet_evening_at_the_hearth',
      name: 'A Quiet Evening at the Hearth',
      description: 'Request a relaxed, low-key evening together.',
      priceBp: 100,
      tier: _RewardTier.uncommon,
    ),

    // ============================================================
    // RARE — 250 BP
    // ============================================================
    _RewardDefinition(
      id: 'adventurers_decree',
      name: "The Adventurer's Decree",
      description: 'Choose the theme or activity for a special date.',
      priceBp: 250,
      tier: _RewardTier.rare,
    ),
    _RewardDefinition(
      id: 'feast_of_the_two',
      name: 'Feast of the Two',
      description: 'Request a special meal experience together.',
      priceBp: 250,
      tier: _RewardTier.rare,
    ),
    _RewardDefinition(
      id: 'the_open_road',
      name: 'The Open Road',
      description: 'Choose a larger local adventure or day outing.',
      priceBp: 250,
      tier: _RewardTier.rare,
    ),

    // ============================================================
    // LEGENDARY — 500 BP
    // ============================================================
    _RewardDefinition(
      id: 'grand_expedition',
      name: 'The Grand Expedition',
      description: 'Request a planned special adventure together.',
      priceBp: 500,
      tier: _RewardTier.legendary,
    ),
    _RewardDefinition(
      id: 'festival_of_two',
      name: 'Festival of Two',
      description: 'Design a special themed date or celebration together.',
      priceBp: 500,
      tier: _RewardTier.legendary,
    ),
    _RewardDefinition(
      id: 'royal_respite',
      name: 'The Royal Respite',
      description:
          'Request a substantial planned relaxation experience together.',
      priceBp: 500,
      tier: _RewardTier.legendary,
    ),

    // ============================================================
    // MYTHIC — 1,000 BP
    // ============================================================
    _RewardDefinition(
      id: 'mythic_quest',
      name: 'The Mythic Quest',
      description:
          'Request an extraordinary planned adventure or experience together.',
      priceBp: 1000,
      tier: _RewardTier.mythic,
    ),
    _RewardDefinition(
      id: 'sovereign_celebration',
      name: 'The Sovereign Celebration',
      description: 'Design a major celebration or memorable occasion for the two of you.',
      priceBp: 1000,
      tier: _RewardTier.mythic,
    ),
    _RewardDefinition(
      id: 'journey_beyond_the_map',
      name: 'The Journey Beyond the Map',
      description:
          'Choose an ambitious future day trip, excursion, or shared adventure '
          'to plan together.',
      priceBp: 1000,
      tier: _RewardTier.mythic,
    ),
  ];

  Future<void> _purchaseReward(_RewardDefinition reward) async {
    if (_purchasingRewardId != null) {
      return;
    }

    final confirmed = await _confirmPurchase(reward);

    if (confirmed != true || !mounted) {
      return;
    }

    final purchaseId = _createPurchaseId(reward.id);

    setState(() {
      _purchasingRewardId = reward.id;
    });

    try {
      final result = await RewardPurchaseService.purchaseIndividualReward(
        coupleId: widget.coupleId,
        rewardId: reward.id,
        purchaseId: purchaseId,
      );

      if (!mounted) {
        return;
      }

      final message = result.alreadyPurchased
          ? '${result.rewardName} was already purchased. '
                'No additional Brownie Points were spent.'
          : '${result.rewardName} purchased for '
                '${result.bpSpent} BP.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyFunctionsError(error))));
    } on FormatException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The reward purchase response was not valid. '
            'Please try again.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The reward could not be purchased. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _purchasingRewardId = null;
        });
      }
    }
  }

  Future<bool?> _confirmPurchase(_RewardDefinition reward) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(reward.name),
          content: Text(
            '${reward.description}\n\n'
            'Spend ${reward.priceBp} BP on this reward?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Not Yet'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text('Spend ${reward.priceBp} BP'),
            ),
          ],
        );
      },
    );
  }

  String _createPurchaseId(String rewardId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final userFragment = widget.userId.length <= 8
        ? widget.userId
        : widget.userId.substring(0, 8);

    return 'purchase_${timestamp}_${userFragment}_$rewardId';
  }

  String _friendlyFunctionsError(FirebaseFunctionsException error) {
    final message = error.message?.trim();

    if (error.code == 'failed-precondition' &&
        message != null &&
        message.toLowerCase().contains('enough brownie points')) {
      return 'You do not have enough Brownie Points for this reward.';
    }

    if (error.code == 'not-found') {
      return 'That reward is not currently available.';
    }

    if (error.code == 'permission-denied') {
      return 'This reward cannot be purchased from your current couple.';
    }

    if (error.code == 'unauthenticated') {
      return 'Please sign in again before purchasing a reward.';
    }

    if (message != null && message.isNotEmpty) {
      return message;
    }

    return 'The reward could not be purchased. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reward Hall')),
      body: StreamBuilder<int>(
        stream: BpWallet.balanceStream(
          coupleId: widget.coupleId,
          userId: widget.userId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load your Brownie Point wallet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final balance = snapshot.data ?? 0;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _WalletBanner(balance: balance),
                const SizedBox(height: 24),
                Text(
                  'The Reward Hall',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Spend the Brownie Points earned through your '
                  'adventures on shared experiences and privileges.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                _buildTierSection(
                  context: context,
                  tier: _RewardTier.common,
                  balance: balance,
                ),
                _buildTierSection(
                  context: context,
                  tier: _RewardTier.uncommon,
                  balance: balance,
                ),
                _buildTierSection(
                  context: context,
                  tier: _RewardTier.rare,
                  balance: balance,
                ),
                _buildTierSection(
                  context: context,
                  tier: _RewardTier.legendary,
                  balance: balance,
                ),
                _buildTierSection(
                  context: context,
                  tier: _RewardTier.mythic,
                  balance: balance,
                ),
                const SizedBox(height: 8),
                _CustomRewardCard(),
                const SizedBox(height: 24),
                Text(
                  'Rewards are invitations to create a positive '
                  'shared experience. They do not override either '
                  "partner's boundaries or consent.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTierSection({
    required BuildContext context,
    required _RewardTier tier,
    required int balance,
  }) {
    final tierRewards = _rewards
        .where((reward) => reward.tier == tier)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TierHeader(tier: tier),
          const SizedBox(height: 8),
          for (final reward in tierRewards)
            _RewardCard(
              reward: reward,
              balance: balance,
              purchasing: _purchasingRewardId == reward.id,
              purchaseInProgress: _purchasingRewardId != null,
              onPurchase: () => _purchaseReward(reward),
            ),
        ],
      ),
    );
  }
}

enum _RewardTier { common, uncommon, rare, legendary, mythic }

extension _RewardTierPresentation on _RewardTier {
  String get name {
    switch (this) {
      case _RewardTier.common:
        return 'Common';
      case _RewardTier.uncommon:
        return 'Uncommon';
      case _RewardTier.rare:
        return 'Rare';
      case _RewardTier.legendary:
        return 'Legendary';
      case _RewardTier.mythic:
        return 'Mythic';
    }
  }

  int get priceBp {
    switch (this) {
      case _RewardTier.common:
        return 50;
      case _RewardTier.uncommon:
        return 100;
      case _RewardTier.rare:
        return 250;
      case _RewardTier.legendary:
        return 500;
      case _RewardTier.mythic:
        return 1000;
    }
  }

  IconData get icon {
    switch (this) {
      case _RewardTier.common:
        return Icons.local_fire_department_outlined;
      case _RewardTier.uncommon:
        return Icons.auto_awesome_outlined;
      case _RewardTier.rare:
        return Icons.diamond_outlined;
      case _RewardTier.legendary:
        return Icons.workspace_premium_outlined;
      case _RewardTier.mythic:
        return Icons.castle_outlined;
    }
  }
}

class _RewardDefinition {
  const _RewardDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.priceBp,
    required this.tier,
  });

  final String id;
  final String name;
  final String description;
  final int priceBp;
  final _RewardTier tier;
}

class _WalletBanner extends StatelessWidget {
  const _WalletBanner({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.toll_outlined, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Coin Purse',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$balance BP',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({required this.tier});

  final _RewardTier tier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(tier.icon, color: _tierColor(tier)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tier.name,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: _tierColor(tier)),
          ),
        ),
        Text(
          '${tier.priceBp} BP',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: _tierColor(tier)),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.balance,
    required this.purchasing,
    required this.purchaseInProgress,
    required this.onPurchase,
  });

  final _RewardDefinition reward;
  final int balance;
  final bool purchasing;
  final bool purchaseInProgress;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final canAfford = balance >= reward.priceBp;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(reward.tier.icon, color: _tierColor(reward.tier)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reward.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${reward.priceBp} BP',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _tierColor(reward.tier),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              reward.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: purchaseInProgress || !canAfford ? null : onPurchase,
              icon: purchasing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.redeem_outlined),
              label: Text(
                purchasing
                    ? 'Purchasing...'
                    : canAfford
                    ? 'Claim Reward'
                    : 'Need ${reward.priceBp - balance} More BP',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomRewardCard extends StatelessWidget {
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
                const Icon(
                  Icons.history_edu_outlined,
                  color: AppTheme.weatheredLeather,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A Pact of Your Own',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '100 BP',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Create a custom reward agreed upon by both partners.'),
            const SizedBox(height: 12),
            Text(
              'Custom rewards will become available when the '
              'partner-agreement flow is added.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // OutlinedButton.icon is not a const constructor.
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Coming Soon'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _tierColor(_RewardTier tier) {
  switch (tier) {
    case _RewardTier.common:
      return AppTheme.weatheredLeather;
    case _RewardTier.uncommon:
      return AppTheme.forestGreen;
    case _RewardTier.rare:
      return AppTheme.arcaneBlue;
    case _RewardTier.legendary:
      return AppTheme.antiqueGold;
    case _RewardTier.mythic:
      return const Color(0xFF6D4C7D);
  }
}
