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

| Level | Place | Time | Style (`ground_style`) | Realism | Status |
|---|---|---|---|---|---|
| 1 Tutorial | Grassy plains | Day | plains | 0.0 | Built |
| 2 | Withered grass plains | Day | withered | 0.03 | Built |
| 3 | Grassy rocks → full rocks | Day, **night falls halfway** | grassrock → hills | 0.4 | Being reworked |
| 4 | Outside at night → **cave entrance** → cave | Night | hills → cave | 0.65 | Being reworked |
| 5 | Deep cave | Darkest | cave | 0.85 | Built |
| 6+ | Graphics evolve from the cave onward | ? | ? | → 1.0 | User will send more references |

**Plan for 10–15 levels:** small steps between levels (realism +~0.03–0.05 per level, effects `fx` grow slowly, mood carried over between levels with fade transitions). More mountain/highland levels will be added **before** the cave, so the current Levels 4–5 will move later. Don't lean into the rocky look too much.

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
- [ ] Replace the player sprite `wanderer_32x32.png` (AI-made placeholder, must not ship).
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
