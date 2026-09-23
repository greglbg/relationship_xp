import 'package:cloud_firestore/cloud_firestore.dart';

/// Provides read-only access to Relationship XP Brownie Point wallets.
///
/// Brownie Point balances are written only by trusted Cloud Functions.
/// Flutter reads the resulting wallet documents so the app can display
/// balances without giving the client authority to award or spend BP.
class BpWallet {
  const BpWallet._();

  /// Returns a live stream of a member's current Brownie Point balance.
  ///
  /// A user who has never earned BP will not have a wallet document yet.
  /// In that case the balance is correctly treated as zero.
  static Stream<int> balanceStream({
    required String coupleId,
    required String userId,
  }) {
    return FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('bpWallets')
        .doc(userId)
        .snapshots()
        .map(_balanceFromSnapshot);
  }

  /// Reads a BP balance from a Firestore wallet snapshot.
  ///
  /// Invalid or missing values are displayed as zero. The backend remains
  /// responsible for validating and changing the authoritative balance.
  static int _balanceFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return 0;
    }

    final data = snapshot.data();

    if (data == null) {
      return 0;
    }

    final balance = data['balance'];

    if (balance is num && balance >= 0) {
      return balance.toInt();
    }

    return 0;
  }
}