import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/anime_card.dart';

class BehaviorScreen extends StatelessWidget {
  const BehaviorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final signals = state.userBehaviorGenres();
    return Scaffold(
      appBar: AppBar(title: const Text('AI Behavior Learning')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const Text('Your Behavior Signals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (signals.isEmpty)
            const Text('Search and save anime to train AI behavior for your account.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: signals.map((s) => Chip(label: Text(s))).toList(),
            ),
          const SizedBox(height: 20),
          const Text('Recommended For You', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          SizedBox(
            height: 244,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => AnimeCard(anime: state.recommendations[i]),
            ),
          ),
        ],
      ),
    );
  }
}
