import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final String token;
  Map<String, dynamic>? user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    token = ModalRoute.of(context)!.settings.arguments as String;
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final res = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() => user = jsonDecode(res.body));
    } else {
      // Handle errors (network, 401, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${res.statusCode}: ${res.reasonPhrase}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(user!['login'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(user!['image']['link']),
            ),
            const SizedBox(height: 16),
            Text(user!['email']),
            // TODO: add skills, projects, wallet, level, etc.
          ],
        ),
      ),
    );
  }
}
