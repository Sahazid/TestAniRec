import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  int selectedEpisode = 0;
  VideoPlayerController? _video;
  bool _playerLoading = false;
  double _playbackSpeed = 1.0;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      episodes = await _api.animeEpisodes(widget.anime.id);
      if (episodes.isNotEmpty) {
        await _playEpisode(0);
      } else {
        _playerError = 'No episodes found for this anime.';
      }
    } catch (_) {
      _playerError = 'Failed to load episodes. Please try again.';
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _playEpisode(int index) async {
    if (index < 0 || index >= episodes.length) return;
    final ep = episodes[index];
    final streamUrl = ep.streamUrl;
    if (streamUrl == null || streamUrl.isEmpty) {
      setState(() => _playerError = 'No stream URL found for this episode.');
      return;
    }
    setState(() {
      selectedEpisode = index;
      _playerLoading = true;
      _playerError = null;
    });
    try {
      await _video?.dispose();
      final controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      _video = controller;
      await controller.initialize().timeout(const Duration(seconds: 20));
      await controller.setLooping(false);
      await controller.setPlaybackSpeed(_playbackSpeed);
      await controller.play();
    } on TimeoutException {
      _playerError = 'Video loading timed out. Check connection and retry.';
    } catch (_) {
      _playerError = 'Unable to play this episode right now.';
    } finally {
      if (!mounted) return;
      setState(() => _playerLoading = false);
    }
  }

  Future<void> _setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _video?.setPlaybackSpeed(speed);
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = episodes.isNotEmpty ? episodes[selectedEpisode] : null;
    return Scaffold(
      appBar: AppBar(title: Text('Watch • ${widget.anime.title}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AspectRatio(
                  aspectRatio: _video?.value.isInitialized == true
                      ? _video!.value.aspectRatio
                      : 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: Colors.black,
                      child: _playerLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (_video == null || !_video!.value.isInitialized)
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      _playerError ?? 'Player is not ready.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                )
                              : VideoPlayer(_video!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (current != null)
                  Text(
                    'Now playing: Episode ${current.number} • ${current.title}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: selectedEpisode > 0 ? () => _playEpisode(selectedEpisode - 1) : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _video == null
                          ? null
                          : () async {
                              if (_video!.value.isPlaying) {
                                await _video!.pause();
                              } else {
                                await _video!.play();
                              }
                              if (!mounted) return;
                              setState(() {});
                            },
                      icon: Icon(_video?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: selectedEpisode < episodes.length - 1 ? () => _playEpisode(selectedEpisode + 1) : null,
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                    const Spacer(),
                    PopupMenuButton<double>(
                      tooltip: 'Playback speed',
                      onSelected: _setSpeed,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 0.5, child: Text('0.5x')),
                        PopupMenuItem(value: 1.0, child: Text('1x')),
                        PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        PopupMenuItem(value: 2.0, child: Text('2x')),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.settings_rounded, size: 18),
                            const SizedBox(width: 4),
                            Text('${_playbackSpeed}x'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Episodes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...episodes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ep = entry.value;
                  final active = i == selectedEpisode;
                  return Card(
                    child: ListTile(
                      selected: active,
                      title: Text('Episode ${ep.number}'),
                      subtitle: Text(ep.title),
                      trailing: Icon(active ? Icons.graphic_eq_rounded : Icons.play_circle_fill_rounded),
                      onTap: () => _playEpisode(i),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
