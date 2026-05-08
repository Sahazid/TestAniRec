import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _animeTitle = TextEditingController();
  final _animeImage = TextEditingController();
  final _animeGenres = TextEditingController();
  final _animeSynopsis = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _animeTitle.dispose();
    _animeImage.dispose();
    _animeGenres.dispose();
    _animeSynopsis.dispose();
    super.dispose();
  }

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
          _AdminTile(icon: Icons.traffic_rounded, title: 'Traffic Events', subtitle: state.adminOverview['searches'].toString()),
          const SizedBox(height: 12),
          const Text('Top Demand Keywords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.topSearchKeywords
                .map((k) => Chip(label: Text('${k['query']} (${k['c']})')))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text('Add User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Username')),
          const SizedBox(height: 8),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await state.adminAddUser(username: _name.text, email: _email.text, password: _password.text);
              _name.clear();
              _email.clear();
              _password.clear();
            },
            child: const Text('Create User'),
          ),
          const SizedBox(height: 16),
          const Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...state.adminUsersRaw.map((u) {
            final id = u['id'] as int;
            final blocked = ((u['is_blocked'] ?? 0) as int) == 1;
            final hash = (u['password_hash'] ?? '').toString();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text('${u['username']} (${u['email']})'),
                subtitle: Text('Role: ${u['role']} • Password hash: ${hash.substring(0, hash.length > 12 ? 12 : hash.length)}...'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      onPressed: () => state.adminBlockUser(id, !blocked),
                      icon: Icon(blocked ? Icons.lock_open_rounded : Icons.block_rounded),
                    ),
                    if ((u['role'] ?? 'user') != 'admin')
                      IconButton(
                        onPressed: () => state.adminDeleteUser(id),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Add Anime', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(controller: _animeTitle, decoration: const InputDecoration(labelText: 'Anime title')),
          const SizedBox(height: 8),
          TextField(controller: _animeImage, decoration: const InputDecoration(labelText: 'Image URL')),
          const SizedBox(height: 8),
          TextField(controller: _animeGenres, decoration: const InputDecoration(labelText: 'Genres (comma separated)')),
          const SizedBox(height: 8),
          TextField(controller: _animeSynopsis, maxLines: 3, decoration: const InputDecoration(labelText: 'Synopsis')),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await state.adminAddAnime(
                title: _animeTitle.text,
                imageUrl: _animeImage.text,
                synopsis: _animeSynopsis.text,
                genres: _animeGenres.text,
              );
              _animeTitle.clear();
              _animeImage.clear();
              _animeGenres.clear();
              _animeSynopsis.clear();
            },
            child: const Text('Add Anime'),
          ),
          const SizedBox(height: 16),
          const Text('Custom Anime List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...state.customAnimeRaw.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(a['title'].toString()),
                  subtitle: Text(a['genres'].toString()),
                  trailing: IconButton(
                    onPressed: () => state.adminRemoveAnime(a['id'] as int),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
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
