import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect/models/address.dart';

void main() {
  group('Address Model Tests', () {
    test('Address.fromMap should parse correctly', () {
      final map = {
        'title': 'Home',
        'street': '123 Pet Street',
        'city': 'Dogville',
        'state': 'CA',
        'zipCode': '90210',
        'isDefault': true,
      };

      final address = Address.fromMap('addr_1', map);

      expect(address.id, 'addr_1');
      expect(address.title, 'Home');
      expect(address.street, '123 Pet Street');
      expect(address.city, 'Dogville');
      expect(address.state, 'CA');
      expect(address.zipCode, '90210');
      expect(address.isDefault, true);
    });

    test('Address.toMap should serialize correctly', () {
      const address = Address(
        id: 'addr_1',
        title: 'Home',
        street: '123 Pet Street',
        city: 'Dogville',
        state: 'CA',
        zipCode: '90210',
        isDefault: true,
      );

      final map = address.toMap();

      expect(map['title'], 'Home');
      expect(map['street'], '123 Pet Street');
      expect(map['city'], 'Dogville');
      expect(map['state'], 'CA');
      expect(map['zipCode'], '90210');
      expect(map['isDefault'], true);
      // Ensure 'id' is not in the map
      expect(map.containsKey('id'), isFalse);
    });

    test('Address.copyWith should update fields correctly', () {
      const address = Address(
        id: 'addr_1',
        title: 'Home',
        street: '123 Pet Street',
        city: 'Dogville',
        state: 'CA',
        zipCode: '90210',
        isDefault: true,
      );

      final updatedAddress = address.copyWith(title: 'Work', isDefault: false);

      expect(updatedAddress.id, 'addr_1'); // unchanged
      expect(updatedAddress.title, 'Work'); // changed
      expect(updatedAddress.street, '123 Pet Street'); // unchanged
      expect(updatedAddress.isDefault, false); // changed
    });
  });
}
