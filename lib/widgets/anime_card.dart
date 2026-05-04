import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/anime.dart';
import '../screens/detail_screen.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final double width;
  final bool compact;
  const AnimeCard({super.key, required this.anime, this.width = 148, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(anime: anime))),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0xFF7C3AED)).withOpacity(.28),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: anime.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF151A2E), Color(0xFF3B1D74)]),
                          ),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF151A2E),
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(.78)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 9,
                        top: 9,
                        child: _GlassBadge(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFC857), size: 14),
                              const SizedBox(width: 3),
                              Text(anime.score.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Text(
                          anime.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 10),
              Text(
                anime.genres.take(2).join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final Widget child;
  const _GlassBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.18)),
      ),
      child: child,
    );
  }
}
