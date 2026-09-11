import 'package:flutter_test/flutter_test.dart';
import 'package:relationship_xp/tasks/task_catalog.dart';

void main() {
  group('TaskCatalog', () {
    test('contains categories and tasks', () {
      expect(TaskCatalog.categories, isNotEmpty);

      expect(TaskCatalog.allTasks, isNotEmpty);
    });

    test('every task has a unique ID', () {
      final taskIds = TaskCatalog.allTasks.map((task) => task.id).toList();

      final uniqueTaskIds = taskIds.toSet();

      expect(uniqueTaskIds.length, taskIds.length);
    });

    test('every category has a unique ID', () {
      final categoryIds = TaskCatalog.categories
          .map((category) => category.id)
          .toList();

      final uniqueCategoryIds = categoryIds.toSet();

      expect(uniqueCategoryIds.length, categoryIds.length);
    });

    test('every task belongs to its containing category', () {
      for (final category in TaskCatalog.categories) {
        for (final task in category.tasks) {
          expect(task.categoryId, category.id);
        }
      }
    });

    test('every built-in task has a valid XP value', () {
      const allowedXpValues = {10, 25, 50, 100};

      for (final task in TaskCatalog.allTasks) {
        expect(
          allowedXpValues.contains(task.xp),
          isTrue,
          reason: '${task.name} has an unexpected XP value of ${task.xp}.',
        );
      }
    });

    test('every built-in task has a positive reward limit', () {
      for (final task in TaskCatalog.allTasks) {
        expect(
          task.rewardLimit,
          greaterThan(0),
          reason: '${task.name} must have a positive reward limit.',
        );
      }
    });

    test('built-in tasks do not require partner approval', () {
      for (final task in TaskCatalog.allTasks) {
        expect(task.requiresApproval, isFalse);
      }
    });

    test('custom tasks use fixed 25 XP', () {
      expect(TaskCatalog.customTaskXp, 25);
    });

    test('daily catalog XP cap is positive', () {
      expect(TaskCatalog.dailyCatalogXpCap, greaterThan(0));
    });

    test('custom submission limit is positive', () {
      expect(TaskCatalog.dailyCustomSubmissionLimit, greaterThan(0));
    });

    test('taskById finds a catalog task', () {
      final task = TaskCatalog.taskById('specific_compliment');

      expect(task, isNotNull);

      expect(task!.xp, 10);
    });

    test('taskById returns null for an unknown task', () {
      final task = TaskCatalog.taskById('not_a_real_task');

      expect(task, isNull);
    });
  });
}
