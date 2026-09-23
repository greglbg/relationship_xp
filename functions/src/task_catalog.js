const DAILY_CATALOG_XP_TARGET = 250;

const TASK_REPEAT_PERIOD = {
  DAILY: "daily",
  WEEKLY: "weekly",
};

const TASK_CATALOG = {
  // Words of Worth

  specific_compliment: {
    name: "Praise of the Worthy",
    description:
      "Recognize a particular quality, effort, or action you appreciate " +
      "in your partner.",
    xp: 10,
    bp: 5,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  thoughtful_note: {
    name: "The Heartfelt Missive",
    description:
      "Send or leave a sincere note telling your partner something " +
      "you appreciate about them.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  remember_favorite_topic: {
    name: "Lore of the Beloved",
    description:
      "Show your partner that you remember a detail about one of " +
      "their favorite interests.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  celebrate_accomplishment: {
    name: "A Victory Worth Honoring",
    description:
      "Take time to recognize your partner's achievement, progress, " +
      "or effort.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  // Deeds of the Steadfast

  bring_drink_or_snack: {
    name: "A Token of Comfort",
    description:
      "Offer your partner a favorite refreshment as a thoughtful gesture.",
    xp: 10,
    bp: 5,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  handle_partner_chore: {
    name: "The Burden Lifted",
    description:
      "Take care of a household responsibility your partner would " +
      "normally handle.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  help_with_errand: {
    name: "A Journey in Their Stead",
    description:
      "Take care of an errand on your partner's behalf.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  handle_difficult_task: {
    name: "The Trial of the Steadfast",
    description:
      "Take on an especially inconvenient, tiring, or time-consuming " +
      "task to help your partner.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  // Adventures Together

  distraction_free_time: {
    name: "The Companion's Respite",
    description:
      "Put distractions away and enjoy at least 20 intentional " +
      "minutes together.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  shared_walk: {
    name: "Steps in Unison",
    description:
      "Share a walk and spend time connecting along the way.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  plan_date_night: {
    name: "The Evening Quest",
    description:
      "Take the initiative to plan an intentional date or shared activity.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  special_outing: {
    name: "An Adventure Worth Remembering",
    description:
      "Plan a special shared experience, such as a day trip, event, " +
      "or memorable outing.",
    xp: 100,
    bp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  // The Council of Two

  ask_about_day: {
    name: "The Attentive Companion",
    description:
      "Invite your partner to share their day and listen without distractions.",
    xp: 10,
    bp: 5,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  meaningful_check_in: {
    name: "The Heart's Council",
    description:
      "Have an intentional conversation about your feelings, needs, " +
      "and experiences.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  share_gratitude: {
    name: "Blessings of the Bond",
    description:
      "Express gratitude for something meaningful in your relationship.",
    xp: 10,
    bp: 5,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  constructive_conversation: {
    name: "The Bridge of Understanding",
    description:
      "Discuss a disagreement respectfully and work toward " +
      "understanding each other's perspectives.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  // Embers of Affection

  affectionate_gesture: {
    name: "A Tender Offering",
    description:
      "Express affection in a way your partner appreciates and feels " +
      "comfortable receiving.",
    xp: 10,
    bp: 5,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  small_romantic_surprise: {
    name: "The Lover's Token",
    description:
      "Offer an unexpected, thoughtful gesture of romance or affection.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  plan_romantic_evening: {
    name: "An Evening by Emberlight",
    description:
      "Plan an intentional romantic evening focused on enjoying time together.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  recreate_memory: {
    name: "Echoes of Our Story",
    description:
      "Revisit or recreate a favorite memory from your relationship.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  // The Steadfast Companion

  encourage_goal: {
    name: "A Voice Beside You",
    description:
      "Remind your partner that you believe in a goal they are pursuing.",
    xp: 10,
    bp: 5,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  help_with_goal: {
    name: "A Hand in Their Quest",
    description:
      "Assist your partner with a meaningful step toward something " +
      "they want to achieve.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  support_stressful_day: {
    name: "A Haven in Hardship",
    description:
      "Do something caring that eases your partner's stressful day.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  show_interest_hobby: {
    name: "The Curious Companion",
    description:
      "Spend time learning about or discussing a hobby your partner enjoys.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  // Hearth & Homestead

  clean_shared_space: {
    name: "The Hearth Restored",
    description:
      "Clean or tidy an area you and your partner both use.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  finish_laundry: {
    name: "The Garments Renewed",
    description:
      "Take care of a substantial laundry task for your household.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  prepare_meal: {
    name: "A Meal from the Hearth",
    description:
      "Make a thoughtful meal that your partner or both of you can enjoy.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  household_project: {
    name: "A Labor for the Hearth",
    description:
      "Finish a meaningful household repair, organization, or improvement project.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  // The Pact of Two

  goal_progress: {
    name: "The Pact Advances",
    description:
      "Take a meaningful step toward a goal you and your partner " +
      "have agreed to pursue together.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  plan_shared_goal: {
    name: "Charting the Path Ahead",
    description:
      "Spend time planning what comes next for a goal you are pursuing together.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  complete_goal_milestone: {
    name: "A Milestone of the Pact",
    description:
      "Reach an important milestone in a goal you are working toward together.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  complete_major_goal: {
    name: "The Pact Fulfilled",
    description:
      "Complete and celebrate a significant goal you have worked toward together.",
    xp: 100,
    bp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  // The Inner Lantern

  share_personal_meaning: {
    name: "The Lantern Within",
    description:
      "Share a belief, value, or experience that gives your life meaning.",
    xp: 10,
    bp: 5,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  learn_partner_beliefs: {
    name: "The Seeker's Lantern",
    description:
      "Ask about your partner's beliefs or values and listen with curiosity " +
      "and respect.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  shared_meaningful_practice: {
    name: "Ritual of Two Lanterns",
    description:
      "Share a spiritual, reflective, or values-based practice that " +
      "feels meaningful to you both.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  meaningful_experience: {
    name: "Beyond the Lantern's Glow",
    description:
      "Create a memorable shared experience centered on what gives " +
      "your lives meaning.",
    xp: 100,
    bp: 50,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  shared_spiritual_study: {
    name: "The Lantern's Lore",
    description:
      "Explore a meaningful teaching, text, or question together " +
      "and share your perspectives.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  // The Inner Sanctuary

  intimate_appreciation: {
    name: "Whispers of Appreciation",
    description:
      "Express sincere appreciation for an aspect of your intimate connection.",
    xp: 10,
    bp: 5,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  discuss_intimacy_preferences: {
    name: "The Sanctuary's Council",
    description:
      "Have an open, respectful conversation about each other's intimacy " +
      "preferences and boundaries.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 2,
    enabled: true,
  },

  intentional_closeness: {
    name: "The Embrace of Two",
    description:
      "Enjoy a moment of mutually welcome closeness without pressure " +
      "or expectation.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  plan_intimate_experience: {
    name: "An Evening in the Sanctuary",
    description:
      "Plan an intimate experience that you both want and feel comfortable sharing.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  selfless_affection: {
    name: "The Gift of Tenderness",
    description:
      "Offer affection in a way your partner enjoys, without expecting " +
      "anything in return.",
    xp: 25,
    bp: 10,
    repeatPeriod: TASK_REPEAT_PERIOD.DAILY,
    rewardLimit: 1,
    enabled: true,
  },

  explore_new_intimate_experience: {
    name: "Beyond the Familiar Veil",
    description:
      "Explore a new intimate experience that you both freely agree to " +
      "and feel comfortable trying.",
    xp: 50,
    bp: 25,
    repeatPeriod: TASK_REPEAT_PERIOD.WEEKLY,
    rewardLimit: 1,
    enabled: true,
  },

  discover_intimacy_item: {
    name: "An Artifact of Affection",
    description:
      "Discover an item that might enhance intimacy and consider it " +
      "together without pressure.",
    xp: 50,
    bp: 25,
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