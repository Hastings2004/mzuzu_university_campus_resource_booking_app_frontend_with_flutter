import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

class CallApi {
 
  // Make sure your backend has CORS configured to allow requests from localhost:61112
  final String _url = "http://localhost:8000/api/";
  String? _token; // To store the authentication token

  // Private method to get the token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    _token = localStorage.getString('token');
    return _token;
  }

  // Method for search requests
  searchData(apiUrl, data) async {
    var fullUrl = _url + apiUrl;
    return await http.post(
      Uri.parse(fullUrl),
      body: jsonEncode(data),
      headers: await _setHeaders(), // Await headers as they now fetch token
    );
  }

  // Method for POST requests
  postData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;
    return await http.post(
      Uri.parse(fullUrl),
      body: jsonEncode(data),
      headers: await _setHeaders(), // Await headers as they now fetch token
    );
  }

  // Method for POST requests with file upload
  postDataWithFile(data, apiUrl, filePath, fileFieldName) async {
    var fullUrl = _url + apiUrl;

    // Create multipart request
    var request = http.MultipartRequest('POST', Uri.parse(fullUrl));

    // Add authorization header
    await _getToken();
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // Add text fields
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Add file
    if (filePath != null) {
      var file = await http.MultipartFile.fromPath(fileFieldName, filePath);
      request.files.add(file);
    }

    return await request.send();
  }

  // Method for patch requests
  patchData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;
    return await http.patch(
      Uri.parse(fullUrl),
      body: jsonEncode(data),
      headers: await _setHeaders(), // Await headers as they now fetch token
    );
  }

  // Method for PUT requests
  putData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;
    return await http.put(
      Uri.parse(fullUrl),
      body: jsonEncode(data),
      headers: await _setHeaders(), // Await headers as they now fetch token
    );
  }

  // Method for GET requests
  getData(apiUrl) async {
    var fullUrl = _url + apiUrl;
    return await http.get(
      Uri.parse(fullUrl),
      headers: await _setHeaders(), // Await headers as they now fetch token
    );
  }

  // Helper method to set common headers, now including Authorization
  _setHeaders() async {
    await _getToken(); // Ensure token is fetched before setting headers
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] =
          'Bearer $_token'; // Add Authorization header if token exists
    }
    return headers;
  }
}
