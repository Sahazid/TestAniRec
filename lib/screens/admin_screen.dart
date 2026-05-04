import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AniRec Admin', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: const [
          _AdminTile(icon: Icons.cloud_sync_rounded, title: 'API Sync', subtitle: 'Connect Firebase/Supabase later to cache Jikan anime data.'),
          _AdminTile(icon: Icons.movie_creation_rounded, title: 'Manage Anime', subtitle: 'Future feature: add custom featured anime, banners and keywords.'),
          _AdminTile(icon: Icons.people_alt_rounded, title: 'Users', subtitle: 'Future feature: view user behavior and watchlists.'),
          _AdminTile(icon: Icons.analytics_rounded, title: 'Analytics', subtitle: 'Future feature: trending searches and recommendation performance.'),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _AdminTile({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        minVerticalPadding: 16,
        leading: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Theme.of(context).colorScheme.primary.withOpacity(.14)),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
