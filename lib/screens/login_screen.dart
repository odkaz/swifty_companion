import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  bool _loggedIn = false;

  Future<void> _authorizeWith42() async {
    final clientId = dotenv.env['API_UID']!;
    final clientSecret = dotenv.env['API_SECRET']!;
    final redirectUri = dotenv.env['REDIRECT_URI']!;

    final authUrl =
        'https://api.intra.42.fr/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=public';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'http',
      );

      final code = Uri.parse(result).queryParameters['code'];

      final res = await http.post(
        Uri.parse('https://api.intra.42.fr/oauth/token'),
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        AppState.token = json['access_token'];
        setState(() => _loggedIn = true);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Login successful!')));
      } else {
        print('❌ Token exchange failed: ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to retrieve token: ${res.statusCode}'),
          ),
        );
      }
    } catch (e) {
      print('❌ Auth error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Auth error: $e')));
    }
  }

  void _submit() {
    final login = _loginController.text.trim();
    if (login.isEmpty || AppState.token == null) return;

    Navigator.pushNamed(context, '/profile', arguments: {'login': login});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swifty Companion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: _loggedIn
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _loginController,
                      decoration: const InputDecoration(
                        labelText: 'Enter 42 login',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('View Profile'),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: _authorizeWith42,
                  child: const Text('🔐 Log in with 42'),
                ),
        ),
      ),
    );
  }
}
