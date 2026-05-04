import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/anime.dart';
import '../providers/app_state.dart';

class DetailScreen extends StatelessWidget {
  final Anime anime;
  const DetailScreen({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final inList = state.isInWatchlist(anime.id);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 480,
            pinned: true,
            stretch: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filledTonal(
                  onPressed: () => state.toggleWatchlist(anime),
                  icon: Icon(inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: anime.largeImageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(.1), Colors.black.withOpacity(.30), Colors.black.withOpacity(.95)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _GlassInfo(icon: Icons.star_rounded, value: anime.score.toStringAsFixed(1), color: const Color(0xFFFFC857)),
                            const SizedBox(width: 8),
                            _GlassInfo(icon: Icons.leaderboard_rounded, value: anime.rank == null ? 'Top' : '#${anime.rank}', color: const Color(0xFF8B5CF6)),
                            const SizedBox(width: 8),
                            _GlassInfo(icon: Icons.calendar_month_rounded, value: anime.year?.toString() ?? 'Anime', color: const Color(0xFF38BDF8)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(anime.title, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, height: 1.05)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: anime.genres.map((g) => Chip(label: Text(g), side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(.16)))).toList(),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: _MetricCard(title: 'Score', value: anime.score.toStringAsFixed(1), icon: Icons.star_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _MetricCard(title: 'Rank', value: anime.rank == null ? '-' : '#${anime.rank}', icon: Icons.workspace_premium_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _MetricCard(title: 'Year', value: anime.year?.toString() ?? '-', icon: Icons.calendar_today_rounded)),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text('Storyline', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 9),
                  Text(anime.synopsis, style: TextStyle(height: 1.65, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => state.toggleWatchlist(anime),
                      icon: Icon(inList ? Icons.check_rounded : Icons.add_rounded),
                      label: Text(inList ? 'Saved in Watchlist' : 'Add to Watchlist'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _open(anime.trailerUrl ?? anime.malUrl),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open Source / Trailer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _GlassInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _GlassInfo({required this.icon, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.black.withOpacity(.44), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.16))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 16), const SizedBox(width: 5), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _MetricCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(.18), Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.72)]),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.12)),
      ),
      child: Column(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))]),
    );
  }
}
