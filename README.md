# PetConnect — Flutter + Firebase

A Flutter rebuild of the PetConnect Figma prototype (React/Vite export), wired
up to **Firebase Authentication** (email/password) and **Cloud Firestore**
for real, persisted data. Colors, fonts (Nunito/Outfit), and every screen in
the original design have a matching Flutter screen.

## Screens included
Onboarding → Sign up / Log in → Home (categories + feed) → Search →
Pet Detail (gallery, health tags, owner card) → Adopt/Buy application →
Marketplace → Sell a Pet (writes to Firestore) → Chats → Chat thread
(realtime messages) → Notifications → Wishlist → Profile (sign out).

## Project structure
```
lib/
  main.dart                 # Firebase init + AuthGate (onboarding/login/app)
  firebase_options.dart     # placeholder — replace via `flutterfire configure`
  theme/app_theme.dart      # colors/fonts copied from the Figma index.css tokens
  models/                   # Pet, Chat, ChatMessage, AppNotification, AppUser
  services/
    auth_service.dart       # FirebaseAuth wrapper (sign up/in/out, reset)
    firestore_service.dart  # all Firestore reads/writes, as streams
    seed_service.dart       # pushes the 8 demo pets into Firestore once
    seed_data.dart          # same demo pets as the Figma app's src/data.ts
    app_state.dart          # wishlist / liked-pet state, synced to Firestore
  widgets/                  # BottomNav, PetCard
  screens/                  # one file per screen, plus screens/auth/
firestore.rules             # security rules for pets/users/chats/notifications
```

## Firestore data model
- `pets/{petId}` — full pet document (name, breed, species, price/adoptionFee,
  owner, health, personality, gallery, etc). Same shape as `Pet` in the
  original `src/types.ts`.
  - `pets/{petId}/applications/{id}` — adoption/purchase requests.
- `users/{uid}` — name, email, avatarId, `likedPetIds` (the wishlist).
  - `users/{uid}/notifications/{id}` — per-user notification feed.
- `chats/{chatId}` — participants, pet reference, last message, unread counts.
  - `chats/{chatId}/messages/{id}` — individual chat messages, ordered by time.

## Setup

1. **Install Flutter** (3.22+) if you don't have it already:
   https://docs.flutter.dev/get-started/install

2. **Scaffold the platform folders.** This zip only contains `lib/`,
   `pubspec.yaml`, and config files — no `android/`, `ios/`, `web/` folders,
   since those are best generated fresh for your machine/toolchain:
   ```bash
   flutter create --org com.petconnect --project-name petconnect petconnect_app
   ```
   Then copy everything from this zip (`lib/`, `pubspec.yaml`,
   `analysis_options.yaml`, `firestore.rules`, `README.md`) into the new
   `petconnect_app/` folder, overwriting the generated `lib/main.dart` and
   `pubspec.yaml`.

3. **Create a Firebase project** at https://console.firebase.google.com, then
   enable:
   - Authentication → Sign-in method → **Email/Password**
   - Firestore Database (start in production mode; rules are provided below)

4. **Connect this project to your Firebase project** with the FlutterFire CLI
   — this overwrites the placeholder `lib/firebase_options.dart` with your
   real config for Android/iOS/web:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

5. **Install dependencies**:
   ```bash
   flutter pub get
   ```

6. **Deploy the security rules** (optional but recommended):
   ```bash
   firebase deploy --only firestore:rules
   ```
   Or paste the contents of `firestore.rules` into the Firestore console's
   Rules tab.

7. **Run the app**:
   ```bash
   flutter run
   ```

On first launch, `SeedService.seedPetsIfEmpty()` (called from `main.dart`)
automatically writes the 8 demo pets into your `pets` collection if it's
empty — so the app shows the same pets as the original Figma prototype
immediately, no manual data entry needed. Sign up for an account, and you're
in: like pets (writes to `users/{uid}.likedPetIds`), message an owner
(creates a `chats` doc + realtime `messages`), or list your own pet from the
Marketplace tab (writes a new `pets` doc).

## Notes
- Pet photos reuse the same Unsplash photo IDs as the Figma export, resolved
  to `https://images.unsplash.com/photo-<id>` at render time — no image
  hosting needed.
- The AI Pet Assistant and Nearby Vets screens from the original design were
  static/mock in the Figma prototype; they weren't included here since they
  don't touch Firestore data. They're straightforward to add as extra
  screens following the same pattern as the rest of the app if you want them.
