class XpSystem {
  XpSystem._();

  // Initial progression limits.
  // Keep these aligned with the Cloud Functions backend.
  static const int maximumLevel = 50;
  static const int maximumXp = 122500;

  // Total XP required to reach a particular level.
  //
  // Level 1:       0 XP
  // Level 2:     100 XP
  // Level 3:     300 XP
  // Level 50: 122500 XP
  static int xpRequiredForLevel(int level) {
    if (level <= 1) {
      return 0;
    }

    final cappedLevel = level > maximumLevel ? maximumLevel : level;

    return 50 * (cappedLevel - 1) * cappedLevel;
  }

  // Convert total XP into an individual level.
  static int levelForXp(int xp) {
    if (xp <= 0) {
      return 1;
    }

    if (xp >= maximumXp) {
      return maximumLevel;
    }

    var level = 1;

    while (level < maximumLevel && xp >= xpRequiredForLevel(level + 1)) {
      level++;
    }

    return level;
  }

  // XP earned since reaching the current level.
  static int xpIntoCurrentLevel(int xp) {
    if (xp <= 0) {
      return 0;
    }

    if (xp >= maximumXp) {
      return 0;
    }

    final level = levelForXp(xp);
    final currentLevelStartingXp = xpRequiredForLevel(level);

    return xp - currentLevelStartingXp;
  }

  // XP required to progress from the current level
  // to the next level.
  static int xpNeededForNextLevel(int xp) {
    if (xp >= maximumXp) {
      return 0;
    }

    final level = levelForXp(xp);

    return xpRequiredForLevel(level + 1) - xpRequiredForLevel(level);
  }

  // Progress bar value between 0.0 and 1.0.
  static double levelProgress(int xp) {
    if (xp >= maximumXp) {
      return 1.0;
    }

    final required = xpNeededForNextLevel(xp);

    if (required <= 0) {
      return 0.0;
    }

    return xpIntoCurrentLevel(xp) / required;
  }
}
