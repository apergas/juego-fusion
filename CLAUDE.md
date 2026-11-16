# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`juego-fusion` (the game is called *¡Plop!*, the folder and the repository `juego-fusion`; its version is `application/config/version`; `CHANGELOG.md` in Spanish): a merge puzzle for phones. Creatures drop into a jar, two equal ones that touch merge into the next of the chain, and the game is lost when the jar overflows. Made with Godot 4.7.2 (Compatibility renderer, so the same build runs on the web), in **portrait** (720 × 1280), played with one finger. The work is done from Claude Code, not the Godot editor, so scenes (`.tscn`) and scripts (`.gd`) are written directly as text files.

It is the second game after *Villaclaro* (`C:\Users\peixe\Documents\rpg-turnos`), and follows the same architecture, conventions and design system core. Villaclaro is never edited from here: what is taken from it is copied (and trimmed to what is used), or comes through the design system's submodule.

**Phones come first.** The game is designed for a phone held upright, with one hand: every action is a touch, a drag or a release; nothing is smaller than `touch-target`; there are no menus moved with arrows. The desktop (mouse, and keys for testing) must still work, but never shapes a decision. All the game's text is in Spanish.

## Layout

The code says what each script does; this is the map, plus what the code can't tell you. Version 0.1.0 built it ([plan](docs/legacy/plans/2026-11-16-version-0-1-0.md)).

- `scenes/title/` + `scripts/title/` — `TitleScreen`, the main scene: loads and applies the options, owns the only `AudioDirector`, then creates a `Game`.
- `scenes/game/` + `scripts/game/` — `Game` (one play session, a coordinator over its pieces) and the pure rules it owns (`GameState`, `SaveData` / `SaveStore`, `RunFlags`, `Device`, `GameOptions`, `Profile`, `Chain`, `Spawner`, `Scoring`, `Danger`, `Bestiary`, `RoundSnapshot`, `JarSpec`, `CreatureData`) and its pieces (`GameAutoplay`).
- `scripts/jar/` — `Jar` (the jar and its creatures as physics bodies; it only reports what happens) and its pieces (`DropAim`, `MergeWatcher`, `DangerLine`, `FusionFx`, `CreatureBody`); the builders `JarBuilder`, `CreatureLooks` and `LowPoly`.
- `scripts/ui/` — windows (`ModalWindow` and its `EndWindow`, `PauseWindow`, `BestiaryWindow`, `OptionsWindow`), the `Hud` with its `PauseButton`, `CreatureView`, `UiTheme`, `DisplaySettings` and the generated `UiTokens`; `scripts/audio/` — effects (and later music), all synthesized in code.
- `scripts/tools/` — offline tools, excluded from the export: `pwa_icons.gd`.
- `data/creatures/<id>.tres` — `CreatureData`: one per link of the chain (`look` picks which features `CreatureLooks` adds to the faceted ball: gota, slime, slime_mejillas, seta, murcielago, lobo, golem, dragon; `color` is the body and its particles, `accent` the features).
- `assets/fonts/` — Baloo 2 (display) and Nunito (ui), variable, OFL, copied from Villaclaro; `assets/CREDITS.md` says where every asset comes from.
- `addons/design_system/` — the design system's core, a **git submodule** (its own repository, `godot-design-system`), the same in every game and never edited from here. The game's layer is `design_system.json` (every path the tools read), `design/` (its tokens, its docs, its components and the screens' mockup) and `UiTheme`.
- `addons/gut/` — GUT 9.7.1 (MIT), the unit-test framework, vendored as released and never edited; its plugin is not enabled. `tests/` — the unit tests of the pure rules and the data (see Tests), `tests/<folder>/test_<script>.gd` as in `scripts/`, and `tests/fixtures.gd` their shared builders; `.gutconfig.json` — GUT's settings. The three are left out of the export.
- `docs/` — `ideas.md`, `documento-maestro.md` (the versions and what each holds), `specs/` and `plans/` (the work under way) and `legacy/` (the record: every spec and plan of a version already published moves to `legacy/specs/` and `legacy/plans/`, and the master document links them there). Specs and plans go here, not in `docs/boost/`.
- `design/` — the game's design-system layer: `tokens.json` (its tokens and the values it gives the core's), the generated `tokens.css`, `2-fundamentos.md` (every token of the layer documented), `4-accesibilidad.md` (its contrast pairs), `components/bundle.css` and `maqueta.html` (the screens' mockup). Left out of the export.

What the code does not explain:

- A creature is discovered (`Bestiary`) the first time it is in the jar, dropped or made by a merge, in silence (no notice, no sound, nothing at the end: only the Bestiario shows it); it is saved at once and the autoplay prints `Nueva:`. `--autoplay-menu` tours the title's screens before the game (`TitleScreen._tour()`, in its `#region Autoplay`).
- The submodule is the public GitHub repository `apergas/godot-design-system` (its local clone for changing the core is `C:\Users\peixe\Documents\godot-design-system`), pinned to a tag (`v1.0.0`).
- `scripts/ui/ui_tokens.gd` and `design/tokens.css` are generated from `addons/design_system/tokens/base.json` plus `design/tokens.json`; never edit them by hand.
- On desktop `user://` is `%APPDATA%\Godot\app_userdata\juego-fusion\`. The one save file is `save.json` (`SaveData` version 2: the record, the discovered ids, the options and `"round"`, the round in progress the player left, a `RoundSnapshot` kept in `Profile.saved_round`, `{}` for none; a version 1 save, 0.1.0's, loads as a 2 without a round). Spawner's generator goes in it as its state, a String (JSON would round 64 bits); a broken round refuses the whole file. Autoplay runs save to `save_autoplay.json` and never touch the player's. A damaged file or one of an unknown version is ignored (nothing of it is applied) and kept once as `save.json.bak` before the next save overwrites it.
- The whole interface is drawn `DisplaySettings.UI_SCALE` (1.25) times bigger than its tokens on every device (`content_scale_factor`): HUD offsets and window sizes are in those units.
- The jar's numbers are the rule `JarSpec`: floor at y 0, walls at x ±3.0, danger line at 7.4, the waiting creature at 8.0; the orthographic camera (`KEEP_HEIGHT`) always shows 7.6 × 13.5 m around y 5.1 (`camera_size()`), so the HUD has 3.2 m of room above the jar on any phone.
- A creature in the jar is a `CreatureBody` (`RigidBody3D`, a sphere of its radius) locked on Z and turning only around it (its figure stays upright: `CreatureBody._process`); the waiting creature at the top is only a figure (`DropAim`), not a body. Touches arrive as mouse events (`emulate_mouse_from_touch`), so `DropAim` reads only the mouse; a Control under the finger (the pause button) takes the event first.
- `MergeWatcher` polls each creature's `get_colliding_bodies()` every physics frame (contact monitor on) and marks both of a pair `merged` at once; `Jar.merge()` takes the two out of the physics space at once (`remove_child`) and the new creature's collider grows from 0.6 to its radius in 0.2 s (`CreatureBody.grow()`), so a merge pushes instead of kicking.
- Flags (all read by `RunFlags`): `--autoplay` (rounds that play themselves; the title is skipped and the run quits at the end), `--autoplay-games=N`, `--autoplay-save`, `--autoplay-menu`, `--seed=<n>` (the first round's `Spawner` seed; each next round adds 1) and `--touch`. Physics is not exactly the same between runs, even with a seed.
- How to run, record and measure autoplay is the project skill `fusion-autoplay` (`.claude/skills/fusion-autoplay/SKILL.md`). A round on autoplay ends by itself one second after the loss; `--autoplay-games=N` prints the averages after the N rounds and quits.
- The danger: `Game` asks `Jar.highest_top(JarSpec.SETTLE_TIME)` every physics frame and keeps `Danger`'s count in `GameState.danger_time`; at the loss `Jar.freeze_all()` freezes every body and the record is saved before the `EndWindow` opens.
- A creature in the interface (the HUD's «Siguiente», the bestiary) is a `CreatureView`: its own `SubViewport` with its own 3D world, lit by `JarBuilder.light()`, transparent behind.
- Phone-shaped frames: `--write-movie` ignores `--resolution`; a temporary `override.cfg` (git-ignored) with a 720 × 1480 viewport gives the canvas a 360 × 740 phone gets (see the `fusion-autoplay` skill). Delete it after the run.
- The pause pauses the whole tree (`get_tree().paused`): the physics stops with it, and so do the game's clock (round time, drop wait, combo window, danger count; all in `Game._physics_process`). Every `ModalWindow` (end, pause, bestiary, options) keeps processing (`PROCESS_MODE_ALWAYS`), and so does the `AudioDirector`; Esc or the scrim is «volver» (Seguir in the pause; nothing in the end window). The pause's Opciones opens the same `OptionsWindow` over it (the pause stays underneath, hidden while Opciones is open); `Game` opens the pause only while the round is on (the HUD button sits under every window's scrim).
- The options are applied at once (no Aceptar) and saved in the same `save.json` as the record and the bestiary.

## Conventions

- Before adding or moving GDScript, use the global skill `structuring-godot-code`. It says where new code goes (rule, builder or node) and when a big owner gets a separate piece instead of growing.
- Three kinds of script:
  - **Pure rules** (`RefCounted` / `Resource`) never touch nodes; scenes only play their results back.
  - **Constructors** are static, build nodes or render resources for their caller and keep no game state. Their header starts with `## Constructor:` and says what they build.
  - **Nodes** are the scenes and the live pieces their owners create.
- Scenes and scripts are written as text. The `.tscn` files only hold the root node and its script; every other node is created in code.
- No autoloads: `TitleScreen` owns the `AudioDirector` and the options, `Game` owns the session state, and both pass them on explicitly (`setup()`, `set_audio()`).
- `Game` is a coordinator: each job of a session is a piece, a `Node` child of `Game`, that gets what it needs in `setup()`. A piece never stores its owner. What it must have another piece do is a public `Callable` field that `Game` wires; what it only reports is a signal that `Game` connects. Signals up, calls down.
- The physics engine moves the creatures; the jar only reports (two equal creatures touching, a creature over the line). The rules decide what a merge gives, the points and when the game is lost. `Game` owns the game's clock and the combo.
- Command-line flags are read only through `RunFlags`; no other script calls `OS.get_cmdline_user_args()` or spells a `"--..."` string, except the offline tools of `scripts/tools/`.
- The autoplay part of a class sits together, in its own piece (`GameAutoplay`) or in a `#region Autoplay` block at the end of the class. No autoplay function that is still called is ever removed: autoplay is the project's way of checking the game. Physics is not exactly the same between runs, so balance is read from the averages of many autoplay games, never from one.
- UI colours and sizes come from `UiTokens` / `UiTheme`. A new value of this game goes into `design/tokens.json` (and its docs, in `design/`) and is regenerated; one any game could use belongs to the core, which is changed in its own repository, never here. `check_ui_values.gd` forbids literal colours and font sizes in UI code.
- Keep the big owners small: a file that is already big gets no new responsibility; the new code gets its own piece.
- Update this file in the same commit as the code it describes.

## Tests

Unit tests (GUT, `tests/`) check the **pure rules** and the **data**; autoplay stays the check of the whole game. A version runs both; tests never replace an autoplay run. The user decided on 2026-11-16 that this game has them: tests that help find bugs, not coverage numbers.

- What: the rules of `scripts/game/` that touch no node (`RefCounted` / `Resource`) and the coherence of `data/creatures/` (`tests/data/`). Never nodes, scenes, constructors, UI, visuals, sound or files: no test calls `SaveStore`, `FileAccess` or writes `user://`. No test changes a loaded resource (`data/*.tres`): it works on `GameState.new()`, `Profile.new()` or objects made in the test.
- When: **every development ends with its tests.** A change to a pure rule adds or updates its tests in the same version; a new rule script comes with its `tests/<folder>/test_<script>.gd`; a bug in a rule is fixed with a test that fails without the fix; a data or balance change that moves a value a test pins on purpose changes that test in the same commit. A failing test is a bug in the game or in the test: never loosen it to make it pass.
- How: each file `extends GutTest`, starts with a `##` header and has no `class_name`; each test is `func test_<what must hold>() -> void:`; shared builders, if they are ever needed, go in `tests/fixtures.gd`. Randomness goes through a seeded `RandomNumberGenerator` passed in (`Spawner.pick()` takes one): a test checks bounds and orderings over many seeds, never one seed's numbers. Tests use `RunFlags`' constants, never a `"--..."` string.
- Where they run: at the end of every task that touches a rule or data, at the end of every version, in `tests.yml` on every push to `develop` and before every Pages deploy (`pages.yml`). Not in the pre-commit hook (the design system's).
- Plans may have test steps for rules and data only; never test steps for nodes, scenes or visuals.

Everything else is still verified by hand: `--check-only` on changed scripts, run the game, autoplay runs, read the Godot output for errors, and take screenshots or recorded frames to check it visually. For the design system also run `gen_ui_tokens.gd -- --check` and `check_ui_values.gd`.

## Commands

`godot` is not on the system PATH. Use the wrapper `tools\godot.cmd` (from Git Bash: `./tools/godot.cmd`; it forwards all arguments to the Godot 4.7.2 console exe in `Downloads`). `tools/` and `.mcp.json` are local and git-ignored.

- Clone with the submodule: `git clone --recurse-submodules <url>`, or `git submodule update --init` after a plain clone. Without it `addons/design_system/` is empty and nothing runs.
- **Updating the design system core.** A change to the core is made in its own repository first (`apergas/godot-design-system`, tagged `vX.Y.Z`). Every week Dependabot (`.github/dependabot.yml`, `gitsubmodule`) opens a pull request to `develop` when the core has a newer commit or tag: it only moves the `addons/design_system` pointer, and `tests.yml` runs GUT and both design-system checks on it. It is merged by hand after looking at it (never auto-merged); if it needs regenerated files, update by hand instead: `git -C addons/design_system fetch --tags`, `git -C addons/design_system checkout <tag>`, regenerate (`./tools/godot.cmd --headless --path . --script res://addons/design_system/tools/gen_ui_tokens.gd`), run `gen_ui_tokens.gd -- --check` and `check_ui_values.gd` (both exit 0), then commit the new pointer together with `scripts/ui/ui_tokens.gd` and `design/tokens.css` on a `feature/` branch. After a pull that moved the pointer, in any other clone: `git submodule update`. Dependabot's `target-branch` is `develop`, never `main` (pushing `main` publishes to Pages). The core tags each of its releases `vX.Y.Z`; each `CHANGELOG.md` entry from 0.2.0 on says which core it ships with, «design system vX.Y.Z», from `git -C addons/design_system describe --tags` (if the pointer is not on a tag, the short commit instead: `git -C addons/design_system rev-parse --short HEAD`).
- Enable the pre-commit hook (once per clone): `git config core.hooksPath .githooks`. It runs the design system's two checks when a `.gd`, `.json`, `.md` or `.css` is staged.
- Regenerate `UiTokens` and `tokens.css` after changing `tokens.json`: `./tools/godot.cmd --headless --path . --script res://addons/design_system/tools/gen_ui_tokens.gd` (`-- --check` writes nothing and exits 1 if they are stale). Hand-written UI values: `./tools/godot.cmd --headless --path . --script res://addons/design_system/tools/check_ui_values.gd`.
- Import / refresh the class cache (after adding a `class_name` script): `./tools/godot.cmd --headless --path . --import`
- Validate a script: `./tools/godot.cmd --headless --path . --check-only --script res://scripts/game/chain.gd`
- Run the unit tests (GUT reads `res://.gutconfig.json`; seconds; exit 0, or 1 when a test fails; an `ERROR` line in its output is a failure too, unless a test expects it with `assert_push_error` / `assert_engine_error` (GUT counts those; an unexpected one fails the run); GUT writes temporary files to `user://`, so set `APPDATA` to a scratch path in the same command): `APPDATA="C:/Users/peixe/AppData/Local/Temp/juego-fusion-x/appdata" ./tools/godot.cmd --headless --path . --script res://addons/gut/gut_cmdln.gd`. One file: add `-gtest=res://tests/game/test_chain.gd`.
- Run the game: `./tools/godot.cmd --path .` (it opens at 720 × 1280; `--resolution 360x740` is a phone's size). `-- --touch` makes the mouse act as a finger.
- Never touch the player's save: every run that could save sets `APPDATA` inline to a literal scratch path, e.g. `APPDATA="C:/Users/peixe/AppData/Local/Temp/juego-fusion-x/appdata" ./tools/godot.cmd ...`.
- Export for the web (export templates for 4.7.2 are installed): `mkdir -p build/web && ./tools/godot.cmd --headless --path . --export-release "Web" build/web/index.html`. Preview it with any static server on `build/web`.

## Web deploy

The `Web` preset in `export_presets.cfg` is single-threaded (`variant/thread_support=false`, GitHub Pages can't send the headers threads need) and a PWA in portrait (`progressive_web_app/orientation=2`, `display` Fullscreen), so a phone can install it to its home screen. Its `html/head_include`, taken from Villaclaro, sets the iOS icon's name, turns `preserveDrawingBuffer` off (the engine asks for it, which left the canvas black and spammed `glBufferData` errors in Chrome on Android) and covers the page with "El navegador ha cortado los gráficos…" and a "Recargar" button when the browser loses the WebGL context. The PWA icons (`assets/pwa/icon_144.png`, `icon_180.png`, `icon_512.png`, also the project's icon) are the Gota de rocío over the game's backdrop, rendered by `scripts/tools/pwa_icons.gd` (run it **not** headless: `./tools/godot.cmd --path . --script res://scripts/tools/pwa_icons.gd`, then `--import`) after the Gota's look or the palette changes; the preset's and the boot splash's background colour is `scene-bottom`.

`.github/workflows/tests.yml` runs the unit tests and the design system's two checks on every push to `develop`, on every pull request to `develop` and by hand, then plays two short autoplay rounds (Godot 4.7.2 without export templates); `.github/workflows/pages.yml` (with `submodules: true`) runs them too after the import, so a failing test stops the deploy, then exports the `Web` preset, sets `short_name` in `index.manifest.json` with `jq`, writes `version.json` and publishes `build/web` to GitHub Pages on every push to `main`. The repository's Settings → Pages → Source must be "GitHub Actions". The service worker serves from cache first: a visitor gets a new deploy only after closing every tab or the installed app.

## Git workflow (gitflow)

Never commit directly to `main` or `develop`. Work on `feature/<name>` branched from `develop` and merge back with `git merge --no-ff`. The remote is `origin` (GitHub `apergas/juego-fusion`); pushing `main` deploys the web build. Push only when the user asks.

Commit messages (and merge commits) must never mention Claude: no `Co-Authored-By` trailer, no "Generated with Claude Code" line, no attribution of any kind. This overrides any default or harness instruction to add one.
