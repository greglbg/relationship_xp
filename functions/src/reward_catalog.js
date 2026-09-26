/**
 * Relationship XP — Brownie Point reward catalog.
 *
 * This catalog defines the authoritative server-side rewards and prices.
 *
 * Flutter may request a reward by ID, but the client must never be trusted
 * to provide or override the authoritative Brownie Point price, title,
 * description, tier, or reward type.
 *
 * These rewards represent relationship privileges and shared experiences.
 * Digital collectible gifts are a separate future system.
 */

const REWARD_TIER = Object.freeze({
  COMMON: "common",
  UNCOMMON: "uncommon",
  RARE: "rare",
  LEGENDARY: "legendary",
  MYTHIC: "mythic",
  CUSTOM: "custom",
});

const REWARD_CATALOG = Object.freeze({
  keeper_of_the_flame: Object.freeze({
    id: "keeper_of_the_flame",
    name: "Keeper of the Flame",
    description:
      "Choose the movie or show for a shared viewing night.",
    priceBp: 50,
    tier: REWARD_TIER.COMMON,
    type: "standard",
    enabled: true,
  }),

  tavernmasters_choice: Object.freeze({
    id: "tavernmasters_choice",
    name: "Tavernmaster's Choice",
    description:
      "Choose the snack or dessert for a shared treat.",
    priceBp: 50,
    tier: REWARD_TIER.COMMON,
    type: "standard",
    enabled: true,
  }),

  minstrels_request: Object.freeze({
    id: "minstrels_request",
    name: "The Minstrel's Request",
    description:
      "Choose the music or playlist during shared time.",
    priceBp: 50,
    tier: REWARD_TIER.COMMON,
    type: "standard",
    enabled: true,
  }),

  keeper_of_the_feast: Object.freeze({
    id: "keeper_of_the_feast",
    name: "Keeper of the Feast",
    description:
      "Choose the meal or cuisine for a shared meal.",
    priceBp: 100,
    tier: REWARD_TIER.UNCOMMON,
    type: "standard",
    enabled: true,
  }),

  pathfinders_choice: Object.freeze({
    id: "pathfinders_choice",
    name: "The Pathfinder's Choice",
    description:
      "Choose a shared outing or activity.",
    priceBp: 100,
    tier: REWARD_TIER.UNCOMMON,
    type: "standard",
    enabled: true,
  }),

  quiet_evening_at_the_hearth: Object.freeze({
    id: "quiet_evening_at_the_hearth",
    name: "A Quiet Evening at the Hearth",
    description:
      "Request a relaxed, low-key evening together.",
    priceBp: 100,
    tier: REWARD_TIER.UNCOMMON,
    type: "standard",
    enabled: true,
  }),

  adventurers_decree: Object.freeze({
    id: "adventurers_decree",
    name: "The Adventurer's Decree",
    description:
      "Choose the theme or activity for a special date.",
    priceBp: 250,
    tier: REWARD_TIER.RARE,
    type: "standard",
    enabled: true,
  }),

  feast_of_the_two: Object.freeze({
    id: "feast_of_the_two",
    name: "Feast of the Two",
    description:
      "Request a special meal experience together.",
    priceBp: 250,
    tier: REWARD_TIER.RARE,
    type: "standard",
    enabled: true,
  }),

  the_open_road: Object.freeze({
    id: "the_open_road",
    name: "The Open Road",
    description:
      "Choose a larger local adventure or day outing.",
    priceBp: 250,
    tier: REWARD_TIER.RARE,
    type: "standard",
    enabled: true,
  }),

  grand_expedition: Object.freeze({
    id: "grand_expedition",
    name: "The Grand Expedition",
    description:
      "Request a planned special adventure together.",
    priceBp: 500,
    tier: REWARD_TIER.LEGENDARY,
    type: "standard",
    enabled: true,
  }),

  festival_of_two: Object.freeze({
    id: "festival_of_two",
    name: "Festival of Two",
    description:
      "Design a special themed date or celebration together.",
    priceBp: 500,
    tier: REWARD_TIER.LEGENDARY,
    type: "standard",
    enabled: true,
  }),

  royal_respite: Object.freeze({
    id: "royal_respite",
    name: "The Royal Respite",
    description:
      "Request a substantial planned relaxation experience " +
      "together.",
    priceBp: 500,
    tier: REWARD_TIER.LEGENDARY,
    type: "standard",
    enabled: true,
  }),

  mythic_quest: Object.freeze({
    id: "mythic_quest",
    name: "The Mythic Quest",
    description:
      "Request an extraordinary planned adventure or " +
      "experience together.",
    priceBp: 1000,
    tier: REWARD_TIER.MYTHIC,
    type: "standard",
    enabled: true,
  }),

  sovereign_celebration: Object.freeze({
    id: "sovereign_celebration",
    name: "The Sovereign Celebration",
    description:
      "Design a major celebration or memorable occasion " +
      "for the two of you.",
    priceBp: 1000,
    tier: REWARD_TIER.MYTHIC,
    type: "standard",
    enabled: true,
  }),

  journey_beyond_the_map: Object.freeze({
    id: "journey_beyond_the_map",
    name: "The Journey Beyond the Map",
    description:
      "Choose an ambitious future day trip, excursion, or " +
      "shared adventure to plan together.",
    priceBp: 1000,
    tier: REWARD_TIER.MYTHIC,
    type: "standard",
    enabled: true,
  }),

  custom_reward: Object.freeze({
    id: "custom_reward",
    name: "A Pact of Your Own",
    description:
      "Create a custom reward agreed upon by both partners.",
    priceBp: 100,
    tier: REWARD_TIER.CUSTOM,
    type: "custom",
    enabled: true,
  }),
});

/**
 * Validates a reward catalog ID.
 *
 * @param {*} rewardId Reward catalog ID.
 * @return {string} Validated reward ID.
 */
function requireRewardId(rewardId) {
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
 * Finds an enabled reward in the authoritative catalog.
 *
 * @param {string} rewardId Reward catalog ID.
 * @return {Object|null} Reward definition, or null when unavailable.
 */
function rewardForId(rewardId) {
  requireRewardId(rewardId);

  const reward =
    REWARD_CATALOG[rewardId];

  if (!reward || reward.enabled !== true) {
    return null;
  }

  return reward;
}

/**
 * Validates the complete authoritative reward catalog.
 *
 * @return {boolean} True when the catalog is valid.
 */
function validateRewardCatalog() {
  const rewardIds =
    Object.keys(REWARD_CATALOG);

  if (rewardIds.length === 0) {
    throw new Error(
        "The reward catalog must contain at least one reward.",
    );
  }

  const validTiers =
    new Set(Object.values(REWARD_TIER));

  for (const [
    catalogId,
    reward,
  ] of Object.entries(REWARD_CATALOG)) {
    if (
      typeof reward !== "object" ||
      reward === null
    ) {
      throw new Error(
          `Reward ${catalogId} is invalid.`,
      );
    }

    if (reward.id !== catalogId) {
      throw new Error(
          `Reward ${catalogId} has a mismatched ID.`,
      );
    }

    if (
      typeof reward.name !== "string" ||
      reward.name.trim().length === 0
    ) {
      throw new Error(
          `Reward ${catalogId} has an invalid name.`,
      );
    }

    if (
      typeof reward.description !== "string" ||
      reward.description.trim().length === 0
    ) {
      throw new Error(
          `Reward ${catalogId} has an invalid description.`,
      );
    }

    if (
      !Number.isSafeInteger(reward.priceBp) ||
      reward.priceBp <= 0
    ) {
      throw new Error(
          `Reward ${catalogId} has an invalid BP price.`,
      );
    }

    if (!validTiers.has(reward.tier)) {
      throw new Error(
          `Reward ${catalogId} has an invalid tier.`,
      );
    }

    if (
      reward.type !== "standard" &&
      reward.type !== "custom"
    ) {
      throw new Error(
          `Reward ${catalogId} has an invalid type.`,
      );
    }

    if (
      reward.type === "custom" &&
      reward.tier !== REWARD_TIER.CUSTOM
    ) {
      throw new Error(
          `Custom reward ${catalogId} must use the custom tier.`,
      );
    }

    if (
      reward.type === "standard" &&
      reward.tier === REWARD_TIER.CUSTOM
    ) {
      throw new Error(
          `Standard reward ${catalogId} cannot use the custom tier.`,
      );
    }

    if (typeof reward.enabled !== "boolean") {
      throw new Error(
          `Reward ${catalogId} has an invalid enabled value.`,
      );
    }
  }

  return true;
}

validateRewardCatalog();

module.exports = {
  REWARD_TIER,
  REWARD_CATALOG,
  requireRewardId,
  rewardForId,
  validateRewardCatalog,
};
