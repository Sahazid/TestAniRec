import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/anime_card.dart';

class AllAnimeScreen extends StatelessWidget {
  final String title;
  const AllAnimeScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.viewAllItems;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: .58,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
          ),
          itemBuilder: (_, i) => AnimeCard(anime: items[i], width: double.infinity),
        ),
      ),
    );
  }
}
