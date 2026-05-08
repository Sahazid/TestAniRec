import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/anime.dart';
import '../providers/app_state.dart';
import '../widgets/anime_card.dart';
import 'all_anime_screen.dart';
import 'auth_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return RefreshIndicator(
      onRefresh: state.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _TopHeader(state: state)),
          if (state.loading && state.top.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else ...[
            if (state.error != null && state.top.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _OfflineNotice(message: 'Offline mode active. Showing cached/sample anime.'),
                ),
              ),
            _Section(title: 'Trending Now', subtitle: 'Top anime updated from Jikan API', items: state.top),
            _Section(title: 'AI Picks For You', subtitle: 'Learns from your searches and watchlist', items: state.recommendations),
            _Section(title: 'This Season', subtitle: 'Fresh seasonal anime to explore', items: state.seasonal),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final AppState state;
  const _TopHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 12, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF050713), Color(0xFF101532), Color(0xFF230B47)]
              : const [Color(0xFFFFFFFF), Color(0xFFF3EEFF), Color(0xFFE9D5FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withOpacity(.32),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AniRec', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                    Text('Find your next anime obsession', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: state.toggleTheme,
                icon: Icon(state.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _HeroBanner(),
          const SizedBox(height: 16),
          _SmartSearchPreview(),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  Future<void> _handleWatchlistTap(BuildContext context, AppState state, Anime anime) async {
    var result = await state.toggleWatchlist(anime);
    if (result == WatchlistActionResult.needsLogin) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (loggedIn == true) {
        result = await state.toggleWatchlist(anime);
      }
    }
    if (!context.mounted) return;
    if (result == WatchlistActionResult.added) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to watchlist.')));
    } else if (result == WatchlistActionResult.removed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from watchlist.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.top.isEmpty) {
      return Container(
        height: 370,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(34), color: Theme.of(context).colorScheme.surfaceContainerHighest),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final anime = state.top[state.heroIndex];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(anime: anime))),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween<double>(begin: .98, end: 1).animate(animation), child: child),
        ),
        child: Container(
          key: ValueKey(anime.id),
          height: 390,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(.30), blurRadius: 34, offset: const Offset(0, 18))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: anime.largeImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(color: Color(0xFF12162C), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF12162C), child: Icon(Icons.image_not_supported_outlined)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(.12), Colors.black.withOpacity(.28), Colors.black.withOpacity(.92)],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.45),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(.16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7A18), size: 18),
                        const SizedBox(width: 6),
                        Text('Top ${state.heroIndex + 1}/10 • changes every 5s', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  bottom: 72,
                  child: Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8B5CF6).withOpacity(.18)),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _MiniPill(icon: Icons.star_rounded, text: anime.score.toStringAsFixed(1), color: const Color(0xFFFFC857)),
                          const SizedBox(width: 8),
                          _MiniPill(icon: Icons.calendar_month_rounded, text: anime.year?.toString() ?? 'Anime', color: const Color(0xFF38BDF8)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(anime.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.02)),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: anime.genres.take(4).map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.12))),
                          child: Text(g, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(anime.synopsis, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, height: 1.4)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(anime: anime))),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('View Details'),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () => _handleWatchlistTap(context, state, anime),
                            icon: Icon(state.isInWatchlist(anime.id) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MiniPill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(.42), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.16))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))]),
    );
  }
}

class _SmartSearchPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final words = state.smartKeywords.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(Theme.of(context).brightness == Brightness.dark ? .42 : .88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.16)),
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withOpacity(.16)),
            child: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: words.map((w) => Text('#${w.replaceAll(' ', '')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Anime> items;
  const _Section({required this.title, required this.subtitle, required this.items});

  Future<void> _openViewAll(BuildContext context, AppState state) async {
    await state.setViewAllItems(items);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AllAnimeScreen(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 0, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.3)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  ])),
                  InkWell(
                    onTap: () => _openViewAll(context, context.read<AppState>()),
                    child: Text('View all', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 244,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => AnimeCard(anime: items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  final String message;
  const _OfflineNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [const Icon(Icons.wifi_off_rounded, color: Colors.orange), const SizedBox(width: 8), Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)))]),
    );
  }
}
