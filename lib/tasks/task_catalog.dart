import '../game/game_balance.dart';

enum TaskRepeatPeriod { daily, weekly }

class RelationshipTask {
  const RelationshipTask({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.xp,
    required this.repeatPeriod,
    required this.rewardLimit,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int xp;
  final TaskRepeatPeriod repeatPeriod;

  /// Maximum number of times this task can award XP during
  /// its repeat period.
  final int rewardLimit;

  /// Built-in catalog tasks do not require partner approval.
  bool get requiresApproval => false;
}

class TaskCategory {
  const TaskCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.tasks,
  });

  final String id;
  final String name;
  final String description;
  final List<RelationshipTask> tasks;
}

class TaskCatalog {
  TaskCatalog._();

  /// These aliases let our existing screens continue working while
  /// GameBalance remains the single source of truth for XP limits.
  static const int customTaskXp = GameBalance.customTaskXp;

  static const int dailyCatalogXpCap = GameBalance.dailyCatalogXpTarget;

  static const int dailyCustomSubmissionLimit =
      GameBalance.dailyCustomRewardLimit;

  static const List<TaskCategory> categories = [
    TaskCategory(
      id: 'appreciation',
      name: 'Appreciation',
      description:
          'Notice, recognize, and celebrate the things you value about '
          'your partner.',
      tasks: [
        RelationshipTask(
          id: 'specific_compliment',
          categoryId: 'appreciation',
          name: 'Give a specific compliment',
          description:
              'Tell your partner something specific that you genuinely '
              'appreciate about them.',
          xp: 10,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'thoughtful_note',
          categoryId: 'appreciation',
          name: 'Leave a thoughtful note',
          description:
              'Write your partner a kind note, message, or other small '
              'expression of appreciation.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'remember_favorite_topic',
          categoryId: 'appreciation',
          name: 'Remember something about a favorite topic',
          description:
              'Remember or bring up something meaningful about a topic '
              'your partner especially enjoys.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'celebrate_accomplishment',
          categoryId: 'appreciation',
          name: 'Celebrate an accomplishment',
          description:
              'Take time to recognize something your partner accomplished '
              'or worked hard on.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
      ],
    ),
    TaskCategory(
      id: 'acts_of_service',
      name: 'Acts of Service',
      description:
          'Make life a little easier through helpful and thoughtful actions.',
      tasks: [
        RelationshipTask(
          id: 'bring_drink_or_snack',
          categoryId: 'acts_of_service',
          name: 'Bring a favorite drink or snack',
          description:
              'Surprise your partner with a drink, snack, or small treat '
              'they enjoy.',
          xp: 10,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'handle_partner_chore',
          categoryId: 'acts_of_service',
          name: 'Take care of one of their usual chores',
          description:
              'Handle a household responsibility your partner would '
              'normally have needed to do.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'help_with_errand',
          categoryId: 'acts_of_service',
          name: 'Help with an errand',
          description:
              'Take care of or help with an errand that saves your partner '
              'time or effort.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'handle_difficult_task',
          categoryId: 'acts_of_service',
          name: 'Handle a difficult task for your partner',
          description:
              'Take on something especially inconvenient, tiring, or '
              'time-consuming to help your partner.',
          xp: 50,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 2,
        ),
      ],
    ),
    TaskCategory(
      id: 'quality_time',
      name: 'Quality Time',
      description:
          'Spend intentional time together and build shared experiences.',
      tasks: [
        RelationshipTask(
          id: 'distraction_free_time',
          categoryId: 'quality_time',
          name: 'Spend 20 minutes distraction-free together',
          description:
              'Put distractions aside and spend at least 20 intentional '
              'minutes focused on each other.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'shared_walk',
          categoryId: 'quality_time',
          name: 'Take a walk together',
          description:
              'Spend some time walking together and enjoying each other\'s '
              'company.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'plan_date_night',
          categoryId: 'quality_time',
          name: 'Plan a date night',
          description:
              'Take the initiative to plan an intentional date or shared '
              'activity.',
          xp: 50,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'special_outing',
          categoryId: 'quality_time',
          name: 'Plan a special outing',
          description:
              'Create a larger shared experience such as a day trip, event, '
              'or memorable adventure.',
          xp: 100,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 1,
        ),
      ],
    ),
    TaskCategory(
      id: 'communication',
      name: 'Communication',
      description:
          'Practice listening, openness, curiosity, and healthy conversation.',
      tasks: [
        RelationshipTask(
          id: 'ask_about_day',
          categoryId: 'communication',
          name: 'Ask about their day and really listen',
          description:
              'Give your partner your attention while they share how their '
              'day went.',
          xp: 10,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'meaningful_check_in',
          categoryId: 'communication',
          name: 'Have a meaningful check-in',
          description:
              'Talk intentionally about how each of you is doing and what '
              'you may need from one another.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 2,
        ),
        RelationshipTask(
          id: 'share_gratitude',
          categoryId: 'communication',
          name: 'Share something you are grateful for',
          description:
              'Tell your partner something about them or your relationship '
              'that you are grateful for.',
          xp: 10,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'constructive_conversation',
          categoryId: 'communication',
          name: 'Work through a disagreement constructively',
          description:
              'Approach a disagreement with respect, listening, and a goal '
              'of understanding rather than winning.',
          xp: 50,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 1,
        ),
      ],
    ),
    TaskCategory(
      id: 'romance',
      name: 'Romance',
      description:
          'Create affectionate, thoughtful, and playful moments together.',
      tasks: [
        RelationshipTask(
          id: 'affectionate_gesture',
          categoryId: 'romance',
          name: 'Share an affectionate gesture',
          description:
              'Offer an affectionate gesture that your partner appreciates '
              'and welcomes.',
          xp: 10,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'small_romantic_surprise',
          categoryId: 'romance',
          name: 'Create a small romantic surprise',
          description:
              'Do something small and unexpected that makes your partner '
              'feel cared for.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'plan_romantic_evening',
          categoryId: 'romance',
          name: 'Plan a romantic evening',
          description:
              'Put together an intentional evening focused on enjoying '
              'time together.',
          xp: 50,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'recreate_memory',
          categoryId: 'romance',
          name: 'Recreate a favorite memory',
          description:
              'Revisit or recreate something meaningful from your '
              'relationship.',
          xp: 50,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 1,
        ),
      ],
    ),
    TaskCategory(
      id: 'support',
      name: 'Personal Support',
      description:
          'Encourage your partner and support the things that matter to them.',
      tasks: [
        RelationshipTask(
          id: 'encourage_goal',
          categoryId: 'support',
          name: 'Encourage one of their goals',
          description:
              'Offer genuine encouragement toward something your partner '
              'is working toward.',
          xp: 10,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'help_with_goal',
          categoryId: 'support',
          name: 'Help with one of their goals',
          description:
              'Provide practical help that moves one of your partner\'s '
              'goals forward.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 2,
        ),
        RelationshipTask(
          id: 'support_stressful_day',
          categoryId: 'support',
          name: 'Support them through a stressful day',
          description:
              'Do something intentionally supportive when your partner is '
              'having a difficult or stressful day.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'show_interest_hobby',
          categoryId: 'support',
          name: 'Show interest in one of their hobbies',
          description:
              'Spend time learning about, discussing, or participating in '
              'something your partner enjoys.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 2,
        ),
      ],
    ),
    TaskCategory(
      id: 'household',
      name: 'Household',
      description:
          'Work together to care for the space and responsibilities you share.',
      tasks: [
        RelationshipTask(
          id: 'clean_shared_space',
          categoryId: 'household',
          name: 'Clean a shared space',
          description: 'Take care of cleaning or tidying an area you both use.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'finish_laundry',
          categoryId: 'household',
          name: 'Take care of the laundry',
          description: 'Complete a meaningful part of the household laundry.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'prepare_meal',
          categoryId: 'household',
          name: 'Prepare a meal',
          description: 'Prepare a meal for your partner or for both of you.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'household_project',
          categoryId: 'household',
          name: 'Complete a household project',
          description:
              'Finish a larger maintenance, organization, or improvement '
              'task for your shared space.',
          xp: 50,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 2,
        ),
      ],
    ),
    TaskCategory(
      id: 'shared_goals',
      name: 'Shared Goals',
      description:
          'Make progress on things you have chosen to accomplish together.',
      tasks: [
        RelationshipTask(
          id: 'goal_progress',
          categoryId: 'shared_goals',
          name: 'Make progress on a shared goal',
          description:
              'Take a meaningful step toward something you have agreed to '
              'work on together.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.daily,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'plan_shared_goal',
          categoryId: 'shared_goals',
          name: 'Plan the next step of a shared goal',
          description:
              'Spend time deciding what comes next for one of your shared '
              'goals.',
          xp: 25,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 2,
        ),
        RelationshipTask(
          id: 'complete_goal_milestone',
          categoryId: 'shared_goals',
          name: 'Complete a shared-goal milestone',
          description:
              'Reach an important milestone in something you are working '
              'toward together.',
          xp: 50,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 1,
        ),
        RelationshipTask(
          id: 'complete_major_goal',
          categoryId: 'shared_goals',
          name: 'Complete a major shared goal',
          description:
              'Celebrate completing a significant goal you have worked on '
              'together.',
          xp: 100,
          repeatPeriod: TaskRepeatPeriod.weekly,
          rewardLimit: 1,
        ),
      ],
    ),
  ];

  static List<RelationshipTask> get allTasks {
    return categories
        .expand((category) => category.tasks)
        .toList(growable: false);
  }

  static RelationshipTask? taskById(String taskId) {
    for (final task in allTasks) {
      if (task.id == taskId) {
        return task;
      }
    }

    return null;
  }

  static TaskCategory? categoryById(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category;
      }
    }

    return null;
  }
}
