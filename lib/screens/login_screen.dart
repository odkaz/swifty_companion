import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _startOAuthFlow(BuildContext context) async {
    final clientId = dotenv.env['API_UID']!;
    final redirect = dotenv.env['REDIRECT_URI']!;
    final authUrl =
        'https://api.intra.42.fr/oauth/authorize'
        '?client_id=$clientId'
        '&redirect_uri=$redirect'
        '&response_type=code'
        '&scope=public';

    try {
      // Opens browser and waits for redirect
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: Uri.parse(redirect).scheme,
      );
      // e.g. result → com.swiftycompanion://callback?code=XYZ
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw 'No code returned';
      await _exchangeCodeForToken(code, context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  Future<void> _exchangeCodeForToken(String code, BuildContext ctx) async {
    final tokenJson = await AuthService.tokenFromCode(code);
    final accessToken = tokenJson['access_token'];
    // 👉 Store it (memory for now, later secure storage)
    Navigator.pushNamed(ctx, '/profile', arguments: accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Swifty Companion')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _startOAuthFlow(context),
          child: Text('Login with 42'),
        ),
      ),
    );
  }
}
