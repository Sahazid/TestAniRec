import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime.dart';
import '../models/anime_episode.dart';

class AnimeApiService {
  static const String baseUrl = 'https://api.jikan.moe/v4';

  Future<List<Anime>> topAnime({int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/top/anime?limit=$limit&sfw=true');
    return _fetchList(uri, fallbackLimit: limit);
  }

  Future<List<Anime>> seasonalAnime({int limit = 12}) async {
    final uri = Uri.parse('$baseUrl/seasons/now?limit=$limit&sfw=true');
    return _fetchList(uri, fallbackLimit: limit);
  }

  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    final uri = Uri.parse(
      '$baseUrl/anime?q=${Uri.encodeComponent(query)}&limit=$limit&sfw=true&order_by=score&sort=desc',
    );

    final results = await _fetchList(uri, fallbackLimit: limit);

    // Offline fallback search filtering
    if (results.isNotEmpty && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      final filtered = results.where((anime) {
        return anime.title.toLowerCase().contains(q);
      }).toList();

      if (filtered.isNotEmpty) {
        return filtered;
      }
    }

    return results;
  }

  Future<List<Anime>> recommendationByKeyword(String keyword) async {
    return searchAnime(keyword, limit: 12);
  }

  Future<List<Anime>> seasonalBy(String season, int year, {int limit = 24}) async {
    final uri = Uri.parse('$baseUrl/seasons/$year/$season?limit=$limit&sfw=true');
    return _fetchList(uri, fallbackLimit: limit);
  }

  Future<List<AnimeEpisode>> animeEpisodes(int animeId) async {
    final uri = Uri.parse('$baseUrl/anime/$animeId/episodes');
    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final data = decoded['data'] as List<dynamic>? ?? [];
        return data.asMap().entries.map((entry) {
          final i = entry.key;
          final raw = entry.value as Map<String, dynamic>;
          return AnimeEpisode(
            malId: raw['mal_id'] ?? (i + 1),
            number: i + 1,
            title: (raw['title'] ?? 'Episode ${i + 1}').toString(),
            forumUrl: raw['forum_url']?.toString(),
            streamUrl: _demoStreamForEpisode(i + 1),
          );
        }).toList();
      }
    } catch (_) {
      // Keep a graceful fallback so "Watch" always has content.
    }
    return List.generate(
      12,
      (i) => AnimeEpisode(
        malId: i + 1,
        number: i + 1,
        title: 'Episode ${i + 1}',
        streamUrl: _demoStreamForEpisode(i + 1),
      ),
    );
  }

  String _demoStreamForEpisode(int episode) {
    const streams = [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    ];
    return streams[(episode - 1) % streams.length];
  }

  Future<List<Anime>> _fetchList(Uri uri, {int fallbackLimit = 10}) async {
    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final data = decoded['data'] as List<dynamic>? ?? [];

        if (data.isNotEmpty) {
          return data
              .map((e) => Anime.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      return _fallbackAnimeList(limit: fallbackLimit);
    } catch (e) {
      return _fallbackAnimeList(limit: fallbackLimit);
    }
  }

  List<Anime> _fallbackAnimeList({int limit = 10}) {
    final data = [
      {
        "mal_id": 1,
        "title": "Attack on Titan",
        "title_english": "Attack on Titan",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/10/47347.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/10/47347l.jpg"
          }
        },
        "score": 9.1,
        "episodes": 25,
        "status": "Finished Airing",
        "year": 2013,
        "rating": "R - 17+",
        "synopsis":
            "Humanity fights for survival against giant humanoid Titans that threaten civilization.",
        "genres": [
          {"name": "Action"},
          {"name": "Drama"},
          {"name": "Dark Fantasy"}
        ]
      },
      {
        "mal_id": 2,
        "title": "Demon Slayer",
        "title_english": "Demon Slayer: Kimetsu no Yaiba",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/1286/99889.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/1286/99889l.jpg"
          }
        },
        "score": 8.8,
        "episodes": 26,
        "status": "Finished Airing",
        "year": 2019,
        "rating": "R - 17+",
        "synopsis":
            "Tanjiro becomes a demon slayer to save his sister and avenge his family.",
        "genres": [
          {"name": "Action"},
          {"name": "Supernatural"},
          {"name": "Adventure"}
        ]
      },
      {
        "mal_id": 3,
        "title": "Jujutsu Kaisen",
        "title_english": "Jujutsu Kaisen",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/1171/109222.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/1171/109222l.jpg"
          }
        },
        "score": 8.6,
        "episodes": 24,
        "status": "Finished Airing",
        "year": 2020,
        "rating": "R - 17+",
        "synopsis":
            "A student joins a secret organization to fight dangerous curses.",
        "genres": [
          {"name": "Action"},
          {"name": "Supernatural"},
          {"name": "School"}
        ]
      },
      {
        "mal_id": 4,
        "title": "One Piece",
        "title_english": "One Piece",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/6/73245.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/6/73245l.jpg"
          }
        },
        "score": 9.0,
        "episodes": null,
        "status": "Currently Airing",
        "year": 1999,
        "rating": "PG-13",
        "synopsis":
            "Monkey D. Luffy and his crew search for the legendary treasure known as One Piece.",
        "genres": [
          {"name": "Action"},
          {"name": "Adventure"},
          {"name": "Fantasy"}
        ]
      },
      {
        "mal_id": 5,
        "title": "Death Note",
        "title_english": "Death Note",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/9/9453.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/9/9453l.jpg"
          }
        },
        "score": 8.9,
        "episodes": 37,
        "status": "Finished Airing",
        "year": 2006,
        "rating": "R - 17+",
        "synopsis":
            "A genius student discovers a notebook that can kill anyone whose name is written in it.",
        "genres": [
          {"name": "Mystery"},
          {"name": "Psychological"},
          {"name": "Supernatural"}
        ]
      },
      {
        "mal_id": 6,
        "title": "Naruto",
        "title_english": "Naruto",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/13/17405.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/13/17405l.jpg"
          }
        },
        "score": 8.0,
        "episodes": 220,
        "status": "Finished Airing",
        "year": 2002,
        "rating": "PG-13",
        "synopsis":
            "Naruto Uzumaki dreams of becoming the strongest ninja and earning respect.",
        "genres": [
          {"name": "Action"},
          {"name": "Adventure"},
          {"name": "Martial Arts"}
        ]
      },
      {
        "mal_id": 7,
        "title": "My Hero Academia",
        "title_english": "My Hero Academia",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/10/78745.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/10/78745l.jpg"
          }
        },
        "score": 8.1,
        "episodes": 13,
        "status": "Finished Airing",
        "year": 2016,
        "rating": "PG-13",
        "synopsis":
            "A powerless boy enters a hero academy after receiving a legendary power.",
        "genres": [
          {"name": "Action"},
          {"name": "School"},
          {"name": "Super Power"}
        ]
      },
      {
        "mal_id": 8,
        "title": "Fullmetal Alchemist: Brotherhood",
        "title_english": "Fullmetal Alchemist: Brotherhood",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/1208/94745.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/1208/94745l.jpg"
          }
        },
        "score": 9.1,
        "episodes": 64,
        "status": "Finished Airing",
        "year": 2009,
        "rating": "R - 17+",
        "synopsis":
            "Two brothers search for the Philosopher's Stone after a failed alchemy experiment.",
        "genres": [
          {"name": "Action"},
          {"name": "Adventure"},
          {"name": "Fantasy"}
        ]
      },
      {
        "mal_id": 9,
        "title": "Hunter x Hunter",
        "title_english": "Hunter x Hunter",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/1337/99013.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/1337/99013l.jpg"
          }
        },
        "score": 9.0,
        "episodes": 148,
        "status": "Finished Airing",
        "year": 2011,
        "rating": "PG-13",
        "synopsis":
            "Gon becomes a Hunter to find his father and explore a dangerous world.",
        "genres": [
          {"name": "Action"},
          {"name": "Adventure"},
          {"name": "Fantasy"}
        ]
      },
      {
        "mal_id": 10,
        "title": "Steins;Gate",
        "title_english": "Steins;Gate",
        "images": {
          "jpg": {
            "image_url": "https://cdn.myanimelist.net/images/anime/5/73199.jpg",
            "large_image_url": "https://cdn.myanimelist.net/images/anime/5/73199l.jpg"
          }
        },
        "score": 9.0,
        "episodes": 24,
        "status": "Finished Airing",
        "year": 2011,
        "rating": "PG-13",
        "synopsis":
            "A group of friends accidentally discover a way to send messages to the past.",
        "genres": [
          {"name": "Sci-Fi"},
          {"name": "Thriller"},
          {"name": "Drama"}
        ]
      }
    ];

    return data
        .take(limit)
        .map((e) => Anime.fromJson(e))
        .toList();
  }
}
