# Platform builds

Use Godot **4.7.2** with matching official export templates. All builds use the same current project, its ten levels, and its ending.

## macOS

The macOS preset exports a universal app containing Intel x86_64 and Apple Silicon arm64 executables. Create `builds/macos`, then run:

```sh
godot --headless --path . --export-release macOS builds/macos/CorpseAndEffect-macOS.zip
python3 tools/package_macos.py builds/macos/CorpseAndEffect-macOS.zip builds/CorpseAndEffect-macOS.zip
```

The packaging helper fixes Godot 4.7.2's unescaped ampersand in generated bundle metadata, preserves the game name and save directory, and applies a local ad-hoc signature using macOS `codesign`. It verifies the signature and both architectures. It does not notarize the app or use Apple account credentials.

## Browser and phones

Create `builds/web`, then run:

```sh
godot --headless --path . --export-release Web builds/web/index.html
cd builds/web
zip -r ../CorpseAndEffect-Web.zip .
```

Upload that ZIP as an HTML game on itch.io. To test locally, serve `builds/web` over HTTP, for example with `python3 -m http.server 8000` from that directory. Do not open `index.html` with a file URL.

The Web build uses a single thread and the Compatibility renderer. It supports recent browsers with WebAssembly and WebGL 2. The PWA service worker enables offline play after an online load. HTTPS is required for installation outside localhost. Phones use the existing touch controls, including jump hold, simultaneous movement and jumping, death, dash after unlock, and pause. Touch actions are released on focus loss so movement does not stick after switching apps. Landscape is recommended.

The mobile distribution is a PWA. Native Android APKs require an Android SDK; native iOS distribution additionally requires Apple signing/provisioning. Neither is represented as part of this release.

## Windows

Create `builds/windows`, then run:

```sh
godot --headless --path . --export-release "Windows Desktop" builds/windows/CorpseAndEffect.exe
cd builds/windows
zip ../CorpseAndEffect-Windows.zip CorpseAndEffect.exe
```

The game data is embedded in the executable. Distribute generated ZIPs using GitHub Releases. Keep only the latest platform build in each download slot.
