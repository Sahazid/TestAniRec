# AniRec - Flutter Anime Recommendation App

AniRec is a modern anime recommendation app based on the UI concept you liked. It uses the public Jikan REST API v4, which is an unofficial open-source MyAnimeList API.

## API source
- API: Jikan REST API v4
- Base URL: `https://api.jikan.moe/v4`
- API key: **No API key required**. Jikan does not provide authenticated requests for MyAnimeList.
- Top anime endpoint used: `https://api.jikan.moe/v4/top/anime?limit=10&sfw=true`
- Search endpoint used: `https://api.jikan.moe/v4/anime?q=naruto&sfw=true`

## Features included
- Animated landing/home hero banner that rotates top anime.
- Anime title, genre chips, score and synopsis overlay on the hero banner.
- Real anime API integration using Jikan.
- Smart search by title, genre and behavior keywords.
- Search feedback showing searched term and result count.
- Watchlist requires login and is saved per user account.
- Local user authentication system: login, signup, forgot password.
- User profile now shows real logged-in account data.
- Working `View all` action from home sections.
- Working admin panel with real stats (users, searches, watchlist items).
- Anime detail page with trailer/source link.
- Episode-wise watch page so users can open anime episodes directly.
- Dark and light theme toggle.
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

## Authentication and admin notes
- Local database: SQLite (`sqflite`) is used to persist users, watchlist records, and search history.
- Passwords are stored as hashes (SHA-256), not plain text.
- Admin access is role-based.
- Default admin rule in this build: signup/login with `admin@anirec.com` to open admin features.

## Run
```bash
flutter pub get
flutter run
```

## Notes
This is a production-style starter but still uses local storage for auth/data and public Jikan API. For full production deployment, consider moving auth, watchlists and admin data to a hosted backend (Firebase/Supabase/custom API) and add robust server-side authorization.
