class Anime {
  final int id;
  final String title;
  final String imageUrl;
  final String largeImageUrl;
  final String synopsis;
  final double score;
  final int? rank;
  final int? year;
  final String? rating;
  final String? trailerUrl;
  final String malUrl;
  final List<String> genres;
  final List<String> themes;

  const Anime({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.largeImageUrl,
    required this.synopsis,
    required this.score,
    this.rank,
    this.year,
    this.rating,
    this.trailerUrl,
    required this.malUrl,
    required this.genres,
    required this.themes,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    final images = json['images']?['jpg'] ?? {};
    return Anime(
      id: json['mal_id'] ?? 0,
      title: json['title_english'] ?? json['title'] ?? 'Unknown Anime',
      imageUrl: images['image_url'] ?? '',
      largeImageUrl: images['large_image_url'] ?? images['image_url'] ?? '',
      synopsis: json['synopsis'] ?? 'No synopsis available.',
      score: (json['score'] ?? 0).toDouble(),
      rank: json['rank'],
      year: json['year'],
      rating: json['rating'],
      trailerUrl: json['trailer']?['url'],
      malUrl: json['url'] ?? '',
      genres: _names(json['genres']),
      themes: _names(json['themes']),
    );
  }

  static List<String> _names(dynamic list) {
    if (list is! List) return const [];
    return list.map((e) => e['name']?.toString() ?? '').where((e) => e.isNotEmpty).toList();
  }
}
