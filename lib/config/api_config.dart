class ApiConfig {
  // For a physical Android/iOS device, use your PC's local Wi-Fi IP address.
  // For Android emulator, use: http://10.0.2.2:5000/api
  // For iOS simulator, use: http://localhost:5000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.30.249.57:5000/api',
  );
}
