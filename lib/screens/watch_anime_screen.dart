import 'package:flutter/material.dart';
import '../models/anime.dart';
import '../models/anime_episode.dart';
import '../services/anime_api_service.dart';
import 'episode_player_screen.dart';

class WatchAnimeScreen extends StatefulWidget {
  final Anime anime;
  const WatchAnimeScreen({super.key, required this.anime});

  @override
  State<WatchAnimeScreen> createState() => _WatchAnimeScreenState();
}

class _WatchAnimeScreenState extends State<WatchAnimeScreen> {
  final AnimeApiService _api = AnimeApiService();
  List<AnimeEpisode> episodes = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      episodes = await _api.animeEpisodes(widget.anime.id);
      if (episodes.isEmpty) error = 'No episodes found for this anime.';
    } catch (_) {
      error = 'Failed to load episodes. Please try again.';
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Watch • ${widget.anime.title}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: episodes.isEmpty ? 1 : episodes.length,
              itemBuilder: (context, i) {
                if (episodes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(child: Text(error ?? 'No episodes available.')),
                  );
                }
                final ep = episodes[i];
                return Card(
                  child: ListTile(
                    title: Text('Episode ${ep.number}'),
                    subtitle: Text(ep.title),
                    trailing: const Icon(Icons.play_circle_fill_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EpisodePlayerScreen(
                            anime: widget.anime,
                            episodes: episodes,
                            initialIndex: i,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
