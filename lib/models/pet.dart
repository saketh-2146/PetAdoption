import 'package:cloud_firestore/cloud_firestore.dart';

class PetOwner {
  final String name;
  final String avatarId;
  final double rating;
  final int reviews;
  final String memberSince;
  final bool verified;

  const PetOwner({
    required this.name,
    required this.avatarId,
    required this.rating,
    required this.reviews,
    required this.memberSince,
    required this.verified,
  });

  factory PetOwner.fromMap(Map<String, dynamic> map) => PetOwner(
        name: map['name'] ?? '',
        avatarId: map['avatarId'] ?? '',
        rating: (map['rating'] ?? 0).toDouble(),
        reviews: (map['reviews'] ?? 0),
        memberSince: map['memberSince'] ?? '',
        verified: map['verified'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'avatarId': avatarId,
        'rating': rating,
        'reviews': reviews,
        'memberSince': memberSince,
        'verified': verified,
      };
}

class PetHealth {
  final bool vaccinated;
  final bool neutered;
  final bool dewormed;
  final bool microchipped;

  const PetHealth({
    required this.vaccinated,
    required this.neutered,
    required this.dewormed,
    required this.microchipped,
  });

  factory PetHealth.fromMap(Map<String, dynamic> map) => PetHealth(
        vaccinated: map['vaccinated'] ?? false,
        neutered: map['neutered'] ?? false,
        dewormed: map['dewormed'] ?? false,
        microchipped: map['microchipped'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'vaccinated': vaccinated,
        'neutered': neutered,
        'dewormed': dewormed,
        'microchipped': microchipped,
      };
}

/// Mirrors `Pet` from the Figma export's src/types.ts, stored 1:1 in the
/// Firestore `pets` collection.
class Pet {
  final String id;
  final String name;
  final String breed;
  final String species; // dog | cat | rabbit | bird | other
  final String age;
  final String gender; // male | female
  final double? price;
  final double? adoptionFee;
  final String type; // adopt | buy
  final String location;
  final String distance;
  final String imageId;
  final List<String> galleryIds;
  final List<String>? imageUrls;
  final String description;
  final PetOwner owner;
  final PetHealth health;
  final List<String> personality;
  final String color;
  final String weight;
  final String category;
  final String? listedByUid;
  final DateTime? createdAt;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectionReason;
  final String? contactEmail;
  final String? contactMobile;
  final String? pincode;
  final String? state;
  final String? district;
  final String? mandal;
  final String? village;
  final String? landmark;

  const Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.species,
    required this.age,
    required this.gender,
    this.price,
    this.adoptionFee,
    required this.type,
    required this.location,
    required this.distance,
    required this.imageId,
    required this.galleryIds,
    this.imageUrls,
    required this.description,
    required this.owner,
    required this.health,
    required this.personality,
    required this.color,
    required this.weight,
    required this.category,
    this.listedByUid,
    this.createdAt,
    this.status = 'Approved', // Default to Approved for older data
    this.approvedAt,
    this.approvedBy,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectionReason,
    this.contactEmail,
    this.contactMobile,
    this.pincode,
    this.state,
    this.district,
    this.mandal,
    this.village,
    this.landmark,
  });

  /// Unsplash photo id -> full image URL, same source used by the React app.
  String imageUrl({int w = 800, int q = 80}) {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      return imageUrls!.first;
    }
    return 'https://images.unsplash.com/photo-$imageId?w=$w&q=$q&auto=format&fit=crop';
  }

  String galleryUrl(String id, {int w = 800, int q = 80}) {
    if (id.startsWith('http')) return id;
    return 'https://images.unsplash.com/photo-$id?w=$w&q=$q&auto=format&fit=crop';
  }

  factory Pet.fromMap(String id, Map<String, dynamic> map) => Pet(
        id: id,
        name: map['name'] ?? '',
        breed: map['breed'] ?? '',
        species: map['species'] ?? 'other',
        age: map['age'] ?? '',
        gender: map['gender'] ?? 'male',
        price: (map['price'] as num?)?.toDouble(),
        adoptionFee: (map['adoptionFee'] as num?)?.toDouble(),
        type: map['type'] ?? 'adopt',
        location: map['location'] ?? '',
        distance: map['distance'] ?? '',
        imageId: map['imageId'] ?? '',
        galleryIds: List<String>.from(map['galleryIds'] ?? const []),
        imageUrls: map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
        description: map['description'] ?? '',
        owner: PetOwner.fromMap(Map<String, dynamic>.from(map['owner'] ?? const {})),
        health: PetHealth.fromMap(Map<String, dynamic>.from(map['health'] ?? const {})),
        personality: List<String>.from(map['personality'] ?? const []),
        color: map['color'] ?? '',
        weight: map['weight'] ?? '',
        category: map['category'] ?? '',
        listedByUid: map['listedByUid'],
        createdAt: (map['createdAt'] is Timestamp)
            ? (map['createdAt'] as Timestamp).toDate()
            : null,
        status: map['status'] ?? 'Approved', // Legacy listings get 'Approved'
        approvedAt: (map['approvedAt'] is Timestamp)
            ? (map['approvedAt'] as Timestamp).toDate()
            : null,
        approvedBy: map['approvedBy'],
        rejectedAt: (map['rejectedAt'] is Timestamp)
            ? (map['rejectedAt'] as Timestamp).toDate()
            : null,
        rejectedBy: map['rejectedBy'],
        rejectionReason: map['rejectionReason'],
        contactEmail: map['contactEmail'],
        contactMobile: map['contactMobile'],
        pincode: map['pincode'],
        state: map['state'],
        district: map['district'],
        mandal: map['mandal'],
        village: map['village'],
        landmark: map['landmark'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'breed': breed,
        'species': species,
        'age': age,
        'gender': gender,
        if (price != null) 'price': price,
        if (adoptionFee != null) 'adoptionFee': adoptionFee,
        'type': type,
        'location': location,
        'distance': distance,
        'imageId': imageId,
        'galleryIds': galleryIds,
        if (imageUrls != null) 'imageUrls': imageUrls,
        'description': description,
        'owner': owner.toMap(),
        'health': health.toMap(),
        'personality': personality,
        'color': color,
        'weight': weight,
        'category': category,
        if (listedByUid != null) 'listedByUid': listedByUid,
        'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'status': status,
        if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
        if (approvedBy != null) 'approvedBy': approvedBy,
        if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
        if (rejectedBy != null) 'rejectedBy': rejectedBy,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (contactMobile != null) 'contactMobile': contactMobile,
        if (pincode != null) 'pincode': pincode,
        if (state != null) 'state': state,
        if (district != null) 'district': district,
        if (mandal != null) 'mandal': mandal,
        if (village != null) 'village': village,
        if (landmark != null) 'landmark': landmark,
      };
}
