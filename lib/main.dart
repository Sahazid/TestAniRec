import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/profile_screen.dart';
import 'services/anime_api_service.dart';
import 'services/local_database_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(AnimeApiService(), LocalDatabaseService())..init(),
      child: const AniRecApp(),
    ),
  );
}

class AniRecApp extends StatelessWidget {
  const AniRecApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final textTheme = GoogleFonts.poppinsTextTheme();

    const seed = Color(0xFF8B5CF6);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AniRec',
      themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F7FF),
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        textTheme: textTheme,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: seed.withOpacity(.14),
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050713),
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        textTheme: textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF111527),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0A0D1A),
          indicatorColor: seed.withOpacity(.24),
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  final pages = const [HomeScreen(), SearchScreen(), WatchlistScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: pages[index],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 68,
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Explore'),
              NavigationDestination(icon: Icon(Icons.bookmark_border_rounded), selectedIcon: Icon(Icons.bookmark_rounded), label: 'Saved'),
              NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
