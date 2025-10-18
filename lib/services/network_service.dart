import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkService {
  late final String baseUrl;

  NetworkService() {
    if (kIsWeb) {
      baseUrl = 'http://localhost:3001/api';
    } else if (Platform.isAndroid) {
      // On Android Emulator, "10.0.2.2" is your computer's localhost
      baseUrl = 'http://10.0.2.2:3001/api';
    } else {
      baseUrl = 'http://localhost:3001/api';
    }
  }

  Future<List<dynamic>> fetchData() async {
    final response = await http.get(Uri.parse('$baseUrl/data'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> postData(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/data'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to post data');
    }
  }
}
