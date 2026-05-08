import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/anime.dart';
import '../models/anime_episode.dart';
import '../services/anime_api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    episodes = await _api.animeEpisodes(widget.anime.id);
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _openEpisode(AnimeEpisode ep) async {
    final uri = Uri.tryParse(ep.forumUrl ?? widget.anime.malUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              itemCount: episodes.length,
              itemBuilder: (_, i) {
                final ep = episodes[i];
                return Card(
                  child: ListTile(
                    title: Text('Episode ${ep.number}'),
                    subtitle: Text(ep.title),
                    trailing: const Icon(Icons.play_circle_fill_rounded),
                    onTap: () => _openEpisode(ep),
                  ),
                );
              },
            ),
    );
  }
}
