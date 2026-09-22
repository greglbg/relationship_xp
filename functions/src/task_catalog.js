const DAILY_CATALOG_XP_TARGET = 250;

const TASK_REPEAT_PERIOD = {
  DAILY: "daily",
  WEEKLY: "weekly",
};

const TASK_CATALOG = {
  // Appreciation

  specific_compliment: {
    name: "Give a specific compliment",
    xp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  thoughtful_note: {
    name: "Leave a thoughtful note",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  remember_favorite_topic: {
    name: "Remember something about a favorite topic",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  celebrate_accomplishment: {
    name: "Celebrate an accomplishment",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  // Acts of Service

  bring_drink_or_snack: {
    name: "Bring a favorite drink or snack",
    xp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  handle_partner_chore: {
    name: "Take care of one of their usual chores",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  help_with_errand: {
    name: "Help with an errand",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  handle_difficult_task: {
    name: "Handle a difficult task for your partner",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  // Quality Time

  distraction_free_time: {
    name: "Spend 20 minutes distraction-free together",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  shared_walk: {
    name: "Take a walk together",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  plan_date_night: {
    name: "Plan a date night",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  special_outing: {
    name: "Plan a special outing",
    xp: 100,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  // Communication

  ask_about_day: {
    name: "Ask about their day and really listen",
    xp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  meaningful_check_in: {
    name: "Have a meaningful check-in",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  share_gratitude: {
    name: "Share something you are grateful for",
    xp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  constructive_conversation: {
    name: "Work through a disagreement constructively",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  // Romance

  affectionate_gesture: {
    name: "Share an affectionate gesture",
    xp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  small_romantic_surprise: {
    name: "Create a small romantic surprise",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  plan_romantic_evening: {
    name: "Plan a romantic evening",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  recreate_memory: {
    name: "Recreate a favorite memory",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  // Support

  encourage_goal: {
    name: "Encourage one of their goals",
    xp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  help_with_goal: {
    name: "Help with one of their goals",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  support_stressful_day: {
    name: "Support them through a stressful day",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  show_interest_hobby: {
    name: "Show interest in one of their hobbies",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  // Household

  clean_shared_space: {
    name: "Clean a shared space",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  finish_laundry: {
    name: "Take care of the laundry",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  prepare_meal: {
    name: "Prepare a meal",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  household_project: {
    name: "Complete a household project",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  // Shared Goals

  goal_progress: {
    name: "Make progress on a shared goal",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  plan_shared_goal: {
    name: "Plan the next step of a shared goal",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  complete_goal_milestone: {
    name: "Complete a shared-goal milestone",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  complete_major_goal: {
    name: "Complete a major shared goal",
    xp: 100,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  // Spiritual

  share_personal_meaning: {
    name: "Share something that gives you meaning",
    xp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  learn_partner_beliefs: {
    name: "Learn about your partner's beliefs",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  shared_meaningful_practice: {
    name: "Share a meaningful practice",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  meaningful_experience: {
    name: "Explore a meaningful experience together",
    xp: 100,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  shared_spiritual_study: {
    name: "Participate in a spiritual study together",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  // Intimacy

  intimate_appreciation: {
    name: "Express an intimate appreciation",
    xp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  discuss_intimacy_preferences: {
    name: "Discuss intimacy and preferences",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  intentional_closeness: {
    name: "Make time for physical or emotional closeness",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  plan_intimate_experience: {
    name: "Plan a special intimate experience",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  selfless_affection: {
    name: "Offer a moment of selfless affection",
    xp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  explore_new_intimate_experience: {
    name: "Explore a new intimate experience together",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  discover_intimacy_item: {
    name: "Discover something new for your intimacy",
    xp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },
};

module.exports = {
  DAILY_CATALOG_XP_TARGET,
  TASK_CATALOG,
  TASK_REPEAT_PERIOD,
};