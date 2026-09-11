import 'package:cloud_functions/cloud_functions.dart';

class CatalogTaskCompletionResult {
  const CatalogTaskCompletionResult({
    required this.alreadyCompleted,
    required this.claimId,
    required this.taskId,
    required this.taskName,
    required this.xpAwarded,
    required this.dailyCatalogXpTarget,
    this.catalogXpEarnedToday,
  });

  final bool alreadyCompleted;
  final String claimId;
  final String taskId;
  final String taskName;
  final int xpAwarded;
  final int dailyCatalogXpTarget;
  final int? catalogXpEarnedToday;

  factory CatalogTaskCompletionResult.fromMap(Map<String, dynamic> data) {
    return CatalogTaskCompletionResult(
      alreadyCompleted: data['alreadyCompleted'] == true,
      claimId: data['claimId'] as String,
      taskId: data['taskId'] as String,
      taskName: data['taskName'] as String,
      xpAwarded: (data['xpAwarded'] as num).toInt(),
      dailyCatalogXpTarget: (data['dailyCatalogXpTarget'] as num).toInt(),
      catalogXpEarnedToday: data['catalogXpEarnedToday'] == null
          ? null
          : (data['catalogXpEarnedToday'] as num).toInt(),
    );
  }
}

class CatalogTaskService {
  CatalogTaskService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<CatalogTaskCompletionResult> completeTask({
    required String coupleId,
    required String taskId,
    required String completionId,
  }) async {
    final callable = _functions.httpsCallable('completeCatalogTask');

    final response = await callable.call<Map<String, dynamic>>({
      'coupleId': coupleId,
      'taskId': taskId,
      'completionId': completionId,
    });

    return CatalogTaskCompletionResult.fromMap(response.data);
  }
}
