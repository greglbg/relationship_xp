class XpSystem {
  XpSystem._();

  static int levelForXp(int xp) {
    if (xp < 0) {
      return 1;
    }

    var level = 1;
    var xpRequiredForNextLevel = 100;
    var remainingXp = xp;

    while (remainingXp >= xpRequiredForNextLevel) {
      remainingXp -= xpRequiredForNextLevel;
      level++;
      xpRequiredForNextLevel = level * 100;
    }

    return level;
  }

  static int xpIntoCurrentLevel(int xp) {
    if (xp <= 0) {
      return 0;
    }

    var level = 1;
    var remainingXp = xp;
    var xpRequiredForNextLevel = 100;

    while (remainingXp >= xpRequiredForNextLevel) {
      remainingXp -= xpRequiredForNextLevel;
      level++;
      xpRequiredForNextLevel = level * 100;
    }

    return remainingXp;
  }

  static int xpNeededForNextLevel(int xp) {
    final level = levelForXp(xp);
    return level * 100;
  }

  static double levelProgress(int xp) {
    final required = xpNeededForNextLevel(xp);

    if (required == 0) {
      return 0;
    }

    return xpIntoCurrentLevel(xp) / required;
  }
}
