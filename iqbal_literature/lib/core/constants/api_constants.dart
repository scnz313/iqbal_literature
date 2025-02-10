class ApiConstants {
  static const String baseUrl = 'https://api.iqballiterature.com';
  
  // API Endpoints
  static const String booksEndpoint = '$baseUrl/books';
  static const String poemsEndpoint = '$baseUrl/poems';
  static const String versesEndpoint = '$baseUrl/verses';
  static const String userEndpoint = '$baseUrl/user';
  
  // API Keys and Headers
  static const String apiKey = 'your_api_key_here';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };
  
  // API Response Codes
  static const int successCode = 200;
  static const int errorCode = 400;
  static const int unauthorizedCode = 401;
  static const int notFoundCode = 404;
}
