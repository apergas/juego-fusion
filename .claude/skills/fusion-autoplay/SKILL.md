---
name: fusion-autoplay
description: Use when running ¡Plop! on autoplay or headless, recording frames to check visuals (also at a phone's size), checking the save round trip, touring the menus, or measuring the balance (points, biggest creature, round length) over many rounds in this project.
---

# ¡Plop! on autoplay

Run every command from the project root in Git Bash with `./tools/godot.cmd` (see CLAUDE.md, Commands). **Every run sets `APPDATA` inline to a scratch folder, never the real one**: autoplay saves to `save_autoplay.json`, but a run without `--autoplay` uses the player's `save.json`. Make the folder first and delete it afterwards:

```bash
S=C:/Users/peixe/AppData/Local/Temp/juego-fusion-run; mkdir -p $S/appdata
```

Physics is not exactly the same between runs, even with `--seed`: read the balance from the averages of many rounds, never from one.

## Runs

- **One round, headless** (ends by itself one second after the round is lost; prints `Música: jar (N ms)` (once, first), each `Suelta:`, `Fusión:`, `Nueva:`, `Cambia:`, `Rompe:` and the `Partida: N puntos, máxima <id>, M min S s` line, followed by `Ayudas: N Romper, M Cambiar`): `APPDATA="$S/appdata" ./tools/godot.cmd --headless --path . --fixed-fps 60 --quit-after 60000 -- --autoplay`
- **A fixed seed** for the Spawner (the first round's; each next round adds 1): add `--seed=<n>`.
- **Balance, 20 rounds** (the spec's check: a mean of 2 to 8 minutes and creature 6 in most rounds): `time APPDATA="$S/appdata" ./tools/godot.cmd --headless --path . --fixed-fps 60 --quit-after 1500000 -- --autoplay --autoplay-games=20 > $S/log.txt 2>&1`, then `grep -E "^(Partida|Media)" $S/log.txt` and `grep -E "ERROR|WARNING" $S/log.txt` (nothing but, at most, Jolt's job-system warning). The last line is `Media de 20 partidas: <points> puntos, máxima <id> (<n> de 20), <time>, 6 o más en <n> de 20`, then `Ayudas de media: <x.x> Romper, <x.x> Cambiar` (the helps make rounds longer, hence the bigger `--quit-after`).
- **Save round trip:** add `--autoplay-save` to a one-round run; the `Guardado:` and `Cargado:` lines must be identical.
- **The kept round** (`--autoplay-resume`): add it to a one-round run; 20 s in it prints `Tarro guardado: …` and `Tarro leído: …` (identical) and `Tarro seguido: N criaturas, P puntos`, then the round goes on to its `Partida:` line.
- **Without the title:** `res://scenes/game/game.tscn` before `--`, e.g. `APPDATA="$S/appdata" ./tools/godot.cmd --path . res://scenes/game/game.tscn -- --autoplay`.
- **Phone layout on the desktop:** `APPDATA="$S/appdata" ./tools/godot.cmd --path . --resolution 360x740 -- --touch` (the mouse acts as a finger).

## Frames

`--write-movie` writes one PNG per frame (720 × 1280; at `--fixed-fps 10`, ten a second) and ignores `--resolution`. Not headless. Look at frames with the Read tool, then delete the folder.

- **A round:** `APPDATA="$S/appdata" ./tools/godot.cmd --path . --write-movie $S/frames/f.png --fixed-fps 10 --quit-after 6000 -- --autoplay --seed=5`. It stops one second after the loss: with `N` the last frame, `N-5` is the end window, `N-40` to `N-12` the danger line blinking, the middle of the run the jar at mid-game; a merge's pop and particles last 2 to 5 frames, so read ten in a row to catch one.
- **At a phone's shape:** write `override.cfg` in the project root (git-ignored) with
  ```
  [display]
  window/size/viewport_width=720
  window/size/viewport_height=1480
  ```
  — the canvas a 360 × 740 phone gets with aspect expand, at twice its size — run the same command, then **delete `override.cfg`**.
- **The menu tour** (`--autoplay-menu`): `APPDATA="$S/appdata" ./tools/godot.cmd --path . --write-movie $S/frames/f.png --fixed-fps 10 --quit-after 200 -- --autoplay --autoplay-menu`: the title (frames 0–19), the bestiary (20–39), the bestiary scrolled to its end (40–59), the options (60–79), then the game, whose pause opens 6 s into the round (about frame 140), Opciones opens over it 2 s later (about 160) and everything closes 2 s after that (about 180). Any option in a run: write it in the same save first, e.g. `"options": {"high_contrast": true}`. To see discovered cards, write `save_autoplay.json` first, e.g. `{"version": 2, "best_score": 0, "discovered": ["gota", "slime_verde"], "options": {}, "round": {}}`, in `$S/appdata/Godot/app_userdata/juego-fusion/`.
- **The tour with a kept round:** write `save_autoplay.json` first with a `"round"` (the example below); the title shows «Seguir» (frames 0–19), the bestiary and the options as above (20–79), the question of «Jugar» (80–99), then the game resumes the round (from about frame 100: its three creatures, 340 points); its pause opens 6 s into the game (about frame 160).
  ```
  {"version": 2, "best_score": 900, "discovered": ["gota", "slime_verde", "slime_azul", "seta"], "options": {}, "round": {"score": 340, "combo": 0, "max_level": 4, "since_merge": 1.0, "current": 2, "next": 1, "can_drop": true, "wait_left": 0.0, "aim_x": 0.0, "danger_time": 0.0, "elapsed": 42.0, "rng_state": "12345", "creatures": [{"level": 4, "x": -2.0, "y": 0.66, "angle": 0.0, "vx": 0.0, "vy": 0.0, "spin": 0.0, "age": 30.0}, {"level": 3, "x": 0.5, "y": 0.52, "angle": 0.4, "vx": 0.0, "vy": 0.0, "spin": 0.0, "age": 20.0}, {"level": 1, "x": 2.2, "y": 0.3, "angle": 0.0, "vx": 0.0, "vy": 0.0, "spin": 0.0, "age": 5.0}]}}
  ```

## Measured

- 0.1.0 (Task 13), `--autoplay-games=20` at `--fixed-fps 60`, headless: mean 11537 puntos, most frequent biggest dragon (18 of 20), mean round 2 min 26 s, creature 6 or more in 20 of 20; about 1 min of real time. Spawner weights 4, 3, 2, 1, friction 0.4, bounce 0.1, angular damp 1.0.
- 0.2.0 (Task 7), the same run: mean 12876 puntos, most frequent biggest dragon (17 of 20), mean round 2 min 38 s, creature 6 or more in 20 of 20; about 1 min of real time. Nothing of the balance changed since 0.1.0.
- 0.3.0 (Task 4), with the helps, the same run: mean 12889 puntos, most frequent biggest dragon (15 of 20), mean round 2 min 52 s, creature 6 or more in 20 of 20, helps 3.0 Romper and 7.5 Cambiar a round; about 1 min 20 s of real time. PowerUps START 1, MAX 3, SWAP_EVERY 1000, BREAK_FROM_LEVEL 6.
