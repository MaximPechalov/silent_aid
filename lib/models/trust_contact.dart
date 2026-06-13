class TrustContact {
  final String id;
  final String name;
  final String phoneNumber;
  final bool isActive;
  
  TrustContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.isActive = true,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'isActive': isActive,
  };
  
  factory TrustContact.fromJson(Map<String, dynamic> json) => TrustContact(
    id: json['id'],
    name: json['name'],
    phoneNumber: json['phoneNumber'],
    isActive: json['isActive'] ?? true,
  );
}