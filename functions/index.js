const {onCall, HttpsError} =
  require("firebase-functions/v2/https");

const {initializeApp} =
  require("firebase-admin/app");

const {
  FieldValue,
  getFirestore,
} = require("firebase-admin/firestore");

const {
  DAILY_CATALOG_XP_TARGET,
  TASK_CATALOG,
  TASK_REPEAT_PERIOD,
} = require("./src/task_catalog");

const {
  browniePointCreditRefs,
  applyBrowniePointCredit,
} = require("./src/bp_wallet");

initializeApp();

const db = getFirestore();

const CUSTOM_TASK_XP = 25;
const DAILY_CUSTOM_REWARD_LIMIT = 3;

const INDIVIDUAL_LEVEL_CAP = 50;
const INDIVIDUAL_XP_CAP = 122500;

const MEMBER_PROGRESS_SCHEMA_VERSION = 1;

const XP_CAP_REASON = "individual_level_cap";

/**
 * Requires the callable request to come from a signed-in user.
 *
 * @param {Object} request Callable function request.
 * @return {string} Firebase Authentication user ID.
 */
function requireSignedInUser(request) {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "You must be signed in to complete an activity.",
    );
  }

  return request.auth.uid;
}

/**
 * Gets and validates the request data object.
 *
 * @param {Object} request Callable function request.
 * @return {Object} Valid request data.
 */
function getRequestData(request) {
  if (!request.data || typeof request.data !== "object") {
    throw new HttpsError(
        "invalid-argument",
        "Activity information is required.",
    );
  }

  return request.data;
}

/**
 * Requires a value to be a non-empty string.
 *
 * @param {*} value Value to validate.
 * @param {string} message Error message to return when invalid.
 * @return {string} Trimmed validated string.
 */
function requireString(value, message) {
  if (typeof value !== "string") {
    throw new HttpsError(
        "invalid-argument",
        message,
    );
  }

  const trimmedValue = value.trim();

  if (trimmedValue.length === 0) {
    throw new HttpsError(
        "invalid-argument",
        message,
    );
  }

  return trimmedValue;
}

/**
 * Validates the unique completion ID supplied by the client.
 *
 * @param {*} value Completion ID value.
 * @return {string} Validated completion ID.
 */
function requireCompletionId(value) {
  const completionId = requireString(
      value,
      "A completion ID is required.",
  );

  const validId = /^[A-Za-z0-9_-]{10,80}$/;

  if (!validId.test(completionId)) {
    throw new HttpsError(
        "invalid-argument",
        "The completion ID is not valid.",
    );
  }

  return completionId;
}

/**
 * Validates an optional catalog photo path.
 *
 * The path must be inside the temporary photo area, belong to the
 * authenticated user, and use the same completion ID as the catalog
 * completion being submitted.
 *
 * @param {*} value Optional photo path supplied by the client.
 * @param {string} coupleId Couple document ID.
 * @param {string} userId Firebase Authentication user ID.
 * @param {string} completionId Unique completion ID.
 * @return {string|null} Validated photo path, or null when omitted.
 */
function optionalCatalogPhotoPath(
    value,
    coupleId,
    userId,
    completionId,
) {
  if (
    value === undefined ||
    value === null
  ) {
    return null;
  }

  const photoPath = requireString(
      value,
      "The activity photo path is not valid.",
  );

  const expectedPath =
    `temporaryPhotos/couples/${coupleId}/catalogProofs/` +
    `${userId}/${completionId}.jpg`;

  if (photoPath !== expectedPath) {
    throw new HttpsError(
        "invalid-argument",
        "The activity photo path is not valid.",
    );
  }

  return photoPath;
}

/**
 * Finds an enabled task in the server-side task catalog.
 *
 * @param {string} taskId Catalog task ID.
 * @return {Object} Catalog task definition.
 */
function getTask(taskId) {
  const task = TASK_CATALOG[taskId];

  if (!task || !task.enabled) {
    throw new HttpsError(
        "not-found",
        "That activity is not available.",
    );
  }

  return task;
}

/**
 * Creates a UTC calendar date key.
 *
 * @param {Date} date Date to convert.
 * @return {string} Date key in YYYY-MM-DD format.
 */
function utcDateKey(date) {
  const year = date.getUTCFullYear();

  const month = String(
      date.getUTCMonth() + 1,
  ).padStart(2, "0");

  const day = String(
      date.getUTCDate(),
  ).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

/**
 * Creates a UTC week key using Monday as the start of the week.
 *
 * @param {Date} date Date contained in the requested week.
 * @return {string} Monday date key for that UTC week.
 */
function utcWeekKey(date) {
  const monday = new Date(date);

  const utcDay = monday.getUTCDay();

  const daysSinceMonday =
    (utcDay + 6) % 7;

  monday.setUTCDate(
      monday.getUTCDate() - daysSinceMonday,
  );

  return utcDateKey(monday);
}

/**
 * Creates the correct reward-period key for a task.
 *
 * @param {Object} task Catalog task definition.
 * @param {Date} now Current server date.
 * @return {string} Daily or weekly reward-period key.
 */
function periodKeyForTask(task, now) {
  if (
    task.repeatPeriod ===
    TASK_REPEAT_PERIOD.DAILY
  ) {
    return utcDateKey(now);
  }

  return utcWeekKey(now);
}

/**
 * Creates a Firestore document ID for a task reward counter.
 *
 * @param {string} userId Firebase Authentication user ID.
 * @param {string} taskId Catalog task ID.
 * @param {string} periodKey Daily or weekly period key.
 * @return {string} Task reward counter document ID.
 */
function taskCounterId(
    userId,
    taskId,
    periodKey,
) {
  return `${userId}_${taskId}_${periodKey}`;
}

/**
 * Creates a Firestore document ID for a daily XP ledger.
 *
 * @param {string} userId Firebase Authentication user ID.
 * @param {string} dayKey UTC date key.
 * @return {string} Daily XP ledger document ID.
 */
function dailyLedgerId(
    userId,
    dayKey,
) {
  return `${userId}_${dayKey}`;
}

/**
 * Creates a Firestore document ID for a custom reward ledger.
 *
 * @param {string} userId Claim owner's Firebase Authentication user ID.
 * @param {string} dayKey UTC date key.
 * @return {string} Custom reward ledger document ID.
 */
function customRewardLedgerId(
    userId,
    dayKey,
) {
  return `${userId}_${dayKey}`;
}

/**
 * Confirms that a user belongs to the requested couple.
 *
 * @param {Object} coupleSnapshot Firestore couple snapshot.
 * @param {string} userId Firebase Authentication user ID.
 * @return {void}
 */
function requireCoupleMembership(
    coupleSnapshot,
    userId,
) {
  if (!coupleSnapshot.exists) {
    throw new HttpsError(
        "not-found",
        "The couple could not be found.",
    );
  }

  const coupleData = coupleSnapshot.data();

  const memberIds = coupleData.memberIds;

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
 * Confirms that both the reviewer and claimant belong to the couple.
 *
 * @param {Object} coupleSnapshot Firestore couple snapshot.
 * @param {string} reviewerId Reviewing user's Firebase Authentication ID.
 * @param {string} claimantId Claim owner's Firebase Authentication ID.
 * @return {void}
 */
function requireCustomReviewMembership(
    coupleSnapshot,
    reviewerId,
    claimantId,
) {
  requireCoupleMembership(
      coupleSnapshot,
      reviewerId,
  );

  const coupleData = coupleSnapshot.data();
  const memberIds = coupleData.memberIds;

  if (!memberIds.includes(claimantId)) {
    throw new HttpsError(
        "failed-precondition",
        "The activity owner is not a member of this couple.",
    );
  }

  if (reviewerId === claimantId) {
    throw new HttpsError(
        "permission-denied",
        "You cannot approve your own custom activity.",
    );
  }
}

/**
 * Reads a non-negative numeric field from a Firestore snapshot.
 *
 * @param {Object} snapshot Firestore document snapshot.
 * @param {string} fieldName Numeric field to read.
 * @param {string} errorMessage Message used for invalid stored data.
 * @return {number} Stored value, or zero when the document is absent.
 */
function readNonNegativeNumber(
    snapshot,
    fieldName,
    errorMessage,
) {
  if (!snapshot.exists) {
    return 0;
  }

  const value = snapshot.data()[fieldName];

  if (
    typeof value !== "number" ||
    value < 0
  ) {
    throw new HttpsError(
        "internal",
        errorMessage,
    );
  }

  return value;
}

/**
 * Reads the awarded XP value from a stored claim.
 *
 * Older claims may only contain the xp field.
 *
 * @param {Object} claim Stored claim data.
 * @return {number} Awarded XP value.
 */
function awardedXpForClaim(claim) {
  if (
    typeof claim.awardedXp === "number" &&
    claim.awardedXp >= 0
  ) {
    return claim.awardedXp;
  }

  if (
    typeof claim.xp === "number" &&
    claim.xp >= 0
  ) {
    return claim.xp;
  }

  return 0;
}

/**
 * Reads the awarded BP value from a stored claim.
 *
 * Older catalog claims created before BP existed return zero.
 *
 * @param {Object} claim Stored claim data.
 * @return {number} Awarded Brownie Points.
 */
function awardedBpForClaim(claim) {
  if (
    Number.isSafeInteger(claim.awardedBp) &&
    claim.awardedBp >= 0
  ) {
    return claim.awardedBp;
  }

  return 0;
}

/**
 * Reads the authoritative XP total from a member progress document.
 *
 * A missing progress document is treated as zero for new users.
 *
 * @param {Object} snapshot Firestore member progress snapshot.
 * @return {number} Current authoritative XP total.
 */
function memberProgressXp(snapshot) {
  if (!snapshot.exists) {
    return 0;
  }

  const totalXp = snapshot.data().totalXp;

  if (
    typeof totalXp !== "number" ||
    totalXp < 0
  ) {
    throw new HttpsError(
        "internal",
        "The member XP progress record is invalid.",
    );
  }

  return totalXp;
}

/**
 * Calculates the XP that may actually be awarded before the
 * individual XP cap is reached.
 *
 * @param {number} currentXp Current authoritative XP total.
 * @param {number} baseXp Normal XP value of the activity.
 * @return {number} Actual XP that may be awarded.
 */
function cappedXpAward(
    currentXp,
    baseXp,
) {
  const normalizedCurrentXp =
    Math.min(
        currentXp,
        INDIVIDUAL_XP_CAP,
    );

  const remainingXp =
    INDIVIDUAL_XP_CAP -
    normalizedCurrentXp;

  return Math.min(
      baseXp,
      remainingXp,
  );
}

/**
 * Returns the authoritative XP total after applying an award.
 *
 * @param {number} currentXp Current authoritative XP total.
 * @param {number} awardedXp Actual XP being awarded.
 * @return {number} New authoritative XP total.
 */
function updatedMemberXp(
    currentXp,
    awardedXp,
) {
  return Math.min(
      currentXp + awardedXp,
      INDIVIDUAL_XP_CAP,
  );
}

/**
 * Creates the standard member progress data written by reward functions.
 *
 * @param {string} userId Firebase Authentication user ID.
 * @param {number} totalXp New authoritative XP total.
 * @return {Object} Firestore member progress data.
 */
function memberProgressData(
    userId,
    totalXp,
) {
  return {
    userId: userId,
    totalXp: totalXp,
    schemaVersion:
      MEMBER_PROGRESS_SCHEMA_VERSION,
    individualLevelCap:
      INDIVIDUAL_LEVEL_CAP,
    individualXpCap:
      INDIVIDUAL_XP_CAP,
    updatedAt:
      FieldValue.serverTimestamp(),
  };
}

exports.validateCatalogTask =
  onCall(async (request) => {
    const userId =
      requireSignedInUser(request);

    const data =
      getRequestData(request);

    const coupleId = requireString(
        data.coupleId,
        "A valid couple ID is required.",
    );

    const taskId = requireString(
        data.taskId,
        "A valid task ID is required.",
    );

    const task = getTask(taskId);

    const coupleRef =
      db.collection("couples").doc(coupleId);

    const coupleSnapshot =
      await coupleRef.get();

    requireCoupleMembership(
        coupleSnapshot,
        userId,
    );

    return {
      valid: true,
      task: {
        id: taskId,
        name: task.name,
        xp: task.xp,
        bp: task.bp,
        repeatPeriod: task.repeatPeriod,
        rewardLimit: task.rewardLimit,
      },
      dailyCatalogXpTarget:
        DAILY_CATALOG_XP_TARGET,
      individualLevelCap:
        INDIVIDUAL_LEVEL_CAP,
      individualXpCap:
        INDIVIDUAL_XP_CAP,
    };
  });

exports.completeCatalogTask =
  onCall(async (request) => {
    const userId =
      requireSignedInUser(request);

    const data =
      getRequestData(request);

    const coupleId = requireString(
        data.coupleId,
        "A valid couple ID is required.",
    );

    const taskId = requireString(
        data.taskId,
        "A valid task ID is required.",
    );

    const completionId =
      requireCompletionId(
          data.completionId,
      );

    const photoPath =
      optionalCatalogPhotoPath(
          data.photoPath,
          coupleId,
          userId,
          completionId,
      );

    const task = getTask(taskId);

    if (
      !Number.isSafeInteger(task.bp) ||
      task.bp <= 0
    ) {
      throw new HttpsError(
          "internal",
          "The activity Brownie Points reward is invalid.",
      );
    }

    const now = new Date();

    const dayKey =
      utcDateKey(now);

    const periodKey =
      periodKeyForTask(task, now);

    const coupleRef =
      db.collection("couples").doc(coupleId);

    const claimRef =
      coupleRef
          .collection("claims")
          .doc(completionId);

    const dailyLedgerRef =
      coupleRef
          .collection("catalogXpDays")
          .doc(
              dailyLedgerId(
                  userId,
                  dayKey,
              ),
          );

    const taskCounterRef =
      coupleRef
          .collection("catalogTaskPeriods")
          .doc(
              taskCounterId(
                  userId,
                  taskId,
                  periodKey,
              ),
          );

    const progressRef =
      coupleRef
          .collection("memberProgress")
          .doc(userId);

    const bpRefs =
      browniePointCreditRefs(
          coupleRef,
          userId,
          completionId,
      );

    const result =
      await db.runTransaction(
          async (transaction) => {
            const coupleSnapshot =
              await transaction.get(
                  coupleRef,
              );

            requireCoupleMembership(
                coupleSnapshot,
                userId,
            );

            const existingClaimSnapshot =
              await transaction.get(
                  claimRef,
              );

            if (
              existingClaimSnapshot.exists
            ) {
              const existingClaim =
                existingClaimSnapshot.data();

              const sameCatalogClaim =
                existingClaim.source ===
                  "catalog" &&
                existingClaim
                    .submittedByUserId ===
                  userId &&
                existingClaim.taskId ===
                  taskId;

              if (sameCatalogClaim) {
                return {
                  alreadyCompleted: true,
                  claimId: completionId,
                  taskId: taskId,
                  taskName:
                    existingClaim.title,
                  xpAwarded:
                    awardedXpForClaim(
                        existingClaim,
                    ),
                  bpAwarded:
                    awardedBpForClaim(
                        existingClaim,
                    ),
                  dailyCatalogXpTarget:
                    DAILY_CATALOG_XP_TARGET,
                };
              }

              throw new HttpsError(
                  "already-exists",
                  "That completion ID " +
                  "has already been used.",
              );
            }

            /*
             * All transaction reads happen before any writes.
             *
             * This is especially important now that XP and BP are
             * awarded atomically in the same Firestore transaction.
             */
            const dailyLedgerSnapshot =
              await transaction.get(
                  dailyLedgerRef,
              );

            const taskCounterSnapshot =
              await transaction.get(
                  taskCounterRef,
              );

            const progressSnapshot =
              await transaction.get(
                  progressRef,
              );

            const bpTransactionSnapshot =
              await transaction.get(
                  bpRefs.bpTransactionRef,
              );

            const bpWalletSnapshot =
              await transaction.get(
                  bpRefs.walletRef,
              );

            const catalogXpEarnedToday =
              readNonNegativeNumber(
                  dailyLedgerSnapshot,
                  "xpEarned",
                  "The daily XP record " +
                  "is invalid.",
              );

            if (
              catalogXpEarnedToday >=
              DAILY_CATALOG_XP_TARGET
            ) {
              throw new HttpsError(
                  "failed-precondition",
                  "Today's catalog XP " +
                  "reward target has " +
                  "already been reached.",
              );
            }

            const rewardedCount =
              readNonNegativeNumber(
                  taskCounterSnapshot,
                  "rewardedCount",
                  "The activity reward " +
                  "record is invalid.",
              );

            if (
              rewardedCount >=
              task.rewardLimit
            ) {
              const periodName =
                task.repeatPeriod ===
                  TASK_REPEAT_PERIOD.DAILY ?
                  "today" :
                  "this week";

              throw new HttpsError(
                  "failed-precondition",
                  "The XP reward for this " +
                  "activity has already " +
                  "been earned the allowed " +
                  "number of times " +
                  `${periodName}.`,
              );
            }

            const currentXp =
              memberProgressXp(
                  progressSnapshot,
              );

            const awardedXp =
              cappedXpAward(
                  currentXp,
                  task.xp,
              );

            const newTotalXp =
              updatedMemberXp(
                  currentXp,
                  awardedXp,
              );

            const cappedByLevel =
              awardedXp < task.xp;

            const newDailyXp =
              catalogXpEarnedToday +
              task.xp;

            /*
             * Apply the BP credit after every required Firestore
             * read has completed, but before the transaction commits.
             *
             * If any later write fails, Firestore rolls back both
             * the XP and BP changes.
             */
            const bpResult =
              applyBrowniePointCredit(
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
                    amount: task.bp,
                    eventId: completionId,
                    sourceType:
                      "catalog_task",
                  },
              );

            if (bpResult.alreadyCredited) {
              throw new HttpsError(
                  "already-exists",
                  "Brownie Points have already " +
                  "been awarded for this completion.",
              );
            }

            transaction.set(
                dailyLedgerRef,
                {
                  userId: userId,
                  dayKey: dayKey,
                  xpEarned: newDailyXp,
                  updatedAt:
                    FieldValue
                        .serverTimestamp(),
                },
                {
                  merge: true,
                },
            );

            transaction.set(
                taskCounterRef,
                {
                  userId: userId,
                  taskId: taskId,
                  repeatPeriod:
                    task.repeatPeriod,
                  periodKey: periodKey,
                  rewardedCount:
                    rewardedCount + 1,
                  updatedAt:
                    FieldValue
                        .serverTimestamp(),
                },
                {
                  merge: true,
                },
            );

            transaction.set(
                progressRef,
                memberProgressData(
                    userId,
                    newTotalXp,
                ),
                {
                  merge: true,
                },
            );

            const claimData = {
              title: task.name,
              xp: task.xp,
              baseXp: task.xp,
              awardedXp: awardedXp,
              baseBp: task.bp,
              awardedBp:
                bpResult.amount,
              submittedByUserId:
                userId,
              status: "approved",
              source: "catalog",
              taskId: taskId,
              repeatPeriod:
                task.repeatPeriod,
              rewardLimit:
                task.rewardLimit,
              dayKey: dayKey,
              periodKey: periodKey,
              createdAt:
                FieldValue
                    .serverTimestamp(),
            };

            if (cappedByLevel) {
              claimData.capReason =
                XP_CAP_REASON;
            }

            if (photoPath !== null) {
              claimData.photoPath =
                photoPath;
            }

            transaction.create(
                claimRef,
                claimData,
            );

            return {
              alreadyCompleted: false,
              claimId: completionId,
              taskId: taskId,
              taskName: task.name,
              baseXp: task.xp,
              xpAwarded: awardedXp,
              totalXp: newTotalXp,
              baseBp: task.bp,
              bpAwarded:
                bpResult.amount,
              bpBalance:
                bpResult.balance,
              levelCapReached:
                newTotalXp >=
                INDIVIDUAL_XP_CAP,
              capReason:
                cappedByLevel ?
                  XP_CAP_REASON :
                  null,
              catalogXpEarnedToday:
                newDailyXp,
              dailyCatalogXpTarget:
                DAILY_CATALOG_XP_TARGET,
              individualLevelCap:
                INDIVIDUAL_LEVEL_CAP,
              individualXpCap:
                INDIVIDUAL_XP_CAP,
            };
          },
      );

    return result;
  });

exports.approveCustomClaim =
  onCall(async (request) => {
    const reviewerId =
      requireSignedInUser(request);

    const data =
      getRequestData(request);

    const coupleId = requireString(
        data.coupleId,
        "A valid couple ID is required.",
    );

    const claimId = requireString(
        data.claimId,
        "A valid claim ID is required.",
    );

    const now = new Date();
    const dayKey = utcDateKey(now);

    const coupleRef =
      db.collection("couples").doc(coupleId);

    const claimRef =
      coupleRef
          .collection("claims")
          .doc(claimId);

    const result =
      await db.runTransaction(
          async (transaction) => {
            const coupleSnapshot =
              await transaction.get(
                  coupleRef,
              );

            const claimSnapshot =
              await transaction.get(
                  claimRef,
              );

            if (!claimSnapshot.exists) {
              throw new HttpsError(
                  "not-found",
                  "The custom activity could not be found.",
              );
            }

            const claim =
              claimSnapshot.data();

            const claimantId =
              claim.submittedByUserId;

            if (
              typeof claimantId !== "string" ||
              claimantId.length === 0
            ) {
              throw new HttpsError(
                  "failed-precondition",
                  "The custom activity owner is invalid.",
              );
            }

            requireCustomReviewMembership(
                coupleSnapshot,
                reviewerId,
                claimantId,
            );

            if (claim.status === "approved") {
              return {
                alreadyApproved: true,
                claimId: claimId,
                xpAwarded:
                  awardedXpForClaim(
                      claim,
                  ),
                rewardedCustomActivitiesToday:
                  null,
                dailyCustomRewardLimit:
                  DAILY_CUSTOM_REWARD_LIMIT,
              };
            }

            if (claim.status !== "pending") {
              throw new HttpsError(
                  "failed-precondition",
                  "This activity is not waiting for approval.",
              );
            }

            if (
              claim.source !== undefined &&
              claim.source !== "custom"
            ) {
              throw new HttpsError(
                  "failed-precondition",
                  "Only custom activities require partner approval.",
              );
            }

            if (claim.xp !== CUSTOM_TASK_XP) {
              throw new HttpsError(
                  "failed-precondition",
                  "The custom activity XP value is invalid.",
              );
            }

            const customLedgerRef =
              coupleRef
                  .collection("customRewardDays")
                  .doc(
                      customRewardLedgerId(
                          claimantId,
                          dayKey,
                      ),
                  );

            const progressRef =
              coupleRef
                  .collection("memberProgress")
                  .doc(claimantId);

            const customLedgerSnapshot =
              await transaction.get(
                  customLedgerRef,
              );

            const progressSnapshot =
              await transaction.get(
                  progressRef,
              );

            const rewardedCount =
              readNonNegativeNumber(
                  customLedgerSnapshot,
                  "rewardedCount",
                  "The daily custom reward record is invalid.",
              );

            const rewardAvailable =
              rewardedCount <
              DAILY_CUSTOM_REWARD_LIMIT;

            const currentXp =
              memberProgressXp(
                  progressSnapshot,
              );

            const normalAward =
              rewardAvailable ?
                CUSTOM_TASK_XP :
                0;

            const awardedXp =
              cappedXpAward(
                  currentXp,
                  normalAward,
              );

            const newTotalXp =
              updatedMemberXp(
                  currentXp,
                  awardedXp,
              );

            const cappedByLevel =
              normalAward > 0 &&
              awardedXp < normalAward;

            const newRewardedCount =
              rewardAvailable ?
                rewardedCount + 1 :
                rewardedCount;

            if (rewardAvailable) {
              transaction.set(
                  customLedgerRef,
                  {
                    userId: claimantId,
                    dayKey: dayKey,
                    rewardedCount:
                      newRewardedCount,
                    xpAwarded:
                      newRewardedCount *
                      CUSTOM_TASK_XP,
                    updatedAt:
                      FieldValue
                          .serverTimestamp(),
                  },
                  {
                    merge: true,
                  },
              );
            }

            transaction.set(
                progressRef,
                memberProgressData(
                    claimantId,
                    newTotalXp,
                ),
                {
                  merge: true,
                },
            );

            const claimUpdate = {
              status: "approved",
              source: "custom",
              baseXp:
                CUSTOM_TASK_XP,
              awardedXp: awardedXp,
              approvalDayKey:
                dayKey,
              reviewedByUserId:
                reviewerId,
              reviewedAt:
                FieldValue
                    .serverTimestamp(),
            };

            if (cappedByLevel) {
              claimUpdate.capReason =
                XP_CAP_REASON;
            }

            transaction.update(
                claimRef,
                claimUpdate,
            );

            return {
              alreadyApproved: false,
              claimId: claimId,
              baseXp:
                CUSTOM_TASK_XP,
              xpAwarded: awardedXp,
              totalXp: newTotalXp,
              rewardAvailable:
                rewardAvailable,
              rewardedCustomActivitiesToday:
                newRewardedCount,
              dailyCustomRewardLimit:
                DAILY_CUSTOM_REWARD_LIMIT,
              levelCapReached:
                newTotalXp >=
                INDIVIDUAL_XP_CAP,
              capReason:
                cappedByLevel ?
                  XP_CAP_REASON :
                  null,
              individualLevelCap:
                INDIVIDUAL_LEVEL_CAP,
              individualXpCap:
                INDIVIDUAL_XP_CAP,
            };
          },
      );

    return result;
  });