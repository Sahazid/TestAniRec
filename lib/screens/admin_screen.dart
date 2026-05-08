import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('AniRec Admin', style: TextStyle(fontWeight: FontWeight.w900))),
        body: const Center(child: Text('Only admin can access this page.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AniRec Admin', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        children: [
          _AdminTile(icon: Icons.people_alt_rounded, title: 'Total Users', subtitle: state.adminOverview['users'].toString()),
          _AdminTile(icon: Icons.search_rounded, title: 'Total Searches', subtitle: state.adminOverview['searches'].toString()),
          _AdminTile(icon: Icons.bookmark_rounded, title: 'Watchlist Items', subtitle: state.adminOverview['watchlistItems'].toString()),
          const SizedBox(height: 12),
          const Text('Latest Registered Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...state.adminUsers.map((u) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(u.email),
                  subtitle: Text('Role: ${u.role}'),
                ),
              )),
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
