import 'package:cloud_functions/cloud_functions.dart';

/// Result returned after attempting to purchase an individual reward.
///
/// The server remains authoritative for the reward price, reward details,
/// purchase status, and resulting Brownie Point balance.
class IndividualRewardPurchaseResult {
  const IndividualRewardPurchaseResult({
    required this.alreadyPurchased,
    required this.purchaseId,
    required this.rewardId,
    required this.rewardName,
    required this.rewardDescription,
    required this.rewardTier,
    required this.rewardType,
    required this.priceBp,
    required this.status,
    required this.bpSpent,
    required this.bpBalance,
  });

  final bool alreadyPurchased;
  final String purchaseId;
  final String rewardId;
  final String rewardName;
  final String rewardDescription;
  final String rewardTier;
  final String rewardType;
  final int priceBp;
  final String status;
  final int bpSpent;

  /// May be null when the server is returning an already-existing purchase.
  final int? bpBalance;

  factory IndividualRewardPurchaseResult.fromMap(Map<String, dynamic> data) {
    return IndividualRewardPurchaseResult(
      alreadyPurchased: data['alreadyPurchased'] == true,
      purchaseId: _requiredString(data['purchaseId'], 'purchaseId'),
      rewardId: _requiredString(data['rewardId'], 'rewardId'),
      rewardName: _requiredString(data['rewardName'], 'rewardName'),
      rewardDescription: _requiredString(
        data['rewardDescription'],
        'rewardDescription',
      ),
      rewardTier: _requiredString(data['rewardTier'], 'rewardTier'),
      rewardType: _requiredString(data['rewardType'], 'rewardType'),
      priceBp: _requiredInt(data['priceBp'], 'priceBp'),
      status: _requiredString(data['status'], 'status'),
      bpSpent: _requiredInt(data['bpSpent'], 'bpSpent'),
      bpBalance: _optionalInt(data['bpBalance'], 'bpBalance'),
    );
  }

  static String _requiredString(dynamic value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'The reward purchase response has an invalid $fieldName.',
      );
    }

    return value.trim();
  }

  static int _requiredInt(dynamic value, String fieldName) {
    if (value is! num) {
      throw FormatException(
        'The reward purchase response has an invalid $fieldName.',
      );
    }

    return value.toInt();
  }

  static int? _optionalInt(dynamic value, String fieldName) {
    if (value == null) {
      return null;
    }

    if (value is! num) {
      throw FormatException(
        'The reward purchase response has an invalid $fieldName.',
      );
    }

    return value.toInt();
  }
}

/// Provides trusted Brownie Point reward-purchase operations.
///
/// Flutter supplies only identifiers. It does not supply the BP price,
/// reward name, description, tier, purchase status, or resulting balance.
///
/// Those values are determined by the secure Cloud Function.
class RewardPurchaseService {
  const RewardPurchaseService._();

  /// Purchases one standard individual reward.
  ///
  /// [purchaseId] must be generated once for a purchase attempt and reused
  /// if that exact attempt needs to be retried. This gives the backend an
  /// idempotency key and prevents a retry from charging BP twice.
  static Future<IndividualRewardPurchaseResult> purchaseIndividualReward({
    required String coupleId,
    required String rewardId,
    required String purchaseId,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'purchaseIndividualReward',
    );

    final response = await callable.call<Map<String, dynamic>>({
      'coupleId': coupleId,
      'rewardId': rewardId,
      'purchaseId': purchaseId,
    });

    return IndividualRewardPurchaseResult.fromMap(response.data);
  }
}
