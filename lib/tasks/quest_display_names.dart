import 'task_catalog.dart';

/// Player-facing Aragoth quest titles and descriptions.
///
/// Task IDs, XP values, repeat periods, and reward limits remain defined
/// in TaskCatalog. This file changes only what players see.
class QuestDisplayNames {
  QuestDisplayNames._();

  static const Map<String, String> _titles = {
    // 1. Words of Worth
    'specific_compliment': 'Praise of the Worthy',
    'thoughtful_note': 'The Heartfelt Missive',
    'remember_favorite_topic': 'Lore of the Beloved',
    'celebrate_accomplishment': 'A Victory Worth Honoring',

    // 2. Deeds of the Steadfast
    'bring_drink_or_snack': 'A Token of Comfort',
    'handle_partner_chore': 'The Burden Lifted',
    'help_with_errand': 'A Journey in Their Stead',
    'handle_difficult_task': 'The Trial of the Steadfast',

    // 3. Adventures Together
    'distraction_free_time': "The Companion's Respite",
    'shared_walk': 'Steps in Unison',
    'plan_date_night': 'The Evening Quest',
    'special_outing': 'An Adventure Worth Remembering',

    // 4. The Council of Two
    'ask_about_day': 'The Attentive Companion',
    'meaningful_check_in': "The Heart's Council",
    'share_gratitude': 'Blessings of the Bond',
    'constructive_conversation': 'The Bridge of Understanding',

    // 5. Embers of Affection
    'affectionate_gesture': 'A Tender Offering',
    'small_romantic_surprise': "The Lover's Token",
    'plan_romantic_evening': 'An Evening by Emberlight',
    'recreate_memory': 'Echoes of Our Story',

    // 6. The Steadfast Companion
    'encourage_goal': 'A Voice Beside You',
    'help_with_goal': 'A Hand in Their Quest',
    'support_stressful_day': 'A Haven in Hardship',
    'show_interest_hobby': 'The Curious Companion',

    // 7. Hearth & Homestead
    'clean_shared_space': 'The Hearth Restored',
    'finish_laundry': 'The Garments Renewed',
    'prepare_meal': 'A Meal from the Hearth',
    'household_project': 'A Labor for the Hearth',

    // 8. The Pact of Two
    'goal_progress': 'The Pact Advances',
    'plan_shared_goal': 'Charting the Path Ahead',
    'complete_goal_milestone': 'A Milestone of the Pact',
    'complete_major_goal': 'The Pact Fulfilled',

    // 9. The Inner Lantern
    'share_personal_meaning': 'The Lantern Within',
    'learn_partner_beliefs': "The Seeker's Lantern",
    'shared_meaningful_practice': 'Ritual of Two Lanterns',
    'meaningful_experience': "Beyond the Lantern's Glow",
    'shared_spiritual_study': "The Lantern's Lore",

    // 10. The Inner Sanctuary
    'intimate_appreciation': 'Whispers of Appreciation',
    'discuss_intimacy_preferences': "The Sanctuary's Council",
    'intentional_closeness': 'The Embrace of Two',
    'plan_intimate_experience': 'An Evening in the Sanctuary',
    'selfless_affection': 'The Gift of Tenderness',
    'explore_new_intimate_experience': 'Beyond the Familiar Veil',
    'discover_intimacy_item': 'An Artifact of Affection',
  };

  static const Map<String, String> _descriptions = {
    // 1. Words of Worth
    'specific_compliment':
        'Recognize a particular quality, effort, or action you appreciate '
        'in your partner.',
    'thoughtful_note':
        'Send or leave a sincere note telling your partner something '
        'you appreciate about them.',
    'remember_favorite_topic':
        'Show your partner that you remember a detail about one of '
        'their favorite interests.',
    'celebrate_accomplishment':
        "Take time to recognize your partner's achievement, progress, "
        'or effort.',

    // 2. Deeds of the Steadfast
    'bring_drink_or_snack':
        'Offer your partner a favorite refreshment as a thoughtful gesture.',
    'handle_partner_chore':
        'Take care of a household responsibility your partner would '
        'normally handle.',
    'help_with_errand': "Take care of an errand on your partner's behalf.",
    'handle_difficult_task':
        'Take on an especially inconvenient, tiring, or time-consuming '
        'task to help your partner.',

    // 3. Adventures Together
    'distraction_free_time':
        'Put distractions away and enjoy at least 20 intentional '
        'minutes together.',
    'shared_walk': 'Share a walk and spend time connecting along the way.',
    'plan_date_night':
        'Take the initiative to plan an intentional date or shared activity.',
    'special_outing':
        'Plan a special shared experience, such as a day trip, event, '
        'or memorable outing.',

    // 4. The Council of Two
    'ask_about_day':
        'Invite your partner to share their day and listen without '
        'distractions.',
    'meaningful_check_in':
        'Have an intentional conversation about your feelings, needs, '
        'and experiences.',
    'share_gratitude':
        'Express gratitude for something meaningful in your relationship.',
    'constructive_conversation':
        'Discuss a disagreement respectfully and work toward '
        "understanding each other's perspectives.",

    // 5. Embers of Affection
    'affectionate_gesture':
        'Express affection in a way your partner appreciates and feels '
        'comfortable receiving.',
    'small_romantic_surprise':
        'Offer an unexpected, thoughtful gesture of romance or affection.',
    'plan_romantic_evening':
        'Plan an intentional romantic evening focused on enjoying '
        'time together.',
    'recreate_memory':
        'Revisit or recreate a favorite memory from your relationship.',

    // 6. The Steadfast Companion
    'encourage_goal':
        'Remind your partner that you believe in a goal they are pursuing.',
    'help_with_goal':
        'Assist your partner with a meaningful step toward something '
        'they want to achieve.',
    'support_stressful_day':
        "Do something caring that eases your partner's stressful day.",
    'show_interest_hobby':
        'Spend time learning about or discussing a hobby your partner enjoys.',

    // 7. Hearth & Homestead
    'clean_shared_space':
        'Clean or tidy an area you and your partner both use.',
    'finish_laundry':
        'Take care of a substantial laundry task for your household.',
    'prepare_meal':
        'Make a thoughtful meal that your partner or both of you can enjoy.',
    'household_project':
        'Finish a meaningful household repair, organization, or '
        'improvement project.',

    // 8. The Pact of Two
    'goal_progress':
        'Take a meaningful step toward a goal you and your partner '
        'have agreed to pursue together.',
    'plan_shared_goal':
        'Spend time planning what comes next for a goal you are '
        'pursuing together.',
    'complete_goal_milestone':
        'Reach an important milestone in a goal you are working '
        'toward together.',
    'complete_major_goal':
        'Complete and celebrate a significant goal you have worked '
        'toward together.',

    // 9. The Inner Lantern
    'share_personal_meaning':
        'Share a belief, value, or experience that gives your life meaning.',
    'learn_partner_beliefs':
        "Ask about your partner's beliefs or values and listen with "
        'curiosity and respect.',
    'shared_meaningful_practice':
        'Share a spiritual, reflective, or values-based practice that '
        'feels meaningful to you both.',
    'meaningful_experience':
        'Create a memorable shared experience centered on what gives '
        'your lives meaning.',
    'shared_spiritual_study':
        'Explore a meaningful teaching, text, or question together '
        'and share your perspectives.',

    // 10. The Inner Sanctuary
    'intimate_appreciation':
        'Express sincere appreciation for an aspect of your '
        'intimate connection.',
    'discuss_intimacy_preferences':
        "Have an open, respectful conversation about each other's "
        'intimacy preferences and boundaries.',
    'intentional_closeness':
        'Enjoy a moment of mutually welcome closeness without pressure '
        'or expectation.',
    'plan_intimate_experience':
        'Plan an intimate experience that you both want and feel '
        'comfortable sharing.',
    'selfless_affection':
        'Offer affection in a way your partner enjoys, without '
        'expecting anything in return.',
    'explore_new_intimate_experience':
        'Explore a new intimate experience that you both freely agree '
        'to and feel comfortable trying.',
    'discover_intimacy_item':
        'Discover an item that might enhance intimacy and consider '
        'it together without pressure.',
  };

  /// Returns the approved fantasy title, or the original title if missing.
  static String titleFor(RelationshipTask task) {
    return _titles[task.id] ?? task.name;
  }

  /// Returns the approved description, or the original if missing.
  static String descriptionFor(RelationshipTask task) {
    return _descriptions[task.id] ?? task.description;
  }

  /// Allows screens displaying a saved task ID to resolve its fantasy title.
  ///
  /// An unknown ID returns null instead of inventing a task name.
  static String? titleForId(String taskId) {
    return _titles[taskId];
  }
}
