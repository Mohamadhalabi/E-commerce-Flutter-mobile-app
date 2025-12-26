class AddressModel {
  final int id;
  final int userId;
  final int? countryId;
  final String city;
  final String address;
  final String street;
  final String postalCode;
  final String phone;
  final bool isDefault;
  final String state; // Kept as fallback

  AddressModel({
    required this.id,
    required this.userId,
    this.countryId,
    required this.city,
    required this.address,
    required this.street,
    required this.postalCode,
    required this.phone,
    required this.isDefault,
    this.state = '',
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      countryId: json['country_id'],
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      // Fix: Backend might return null for street, ensure empty string fallback
      street: json['street'] ?? '',
      postalCode: json['postal_code'] ?? '',
      phone: json['phone'] ?? '',
      // Handle boolean or 0/1 integer
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
      // Handle missing state safely
      state: json['state'] ?? '',
    );
  }
}