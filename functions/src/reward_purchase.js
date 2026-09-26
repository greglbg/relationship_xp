/**
 * Relationship XP — reward purchase model.
 *
 * This module defines and validates server-created reward purchase records.
 *
 * Reward purchases:
 * couples/{coupleId}/rewardPurchases/{purchaseId}
 *
 * The client must never be trusted to determine:
 * - authoritative BP price
 * - reward identity or presentation
 * - purchaser identity
 * - BP contribution amounts
 * - purchase status
 *
 * Those values are determined by trusted Cloud Functions.
 *
 * Purchase records preserve a snapshot of the reward as it existed when
 * purchased. This allows historical purchases to remain understandable
 * even if the reward catalog changes later.
 */

const {FieldValue} = require("firebase-admin/firestore");

const REWARD_PURCHASE_SCHEMA_VERSION = 1;

const REWARD_PURCHASE_STATUS = Object.freeze({
  purchased: "purchased",
  pendingPartnerApproval: "pending_partner_approval",
  cancelled: "cancelled",
  redeemed: "redeemed",
});

const REWARD_PURCHASE_SCOPE = Object.freeze({
  individual: "individual",
  couple: "couple",
});

/**
 * Validates a reward purchase document ID.
 *
 * @param {*} purchaseId Reward purchase ID.
 * @return {string} Validated purchase ID.
 */
function requirePurchaseId(purchaseId) {
  if (
    typeof purchaseId !== "string" ||
    purchaseId.length === 0 ||
    purchaseId.includes("/")
  ) {
    throw new Error(
        "A valid reward purchase ID is required.",
    );
  }

  return purchaseId;
}

/**
 * Validates a user ID used in a reward purchase.
 *
 * @param {*} userId Firebase Authentication user ID.
 * @return {string} Validated user ID.
 */
function requirePurchaseUserId(userId) {
  if (
    typeof userId !== "string" ||
    userId.length === 0 ||
    userId.includes("/")
  ) {
    throw new Error(
        "A valid reward purchase user ID is required.",
    );
  }

  return userId;
}

/**
 * Validates a reward ID.
 *
 * @param {*} rewardId Reward catalog ID.
 * @return {string} Validated reward ID.
 */
function requirePurchaseRewardId(rewardId) {
  if (
    typeof rewardId !== "string" ||
    rewardId.length === 0 ||
    rewardId.includes("/")
  ) {
    throw new Error(
        "A valid reward ID is required.",
    );
  }

  return rewardId;
}

/**
 * Validates a reward display name.
 *
 * @param {*} rewardName Reward display name.
 * @return {string} Trimmed reward name.
 */
function requirePurchaseRewardName(rewardName) {
  if (
    typeof rewardName !== "string" ||
    rewardName.trim().length === 0
  ) {
    throw new Error(
        "A valid reward name is required.",
    );
  }

  return rewardName.trim();
}

/**
 * Validates a reward description.
 *
 * @param {*} rewardDescription Reward description.
 * @return {string} Trimmed reward description.
 */
function requirePurchaseRewardDescription(
    rewardDescription,
) {
  if (
    typeof rewardDescription !== "string" ||
    rewardDescription.trim().length === 0
  ) {
    throw new Error(
        "A valid reward description is required.",
    );
  }

  return rewardDescription.trim();
}

/**
 * Validates a reward tier.
 *
 * @param {*} rewardTier Reward tier.
 * @return {string} Validated reward tier.
 */
function requirePurchaseRewardTier(rewardTier) {
  const validTiers = new Set([
    "common",
    "uncommon",
    "rare",
    "legendary",
    "mythic",
    "custom",
  ]);

  if (
    typeof rewardTier !== "string" ||
    !validTiers.has(rewardTier)
  ) {
    throw new Error(
        "A valid reward tier is required.",
    );
  }

  return rewardTier;
}

/**
 * Validates an authoritative Brownie Point price.
 *
 * @param {*} priceBp Brownie Point price.
 * @return {number} Validated price.
 */
function requirePurchasePrice(priceBp) {
  if (
    !Number.isSafeInteger(priceBp) ||
    priceBp <= 0
  ) {
    throw new Error(
        "A valid reward BP price is required.",
    );
  }

  return priceBp;
}

/**
 * Validates whether a reward belongs to an individual or couple.
 *
 * @param {*} scope Reward purchase scope.
 * @return {string} Validated purchase scope.
 */
function requirePurchaseScope(scope) {
  if (
    scope !== REWARD_PURCHASE_SCOPE.individual &&
    scope !== REWARD_PURCHASE_SCOPE.couple
  ) {
    throw new Error(
        "A valid reward purchase scope is required.",
    );
  }

  return scope;
}

/**
 * Validates whether a reward is standard or custom.
 *
 * @param {*} rewardType Reward type.
 * @return {string} Validated reward type.
 */
function requireRewardType(rewardType) {
  if (
    rewardType !== "standard" &&
    rewardType !== "custom"
  ) {
    throw new Error(
        "A valid reward type is required.",
    );
  }

  return rewardType;
}

/**
 * Validates a Brownie Point debit transaction ID.
 *
 * @param {*} debitTransactionId Debit transaction ID.
 * @return {string} Validated transaction ID.
 */
function requireDebitTransactionId(
    debitTransactionId,
) {
  if (
    typeof debitTransactionId !== "string" ||
    debitTransactionId.length === 0 ||
    debitTransactionId.includes("/")
  ) {
    throw new Error(
        "A valid debit transaction ID is required.",
    );
  }

  return debitTransactionId;
}

/**
 * Validates the authoritative reward snapshot stored with a purchase.
 *
 * @param {Object} reward Reward snapshot.
 * @param {*} reward.rewardId Reward ID.
 * @param {*} reward.rewardName Reward name.
 * @param {*} reward.rewardDescription Reward description.
 * @param {*} reward.rewardTier Reward tier.
 * @param {*} reward.rewardType Reward type.
 * @param {*} reward.priceBp Brownie Point price.
 * @return {boolean} True when the snapshot is valid.
 */
function validateRewardSnapshot({
  rewardId,
  rewardName,
  rewardDescription,
  rewardTier,
  rewardType,
  priceBp,
}) {
  requirePurchaseRewardId(rewardId);
  requirePurchaseRewardName(rewardName);
  requirePurchaseRewardDescription(
      rewardDescription,
  );
  requirePurchaseRewardTier(rewardTier);
  requireRewardType(rewardType);
  requirePurchasePrice(priceBp);

  if (
    rewardType === "custom" &&
    rewardTier !== "custom"
  ) {
    throw new Error(
        "A custom reward must use the custom tier.",
    );
  }

  if (
    rewardType === "standard" &&
    rewardTier === "custom"
  ) {
    throw new Error(
        "A standard reward cannot use the custom tier.",
    );
  }

  return true;
}

/**
 * Creates the Firestore reference for a reward purchase.
 *
 * @param {Object} coupleRef Firestore couple document reference.
 * @param {string} purchaseId Reward purchase ID.
 * @return {Object} Reward purchase document reference.
 */
function rewardPurchaseRef(
    coupleRef,
    purchaseId,
) {
  requirePurchaseId(purchaseId);

  return coupleRef
      .collection("rewardPurchases")
      .doc(purchaseId);
}

/**
 * Builds a completed individual reward purchase record.
 *
 * @param {Object} data Purchase information.
 * @param {string} data.purchaseId Purchase ID.
 * @param {string} data.purchaserId Purchaser user ID.
 * @param {string} data.rewardId Reward ID.
 * @param {string} data.rewardName Reward name.
 * @param {string} data.rewardDescription Reward description.
 * @param {string} data.rewardTier Reward tier.
 * @param {string} data.rewardType Reward type.
 * @param {number} data.priceBp Brownie Point price.
 * @param {string} data.debitTransactionId Debit transaction ID.
 * @return {Object} Firestore reward purchase data.
 */
function buildIndividualRewardPurchase({
  purchaseId,
  purchaserId,
  rewardId,
  rewardName,
  rewardDescription,
  rewardTier,
  rewardType,
  priceBp,
  debitTransactionId,
}) {
  requirePurchaseId(purchaseId);
  requirePurchaseUserId(purchaserId);

  validateRewardSnapshot({
    rewardId: rewardId,
    rewardName: rewardName,
    rewardDescription:
      rewardDescription,
    rewardTier: rewardTier,
    rewardType: rewardType,
    priceBp: priceBp,
  });

  requireDebitTransactionId(
      debitTransactionId,
  );

  return {
    schemaVersion:
      REWARD_PURCHASE_SCHEMA_VERSION,

    purchaseId: purchaseId,

    rewardId: rewardId,

    rewardName:
      rewardName.trim(),

    rewardDescription:
      rewardDescription.trim(),

    rewardTier: rewardTier,

    rewardType: rewardType,

    scope:
      REWARD_PURCHASE_SCOPE.individual,

    status:
      REWARD_PURCHASE_STATUS.purchased,

    purchaserId: purchaserId,

    priceBp: priceBp,

    contributions: {
      [purchaserId]: priceBp,
    },

    debitTransactionIds: {
      [purchaserId]:
        debitTransactionId,
    },

    createdAt:
      FieldValue.serverTimestamp(),

    updatedAt:
      FieldValue.serverTimestamp(),
  };
}

/**
 * Builds a pending couple reward purchase record.
 *
 * @param {Object} data Purchase information.
 * @param {string} data.purchaseId Purchase ID.
 * @param {string} data.purchaserId Purchaser user ID.
 * @param {string} data.partnerId Partner user ID.
 * @param {string} data.rewardId Reward ID.
 * @param {string} data.rewardName Reward name.
 * @param {string} data.rewardDescription Reward description.
 * @param {string} data.rewardTier Reward tier.
 * @param {string} data.rewardType Reward type.
 * @param {number} data.priceBp Brownie Point price.
 * @return {Object} Firestore pending reward purchase data.
 */
function buildPendingCoupleRewardPurchase({
  purchaseId,
  purchaserId,
  partnerId,
  rewardId,
  rewardName,
  rewardDescription,
  rewardTier,
  rewardType,
  priceBp,
}) {
  requirePurchaseId(purchaseId);
  requirePurchaseUserId(purchaserId);
  requirePurchaseUserId(partnerId);

  validateRewardSnapshot({
    rewardId: rewardId,
    rewardName: rewardName,
    rewardDescription:
      rewardDescription,
    rewardTier: rewardTier,
    rewardType: rewardType,
    priceBp: priceBp,
  });

  if (purchaserId === partnerId) {
    throw new Error(
        "A couple reward requires two different partners.",
    );
  }

  if (priceBp % 2 !== 0) {
    throw new Error(
        "A couple reward price must divide evenly " +
        "between both partners.",
    );
  }

  const contributionBp =
    priceBp / 2;

  return {
    schemaVersion:
      REWARD_PURCHASE_SCHEMA_VERSION,

    purchaseId: purchaseId,

    rewardId: rewardId,

    rewardName:
      rewardName.trim(),

    rewardDescription:
      rewardDescription.trim(),

    rewardTier: rewardTier,

    rewardType: rewardType,

    scope:
      REWARD_PURCHASE_SCOPE.couple,

    status:
      REWARD_PURCHASE_STATUS
          .pendingPartnerApproval,

    purchaserId: purchaserId,

    partnerId: partnerId,

    priceBp: priceBp,

    contributionBp:
      contributionBp,

    contributions: {},

    debitTransactionIds: {},

    approvedBy: {
      [purchaserId]: true,
      [partnerId]: false,
    },

    createdAt:
      FieldValue.serverTimestamp(),

    updatedAt:
      FieldValue.serverTimestamp(),
  };
}

module.exports = {
  REWARD_PURCHASE_SCHEMA_VERSION,
  REWARD_PURCHASE_STATUS,
  REWARD_PURCHASE_SCOPE,
  requirePurchaseId,
  requirePurchaseUserId,
  requirePurchaseRewardId,
  requirePurchaseRewardName,
  requirePurchaseRewardDescription,
  requirePurchaseRewardTier,
  requirePurchasePrice,
  requirePurchaseScope,
  requireRewardType,
  requireDebitTransactionId,
  validateRewardSnapshot,
  rewardPurchaseRef,
  buildIndividualRewardPurchase,
  buildPendingCoupleRewardPurchase,
};
