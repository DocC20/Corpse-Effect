# How to release Corpse & Effect

Three ways for people to play:
1. **Web** (any PC or phone browser, nothing to install). Hosted free on GitHub Pages.
2. **Windows .exe** (download, unzip, double-click). On a GitHub Release.
3. **Android .apk** (phone app). On the same GitHub Release. iPhone players use the web version (making an iPhone app needs a Mac).

Keep the **source** repo (DocC20/Corpse-Effect) **private**: some art packs don't allow sharing their raw files. A finished game build is fine to share. So we make a second, **public** repo that only holds the builds.

## 0. Before every release
- In Godot: Project → Reload Current Project, then play it once from the menu to the end.
- Export templates are already installed (Editor → Manage Export Templates shows 4.7.2).

## 1. Make the public "play" repo (once)
1. GitHub Desktop → File → New repository.
2. Name: `corpse-effect-play`. Local path: `C:\Users\tudor\Documents`. Tick "Initialize with a README". Create.
3. Click **Publish repository** and **untick "Keep this code private"**.

## 2. Web version (GitHub Pages)
1. Godot → Project → Export → pick **Web** (already set up: no threads, so it works on GitHub Pages and itch.io).
2. Export path is already `../corpse-effect-play/index.html`. Untick **Export With Debug**. Click **Export Project** → Save.
3. GitHub Desktop → repo `corpse-effect-play` → write "Web build" → Commit → Push.
4. On github.com → `corpse-effect-play` → Settings → Pages → Source: "Deploy from a branch" → Branch `main`, folder `/ (root)` → Save.
5. After 1–2 minutes the game is live at `https://docc20.github.io/corpse-effect-play/`.
6. Phones: open that link. Touch buttons appear automatically on phones and tablets. On Android Chrome you can "Add to Home screen" so it opens like an app.

Updating later: export again into the same folder, commit, push. The site updates in a minute.

## 3. Windows .exe (GitHub Release)
1. Godot → Project → Export → **Windows Desktop** (preset is set up: one single .exe, the game data is inside it).
2. Untick Export With Debug → Export Project. It goes to `C:\Users\tudor\Documents\builds\windows\CorpseAndEffect.exe`.
3. Right-click the .exe → Send to → Compressed (zipped) folder → name it `CorpseAndEffect-Windows.zip`.
4. github.com → `corpse-effect-play` → **Releases** (right side) → Draft a new release → tag `v1.0` → title "Corpse & Effect v1.0" → drag the zip in → **Publish release**.
5. Players: download the zip, unzip, double-click. Windows may say "Windows protected your PC" (the exe isn't signed): click **More info → Run anyway**. Put that line in the release notes.

## 4. Android app (.apk)
One-time setup (about 15 minutes):
1. Install **Java JDK 17** (Adoptium Temurin 17, the .msi installer).
2. Install **Android Studio**, open it once, let it download the SDK. Note the SDK path (usually `C:\Users\tudor\AppData\Local\Android\Sdk`).
3. Godot → Editor → Editor Settings → Export → Android: set **Java SDK Path** (e.g. `C:\Program Files\Eclipse Adoptium\jdk-17...`) and **Android SDK Path**.
Then each release:
4. Project → Export → Add... → **Android**. Name: Corpse & Effect. Package/Unique Name: `com.docc20.corpseeffect`. Screen orientation: Landscape.
5. Leave Export With Debug **ticked** the first time (Godot signs it with its own debug key, so no extra setup). Export Project → `CorpseAndEffect.apk`.
6. Add the .apk to the same GitHub Release (Edit release → drag it in → Update).
7. Players on Android: download the apk, allow "Install unknown apps" for their browser, install.
For the Google Play Store you'd need a release keystore and a $25 developer account. Not needed for the jam.

## 5. itch.io (best for the jam voting)
- Zip the contents of `corpse-effect-play` (index.html and the other files, not the folder) and upload as an HTML game, tick "This file will be played in the browser" and "Mobile friendly", viewport 1280 × 720, enable fullscreen button.
- Also upload the Windows zip and the APK as downloads on the same page.

## Controls (for the store page)
A/D or arrows move · W/Space jump (hold = higher) · R let go · Shift/K/J dash (from level 6) · Esc pause · F11 fullscreen. Phones: on-screen buttons.
