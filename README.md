# Corpse & Effect

A 2D platformer made for the **Bounce Back** game jam. Every death leaves your body behind as a trampoline. Fall, let go, and rise.

## Play the latest version

- **Browser / Android / iPhone / iPad:** [Play here](https://docc20.github.io/Corpse-Effect/). Touch controls appear automatically. Play with the phone sideways.
- **macOS (Intel and Apple Silicon):** download `CorpseAndEffect-macOS.zip` from [the latest release](https://github.com/DocC20/Corpse-Effect/releases/latest), extract it and open `Corpse & Effect.app`.
- **Windows:** download `CorpseAndEffect-Windows.zip` from [the latest release](https://github.com/DocC20/Corpse-Effect/releases/latest), extract it and run `CorpseAndEffect.exe`.

The Mac build is ad-hoc signed, but is not Apple notarized. If macOS blocks the downloaded app, review it and use **System Settings → Privacy & Security → Open Anyway**.

## Install on your phone

Open the browser game in its own tab. Android: use **Install / Offline** or the browser's **Install app** menu. iPhone/iPad: open in Safari, then **Share → Add to Home Screen**. Load the game once online before playing offline. The mobile version is an installable Web app; it is not an APK or App Store IPA.

## Upload to itch.io

Upload `CorpseAndEffect-Web.zip` from the latest release as an HTML game, tick **This file will be played in the browser**, enable **Mobile friendly** and the fullscreen button, and use a 1280 × 720 viewport. `index.html` is at the ZIP root. Add the Mac and Windows ZIPs as separate downloadable files and select their matching operating systems.

## Controls
- A / D or arrows: move
- W / Space / Up: jump (hold for higher)
- R: let go (leave a body you can bounce on)
- Shift / K / J: dash (unlocked on level 6)
- Esc: pause, F11: fullscreen
- Phones and tablets: on-screen buttons

## Team
- Enache Andrei Christian: lead developer, concept, systems programming
- Alex Ionita: lead developer, concept, gameplay programming
- Rosu Tudor: visual effects, graphics, cross-platform support
- Nita David: sound design, level design

## Repository layout
- `Play/` ready-to-play Windows and Mac builds
- `docs/` the browser version (served by GitHub Pages)
- the full Godot 4.7.2 project (open `project.godot` to edit it)

Asset credits are in `CREDITS.md`, and build instructions are in `PLATFORMS.md`.
