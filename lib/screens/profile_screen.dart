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
    print('📡 Calling _fetchUser...');
    try {
      final res = await http.get(
        Uri.parse('https://api.intra.42.fr/v2/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => user = data);
        print('✅ User fetched: ${user!['login']}');
      } else if (res.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Session expired. Please log in again.'),
          ),
        );
        Navigator.pop(context); // Go back to login
      } else {
        print('❌ HTTP ${res.statusCode}: ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${res.statusCode}: ${res.reasonPhrase}'),
          ),
        );
      }
    } catch (e) {
      print('❌ Network error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Network error: $e')));
    }
  }

  Widget _detailsRow(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Flexible(child: Text(value ?? '—')),
      ],
    ),
  );

  Widget _skillTile(Map skill) {
    final level = skill['level'] as double;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${skill['name']}  (${level.toStringAsFixed(2)})'),
        LinearProgressIndicator(
          value: (level / 21).clamp(0, 1),
        ), // 21 is max 42 level/2
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _projectRow(Map prj) {
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

    return Scaffold(
      appBar: AppBar(title: Text(user!['login'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(user!['image']['link']),
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
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const Text(
                  'Skills',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ...List<Map>.from(
                  user!['cursus_users'][0]['skills'],
                ).map(_skillTile),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Projects',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ...List<Map>.from(user!['projects_users']).map(_projectRow),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
