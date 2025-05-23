import 'dart:convert';

import 'package:http/http.dart' as http;

class CallApi{
  final String _url = "http://127.0.0.1:8000/api/";

  postData(data, apiUrl) async{
    var fullUrl = _url + apiUrl;
    return await http.post(
      Uri.parse(fullUrl),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );
  }

  _setHeaders() => {    
      'Content-Type': 'application/json',
      'Accept': 'application/json',
  };
}

