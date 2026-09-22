import 'task_catalog.dart';

/// User-facing fantasy category names.
/// The catalog's IDs and stored data stay unchanged.
class QuestCategoryNames {
  QuestCategoryNames._();

  static const Map<String, String> _names = {
    'appreciation': 'Words of Worth',
    'acts_of_service': 'Deeds of the Steadfast',
    'quality_time': 'Adventures Together',
    'communication': 'The Council of Two',
    'romance': 'Embers of Affection',
    'support': 'The Steadfast Companion',
    'household': 'Hearth & Homestead',
    'shared_goals': 'The Pact of Two',
    'spiritual': 'The Inner Lantern',
    'intimacy': 'The Inner Sanctuary',
  };

  static String forCategory(TaskCategory category) =>
      _names[category.id] ?? category.name;
}