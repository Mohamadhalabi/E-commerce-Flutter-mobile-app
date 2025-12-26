class CountryModel {
  final int id;
  final String name;
  final String code; // iso2

  CountryModel({required this.id, required this.name, required this.code});

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}