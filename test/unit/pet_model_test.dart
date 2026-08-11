import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect/models/pet.dart';

void main() {
  group('Pet Model Tests', () {
    test('PetOwner.fromMap should parse correctly', () {
      final map = {
        'name': 'John Doe',
        'avatarId': 'avatar123',
        'rating': 4.5,
        'reviews': 10,
        'memberSince': '2023',
        'verified': true,
      };

      final owner = PetOwner.fromMap(map);

      expect(owner.name, 'John Doe');
      expect(owner.avatarId, 'avatar123');
      expect(owner.rating, 4.5);
      expect(owner.reviews, 10);
      expect(owner.memberSince, '2023');
      expect(owner.verified, true);
    });

    test('PetHealth.fromMap should parse correctly', () {
      final map = {
        'vaccinated': true,
        'neutered': false,
        'dewormed': true,
        'microchipped': false,
      };

      final health = PetHealth.fromMap(map);

      expect(health.vaccinated, true);
      expect(health.neutered, false);
      expect(health.dewormed, true);
      expect(health.microchipped, false);
    });
  });
}
