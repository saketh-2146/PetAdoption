import '../models/pet.dart';

/// Same 8 demo pets as the original Figma export's `src/data.ts`, rewritten
/// as Dart `Pet` objects so they can be pushed straight into Firestore.
/// See SeedService.seedIfEmpty().
final List<Pet> seedPets = [];

/// Matches data.ts `categories`.
const List<Map<String, String>> seedCategories = [
  {'id': 'all', 'label': 'All Pets', 'emoji': '🐾'},
  {'id': 'dog', 'label': 'Dogs', 'emoji': '🐕'},
  {'id': 'cat', 'label': 'Cats', 'emoji': '🐱'},
  {'id': 'rabbit', 'label': 'Rabbits', 'emoji': '🐰'},
  {'id': 'bird', 'label': 'Birds', 'emoji': '🦜'},
  {'id': 'other', 'label': 'Others', 'emoji': '🐹'},
];

