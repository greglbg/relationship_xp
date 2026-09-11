import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../services/catalog_task_service.dart';
import '../../tasks/task_catalog.dart';
import 'custom_claim_screen.dart';

class SubmitClaimScreen extends StatelessWidget {
  const SubmitClaimScreen({required this.coupleId, super.key});

  final String coupleId;

  Future<void> openCustomActivity(BuildContext context) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CustomClaimScreen(coupleId: coupleId),
      ),
    );

    if (submitted == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void openCategory(BuildContext context, TaskCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CategoryTaskScreen(coupleId: coupleId, category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Activity')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Choose an activity',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Built-in activities have fixed XP values and reward limits.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ...TaskCatalog.categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CategoryCard(
                  category: category,
                  onTap: () {
                    openCategory(context, category);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  openCustomActivity(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.edit_outlined)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Activity',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${TaskCatalog.customTaskXp} XP • '
                              'Partner approval required',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Photos are optional for custom activities. '
              'Built-in activity photo support is coming next.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.category, required this.onTap, super.key});

  final TaskCategory category;
  final VoidCallback onTap;

  IconData get categoryIcon {
    switch (category.id) {
      case 'appreciation':
        return Icons.favorite_outline;
      case 'acts_of_service':
        return Icons.volunteer_activism_outlined;
      case 'quality_time':
        return Icons.schedule_outlined;
      case 'communication':
        return Icons.chat_bubble_outline;
      case 'romance':
        return Icons.auto_awesome_outlined;
      case 'support':
        return Icons.handshake_outlined;
      case 'household':
        return Icons.home_outlined;
      case 'shared_goals':
        return Icons.flag_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(categoryIcon)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${category.tasks.length} activities',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryTaskScreen extends StatelessWidget {
  const CategoryTaskScreen({
    required this.coupleId,
    required this.category,
    super.key,
  });

  final String coupleId;
  final TaskCategory category;

  String repeatDescription(RelationshipTask task) {
    final period = switch (task.repeatPeriod) {
      TaskRepeatPeriod.daily => 'day',
      TaskRepeatPeriod.weekly => 'week',
    };

    if (task.rewardLimit == 1) {
      return 'Earn XP once per $period';
    }

    return 'Earn XP up to ${task.rewardLimit} times per $period';
  }

  void openTask(BuildContext context, RelationshipTask task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CatalogTaskDetailsScreen(
          coupleId: coupleId,
          task: task,
          categoryName: category.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: category.tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = category.tasks[index];

          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                openTask(context, task);
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(child: Text('${task.xp}')),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${task.xp} XP • ${repeatDescription(task)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CatalogTaskDetailsScreen extends StatefulWidget {
  const CatalogTaskDetailsScreen({
    required this.coupleId,
    required this.task,
    required this.categoryName,
    super.key,
  });

  final String coupleId;
  final RelationshipTask task;
  final String categoryName;

  @override
  State<CatalogTaskDetailsScreen> createState() =>
      _CatalogTaskDetailsScreenState();
}

class _CatalogTaskDetailsScreenState extends State<CatalogTaskDetailsScreen> {
  final CatalogTaskService _catalogTaskService = CatalogTaskService();

  late final String _completionId;

  bool _isSubmitting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _completionId = FirebaseFirestore.instance
        .collection('_completionIds')
        .doc()
        .id;
  }

  String get repeatDescription {
    final period = switch (widget.task.repeatPeriod) {
      TaskRepeatPeriod.daily => 'day',
      TaskRepeatPeriod.weekly => 'week',
    };

    if (widget.task.rewardLimit == 1) {
      return 'This activity can award XP once per $period.';
    }

    return 'This activity can award XP up to '
        '${widget.task.rewardLimit} times per $period.';
  }

  Future<void> completeActivity() async {
    if (_isSubmitting || _completed) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _catalogTaskService.completeTask(
        coupleId: widget.coupleId,
        taskId: widget.task.id,
        completionId: _completionId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _completed = true;
        _isSubmitting = false;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.celebration_outlined),
            title: Text(
              result.alreadyCompleted
                  ? 'Activity Already Recorded'
                  : 'Activity Complete!',
            ),
            content: Text(
              result.alreadyCompleted
                  ? 'This completion was already recorded. '
                        'No duplicate XP was awarded.'
                  : 'You earned ${result.xpAwarded} XP for '
                        '${result.taskName}.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Nice!'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      final message = error.message?.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message == null || message.isEmpty
                ? 'The activity could not be completed. Please try again.'
                : message,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while completing the activity. '
            'Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.categoryName,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.task.name,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                widget.task.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '${widget.task.xp} XP',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(repeatDescription, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text(
                        'Photo support for built-in activities is coming next.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.security_outlined),
                      const SizedBox(height: 8),
                      Text(
                        'XP is securely verified',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Relationship XP verifies the activity, reward limit, '
                        'and XP value before recording the completion.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting || _completed
                    ? null
                    : completeActivity,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting
                      ? 'Completing...'
                      : _completed
                      ? 'Activity Completed'
                      : 'Complete Activity',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
