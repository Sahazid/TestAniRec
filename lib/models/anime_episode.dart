class AnimeEpisode {
  final int malId;
  final int number;
  final String title;
  final String? forumUrl;

  const AnimeEpisode({
    required this.malId,
    required this.number,
    required this.title,
    this.forumUrl,
  });

  factory AnimeEpisode.fromJson(Map<String, dynamic> json) {
    return AnimeEpisode(
      malId: json['mal_id'] ?? 0,
      number: json['mal_id'] ?? 0,
      title: (json['title'] ?? 'Episode').toString(),
      forumUrl: json['forum_url']?.toString(),
    );
  }
}
