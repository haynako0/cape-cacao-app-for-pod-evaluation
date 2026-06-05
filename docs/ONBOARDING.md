# CAPE — Cacao App for Pod Evaluation
### Onboarding Guide for Student Developers

---

## Table of Contents

1. [Welcome to CAPE](#1-welcome-to-cape)
2. [Crash Course: Flutter & Provider](#2-crash-course-flutter--provider)
3. [Windows → Android Dev Setup](#3-windows--android-dev-setup)
4. [Codebase Tour](#4-codebase-tour)
5. [How to Run & Debug](#5-how-to-run--debug)

---

## 1. Welcome to CAPE

**CAPE** (Cacao App for Pod Evaluation) is an Android app that uses a machine learning model running *entirely on your phone* — no internet required — to detect diseases on cacao pods in real time.

Point the camera at a cacao pod. Press scan. Within seconds, the app draws colored boxes around each pod it finds and tells you whether it's healthy or suffering from **Blackpod Rot**, **Cacao Pod Borer**, or **Mirid Bug** damage.

### What makes this app technically interesting

| Feature | Technology |
|---|---|
| On-device AI detection | YOLOv11s object detection model |
| ML inference runtime | ONNX Runtime (runs the model natively on Android) |
| UI framework | Flutter (one codebase → Android app) |
| State management | Provider pattern |
| Offline knowledge base | `cocoa_info.json` — rich disease info served without internet |
| Scan history | Local file storage (JSON + saved images) |
| Multi-language support | English, Tagalog, Bisaya — all strings in `settings_provider.dart` |

### Repository

```
https://github.com/haynako0/cape-cacao-app-for-pod-evaluation
```

---

## 2. Crash Course: Flutter & Provider

Before you touch any code, you need to understand two ideas. Everything else builds on top of them.

### 2.1 What is Flutter?

Flutter is Google's framework for building mobile apps using a language called **Dart**. Instead of writing separate code for Android and iPhone, you write one set of Dart files and Flutter compiles them into a real Android app.

Every visual element — a button, a card, a text label — is called a **Widget**. You nest widgets inside other widgets to build a screen, similar to how HTML elements nest inside each other.

```
Scaffold (the whole screen)
  └── Column (stack things vertically)
        ├── Image (the photo)
        ├── Text ("Scan Result")
        └── Card (a rounded box)
              └── Text ("BLACKPOD — 91% confidence")
```

### 2.2 What is Provider, and why does CAPE use it?

**The problem:** Imagine you're in a hospital. The doctor (one screen) updates a patient's chart. The nurse (another screen) needs to see that update immediately. How do you share information between completely separate rooms?

**The solution: a whiteboard in the hallway.**

Provider is CAPE's whiteboard. Any screen in the app can write information to it, and any other screen automatically refreshes the moment that information changes.

CAPE has three whiteboards (Providers):

| Provider file | What it stores | Who reads it |
|---|---|---|
| `settings_provider.dart` | Language, theme, sounds, confidence threshold | Every screen |
| `navigation_provider.dart` | Which screen is active, scan results, history entry being viewed | `main.dart`, `result_screen.dart` |
| `history_provider.dart` | The list of all past scans | `history_screen.dart`, `analytics_screen.dart` |

**How it works in practice:**

When you take a photo, `scan_screen.dart` calls:
```dart
navProvider.showResult(imageBytes, fileName: image.name);
```
This writes the image to `NavigationProvider`'s whiteboard. `main.dart` is watching the whiteboard, sees the change, and immediately slides `ResultScreen` into view. No passing data between screens manually. No page navigation arguments. The whiteboard handles it.

### 2.3 The `watch` vs `read` distinction

You'll see these two patterns everywhere in CAPE:

```dart
final settings = context.watch<SettingsProvider>();
```
> "Keep watching this whiteboard. Rebuild this widget every time it changes."

```dart
final settings = context.read<SettingsProvider>();
```
> "Read the whiteboard once right now. Don't subscribe to future changes."

**Rule of thumb:** Use `watch` in `build()` methods (the part that draws the UI). Use `read` inside button press handlers and async functions.

---

## 3. Windows → Android Dev Setup

Follow every step in order. Do not skip.

### Step 1 — Install Git for Windows

1. Download from: **https://git-scm.com/download/win**
2. Run the installer. Accept all defaults.
3. Open a new **Command Prompt** window and verify:

```cmd
git --version
```

Expected output: `git version 2.x.x.windows.x`

---

### Step 2 — Install Android Studio 2025.1.1

1. Download **Android Studio Meerkat (2025.1.1)** from:
   **https://developer.android.com/studio**

2. Run the installer. When the setup wizard asks which components to install, make sure these are checked:
   - ✅ Android SDK
   - ✅ Android SDK Platform
   - ✅ Android Virtual Device

3. Complete the wizard. Android Studio will download the SDK automatically.

---

### Step 3 — Install the Flutter SDK

1. Download **Flutter 3.35.5 (Stable)** from:
   **https://docs.flutter.dev/get-started/install/windows/mobile**

2. Extract the downloaded `.zip` file to:
   ```
   C:\flutter
   ```
   > ⚠️ **Do NOT place Flutter inside** `C:\Program Files\` or any folder with spaces in the name. This causes build failures.

3. Add Flutter to your system PATH:
   - Press `Windows Key + S` → search **"Environment Variables"** → click **"Edit the system environment variables"**
   - Click **"Environment Variables..."**
   - Under **"User variables"**, find the variable named `Path` → click **Edit**
   - Click **New** → type `C:\flutter\bin`
   - Click **OK** on all three windows

4. Open a **new** Command Prompt and verify:

```cmd
flutter --version
```

Expected output includes: `Flutter 3.35.5` and `Dart 3.x.x`

---

### Step 4 — Configure Flutter to use Android Studio's SDK

Run this command:

```cmd
flutter config --android-studio-dir "C:\Program Files\Android\Android Studio"
```

> If you installed Android Studio to a different location, adjust the path accordingly.

---

### Step 5 — Accept Android SDK Licenses

This is the single most commonly skipped step. Skipping it causes Gradle build failures.

```cmd
flutter doctor --android-licenses
```

When prompted, type `y` and press Enter for **every** license. There are approximately 5–7 of them.

---

### Step 6 — Install Android SDK 36 and Build Tools

1. Open **Android Studio**
2. Go to **Settings** (or Preferences) → **Languages & Frameworks** → **Android SDK**
3. In the **SDK Platforms** tab, check:
   - ✅ Android 16.0 ("Baklava") — API Level 36
4. In the **SDK Tools** tab, check:
   - ✅ Android SDK Build-Tools 36.1.0
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools
5. Click **Apply** and let it download.

---

### Step 7 — Install the Flutter Plugin in Android Studio

1. Open Android Studio
2. Go to **Settings** → **Plugins**
3. Search for **Flutter** → click **Install**
4. When prompted, also install **Dart** (it's a dependency)
5. Restart Android Studio

---

### Step 8 — Run the Flutter Doctor check

```cmd
flutter doctor
```

Your output should show checkmarks like this:

```
[✓] Flutter (Channel stable, 3.35.5)
[✓] Windows Version
[✓] Android toolchain - develop for Android devices
[✓] Android Studio (version 2025.1)
[✓] VS Code (optional)
[✓] Connected device
[✓] Network resources
```

> If you see `[!]` (warning) next to Android toolchain, re-run Step 5. If you see `[✗]` (error), read the message carefully — it tells you exactly what to install.

---

### Step 9 — Clone the CAPE repository

Navigate to where you want to store the project, then clone it:

```cmd
cd C:\Users\YourName\Documents
git clone https://github.com/haynako0/cape-cacao-app-for-pod-evaluation.git
cd cape-cacao-app-for-pod-evaluation
```

---

### Step 10 — Install project dependencies

```cmd
flutter pub get
```

This reads `pubspec.yaml` and downloads every package the app needs (camera, onnxruntime, etc.) into a hidden `.dart_tool/` folder. You must run this once after cloning, and again any time `pubspec.yaml` changes.

---

### Step 11 — Connect an Android device or start an emulator

**Option A — Physical Android phone (recommended for ONNX performance):**
1. On your phone: **Settings** → **About Phone** → tap **Build Number** 7 times → Developer Mode unlocked
2. **Settings** → **Developer Options** → enable **USB Debugging**
3. Plug in via USB cable
4. Run `flutter devices` — your phone should appear in the list

**Option B — Android Emulator:**
1. In Android Studio: **Tools** → **Device Manager** → **Create Device**
2. Choose a Pixel device → select **API Level 36** system image → Finish
3. Click the ▶ play button to start the emulator

> ⚠️ The ONNX model runs significantly slower on emulators than real hardware. For testing ML inference speed, always prefer a physical device.

---

### Step 12 — Build and run CAPE

```cmd
flutter run
```

The first build takes 3–7 minutes. Subsequent runs are much faster (under 30 seconds).

When you see:
```
Syncing files to device...
```
...the app is installing on your phone. After a few seconds it will open automatically.

---

## 4. Codebase Tour

### Project folder structure

```
cape-cacao-app-for-pod-evaluation/
├── android/              ← Android-specific config (you rarely touch this)
├── assets/               ← ALL static files: images, audio, model, labels
│   ├── audio/            ← .mp3 tap and scan sounds
│   ├── fonts/            ← CustomFont1, CustomFont2, CustomFont3 (.ttf / .otf)
│   ├── icons/            ← scan_icon.svg (the camera button icon)
│   ├── images/           ← hero images, confusion matrix, screenshots
│   ├── models/
│   │   └── v1.onnx       ← THE BRAIN: the trained YOLOv11s detection model
│   ├── best.onnx         ← (legacy, not currently loaded by the app)
│   ├── cocoa_info.json   ← disease descriptions in all 3 languages
│   └── labels.txt        ← class names: HEALTHY, BLACKPOD, MIRID, PODBORER
├── lib/                  ← ALL Dart source code lives here
│   ├── models/
│   │   └── history_entry.dart
│   ├── providers/
│   │   ├── history_provider.dart
│   │   ├── navigation_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/
│   │   ├── about_screen.dart
│   │   ├── analytics_screen.dart
│   │   ├── basic_credits_screen.dart
│   │   ├── cinematic_credits_screen.dart
│   │   ├── history_screen.dart
│   │   ├── home_screen.dart
│   │   ├── result_screen.dart
│   │   ├── scan_screen.dart
│   │   └── settings_screen.dart
│   ├── main.dart
│   ├── onnx_service.dart
│   └── sfx_service.dart
└── pubspec.yaml          ← Project manifest: dependencies + asset registration
```

---

### 4.1 `assets/` — and the critical `pubspec.yaml` registration rule

> **Rookie Mistake #1:** You add a file to the `assets/` folder in File Explorer, but the app crashes with `Unable to load asset`. This happens because Flutter does NOT automatically detect files in `assets/`. You must register every file (or folder) in `pubspec.yaml`.

Open `pubspec.yaml` and find this section:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/fonts/
    - assets/labels.txt
    - assets/best.onnx
    - assets/cocoa_info.json
    - assets/audio/
    - assets/icons/
    - assets/models/
    - assets/audio/credits_theme.mp3
```

**The rules:**
- A line ending in `/` (like `assets/images/`) registers **every file in that folder** at one level deep. It does **not** recurse into subfolders automatically.
- A specific file path (like `assets/labels.txt`) registers just that one file.
- After adding a new asset entry to `pubspec.yaml`, you must run `flutter pub get` again.

**Example:** If you add a new sound file `assets/audio/newbeep.mp3`, you do not need to change `pubspec.yaml` because `assets/audio/` already covers the whole folder. But if you create a new subfolder `assets/audio/effects/beep.mp3`, you would need to add `- assets/audio/effects/` as a new line.

---

### 4.2 `lib/models/` — Data structures

#### `history_entry.dart`

This is a plain data class. It has no logic — it just holds information about one completed scan.

| Property | Type | Meaning |
|---|---|---|
| `id` | `String` | Timestamp-based unique ID (e.g. `"1717823400000"`) |
| `date` | `DateTime` | When the scan happened |
| `imagePath` | `String` | Full local file path to the saved JPEG |
| `detections` | `List<Detection>` | Every bounding box the model found |
| `selectedJsonIndices` | `Map<String, Map<String, int>>` | Which variant of disease text to show for each class |
| `originalFileName` | `String` | The source image filename (e.g. `"IMG_2041.jpg"`) |
| `modelName` | `String?` | Which ONNX model was used (currently always `"v1 (No Borer)"`) |

`toMap()` converts it to JSON-compatible data for saving. `fromMap()` rebuilds it when loading from disk.

`Detection` itself is defined in `onnx_service.dart` (because the inference service creates it). It holds `left`, `top`, `width`, `height`, `label`, and `confidence` for one detected pod.

---

### 4.3 `lib/providers/` — The whiteboards

#### `settings_provider.dart`

The largest provider in the app. Controls everything the user can customize.

**What it manages:**
- Selected language (English / Tagalog / Bisaya)
- Active theme (4 color schemes × light/dark = 8 total `ColorScheme` objects defined as `static const`)
- Text size and font family
- Tap SFX and scan SFX toggles and selections
- Confidence threshold (the minimum % score the model needs to report a detection)
- The entire localization dictionary (the `_localizedStrings` map at the bottom of the file)

**How it persists data:** `SharedPreferences` — a simple key-value store that survives app restarts. Every `change*()` method writes to both the in-memory variable and `SharedPreferences` in one call.

**How it plays sounds:** It delegates to `SfxService`. When `playTapSound()` is called, it checks whether tap sounds are enabled, then asks `SfxService` to play the selected sound file.

**How it provides translations:** `translate(key)` looks up a string key in `_localizedStrings[_selectedLanguage]`. Every piece of visible text in every screen goes through this method.

#### `navigation_provider.dart`

Controls which screen the user is looking at and whether the result overlay is visible.

**Key state:**
- `currentIndex` — which of the 5 bottom-nav tabs is active (0=Home, 1=History, 2=Scan, 3=About, 4=Settings)
- `resultImageBytes` — if this is non-null, the result overlay is shown
- `viewingHistoryEntry` — if this is non-null, the user is replaying an old scan
- `_primaryScanAction` — a callback registered by `scan_screen.dart` so the central button knows what to do

**The trick:** The bottom navigation bar's central camera button is in `main.dart`, but the actual "take photo" and "scan from gallery" logic lives in `scan_screen.dart`. They communicate through `registerScanAction()`. The scan screen registers its capture function with the provider; the button reads it back and calls it.

#### `history_provider.dart`

Manages the complete list of past scans.

**Storage:** One JSON file at `[app documents directory]/history.json`. Each entry in the JSON array maps to a `HistoryEntry`. Images are stored as individual `.jpg` files in the same directory, named by their timestamp ID.

**Operations:**
- `addHistoryEntry()` — saves the JPEG to disk, creates a `HistoryEntry`, appends it to the list, writes `history.json`
- `deleteHistoryEntry()` — deletes the JPEG file, removes the entry, rewrites `history.json`
- `clearAllHistory()` — deletes every JPEG, empties the list, rewrites `history.json`

---

### 4.4 `lib/onnx_service.dart` — The ML engine

This is the most important file in the project. It transforms a raw photo into a list of detections.

#### The ML inference pipeline — step by step

```
📷 Raw photo bytes (JPEG, any size)
        │
        ▼
┌─────────────────────────────────────────────┐
│  STEP 1: Native resize (FlutterImageCompress)│
│  Compress + resize to ~640px while keeping  │
│  quality. Reduces memory for next step.      │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│  STEP 2: GPU letterbox composition           │
│  Draw the image onto a 640×640 black canvas  │
│  with equal padding on both sides (the       │
│  "letterbox" effect). This is what the model │
│  was trained to expect — always 640×640,     │
│  always with black padding bars.             │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│  STEP 3: Convert to Float32 tensor (Isolate) │
│  RGBA pixel bytes → [R, G, B] / 255.0        │
│  Shape: [1, 3, 640, 640] (batch, channels,   │
│  height, width). Runs in background isolate  │
│  so UI stays responsive.                     │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│  STEP 4: ONNX Runtime inference              │
│  Feed tensor into v1.onnx model.             │
│  Output: [1, 8, 8400] tensor.                │
│  8 = 4 box coords + 4 class scores.          │
│  8400 = number of candidate detections.      │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│  STEP 5: Post-processing                     │
│  For each of 8400 candidates:                │
│  • Find the class with the highest score     │
│  • If score > confidenceThreshold → keep     │
│  • Un-pad and un-scale box coords back to    │
│    original image pixel coordinates           │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│  STEP 6: Non-Maximum Suppression (NMS)       │
│  If two boxes of the same class overlap      │
│  by more than 45% (IoU threshold), keep only │
│  the one with higher confidence. Eliminates  │
│  duplicate detections on the same pod.       │
└────────────────────┬────────────────────────┘
                     │
                     ▼
📦 List<Detection> — one per real pod found
```

#### Why letterboxing matters

The model was trained on 640×640 square images with padding. If you simply stretch a portrait photo to 640×640 without padding, you distort the aspect ratio. A round cacao pod becomes an oval. The model, trained on round pods, fails to recognize it. Letterboxing preserves the pod's actual shape.

#### What `labels.txt` does

```
HEALTHY
BLACKPOD
MIRID
PODBORER
```

The model's output tensor has 8 rows: 4 for box coordinates and 4 for class scores. The order of those 4 class scores matches the order of labels in this file. Row index 4 (the 5th row) = score for `HEALTHY`. Row index 7 (the 8th row) = score for `PODBORER`. `_loadLabels()` in `OnnxService.create()` reads this file so that `_labels[0]` = `"HEALTHY"` and so on.

---

### 4.5 `lib/sfx_service.dart` — Audio feedback

Manages a pool of 8 `FlutterSoundPlayer` instances. Uses a pool (instead of a single player) so rapid taps don't cancel the previous sound — each tap grabs the next available player from the pool in round-robin order.

On initialization, it extracts audio assets from the bundle to the device's temp directory, because `FlutterSoundPlayer` requires actual file paths (not Flutter asset paths) to play files.

Supports `Vibration` as a special case — instead of loading a file, it calls `HapticFeedback.lightImpact()`.

---

### 4.6 `lib/screens/` — The UI layer

Each screen is a Flutter `Widget` — a class that describes what to draw. None of them contain business logic. They read from providers and call methods on providers.

| File | Role | Key provider interactions |
|---|---|---|
| `home_screen.dart` | Landing page with disease info cards and expandable tiles | Reads `SettingsProvider` for translated strings |
| `scan_screen.dart` | Camera viewfinder + gallery grid for image selection | Calls `navProvider.showResult()` after image selection or photo capture; calls `navProvider.registerScanAction()` so the central button knows what to trigger |
| `result_screen.dart` | Displays the annotated image with bounding boxes and disease info | Calls `OnnxService.runInference()`, reads `cocoa_info.json`, calls `historyProvider.addHistoryEntry()`, calls `PhotoManager` to save image to gallery |
| `history_screen.dart` | Scrollable list of past scans with search and filter | Reads `HistoryProvider.historyEntries`; calls `navProvider.showHistoryDetail()` to replay a scan |
| `analytics_screen.dart` | Charts and KPIs built from history data | Reads `HistoryProvider.historyEntries`, computes stats locally, renders `fl_chart` widgets |
| `settings_screen.dart` | All user preferences | Calls `SettingsProvider.change*()` and `toggle*()` methods; reads current values via `watch` |
| `about_screen.dart` | Model statistics, performance curves, confusion matrix | Purely informational; shows static images from `assets/images/` |
| `basic_credits_screen.dart` | Team credits with parallax hero banner | Leads to `CinematicCreditsScreen` |
| `cinematic_credits_screen.dart` | Scrolling cinematic credits synced to music | Uses `just_audio` to play `credits_theme.mp3`; scroll position driven by audio position, not a timer |

#### How `result_screen.dart` connects the ML output to visible text

After inference completes, `result_screen.dart` has a `List<Detection>`. For each detection:

1. `detection.label` (e.g. `"BLACKPOD"`) is used to look up data in `_cocoaInfoData`
2. `_cocoaInfoData` was loaded from `assets/cocoa_info.json` at screen startup
3. The JSON structure is: `BLACKPOD → condition_overview → English → [text variant 0, text variant 1, text variant 2]`
4. `_currentJsonIndices` stores which variant (0, 1, or 2) to show for each section of each class, so different scans show slightly different descriptions rather than always the same text
5. `_getJsonText(label, section)` assembles the final string using the active language from `SettingsProvider`

The `_EnhancedBoundingBoxPainter` (at the bottom of `result_screen.dart`) is a `CustomPainter` that draws colored rectangles and labels on a canvas overlaid on top of the photo. It scales and offsets all coordinates to account for how `BoxFit.contain` positions the image within the 340px preview container.

---

### 4.7 `lib/main.dart` — Entry point and app shell

`main()` does three things before showing any UI:
1. Ensures Flutter is fully initialized (`WidgetsFlutterBinding.ensureInitialized()`)
2. Creates `SettingsProvider` and calls `loadSettings()` (loads saved prefs from `SharedPreferences`)
3. Wraps the entire app in `MultiProvider` so every screen below can access all three providers

`CocoaRomiApp` builds the `MaterialApp` and applies the current theme from `SettingsProvider`. It wraps every tap in a `Listener` that calls `settings.playTapSound()` — this is why every tap in the entire app triggers the sound effect without each widget individually wiring it up.

`HomePage` manages the `PageController` (which controls the swipe between the 5 main screens) and the animation controllers for the pulsing scan button and the rainbow glow ring. The five screens (`HomeScreen`, `HistoryScreen`, `ScanScreen`, `AboutScreen`, `SettingsScreen`) are instantiated once in a `List` and never recreated — they persist in memory as long as the app is open.

The `ResultScreen` is not in the `PageView`. It sits in a `Stack` on top of everything, and becomes visible only when `NavigationProvider.resultImageBytes` or `NavigationProvider.viewingHistoryEntry` is non-null.

---

## 5. How to Run & Debug

### Running the app

```cmd
flutter run
```

For a release build (faster, closer to production performance):

```cmd
flutter run --release
```

To target a specific device when multiple are connected:

```cmd
flutter devices
flutter run -d <device-id>
```

---

### Reading the console

When `flutter run` is active, the console streams logs. Learn to read three categories:

#### [PERF] tags — normal, expected output

CAPE uses `debugPrint` with `[PERF]` prefixes to measure the inference pipeline. You will see this every time you scan an image. This is intentional and healthy:

```
[PERF] Model Loaded (assets/models/v1.onnx) in: 1243ms
[PERF] Native Resize took: 38ms
[PERF] GPU Composition & Decode took: 112ms
[PERF] Float32 Conversion in Isolate took: 44ms
[PERF] ONNX Session Run took: 267ms
[PERF] Post-processing took: 8ms
[PERF] TOTAL INFERENCE PIPELINE: 512ms
```

If `ONNX Session Run` is above 2000ms, you are on an emulator. Use a physical device.

#### Flutter/Dart errors — red text

These appear when Dart code crashes. The most important line is always the first one. Example:

```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞══
The following assertion was thrown building ResultScreen:
RenderBox was not laid out: _RenderProxyBox#b3c2f
```

Read the stack trace below it — the first file and line number from your own code (not from Flutter internals) is where the bug is.

#### Gradle/Android build errors — appear before the app installs

> **Rookie Mistake #2:** The app fails to build and the error is hundreds of lines of Gradle output. Students scroll up looking for where it says `ERROR:` but miss that the actual cause is always in the first few lines of the failure block.

**How to find the real error:**

1. Scroll up to find the first line that says `FAILURE: Build failed with an exception.`
2. Read the `* What went wrong:` section immediately below it
3. Ignore everything after `* Try:` — that's just suggestions

Common Gradle errors and their fixes:

| Error message | Fix |
|---|---|
| `License for package Android SDK Platform 36 not accepted` | Run `flutter doctor --android-licenses` again |
| `Minimum supported Gradle version is X.X` | Run `flutter clean` then `flutter run` again |
| `SDK location not found. Define a valid SDK location` | Open Android Studio → SDK Manager → note the SDK Path → create a file at `android/local.properties` containing `sdk.dir=C\:\\Users\\YourName\\AppData\\Local\\Android\\Sdk` |
| `Could not resolve com.android.tools.build:gradle` | Check your internet connection; corporate firewalls sometimes block Gradle repositories |
| `Execution failed for task ':app:mergeDebugAssets'` | An asset listed in `pubspec.yaml` does not exist at that path — check your `assets/` folder |

#### Common Flutter/Provider errors

| Error | Cause | Fix |
|---|---|---|
| `Could not find the correct Provider above this Widget` | A widget tried to `context.watch<SomeProvider>()` but that provider wasn't registered in `MultiProvider` in `main.dart` | Add the provider to the `MultiProvider` list |
| `Unable to load asset: assets/some_file.ext` | File exists on disk but is not registered in `pubspec.yaml` | Add the path to `pubspec.yaml` under `flutter: assets:` and run `flutter pub get` |
| `setState() called after dispose()` | An async operation completed after the widget was removed from the screen | Check `if (mounted)` before calling `setState()` |

---

### Hot reload and hot restart

While `flutter run` is active in your terminal, press:

| Key | What it does |
|---|---|
| `r` | **Hot reload** — re-runs `build()` on all visible widgets. Preserves app state. Use this for UI changes. |
| `R` | **Hot restart** — restarts the entire Dart VM. Clears state. Use this when you change providers, models, or `initState()` logic. |
| `q` | Quit the runner |

---

### Running `flutter analyze`

Before submitting any code change, run:

```cmd
flutter analyze
```

This checks your Dart code for type errors, unused imports, and bad patterns without running the app. Fix any `error` level issues before running.

---

*Built by Erl Teodemar D. Sofer, Nixon E. Coronado, and Riana Alexis C. Bagalso — Laguna State Polytechnic University, Santa Cruz Main Campus.*
