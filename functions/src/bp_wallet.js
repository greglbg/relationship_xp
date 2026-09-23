/**
 * Relationship XP — Brownie Points wallet foundation.
 *
 * This module is intended for trusted server-side Firebase Functions.
 *
 * It does not decide whether a player deserves BP. Existing reward
 * functions must verify authentication, couple membership, reward
 * eligibility, and the authoritative BP amount.
 *
 * Wallets:
 * couples/{coupleId}/bpWallets/{userId}
 *
 * Transaction records:
 * couples/{coupleId}/bpTransactions/{transactionId}
 */

const {FieldValue} = require("firebase-admin/firestore");

const BP_WALLET_SCHEMA_VERSION = 1;

function requirePositiveBpAmount(amount) {
  if (!Number.isSafeInteger(amount) || amount <= 0) {
    throw new Error(
        "The Brownie Points amount must be a positive whole number.",
    );
  }

  return amount;
}

function requireBpUserId(userId) {
  if (
    typeof userId !== "string" ||
    userId.length === 0 ||
    userId.includes("/")
  ) {
    throw new Error(
        "A valid wallet user ID is required.",
    );
  }

  return userId;
}

function requireBpEventId(eventId) {
  if (
    typeof eventId !== "string" ||
    eventId.length === 0 ||
    eventId.includes("/")
  ) {
    throw new Error(
        "A valid reward event ID is required.",
    );
  }

  return eventId;
}

function requireBpSourceType(sourceType) {
  if (
    typeof sourceType !== "string" ||
    sourceType.length === 0
  ) {
    throw new Error(
        "A valid BP reward source is required.",
    );
  }

  return sourceType;
}

function readBpBalance(walletSnapshot) {
  if (!walletSnapshot.exists) {
    return 0;
  }

  const balance = walletSnapshot.data().balance;

  if (!Number.isSafeInteger(balance) || balance < 0) {
    throw new Error(
        "The stored Brownie Points balance is invalid.",
    );
  }

  return balance;
}

function browniePointCreditRefs(
    coupleRef,
    userId,
    eventId,
) {
  requireBpUserId(userId);
  requireBpEventId(eventId);

  const walletRef = coupleRef
      .collection("bpWallets")
      .doc(userId);

  const transactionId =
    `${userId}_${eventId}`;

  const bpTransactionRef = coupleRef
      .collection("bpTransactions")
      .doc(transactionId);

  return {
    walletRef: walletRef,
    bpTransactionRef: bpTransactionRef,
    transactionId: transactionId,
  };
}

function applyBrowniePointCredit(
    transaction,
    {
      walletRef,
      bpTransactionRef,
      walletSnapshot,
      bpTransactionSnapshot,
      transactionId,
      userId,
      amount,
      eventId,
      sourceType,
    },
) {
  requireBpUserId(userId);
  requireBpEventId(eventId);
  requireBpSourceType(sourceType);
  requirePositiveBpAmount(amount);

  const expectedTransactionId =
    `${userId}_${eventId}`;

  if (transactionId !== expectedTransactionId) {
    throw new Error(
        "The BP transaction ID is invalid.",
    );
  }

  if (bpTransactionSnapshot.exists) {
    const existing =
      bpTransactionSnapshot.data();

    if (
      existing.userId !== userId ||
      existing.eventId !== eventId ||
      existing.sourceType !== sourceType ||
      existing.amount !== amount ||
      existing.type !== "credit"
    ) {
      throw new Error(
          "This BP reward event conflicts with an existing transaction.",
      );
    }

    return {
      alreadyCredited: true,
      transactionId: transactionId,
      amount: 0,
      balance: readBpBalance(walletSnapshot),
    };
  }

  const currentBalance =
    readBpBalance(walletSnapshot);

  const newBalance =
    currentBalance + amount;

  if (!Number.isSafeInteger(newBalance)) {
    throw new Error(
        "The Brownie Points balance would exceed the supported range.",
    );
  }

  transaction.set(
      walletRef,
      {
        userId: userId,
        balance: newBalance,
        schemaVersion:
          BP_WALLET_SCHEMA_VERSION,
        updatedAt:
          FieldValue.serverTimestamp(),
      },
      {merge: true},
  );

  transaction.create(
      bpTransactionRef,
      {
        userId: userId,
        eventId: eventId,
        type: "credit",
        sourceType: sourceType,
        amount: amount,
        balanceAfter: newBalance,
        createdAt:
          FieldValue.serverTimestamp(),
      },
  );

  return {
    alreadyCredited: false,
    transactionId: transactionId,
    amount: amount,
    balance: newBalance,
  };
}

module.exports = {
  BP_WALLET_SCHEMA_VERSION,
  requirePositiveBpAmount,
  readBpBalance,
  browniePointCreditRefs,
  applyBrowniePointCredit,
};