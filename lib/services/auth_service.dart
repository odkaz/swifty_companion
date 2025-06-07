import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static final _client = http.Client();

  static Future<Map<String, dynamic>> tokenFromCode(String code) async {
    final res = await _client.post(
      Uri.parse('https://api.intra.42.fr/oauth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': dotenv.env['API_UID'],
        'client_secret': dotenv.env['API_SECRET'],
        'code': code,
        'redirect_uri': dotenv.env['REDIRECT_URI'],
      },
    );
    if (res.statusCode != 200) {
      throw 'Token error ${res.statusCode}: ${res.body}';
    }
    return jsonDecode(
      res.body,
    ); // contains access_token, expires_in, refresh_token…
  }
}
