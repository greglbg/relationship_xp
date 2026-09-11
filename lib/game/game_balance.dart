class GameBalance {
  GameBalance._();

  /// Fixed XP value for a custom activity.
  ///
  /// Custom activities require partner approval.
  static const int customTaskXp = 25;

  /// The normal daily target ceiling for automatically rewarded
  /// built-in catalog activities.
  ///
  /// A user may begin a valid task while below this amount.
  /// If the final task pushes them slightly above 250 XP, the full
  /// task value can still be awarded.
  static const int dailyCatalogXpTarget = 250;

  /// Maximum number of custom activities that can earn XP for one
  /// person during a calendar day.
  ///
  /// At 25 XP each, this allows up to 75 custom XP per day.
  static const int dailyCustomRewardLimit = 3;

  /// Highest XP value currently used by one built-in catalog task.
  ///
  /// This is useful when reasoning about the maximum possible
  /// overflow above the daily catalog XP target.
  static const int maximumCatalogTaskXp = 100;

  /// Returns whether another built-in catalog task may begin an
  /// XP-awarding completion.
  ///
  /// Once the user has reached or exceeded the daily catalog target,
  /// later catalog activities can still be meaningful activities,
  /// but they should not award additional XP that day.
  static bool canStartCatalogXpReward(int catalogXpEarnedToday) {
    return catalogXpEarnedToday < dailyCatalogXpTarget;
  }

  /// Returns whether another custom activity may still earn XP today.
  static bool canEarnAnotherCustomReward(int rewardedCustomActivitiesToday) {
    return rewardedCustomActivitiesToday < dailyCustomRewardLimit;
  }
}
