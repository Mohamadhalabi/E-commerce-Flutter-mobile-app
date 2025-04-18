import 'package:shop/services/api_client.dart';

late ApiClient apiClient;

Future<void> initApiClient() async {
  apiClient = await ApiClient.fromEnv();

  // Optional: set language and currency here, or update later from user preferences
  apiClient.setLocale(language: 'en', currency: 'USD');
}