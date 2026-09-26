/**
 * Relationship XP — individual reward purchase service.
 *
 * Performs the trusted server-side work required to purchase an
 * individual reward with Brownie Points.
 *
 * functions/index.js provides the authenticated callable entry point.
 *
 * The reward catalog is authoritative for new purchases. Once a purchase
 * has been created, its stored reward snapshot remains authoritative for
 * that historical purchase.
 */

const {HttpsError} =
  require("firebase-functions/v2/https");

const {
  browniePointDebitRefs,
  applyBrowniePointDebit,
} = require("./bp_wallet");

const {
  rewardForId,
} = require("./reward_catalog");

const {
  rewardPurchaseRef,
  buildIndividualRewardPurchase,
} = require("./reward_purchase");

/**
 * Validates a client-supplied reward purchase ID.
 *
 * @param {*} value Reward purchase ID value.
 * @return {string} Validated purchase ID.
 */
function requireIndividualPurchaseId(value) {
  if (typeof value !== "string") {
    throw new HttpsError(
        "invalid-argument",
        "A reward purchase ID is required.",
    );
  }

  const purchaseId = value.trim();

  const validId =
    /^[A-Za-z0-9_-]{10,80}$/;

  if (!validId.test(purchaseId)) {
    throw new HttpsError(
        "invalid-argument",
        "The reward purchase ID is not valid.",
    );
  }

  return purchaseId;
}

/**
 * Validates a couple ID supplied for a reward purchase.
 *
 * @param {*} value Couple ID value.
 * @return {string} Validated couple ID.
 */
function requirePurchaseCoupleId(value) {
  if (
    typeof value !== "string" ||
    value.trim().length === 0
  ) {
    throw new HttpsError(
        "invalid-argument",
        "A valid couple ID is required.",
    );
  }

  const coupleId = value.trim();

  if (coupleId.includes("/")) {
    throw new HttpsError(
        "invalid-argument",
        "The couple ID is not valid.",
    );
  }

  return coupleId;
}

/**
 * Validates a requested reward catalog ID.
 *
 * @param {*} value Reward ID value.
 * @return {string} Validated reward ID.
 */
function requireRequestedRewardId(value) {
  if (
    typeof value !== "string" ||
    value.trim().length === 0
  ) {
    throw new HttpsError(
        "invalid-argument",
        "A valid reward ID is required.",
    );
  }

  const rewardId = value.trim();

  if (rewardId.includes("/")) {
    throw new HttpsError(
        "invalid-argument",
        "The reward ID is not valid.",
    );
  }

  return rewardId;
}

/**
 * Confirms that the purchaser belongs to the requested couple.
 *
 * @param {Object} coupleSnapshot Firestore couple document snapshot.
 * @param {string} userId Firebase Authentication user ID.
 * @return {void}
 */
function requirePurchaseMembership(
    coupleSnapshot,
    userId,
) {
  if (!coupleSnapshot.exists) {
    throw new HttpsError(
        "not-found",
        "The couple could not be found.",
    );
  }

  const coupleData =
    coupleSnapshot.data();

  const memberIds =
    coupleData.memberIds;

  if (
    !Array.isArray(memberIds) ||
    !memberIds.includes(userId)
  ) {
    throw new HttpsError(
        "permission-denied",
        "You are not a member of this couple.",
    );
  }
}

/**
 * Validates a required string stored in a reward purchase record.
 *
 * @param {*} value Stored field value.
 * @param {string} fieldName Field name used in error messages.
 * @return {string} Validated stored string.
 */
function requireStoredString(
    value,
    fieldName,
) {
  if (
    typeof value !== "string" ||
    value.trim().length === 0
  ) {
    throw new HttpsError(
        "internal",
        `Stored reward purchase has an invalid ${fieldName}.`,
    );
  }

  return value;
}

/**
 * Validates a positive integer stored in a reward purchase record.
 *
 * @param {*} value Stored field value.
 * @param {string} fieldName Field name used in error messages.
 * @return {number} Validated positive integer.
 */
function requireStoredPositiveInteger(
    value,
    fieldName,
) {
  if (
    !Number.isSafeInteger(value) ||
    value <= 0
  ) {
    throw new HttpsError(
        "internal",
        `Stored reward purchase has an invalid ${fieldName}.`,
    );
  }

  return value;
}

/**
 * Returns the stored result for an idempotent purchase retry.
 *
 * @param {Object} purchaseSnapshot Firestore purchase snapshot.
 * @param {string} purchaseId Reward purchase ID.
 * @param {string} userId Purchaser user ID.
 * @param {string} rewardId Requested reward ID.
 * @return {Object|null} Existing purchase result, or null if absent.
 */
function existingIndividualPurchaseResult(
    purchaseSnapshot,
    purchaseId,
    userId,
    rewardId,
) {
  if (!purchaseSnapshot.exists) {
    return null;
  }

  const existing =
    purchaseSnapshot.data();

  /*
   * A purchase ID is an idempotency key.
   *
   * For a retry to represent the same logical purchase, the immutable
   * identity of the request must match the existing document:
   *
   * - purchase ID
   * - purchaser
   * - reward ID
   * - individual purchase scope
   *
   * We intentionally do NOT compare the stored reward name, description,
   * tier, type, or BP price against the current reward catalog.
   *
   * Those values are historical snapshots. If the catalog changes later,
   * retrying an old purchase must still return the original purchase
   * without charging the user again.
   */

  const samePurchase =
    existing.purchaseId === purchaseId &&
    existing.purchaserId === userId &&
    existing.rewardId === rewardId &&
    existing.scope === "individual";

  if (!samePurchase) {
    throw new HttpsError(
        "already-exists",
        "That reward purchase ID has already been used.",
    );
  }

  const storedRewardId =
    requireStoredString(
        existing.rewardId,
        "reward ID",
    );

  const storedRewardName =
    requireStoredString(
        existing.rewardName,
        "reward name",
    );

  const storedRewardDescription =
    requireStoredString(
        existing.rewardDescription,
        "reward description",
    );

  const storedRewardTier =
    requireStoredString(
        existing.rewardTier,
        "reward tier",
    );

  const storedRewardType =
    requireStoredString(
        existing.rewardType,
        "reward type",
    );

  const storedPriceBp =
    requireStoredPositiveInteger(
        existing.priceBp,
        "BP price",
    );

  const storedStatus =
    requireStoredString(
        existing.status,
        "status",
    );

  return {
    alreadyPurchased: true,
    purchaseId: purchaseId,
    rewardId: storedRewardId,
    rewardName: storedRewardName,
    rewardDescription:
      storedRewardDescription,
    rewardTier: storedRewardTier,
    rewardType: storedRewardType,
    priceBp: storedPriceBp,
    status: storedStatus,
    bpSpent: 0,
    bpBalance: null,
  };
}

/**
 * Purchases an individual reward with Brownie Points.
 *
 * @param {Object} options Purchase service options.
 * @param {Object} options.db Firestore database instance.
 * @param {string} options.userId Purchaser user ID.
 * @param {string} options.coupleId Couple ID.
 * @param {string} options.rewardId Requested reward ID.
 * @param {string} options.purchaseId Unique purchase ID.
 * @return {Promise<Object>} Completed reward purchase result.
 */
async function purchaseIndividualReward({
  db,
  userId,
  coupleId,
  rewardId,
  purchaseId,
}) {
  if (!db) {
    throw new HttpsError(
        "internal",
        "The reward purchase service is unavailable.",
    );
  }

  if (
    typeof userId !== "string" ||
    userId.length === 0
  ) {
    throw new HttpsError(
        "unauthenticated",
        "You must be signed in to purchase a reward.",
    );
  }

  const validatedCoupleId =
    requirePurchaseCoupleId(
        coupleId,
    );

  const validatedRewardId =
    requireRequestedRewardId(
        rewardId,
    );

  const validatedPurchaseId =
    requireIndividualPurchaseId(
        purchaseId,
    );

  const reward =
    rewardForId(
        validatedRewardId,
    );

  if (!reward) {
    throw new HttpsError(
        "not-found",
        "That reward is not available.",
    );
  }

  if (reward.type !== "standard") {
    throw new HttpsError(
        "failed-precondition",
        "Custom rewards must be created through the custom reward flow.",
    );
  }

  if (
    !Number.isSafeInteger(reward.priceBp) ||
    reward.priceBp <= 0
  ) {
    throw new HttpsError(
        "internal",
        "The reward has an invalid Brownie Points price.",
    );
  }

  const coupleRef =
    db.collection("couples")
        .doc(validatedCoupleId);

  const purchaseRef =
    rewardPurchaseRef(
        coupleRef,
        validatedPurchaseId,
    );

  const bpEventId =
    `reward_${validatedPurchaseId}`;

  const bpRefs =
    browniePointDebitRefs(
        coupleRef,
        userId,
        bpEventId,
    );

  const result =
    await db.runTransaction(
        async (transaction) => {
          /*
           * Keep all Firestore reads before all Firestore writes.
           */

          const coupleSnapshot =
            await transaction.get(
                coupleRef,
            );

          requirePurchaseMembership(
              coupleSnapshot,
              userId,
          );

          const purchaseSnapshot =
            await transaction.get(
                purchaseRef,
            );

          const existingResult =
            existingIndividualPurchaseResult(
                purchaseSnapshot,
                validatedPurchaseId,
                userId,
                validatedRewardId,
            );

          if (existingResult !== null) {
            return existingResult;
          }

          const bpTransactionSnapshot =
            await transaction.get(
                bpRefs.bpTransactionRef,
            );

          const bpWalletSnapshot =
            await transaction.get(
                bpRefs.walletRef,
            );

          const bpResult =
            applyBrowniePointDebit(
                transaction,
                {
                  walletRef:
                    bpRefs.walletRef,
                  bpTransactionRef:
                    bpRefs.bpTransactionRef,
                  walletSnapshot:
                    bpWalletSnapshot,
                  bpTransactionSnapshot:
                    bpTransactionSnapshot,
                  transactionId:
                    bpRefs.transactionId,
                  userId: userId,
                  amount:
                    reward.priceBp,
                  eventId:
                    bpEventId,
                  sourceType:
                    "reward_purchase",
                },
            );

          if (bpResult.alreadyDebited) {
            throw new HttpsError(
                "failed-precondition",
                "This reward purchase has already been charged.",
            );
          }

          if (bpResult.insufficientBalance) {
            throw new HttpsError(
                "failed-precondition",
                "You do not have enough Brownie Points for this reward.",
            );
          }

          const purchaseData =
            buildIndividualRewardPurchase({
              purchaseId:
                validatedPurchaseId,
              purchaserId:
                userId,
              rewardId:
                reward.id,
              rewardName:
                reward.name,
              rewardDescription:
                reward.description,
              rewardTier:
                reward.tier,
              rewardType:
                reward.type,
              priceBp:
                reward.priceBp,
              debitTransactionId:
                bpRefs.transactionId,
            });

          transaction.create(
              purchaseRef,
              purchaseData,
          );

          return {
            alreadyPurchased: false,
            purchaseId:
              validatedPurchaseId,
            rewardId:
              reward.id,
            rewardName:
              reward.name,
            rewardDescription:
              reward.description,
            rewardTier:
              reward.tier,
            rewardType:
              reward.type,
            priceBp:
              reward.priceBp,
            status: "purchased",
            bpSpent:
              bpResult.amount,
            bpBalance:
              bpResult.balance,
          };
        },
    );

  return result;
}

module.exports = {
  requireIndividualPurchaseId,
  purchaseIndividualReward,
};
