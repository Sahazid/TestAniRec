import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/anime.dart';
import '../services/anime_api_service.dart';
import '../services/local_database_service.dart';

enum WatchlistActionResult { added, removed, needsLogin }

class AppState extends ChangeNotifier {
  final AnimeApiService api;
  final LocalDatabaseService db;
  AppState(this.api, this.db);

  bool isDark = true;
  bool loading = false;
  String? error;
  int heroIndex = 0;
  Timer? _heroTimer;
  List<Anime> top = [];
  List<Anime> seasonal = [];
  List<Anime> searchResults = [];
  List<Anime> recommendations = [];
  List<Anime> viewAllItems = [];
  final Set<int> watchlistIds = {};
  final List<String> behaviorKeywords = [];
  AppUser? currentUser;
  bool authBusy = false;
  String? authError;
  String? lastSearchQuery;
  int lastSearchCount = 0;
  DateTime? lastSearchTime;
  String selectedSeason = 'spring';
  int selectedYear = DateTime.now().year;
  List<Anime> seasonalCatalog = [];
  List<AppUser> adminUsers = [];
  Map<String, int> adminOverview = {'users': 0, 'searches': 0, 'watchlistItems': 0};

  final List<String> smartKeywords = const [
    'Overpowered MC', 'Isekai', 'Reincarnation', 'Time Travel', 'School Life',
    'Shounen', 'Sad', 'Romance', 'Magic', 'Supernatural', 'Revenge', 'Comedy',
    'Dark Fantasy', 'Sports', 'Slice of Life', 'Psychological'
  ];

  Future<void> init() async {
    await _loadPrefs();
    currentUser = await db.getActiveUser();
    await _syncUserWatchlist();
    await refresh();
    await loadSeasonalCatalog();
    await loadAdminOverview();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      top = await api.topAnime(limit: 10);
      seasonal = await api.seasonalAnime(limit: 12);
      viewAllItems = top;
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
    final clean = query.trim();
    if (clean.isEmpty) return;
    _rememberKeyword(clean);
    loading = true;
    lastSearchQuery = clean;
    notifyListeners();
    try {
      searchResults = await api.searchAnime(clean);
      lastSearchCount = searchResults.length;
      lastSearchTime = DateTime.now();
      await db.logSearch(userId: currentUser?.id, query: clean);
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

  Future<WatchlistActionResult> toggleWatchlist(Anime anime) async {
    if (currentUser == null) return WatchlistActionResult.needsLogin;
    final existed = watchlistIds.contains(anime.id);
    await db.toggleWatchlist(userId: currentUser!.id, animeId: anime.id);
    if (watchlistIds.contains(anime.id)) {
      watchlistIds.remove(anime.id);
    } else {
      watchlistIds.add(anime.id);
      _rememberKeyword([...anime.genres, ...anime.themes].take(2).join(' '));
    }
    await _savePrefs();
    await makeRecommendations();
    notifyListeners();
    return existed ? WatchlistActionResult.removed : WatchlistActionResult.added;
  }

  Future<void> _syncUserWatchlist() async {
    watchlistIds.clear();
    if (currentUser == null) return;
    final ids = await db.getUserWatchlistIds(currentUser!.id);
    watchlistIds.addAll(ids);
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
    behaviorKeywords.addAll(prefs.getStringList('behaviorKeywords') ?? []);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    await prefs.setStringList('behaviorKeywords', behaviorKeywords);
  }

  Future<bool> signup({required String email, required String password}) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      currentUser = await db.registerUser(email: email, password: password);
      await _syncUserWatchlist();
      await loadAdminOverview();
      return true;
    } catch (_) {
      authError = 'Account already exists or invalid information.';
      return false;
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      final user = await db.login(email: email, password: password);
      if (user == null) {
        authError = 'Invalid email or password.';
        return false;
      }
      currentUser = user;
      await _syncUserWatchlist();
      await loadAdminOverview();
      return true;
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email, String newPassword) async {
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await db.updatePasswordByEmail(email: email, newPassword: newPassword);
      return true;
    } catch (_) {
      authError = 'Unable to reset password.';
      return false;
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await db.logout();
    currentUser = null;
    watchlistIds.clear();
    notifyListeners();
  }

  Future<void> setViewAllItems(List<Anime> items) async {
    viewAllItems = items;
    notifyListeners();
  }

  Future<void> loadSeasonalCatalog() async {
    loading = true;
    notifyListeners();
    try {
      seasonalCatalog = await api.seasonalBy(selectedSeason, selectedYear, limit: 24);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSeasonSelection({required String season, required int year}) async {
    selectedSeason = season;
    selectedYear = year;
    await loadSeasonalCatalog();
  }

  Future<void> loadAdminOverview() async {
    adminOverview = await db.adminStats();
    adminUsers = await db.latestUsers(limit: 10);
    notifyListeners();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    super.dispose();
  }
}
