# No Tomorrow — Self-Improvement RPG

A gamified self-improvement app built with Flutter. Complete daily tasks, level up, and unlock a collectible card collection.

---

## Features

- **Pizza Wheel Navigation** — swipe the home wheel to browse sections
- **WORK / LIVE Missions** — split task categories with blurred photo backgrounds
- **XP & Leveling** — earn XP by completing tasks, level up with animations
- **Collectible Cards** — cards drop on level-up, organized by rarity (Epic / Rare / Uncommon) and album (OP / JP / SP / PK)
- **Collection Screen** — album list with B&W locked state, full color when complete
- **Swipe to go back** — left-to-right swipe exits any screen

---

## Run on iPhone (Mac)

### 1. Install dependencies (one time)

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/master/install.sh)"

# Install Flutter
brew install --cask flutter

# Install CocoaPods
sudo gem install cocoapods
```

### 2. Clone the project

```bash
git clone https://github.com/hamzayevmaqsud/no_tomorrow.git
cd no_tomorrow
```

### 3. Install project dependencies

```bash
flutter pub get
cd ios && pod install && cd ..
```

### 4. Accept Xcode license (one time)

```bash
open -a Xcode
# Click Agree when prompted
```

### 5. Enable Developer Mode on iPhone

`Settings → Privacy & Security → Developer Mode → ON`

### 6. Connect iPhone and run

```bash
flutter devices          # find your device ID
flutter run              # auto-picks connected iPhone
```

---

## Run on Web (Windows / Mac)

```bash
flutter run -d edge      # Microsoft Edge
flutter run -d chrome    # Google Chrome
```

---

## Update from GitHub

```bash
git pull
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## Project Structure

```
lib/
  main.dart                  # App entry point
  models/
    game_state.dart          # XP, level, progress
    task.dart                # Task model (category, priority)
    collection_state.dart    # Collectible cards & albums
    section.dart             # Home wheel sections
  screens/
    home_screen.dart         # Pizza wheel main screen
    tasks_menu_screen.dart   # WORK / LIVE selection
    tasks_screen.dart        # Mission list
    collection_screen.dart   # Album & card collection
    settings_screen.dart     # Theme toggle & settings
    section_screen.dart      # Placeholder for other sections
  widgets/
    swipe_to_pop.dart        # Swipe-to-go-back wrapper
  theme/
    app_colors.dart          # Color palette
    app_theme.dart           # Light / dark themes
assets/
  images/                    # Avatar
  fonts/                     # Outfit, JetBrains Mono, etc.
  collection/
    Epic/                    # Epic rarity cards
    Rare/                    # Rare rarity cards
    Uncommon/                # Uncommon rarity cards
    Albums/                  # Album cover images
    Tasks menu/              # Work & Live background images
```

---

## Tech Stack

- Flutter 3.41+ / Dart 3.11+
- `video_player` — MP4 collectible cards
- `google_fonts` — Outfit, JetBrains Mono
