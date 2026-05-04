import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime.dart';
import '../services/anime_api_service.dart';

class AppState extends ChangeNotifier {
  final AnimeApiService api;
  AppState(this.api);

  bool isDark = true;
  bool loading = false;
  String? error;
  int heroIndex = 0;
  Timer? _heroTimer;
  List<Anime> top = [];
  List<Anime> seasonal = [];
  List<Anime> searchResults = [];
  List<Anime> recommendations = [];
  final Set<int> watchlistIds = {};
  final List<String> behaviorKeywords = [];

  final List<String> smartKeywords = const [
    'Overpowered MC', 'Isekai', 'Reincarnation', 'Time Travel', 'School Life',
    'Shounen', 'Sad', 'Romance', 'Magic', 'Supernatural', 'Revenge', 'Comedy',
    'Dark Fantasy', 'Sports', 'Slice of Life', 'Psychological'
  ];

  Future<void> init() async {
    await _loadPrefs();
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      top = await api.topAnime(limit: 10);
      seasonal = await api.seasonalAnime(limit: 12);
      await makeRecommendations();
      _startHeroTimer();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    _rememberKeyword(query);
    loading = true;
    notifyListeners();
    try {
      searchResults = await api.searchAnime(query.trim());
      await makeRecommendations();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> makeRecommendations() async {
    final seed = behaviorKeywords.isNotEmpty ? behaviorKeywords.last : 'action adventure';
    try {
      recommendations = await api.recommendationByKeyword(seed);
    } catch (_) {
      recommendations = seasonal.take(8).toList();
    }
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (top.isEmpty) return;
      heroIndex = (heroIndex + 1) % top.length;
      notifyListeners();
    });
  }

  void toggleTheme() {
    isDark = !isDark;
    _savePrefs();
    notifyListeners();
  }

  bool isInWatchlist(int id) => watchlistIds.contains(id);

  void toggleWatchlist(Anime anime) {
    if (watchlistIds.contains(anime.id)) {
      watchlistIds.remove(anime.id);
    } else {
      watchlistIds.add(anime.id);
      _rememberKeyword([...anime.genres, ...anime.themes].take(2).join(' '));
    }
    _savePrefs();
    makeRecommendations();
    notifyListeners();
  }

  void _rememberKeyword(String keyword) {
    final clean = keyword.trim();
    if (clean.isEmpty) return;
    behaviorKeywords.remove(clean);
    behaviorKeywords.add(clean);
    if (behaviorKeywords.length > 8) behaviorKeywords.removeAt(0);
    _savePrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool('isDark') ?? true;
    watchlistIds.addAll((prefs.getStringList('watchlist') ?? []).map(int.parse));
    behaviorKeywords.addAll(prefs.getStringList('behaviorKeywords') ?? []);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    await prefs.setStringList('watchlist', watchlistIds.map((e) => e.toString()).toList());
    await prefs.setStringList('behaviorKeywords', behaviorKeywords);
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    super.dispose();
  }
}
