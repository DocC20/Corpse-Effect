# Corpse & Effect: Game Plan

Game jam theme: **Bounce Back**. Voting jam, so the game must be playable in the browser (itch.io web export).

## Core idea
2D platformer. Every death leaves your body behind as a **Bodypad** (a trampoline). You solve levels by dying in the right places and bouncing off your past selves.
- R = die on purpose. Spikes and falling also kill you.
- Bodies glow orange, squish, and stack. Max 15 at once (oldest fades).

## Story / vibe arc
Starts as a **happy fantasy obby**, slowly turns **dark and gloomy** (Hollow Knight / Little Nightmares feel).
Art starts **pixelly** and becomes **more realistic** level by level (Atmosphere `realism`: 0 → 1).
The journey climbs a mountain (Celeste-like climbing feeling, original design) and goes into a cave.

Current game: **10 levels + an ending scene** (boss fight skipped for now).

| Level | File | Place | Style (`ground_style`) | Realism | New idea in this level |
|---|---|---|---|---|---|
| 1 | main.tscn | Grassy meadow, day | plains | 0.0 | Tutorial: move, jump, R, bounce |
| 2 | level2.tscn | Withered meadow | withered | 0.03 | Dry animated plants |
| 3 | level3.tscn | Highland, **night falls halfway** | highland | 0.06 | Night event |
| 4 | level4.tscn | Mountain path at night | grassrock | 0.08 | Bridge spike pits with bodies, edge-pad leap |
| 5 | level5.tscn | Cliffs at night | hills | 0.1 | Bottomless chasms (no body stays), roots hanging above |
| 6 | level6.tscn | Windy ridge | hills | 0.12 | **Dash unlocked** (crystal pickup), bounce + dash |
| 7 | level7.tscn | Cave mouth (old Level 4) | hills → cave | 0.16 | Into the mountain |
| 8 | level8.tscn | Deep cave (old Level 5) | cave | 0.2 | Body stacking |
| 9 | level9.tscn | Sunken ruins | ruins (Hollow Echo) | 0.3 | Crystal ceilings: keep low, dash |
| 10 | level10.tscn | Mossy cavern | moss (Mossy Cavern) | 0.5 | Thorns, light shaft to the surface |
| End | ending.tscn | Meadow at dawn | plains | 0.2 | Night turns to day, your fallen selves rise as lights, title, credits |

Small steps between levels (realism and `fx` grow slowly, mood carried between levels with fade transitions). Later: 5 more levels and the Level 15 boss.

## Art direction notes from the user
- Hollow Knight + Little Nightmares: gloomy with a little colour.
- Grass: grassy vibe, but the player must stand on a real platform edge, not on top of the grass.
- Don't modify the asset files; change the vibe with shaders/lighting instead.
- Tone down realism in the first levels (stylize shader).
- Spikes must fit the world: thorny roots outdoors (from the rock sheet), crystal stalagmites in caves (from Caverns). Dying on them plays a sink-in animation and the body stays embedded.
- Grass sits at knee height behind the player; you stand on a solid platform edge.
- Transition must be gradual: grass → withered grass → grass + rocks → full rocks → (sudden) cave.
- Checkpoints match the world: big tree on grass, standing stone on rock, glowing crystal in the cave.
- Night look based on the early pixel demo: big moon with a soft halo, navy night palette, twinkling stars, stepped (pixel) lighting and film grain at low realism, combined with the fog of the later levels.
- Bodypad light in the cave: bigger, softer, flickering, with a warm bounce glow (scales with realism).
- Cave inspiration: blue icy caves, stalactites, distant castle silhouette (mood reference only).
- Text: small, crisp, nice font (Lora), animated, stays visible until the player passes that part.
- No AI-generated art or sounds (jam rule). Use team art or free licensed packs, and keep `CREDITS.md` updated.

## Assets in the project
- `assets/country`: Country Platform (ansimuz, CC0). Plains/withered levels.
- `assets/rocks`: rock/moon tileset (source TBC). Hills levels.
- `assets/caverns`: Caverns (ansimuz, CC0). Cave levels.
- `assets/kenney/light`: Kenney Light Masks (CC0). Light textures.
- Not used yet: Kenney Fantasy UI Borders (prompt frames, menus), Kenney Minimap Pack.
- `fonts`: Lora (OFL).

## To do / not done yet
- [x] Replace the player sprite `wanderer_32x32.png` with the Hollow Echo character (the old file is no longer used and can be deleted).
- [ ] Confirm source + license of the rock/moon tileset for credits.
- [ ] Playtest levels 1–5 and tune jumps (untested: level 3 cliff bounce + dark gap, level 5 body stack vs WallC).
- [x] End screen after level 5 (total deaths, press R to play again).
- [x] Main menu (cartoony) and Esc pause menu that gets higher quality and scarier each level (Kenney UI borders).
- [x] Fade transitions between levels; end screen returns to the main menu.
- [ ] Sound effects (user has them) — next.
- [ ] More mountain levels before the cave.
- [ ] Sound effects and music (no AI; Freesound CC0, Sonniss, own recordings).
- [ ] Web export to itch.io (Thread Support off) and test shaders/lights in the browser.
- [ ] Check the Godot debugger for errors (send a screenshot of Debugger → Errors).
- [ ] More levels after the cave, once the user sends references.
- [ ] itch.io page: cover image, GIF, description, credits, AI-use disclosure if the jam asks.

## Working rules
- After Claude edits files, use Project → Reload Current Project and don't save first, or Godot overwrites the changes.
- No comments in code.
- Levels are built from plain blocks; the Atmosphere node skins them automatically per style.

## Controls
- A/D or arrows: move. W/Space/Up: jump (hold for higher). R: let go (leave a body). Esc: pause.
- Shift, K or J: dash (from Level 6). F11 or Alt+Enter: fullscreen.
- Touch buttons (< > ^ R, >> after the dash, II pause top-left) only appear on phones and tablets (Settings → Touch buttons: Auto / On / Off). Tutorial text swaps to touch wording on phones.

## Change log
### Session 1 (Nov 14)
- Core mechanic: R to die, Bodypads, spikes, checkpoints, goal flags, deaths counter, smooth movement (coyote time, jump buffer).
- Tutorial prompts with Lora font, typing animation, stay until passed.
- Atmosphere system: mood (happy → gloomy), realism (pixel → smooth), ground styles, fog, particles, vignette, lights, night event, moon.
- Levels 1–5 built and linked. Level 5 ends the game with an end screen.
- Assets: Country Platform + Caverns (ansimuz, CC0), Kenney Light Masks/UI Borders/Minimap (CC0), rock/moon tileset (source TBC).
- Renamed the game to **Corpse & Effect**.
- Fixes: double death on respawn, bodies landing on the head, Godot overwriting edits, stray grass patch on the tree.
- Session 1 (later): grass moved to knee height behind the player (walk on the path), cave spikes recut as clear crystal spikes with gaps, bodies drawn in front of spikes, real cave mouth (rock arch, roots, darkness inside), cave ceilings show their edge underneath, fixed the empty dropdown parse error, fixed controls being re-added on every level load, fixed screen shake in wide levels.
- Session 1 (polish): early levels toned down (`fx`), smaller realism steps, mood carried between levels, Level 3 kept grassy (highland), taller trees, solid-looking rock (no cyan line / hollow frame), removed the confusing hanging roots at the cave mouth, flag replaced with a glowing wisp, new main menu (`menu.tscn` is now the start scene), Esc pause menu.
- Mobile/itch: touch controls (only on touchscreens: < > ^ R and pause), performance pass (shaders/lights only update when the mood changes, cheaper fog and half the particles on web/mobile). To do: touch-friendly wording in tutorial prompts, export Web + Windows builds to itch.io.
- Fixes from playtest screenshots: Level 3 stays moody (withered tint 0.45, mood 0.12-0.25), softer grass block edges (side shading + grass overhang), Level 3 cliff now grassy (rock only near caves), Level 5 stacking wall now textured (was a blue box), smoother cave mouth (wider darkness fade), removed cyan dots from rock edges.

### Session 2 (Nov 14)
- Phase 1: Game autoload (save file, settings, music crossfade, loading screen), main menu (New Game / Continue / Settings / Quit), settings in the pause menu. Fixed the music loop parse error. New checkpoint sound.
- New player: Hollow Echo hooded character (idle, run, jump animations). Orange cloak before the dash, blue cloak after picking up the dash crystal on Level 6. Dash leaves blue afterimages.
- Bodies now lie down sideways (fit the bounce pad).
- Dash: Shift/K/J, 0.15 s, no gravity while dashing, one per air time, resets on landing or bouncing off a body. Saved in the save file.
- Footsteps per surface (grass, dry leaves, gravel, stone, mud) synced to the run animation; jump and landing sounds (Footsteps SFX Free, CC BY 4.0).
- New world styles: `ruins` (Hollow Echo tiles, background layers, vines, crystals) and `moss` (Mossy Cavern blocks, thorns, hanging plants, hills, Brown Cave rocks, glowing flowers). Animated plants on withered, highland, rock and moss ground.
- Levels 4, 5, 6, 9, 10 are new; old Levels 4 and 5 became Levels 7 and 8. Level 10 ends at a light shaft and leads to the ending scene.
- Ending scene instead of a plain "you made it" text.
- Not playtested yet: all new levels. Still wanted: real sounds for bounce, death, dash whoosh, menu click.

### Session 2 (polish)
- Checkpoints remade: amber crystal on rock levels (Hollow Echo), trees sway, crystals float and pulse, unlit until reached, then a flash, light ring, burst and lasting sparkles.
- HUD redone in the same Lora style as the tutorial text, top-right, no boxes. Grows per level: deaths only → level name + line → roman numeral, diamond ornament, bodies count, dash crystal → red tint, "Fallen", slight flicker. Death number pops when it changes. Level title cards use the same style.
- Fullscreen: F11 / Alt+Enter / Settings. Note: inside the Godot editor's embedded Game view fullscreen can't change; it works in the exported game (or turn off "Embed Game" in the Game tab).
- Touch controls only on real phones/tablets (laptop touchscreens no longer show them).
- More animation: dust puffs (run, jump, land, dash, bounce), grass bends when walked through, cave/ruin/moss drips, small shake on very hard landings.
- Export presets: Web → ../corpse-effect-play/index.html, Windows Desktop → single .exe in ../builds/windows. See RELEASE_GUIDE.md.

### Session 2 (final touches)
- Ending: bodies rain from the sky as ragdolls (torso + legs on a joint), tumble into the grass, then each turns into a rising light.
- Team credits added to the ending and CREDITS.md.

## Roadmap to the full game (15 levels)

### Phase 1 — Menus, saving, sound
- Loading screen (PSX UI style, tips, progress bar).
- Main menu: **New Game**, **Continue** (load save), **Settings**, Quit.
- Save file (`user://save.cfg`): furthest level reached, total deaths, settings. New Game asks before overwriting.
- Settings: music volume, sound volume, fullscreen, screen shake on/off, touch controls on/off.
- Audio manager: music crossfades with the mood; SFX for checkpoint and goal from the user's files. Still needed: jump, land, death/squish, bounce, dash, menu click (Kenney CC0 audio packs are a good source).

### Phase 2 — Player
- Dash ability (unlocked around Level 5): short burst, resets on landing or bouncing off a body.
- Replace the AI placeholder sprite (`wanderer_32x32.png`).
- The character improves as the game goes on: simple pixel look early, more detailed and smoother animation later (Hollow Echo character early, Mossy Cavern character late, if the user downloads them).

### Phase 3 — Levels 6–14
| Level | Place | Art |
|---|---|---|
| 1–3 | Meadow → withered meadow → highland (night falls) | Country Platform |
| 4 | Mountain path at night | Country + rocks |
| 5 | Cliffs at night, **dash unlocked** | rocks |
| 6 | Windy ridge | rocks |
| 7 | Cave mouth | rocks → Caverns |
| 8–9 | Purple caves, crystal tunnels | Caverns |
| 10–11 | Underground blue-brick ruins | Hollow Echo (16×16) |
| 12–13 | Mossy cavern (big realism step) | Mossy Cavern (HD) |
| 14 | The deep brown cave | BrownCave (HD) |
| 15 | **Boss fight** | mix |
(Current Levels 4–5 get reworked into this order.)

### Phase 4 — Level 15 boss
- Boss idea: it can only be hurt with your past selves (e.g. bounce off bodies to reach its weak point, or drop bodies onto it). Three phases, gloomiest and most realistic level.

### Phase 5 — Polish and release
- Playtest every level, tune jumps, touch-friendly tutorial text.
- Web + Windows export, itch.io page, credits, AI-use disclosure if the jam asks.

### Assets to get / confirm
- Download and send: Hollow Echo (hollowdolphin), Mossy Cavern (maaot), 2D BrownCave (maaot).
- Confirm source + license: grass panorama image, Fly to Freedom pack, Dark Fantasy Ambient Strings, PSX UI itch page (rohhsa), the two Freesound sounds, Purrple Cat track.
- Hollow Echo and Mossy Cavern don't allow redistributing the files → make the GitHub repo **private**.
