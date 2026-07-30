# Bulletin

A public blog/forum application built with Flutter, Provider, go_router, and
Supabase.

## Features

- Email and password registration, login, and logout
- Public paginated post listing
- Multiple-image previews on post cards
- Post create, read, update, and delete
- Multiple post image upload, addition, and deletion
- Comment create, read, update, and delete
- Multiple comment image upload, addition, and deletion
- Owner-only edit and delete actions
- Responsive Flutter Web and mobile layout

## Technology

- Flutter and Dart
- Provider for state management
- go_router for navigation
- Supabase Authentication
- Supabase Postgres Database with Row Level Security
- Supabase Storage

## Supabase Setup

1. Create a Supabase project.
2. Open the Supabase SQL Editor.
3. Run `supabase/schema.sql`.
4. In Authentication settings, disable email confirmation for faster testing.
5. Copy `.env.example` to `.env`.
6. Add the project URL and publishable key:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

The publishable key is intended for client applications. Security is enforced
by the Row Level Security and Storage policies in `supabase/schema.sql`.

Comments store the author's email directly. The application does not require a
separate profiles table.

## Run Locally

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

For Flutter Web:

```bash
flutter run -d chrome --dart-define-from-file=.env
```

## Verify

Test these flows before submission:

1. Logged-out visitors can list and view posts, post images, comments, and
   comment images.
2. Logged-out visitors cannot create or edit content.
3. User A can create, update, and delete their own posts and comments.
4. User B cannot update or delete content owned by User A.
5. Pagination loads another page without duplicating posts.
6. Deleting a post or comment removes its images from Supabase Storage.
7. Mobile and desktop layouts allow every button to be pressed.

Run checks:

```bash
flutter analyze
flutter test
flutter build web --release
```

## Deploy Flutter Web

Build for a root domain such as Vercel or Cloudflare Pages:

```bash
flutter build web --release --dart-define-from-file=.env
```

Deploy the generated `build/web` directory.

For GitHub Pages under a repository path:

```bash
flutter build web --release --base-href /bulletin-flutter/ --dart-define-from-file=.env
```

Deploy `build/web` to the `gh-pages` branch. Configure the host so unknown
routes return `index.html`; this allows go_router URLs to load after a browser
refresh.

## Submission

- Live URL: https://bulletin-flutter.pages.dev
- GitHub repository: https://github.com/abdlmnn/bulletin-flutter
