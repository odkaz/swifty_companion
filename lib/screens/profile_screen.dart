import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../state/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final String login;
  Map<String, dynamic>? user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    login = args['login'];
    _fetchUser();
  }

  Future<void> _ensureToken() async {
    if (AppState.token != null) return;

    const clientId = 'YOUR_CLIENT_ID';
    const clientSecret = 'YOUR_CLIENT_SECRET';

    final res = await http.post(
      Uri.parse('https://api.intra.42.fr/oauth/token'),
      body: {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (res.statusCode == 200) {
      AppState.token = jsonDecode(res.body)['access_token'];
    }
  }

  Future<void> _fetchUser({bool retrying = false}) async {
    try {
      final res = await http.get(
        Uri.parse('https://api.intra.42.fr/v2/users/$login'),
        headers: {'Authorization': 'Bearer ${AppState.token}'},
      );

      if (res.statusCode == 200) {
        setState(() => user = jsonDecode(res.body));
      } else if (res.statusCode == 401 && !retrying) {
        // Token expired: clear and retry
        print("token${AppState.token}");
        AppState.token = null;
        await _ensureToken(); // reuse the same logic from login
        _fetchUser(retrying: true); // retry only once
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${res.statusCode}: ${res.reasonPhrase}'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  Widget _detailsRow(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value ?? '—')),
      ],
    ),
  );

  Widget _skillTile(Map skill) {
    final level = skill['level'] as double;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${skill['name']} (${level.toStringAsFixed(2)})'),
        LinearProgressIndicator(value: (level / 21).clamp(0, 1)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _projectRow(Map prj) {
    if (prj['project'] == null) return const SizedBox.shrink();
    final bool? ok = prj['validated?'];
    final icon = ok == null
        ? Icons.help_outline
        : ok
        ? Icons.check_circle
        : Icons.cancel;
    final color = ok == null
        ? Colors.grey
        : ok
        ? Colors.green
        : Colors.red;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(prj['project']['name']),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final skills = user!['cursus_users']?[0]?['skills'] ?? [];
    final projects = user!['projects_users'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(user!['login']),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(user!['image']?['link'] ?? ''),
            ),
            const SizedBox(height: 16),
            _detailsRow('Email', user!['email']),
            _detailsRow('Mobile', user!['phone']),
            _detailsRow('Location', user!['location']),
            _detailsRow('Wallet', user!['wallet']?.toString()),
            _detailsRow(
              'Level',
              user!['cursus_users']?[0]?['level']?.toStringAsFixed(2),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Skills',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ...List<Map>.from(skills).map(_skillTile),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Projects',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ...List<Map>.from(
              projects,
            ).where((p) => p['project'] != null).map(_projectRow),
          ],
        ),
      ),
    );
  }
}
