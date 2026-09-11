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

initializeApp();

const db = getFirestore();

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
        repeatPeriod: task.repeatPeriod,
        rewardLimit: task.rewardLimit,
      },
      dailyCatalogXpTarget:
        DAILY_CATALOG_XP_TARGET,
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
                    existingClaim.xp,
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

            const dailyLedgerSnapshot =
              await transaction.get(
                  dailyLedgerRef,
              );

            const taskCounterSnapshot =
              await transaction.get(
                  taskCounterRef,
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

            const newDailyXp =
              catalogXpEarnedToday +
              task.xp;

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

            const claimData = {
              title: task.name,
              xp: task.xp,
              baseXp: task.xp,
              awardedXp: task.xp,
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
              xpAwarded: task.xp,
              catalogXpEarnedToday:
                newDailyXp,
              dailyCatalogXpTarget:
                DAILY_CATALOG_XP_TARGET,
            };
          },
      );

    return result;
  });
