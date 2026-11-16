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

- **One round, headless** (ends by itself one second after the round is lost; prints each `Suelta:`, `Fusión:`, `Nueva:` and the `Partida: N puntos, máxima <id>, M min S s` line): `APPDATA="$S/appdata" ./tools/godot.cmd --headless --path . --fixed-fps 60 --quit-after 60000 -- --autoplay`
- **A fixed seed** for the Spawner (the first round's; each next round adds 1): add `--seed=<n>`.
- **Balance, 20 rounds** (the spec's check: a mean of 2 to 8 minutes and creature 6 in most rounds): `time APPDATA="$S/appdata" ./tools/godot.cmd --headless --path . --fixed-fps 60 --quit-after 700000 -- --autoplay --autoplay-games=20 > $S/log.txt 2>&1`, then `grep -E "^(Partida|Media)" $S/log.txt` and `grep -E "ERROR|WARNING" $S/log.txt` (nothing but, at most, Jolt's job-system warning). The last line is `Media de 20 partidas: <points> puntos, máxima <id> (<n> de 20), <time>, 6 o más en <n> de 20`.
- **Save round trip:** add `--autoplay-save` to a one-round run; the `Guardado:` and `Cargado:` lines must be identical.
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
- **The menu tour** (`--autoplay-menu`): `APPDATA="$S/appdata" ./tools/godot.cmd --path . --write-movie $S/frames/f.png --fixed-fps 10 --quit-after 200 -- --autoplay --autoplay-menu`: the title (frames 0–19), the bestiary (20–39), the bestiary scrolled to its end (40–59), the options (60–79), then the game, whose pause opens 6 s into the round (about frame 140), Opciones opens over it 2 s later (about 160) and everything closes 2 s after that (about 180). Any option in a run: write it in the same save first, e.g. `"options": {"high_contrast": true}`. To see discovered cards, write `save_autoplay.json` first, e.g. `{"version": 1, "best_score": 0, "discovered": ["gota", "slime_verde"], "options": {}}`, in `$S/appdata/Godot/app_userdata/juego-fusion/`.

## Measured

Version 0.1.0, first measurement, 20 rounds (about 1 min of real time headless): `Media de 20 partidas: 12498 puntos, máxima dragon (17 de 20), 2 min 37 s, 6 o más en 20 de 20`.
