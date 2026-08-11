class Address {
  final String id;
  final String title;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.title,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.isDefault,
  });

  factory Address.fromMap(String id, Map<String, dynamic> map) => Address(
        id: id,
        title: map['title'] ?? '',
        street: map['street'] ?? '',
        city: map['city'] ?? '',
        state: map['state'] ?? '',
        zipCode: map['zipCode'] ?? '',
        isDefault: map['isDefault'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'isDefault': isDefault,
      };

  Address copyWith({
    String? id,
    String? title,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      title: title ?? this.title,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
