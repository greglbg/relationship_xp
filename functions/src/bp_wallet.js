/**
 * Relationship XP — Brownie Points wallet foundation.
 *
 * This module is intended for trusted server-side Firebase Functions.
 *
 * It does not decide whether a player deserves to earn or spend BP.
 * Calling functions must verify authentication, couple membership,
 * transaction eligibility, and the authoritative BP amount.
 *
 * Wallets:
 * couples/{coupleId}/bpWallets/{userId}
 *
 * Transaction records:
 * couples/{coupleId}/bpTransactions/{transactionId}
 */

const {FieldValue} = require("firebase-admin/firestore");

const BP_WALLET_SCHEMA_VERSION = 1;

/**
 * Validates a positive Brownie Point amount.
 *
 * @param {*} amount Brownie Point amount.
 * @return {number} Validated Brownie Point amount.
 */
function requirePositiveBpAmount(amount) {
  if (!Number.isSafeInteger(amount) || amount <= 0) {
    throw new Error(
        "The Brownie Points amount must be a positive whole number.",
    );
  }

  return amount;
}

/**
 * Validates a Brownie Point wallet user ID.
 *
 * @param {*} userId Firebase Authentication user ID.
 * @return {string} Validated user ID.
 */
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

/**
 * Validates a Brownie Point event ID.
 *
 * @param {*} eventId Brownie Point event ID.
 * @return {string} Validated event ID.
 */
function requireBpEventId(eventId) {
  if (
    typeof eventId !== "string" ||
    eventId.length === 0 ||
    eventId.includes("/")
  ) {
    throw new Error(
        "A valid Brownie Points event ID is required.",
    );
  }

  return eventId;
}

/**
 * Validates a Brownie Point transaction source type.
 *
 * @param {*} sourceType Transaction source type.
 * @return {string} Validated source type.
 */
function requireBpSourceType(sourceType) {
  if (
    typeof sourceType !== "string" ||
    sourceType.length === 0
  ) {
    throw new Error(
        "A valid BP transaction source is required.",
    );
  }

  return sourceType;
}

/**
 * Reads the current balance from a Brownie Point wallet snapshot.
 *
 * @param {Object} walletSnapshot Firestore wallet document snapshot.
 * @return {number} Current Brownie Point balance.
 */
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

/**
 * Creates wallet and transaction references for a BP event.
 *
 * @param {Object} coupleRef Firestore couple document reference.
 * @param {string} userId Firebase Authentication user ID.
 * @param {string} eventId Brownie Point event ID.
 * @return {Object} Wallet and transaction references.
 */
function browniePointTransactionRefs(
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

/**
 * Creates wallet and transaction references for a BP credit.
 *
 * @param {Object} coupleRef Firestore couple document reference.
 * @param {string} userId Firebase Authentication user ID.
 * @param {string} eventId Brownie Point event ID.
 * @return {Object} Wallet and transaction references.
 */
function browniePointCreditRefs(
    coupleRef,
    userId,
    eventId,
) {
  return browniePointTransactionRefs(
      coupleRef,
      userId,
      eventId,
  );
}

/**
 * Creates wallet and transaction references for a BP debit.
 *
 * @param {Object} coupleRef Firestore couple document reference.
 * @param {string} userId Firebase Authentication user ID.
 * @param {string} eventId Brownie Point event ID.
 * @return {Object} Wallet and transaction references.
 */
function browniePointDebitRefs(
    coupleRef,
    userId,
    eventId,
) {
  return browniePointTransactionRefs(
      coupleRef,
      userId,
      eventId,
  );
}

/**
 * Applies an idempotent Brownie Point credit.
 *
 * @param {Object} transaction Firestore transaction.
 * @param {Object} data Brownie Point credit data.
 * @return {Object} Brownie Point credit result.
 */
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

/**
 * Applies an idempotent Brownie Point debit.
 *
 * @param {Object} transaction Firestore transaction.
 * @param {Object} data Brownie Point debit data.
 * @return {Object} Brownie Point debit result.
 */
function applyBrowniePointDebit(
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
      existing.type !== "debit"
    ) {
      throw new Error(
          "This BP spending event conflicts with an existing transaction.",
      );
    }

    return {
      alreadyDebited: true,
      transactionId: transactionId,
      amount: 0,
      balance: readBpBalance(walletSnapshot),
    };
  }

  const currentBalance =
    readBpBalance(walletSnapshot);

  if (currentBalance < amount) {
    return {
      alreadyDebited: false,
      insufficientBalance: true,
      transactionId: transactionId,
      amount: 0,
      balance: currentBalance,
    };
  }

  const newBalance =
    currentBalance - amount;

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
        type: "debit",
        sourceType: sourceType,
        amount: amount,
        balanceAfter: newBalance,
        createdAt:
          FieldValue.serverTimestamp(),
      },
  );

  return {
    alreadyDebited: false,
    insufficientBalance: false,
    transactionId: transactionId,
    amount: amount,
    balance: newBalance,
  };
}

module.exports = {
  BP_WALLET_SCHEMA_VERSION,
  requirePositiveBpAmount,
  readBpBalance,
  browniePointTransactionRefs,
  browniePointCreditRefs,
  browniePointDebitRefs,
  applyBrowniePointCredit,
  applyBrowniePointDebit,
};
