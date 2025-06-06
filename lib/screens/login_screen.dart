import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _startOAuthFlow(BuildContext context) async {
    final clientId = dotenv.env['API_UID'];
    final redirectUri = dotenv.env['REDIRECT_URI'];

    final authUrl = Uri.parse(
      'https://api.intra.42.fr/oauth/authorize'
      '?client_id=$clientId'
      '&redirect_uri=$redirectUri'
      '&response_type=code'
      '&scope=public',
    );

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch login URL')),
      );
    }
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
