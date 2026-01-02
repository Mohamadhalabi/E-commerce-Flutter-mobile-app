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
  final String state;

  // ✅ ADD THIS FIELD
  final String? countryName;

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
    // ✅ ADD TO CONSTRUCTOR
    this.countryName,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      countryId: json['country_id'],
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      street: json['street'] ?? '',
      postalCode: json['postal_code'] ?? '',
      phone: json['phone'] ?? '',
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
      state: json['state'] ?? '',

      // ✅ PARSE IT HERE
      // The backend usually sends 'country_name' in the checkout quote addresses
      countryName: json['country_name'],
    );
  }
}