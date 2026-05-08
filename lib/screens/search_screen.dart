import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/anime_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.searchResults.isEmpty ? state.top : state.searchResults;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 16, 18, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? const [Color(0xFF050713), Color(0xFF1A1238)]
                      : const [Color(0xFFFFFFFF), Color(0xFFF1E8FF)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Smart Search', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                  const SizedBox(height: 6),
                  Text('Search by mood, genre, title, or special keyword.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(.16), blurRadius: 24, offset: const Offset(0, 10))],
                    ),
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: state.search,
                      decoration: InputDecoration(
                        hintText: 'Try: Dark Fantasy, Romance, Isekai...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(icon: const Icon(Icons.auto_awesome_rounded), onPressed: () => state.search(controller.text)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Special Keywords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: state.smartKeywords.map((k) => ActionChip(
                      avatar: const Icon(Icons.bolt_rounded, size: 16),
                      label: Text(k),
                      onPressed: () {
                        controller.text = k;
                        state.search(k);
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
                  if (state.lastSearchQuery != null)
                    Text(
                      'Searched: "${state.lastSearchQuery}" • ${state.lastSearchCount} results',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!state.loading && state.lastSearchQuery != null && state.searchResults.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text('No anime found for this search keyword. Try another genre or title.'),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 110),
            sliver: SliverGrid.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .58, crossAxisSpacing: 14, mainAxisSpacing: 18),
              itemBuilder: (_, i) => AnimeCard(anime: items[i], width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}
