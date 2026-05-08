import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/anime_card.dart';
import 'auth_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 72),
                const SizedBox(height: 16),
                const Text('Login to access your watchlist', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                  child: const Text('Login / Signup'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final items = [...state.top, ...state.seasonal, ...state.recommendations].where((a) => state.watchlistIds.contains(a.id)).toSet().toList();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 16, 18, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Watchlist', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                const SizedBox(height: 6),
                Text('${items.length} saved anime', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_add_outlined, size: 74, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 18),
                    const Text('No anime saved yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('Open an anime details page and save it to build your personal list.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              sliver: SliverGrid.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .58, crossAxisSpacing: 14, mainAxisSpacing: 18),
                itemBuilder: (_, i) => AnimeCard(anime: items[i], width: double.infinity),
              ),
            ),
        ],
      ),
    );
  }
}
