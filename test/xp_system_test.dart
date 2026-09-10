import 'package:flutter_test/flutter_test.dart';
import 'package:relationship_xp/game/xp_system.dart';

void main() {
  group('XpSystem level calculation', () {
    test('starts at level 1 with zero XP', () {
      expect(XpSystem.levelForXp(0), 1);
    });

    test('reaches level 2 at 100 XP', () {
      expect(XpSystem.levelForXp(99), 1);
      expect(XpSystem.levelForXp(100), 2);
    });

    test('reaches level 3 at 300 total XP', () {
      expect(XpSystem.levelForXp(299), 2);
      expect(XpSystem.levelForXp(300), 3);
    });

    test('reaches level 4 at 600 total XP', () {
      expect(XpSystem.levelForXp(599), 3);
      expect(XpSystem.levelForXp(600), 4);
    });
  });

  group('XpSystem level progress', () {
    test('calculates XP earned inside the current level', () {
      expect(XpSystem.xpIntoCurrentLevel(0), 0);
      expect(XpSystem.xpIntoCurrentLevel(50), 50);
      expect(XpSystem.xpIntoCurrentLevel(100), 0);
      expect(XpSystem.xpIntoCurrentLevel(250), 150);
      expect(XpSystem.xpIntoCurrentLevel(350), 50);
    });

    test('calculates XP required for the next level', () {
      expect(XpSystem.xpNeededForNextLevel(0), 100);
      expect(XpSystem.xpNeededForNextLevel(100), 200);
      expect(XpSystem.xpNeededForNextLevel(300), 300);
    });

    test('calculates progress as a value between 0 and 1', () {
      expect(XpSystem.levelProgress(50), 0.5);
      expect(XpSystem.levelProgress(100), 0.0);
      expect(XpSystem.levelProgress(200), 0.5);
    });
  });
}
