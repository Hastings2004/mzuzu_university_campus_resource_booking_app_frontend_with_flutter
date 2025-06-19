import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

class CallApi {
  final String _url = "http://127.0.0.1:8000/api/";
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
      headers['Authorization'] = 'Bearer $_token'; // Add Authorization header if token exists
    }
    return headers;
  }
}