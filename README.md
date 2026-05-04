# AniRec - Flutter Anime Recommendation App

AniRec is a modern anime recommendation app based on the UI concept you liked. It uses the public Jikan REST API v4, which is an unofficial open-source MyAnimeList API.

## API source
- API: Jikan REST API v4
- Base URL: `https://api.jikan.moe/v4`
- API key: **No API key required**. Jikan does not provide authenticated requests for MyAnimeList.
- Top anime endpoint used: `https://api.jikan.moe/v4/top/anime?limit=10&sfw=true`
- Search endpoint used: `https://api.jikan.moe/v4/anime?q=naruto&sfw=true`

## Features included
- Animated landing/home hero banner that changes top 10 anime every 1 second.
- Anime title, genre chips, score and synopsis overlay on the hero banner.
- Real anime API integration using Jikan.
- Search by anime title, mood/keyword and genre.
- Smart recommendation section based on saved user behavior/search keywords/watchlist.
- Watchlist using local storage.
- Dark and light theme toggle.
- Anime detail page with trailer / MyAnimeList link support.
- Admin panel placeholder for future CMS/backend management.
- Modern responsive UI inspired by the sample mockup.

## Run without Android Studio
You still need Flutter SDK and Android command-line tools or an online builder.

### Online build: Codemagic
1. Create a GitHub account.
2. Create a new GitHub repository named `anirec`.
3. Upload this project folder.
4. Go to https://codemagic.io/ and connect the GitHub repo.
5. Choose Flutter workflow.
6. Build Android APK.
7. Download `app-release.apk` from build artifacts.

### Local build command
```bash
flutter pub get
flutter run
flutter build apk --release
```
APK location:
```bash
build/app/outputs/flutter-apk/app-release.apk
```

## Notes
This is a ready starter source project, not a store-ready production backend. Jikan is public and rate-limited, so for production you should add Firebase/Supabase backend caching, user login, admin CMS and analytics.
