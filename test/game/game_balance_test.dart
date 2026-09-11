import 'package:flutter_test/flutter_test.dart';
import 'package:relationship_xp/game/game_balance.dart';

void main() {
  group('GameBalance', () {
    test('custom activities are worth 25 XP', () {
      expect(GameBalance.customTaskXp, 25);
    });

    test('daily catalog XP target is 250', () {
      expect(GameBalance.dailyCatalogXpTarget, 250);
    });

    test('daily custom reward limit is 3', () {
      expect(GameBalance.dailyCustomRewardLimit, 3);
    });

    test('maximum catalog task XP is 100', () {
      expect(GameBalance.maximumCatalogTaskXp, 100);
    });

    test('catalog XP can begin while below daily target', () {
      expect(GameBalance.canStartCatalogXpReward(0), isTrue);

      expect(GameBalance.canStartCatalogXpReward(249), isTrue);
    });

    test('catalog XP cannot begin after reaching daily target', () {
      expect(GameBalance.canStartCatalogXpReward(250), isFalse);

      expect(GameBalance.canStartCatalogXpReward(300), isFalse);
    });

    test('final catalog task may create controlled overflow', () {
      const currentXp = 225;
      const taskXp = 50;

      expect(GameBalance.canStartCatalogXpReward(currentXp), isTrue);

      expect(currentXp + taskXp, 275);
    });

    test('first three custom activities may earn XP', () {
      expect(GameBalance.canEarnAnotherCustomReward(0), isTrue);

      expect(GameBalance.canEarnAnotherCustomReward(1), isTrue);

      expect(GameBalance.canEarnAnotherCustomReward(2), isTrue);
    });

    test('fourth custom activity cannot earn XP that day', () {
      expect(GameBalance.canEarnAnotherCustomReward(3), isFalse);

      expect(GameBalance.canEarnAnotherCustomReward(4), isFalse);
    });
  });
}
