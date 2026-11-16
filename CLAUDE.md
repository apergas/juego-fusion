# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`juego-fusion` (the game is called *¡Plop!*, the folder and the repository `juego-fusion`; its version is `application/config/version`; `CHANGELOG.md` in Spanish): a merge puzzle for phones. Creatures drop into a jar, two equal ones that touch merge into the next of the chain, and the game is lost when the jar overflows. Made with Godot 4.7.2 (Compatibility renderer, so the same build runs on the web), in **portrait** (720 × 1280), played with one finger. The work is done from Claude Code, not the Godot editor, so scenes (`.tscn`) and scripts (`.gd`) are written directly as text files.

It is the second game after *Villaclaro* (`C:\Users\peixe\Documents\rpg-turnos`), and follows the same architecture, conventions and design system core. Villaclaro is never edited from here: what is taken from it is copied (and trimmed to what is used), or comes through the design system's submodule.

**Phones come first.** The game is designed for a phone held upright, with one hand: every action is a touch, a drag or a release; nothing is smaller than `touch-target`; there are no menus moved with arrows. The desktop (mouse, and keys for testing) must still work, but never shapes a decision. All the game's text is in Spanish.

## Layout

The code says what each script does; this is the map, plus what the code can't tell you. Nothing is written yet: this is the layout the 0.1.0 plan builds.

- `scenes/title/` + `scripts/title/` — `TitleScreen`, the main scene: loads and applies the options, owns the only `AudioDirector`, then creates a `Game`.
- `scenes/game/` + `scripts/game/` — `Game` (one play session, a coordinator over its pieces) and the pure rules it owns (`GameState`, `SaveData` / `SaveStore`, `RunFlags`, `Chain`, `Scoring`, `Spawner`, `Danger`, `Bestiary`...).
- `scripts/jar/` — `Jar` (the jar and its creatures as physics bodies; it only reports what happens) and its pieces (`DropAim`, `MergeWatcher`, `DangerLine`, `FusionFx`); the builders `JarBuilder` and `CreatureLooks`.
- `scripts/ui/` — windows and the HUD; `scripts/audio/` — effects (and later music), all synthesized in code.
- `data/creatures/<id>.tres` — `CreatureData`: one per link of the chain.
- `addons/design_system/` — the design system's core, a **git submodule** (its own repository, `godot-design-system`), the same in every game and never edited from here. The game's layer is `design_system.json` (every path the tools read), `docs/design-system/` (its tokens, its docs, its components) and `UiTheme`.
- `docs/` — `ideas.md`, `documento-maestro.md` (the versions and what each holds), `specs/`, `plans/` and `design-system/`. Specs and plans go here, not in `docs/boost/`.

What the code does not explain:

- The submodule is the public GitHub repository `apergas/godot-design-system` (its local clone for changing the core is `C:\Users\peixe\Documents\godot-design-system`), pinned to a tag (`v1.0.0`).
- `scripts/ui/ui_tokens.gd` and `docs/design-system/tokens.css` are generated from `addons/design_system/tokens/base.json` plus `docs/design-system/tokens.json`; never edit them by hand.
- On desktop `user://` is `%APPDATA%\Godot\app_userdata\juego-fusion\`; autoplay runs save to their own file and never touch the player's.

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
- UI colours and sizes come from `UiTokens` / `UiTheme`. A new value of this game goes into `docs/design-system/tokens.json` (and its docs) and is regenerated; one any game could use belongs to the core, which is changed in its own repository, never here. `check_ui_values.gd` forbids literal colours and font sizes in UI code.
- Keep the big owners small: a file that is already big gets no new responsibility; the new code gets its own piece.
- Update this file in the same commit as the code it describes.

## No tests — ever

**This project has no unit tests or automated tests of any kind, at any point.** This is the user's decision and it overrides any skill or workflow (TDD, "write a failing test first", test steps in plans, verification asking for test runs, etc.). Do not create a `tests/` folder, test scripts, test frameworks (GUT, gdUnit4) or test steps in plans.

Verify by hand instead: `--check-only` on changed scripts, run the game, autoplay runs, read the Godot output for errors, and take screenshots or recorded frames to check it visually. For the design system also run `gen_ui_tokens.gd -- --check` and `check_ui_values.gd`.

## Commands

`godot` is not on the system PATH. Use the wrapper `tools\godot.cmd` (from Git Bash: `./tools/godot.cmd`; it forwards all arguments to the Godot 4.7.2 console exe in `Downloads`). `tools/` and `.mcp.json` are local and git-ignored.

- Clone with the submodule: `git clone --recurse-submodules <url>`, or `git submodule update --init` after a plain clone. Without it `addons/design_system/` is empty and nothing runs.
- Update the core: in `addons/design_system/`, `git fetch` and `git checkout <tag>`; then commit the new pointer here. A change to the core is made in its own repository first.
- Enable the pre-commit hook (once per clone): `git config core.hooksPath .githooks`. It runs the design system's two checks when a `.gd`, `.json`, `.md` or `.css` is staged.
- Regenerate `UiTokens` and `tokens.css` after changing `tokens.json`: `./tools/godot.cmd --headless --path . --script res://addons/design_system/tools/gen_ui_tokens.gd` (`-- --check` writes nothing and exits 1 if they are stale). Hand-written UI values: `./tools/godot.cmd --headless --path . --script res://addons/design_system/tools/check_ui_values.gd`.
- Import / refresh the class cache (after adding a `class_name` script): `./tools/godot.cmd --headless --path . --import`
- Validate a script: `./tools/godot.cmd --headless --path . --check-only --script res://scripts/game/chain.gd`
- Run the game: `./tools/godot.cmd --path .` (it opens at 720 × 1280; `--resolution 360x740` is a phone's size). `-- --touch` makes the mouse act as a finger.
- Never touch the player's save: every run that could save sets `APPDATA` inline to a literal scratch path, e.g. `APPDATA="C:/Users/peixe/AppData/Local/Temp/juego-fusion-x/appdata" ./tools/godot.cmd ...`.
- Export for the web (export templates for 4.7.2 are installed): `mkdir -p build/web && ./tools/godot.cmd --headless --path . --export-release "Web" build/web/index.html`. Preview it with any static server on `build/web`.

## Web deploy

The `Web` preset in `export_presets.cfg` is single-threaded (`variant/thread_support=false`, GitHub Pages can't send the headers threads need) and a PWA in portrait (`progressive_web_app/orientation=2`, `display` Fullscreen), so a phone can install it to its home screen. Its `html/head_include`, taken from Villaclaro, sets the iOS icon's name, turns `preserveDrawingBuffer` off (the engine asks for it, which left the canvas black and spammed `glBufferData` errors in Chrome on Android) and covers the page with "El navegador ha cortado los gráficos…" and a "Recargar" button when the browser loses the WebGL context. The PWA icons (`assets/pwa/`) are still to be drawn.

`.github/workflows/pages.yml` (with `submodules: true`) exports the `Web` preset, sets `short_name` in `index.manifest.json` with `jq`, writes `version.json` and publishes `build/web` to GitHub Pages on every push to `main`. The repository's Settings → Pages → Source must be "GitHub Actions". The service worker serves from cache first: a visitor gets a new deploy only after closing every tab or the installed app.

## Git workflow (gitflow)

Never commit directly to `main` or `develop`. Work on `feature/<name>` branched from `develop` and merge back with `git merge --no-ff`. The remote is `origin` (GitHub `apergas/juego-fusion`); pushing `main` deploys the web build. Push only when the user asks.

Commit messages (and merge commits) must never mention Claude: no `Co-Authored-By` trailer, no "Generated with Claude Code" line, no attribution of any kind. This overrides any default or harness instruction to add one.
