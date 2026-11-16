# Ideas

Ideas y pasos pendientes del juego. Cuando una idea pasa a un spec y al documento maestro, se borra de aquí.

## 2026-11-16 · El juego: fusión de criaturas

Un juego para móviles, que se abre en la web como Villaclaro pero pensado al 100 % para el móvil: en vertical, con una mano, partidas cortas y nada de menús con flechas.

**La idea en una frase:** caen criaturas a un tarro; juntas dos iguales y se convierten en la siguiente, más grande. El objetivo es llegar a la criatura más grande antes de que el tarro rebose.

**Cómo se ve la pantalla (vertical):**
- Arriba: los puntos, el récord y la criatura que caerá después.
- En medio: el tarro, con una línea de peligro cerca del borde.
- Abajo: dos ayudas, Romper y Cambiar.
- Las criaturas tienen física: ruedan, rebotan y se apilan, como canicas en un bote.

**Cómo se juega:**
1. Pones el dedo encima del tarro y la criatura que va a caer sigue tu dedo de lado a lado.
2. Al soltar, cae y rueda hasta pararse.
3. Si toca otra igual, se fusionan en la siguiente de la cadena, con un «¡plop!», vibración, partículas y puntos.
4. Las fusiones encadenan: la criatura nueva puede tocar otra igual y fusionarse otra vez. Ahí están los combos.
5. Pierdes si algo se queda por encima de la línea de peligro unos segundos.

Lo único que decides es dónde sueltas cada criatura. Las cosas no caen solas: tú decides cuándo soltar, así que no pide reflejos.

**La cadena de evolución** (provisional, con criaturas del mundo de Villaclaro):

| # | Criatura | Tamaño |
|---|---|---|
| 1 | Gota de rocío | diminuta |
| 2 | Slime verde | pequeña |
| 3 | Slime azul | |
| 4 | Seta saltarina | |
| 5 | Murciélago | mediana |
| 6 | Lobo de niebla | |
| 7 | Gólem de musgo | grande |
| 8 | Dragón pequeño | |
| 9 | Coloso | enorme |
| 10 | Albor | la meta |

En el tarro solo caen las criaturas 1 a 5 al azar. Las grandes solo se consiguen fusionando, y llegar a la 10 es el récord de verdad.

**Una partida:**
- Dura de 3 a 10 minutos.
- Empieza tranquila y se complica cuando el tarro se llena de criaturas medianas sin pareja.
- Hay pocas ayudas por partida y se ganan con combos: **Romper** quita una criatura y **Cambiar** cambia la siguiente que cae.
- Al final ves tus puntos, la criatura más grande que has hecho y si has batido el récord.

**Lo que engancha:**
- **El bestiario de fusiones:** la primera vez que creas una criatura se desbloquea su ficha, con su dibujo y una línea de texto. Completarlo es el gran objetivo.
- **El «una más»:** partidas cortas y la sensación de que la siguiente saldrá mejor.
- **Más adelante:** tarros distintos (estrecho y alto, con un obstáculo en medio, criaturas que pesan más) y un reto del día con la misma secuencia para todos.

**Lo que aprovecha de Villaclaro:**
- las criaturas (`CreatureBuilder` y sus aspectos);
- el bestiario como colección;
- la partida automática: un bot juega mil partidas y mide los puntos de media y hasta qué criatura llega, para equilibrar sin tests;
- el design system, el audio generado por código y la exportación web como app instalable con su aviso de versión nueva.

Lo nuevo es la física: las criaturas son cuerpos redondos con Jolt, la misma que usa Villaclaro.

**La primera versión jugable (0.1.0):**
- 1 tarro y 8 criaturas en la cadena;
- puntos, récord y game over;
- guardado del récord y del bestiario;
- versión web en vertical.

Lo importante de esa versión es el «tacto» de las fusiones: es lo que hace bueno o malo el juego.

## 2026-11-16 · Pasos para empezar a desarrollar

Ya hecho: esta carpeta, `docs/` y un proyecto de Godot 4.7.2 vacío. Lleva Compatibility, va en vertical a 720 × 1280 y usa Jolt; su nombre es provisional. `tools/godot.cmd` está copiado de Villaclaro.

**1. Preparar el proyecto**
- Decidir el nombre del juego y renombrar la carpeta y `config/name` si cambia.
- Crear el repo en GitHub con las mismas ramas que Villaclaro: `main`, `develop` y `feature/*`, con merges `--no-ff`.
- Copiar `.mcp.json` de Villaclaro si hace falta.

**2. Traer lo reutilizable de Villaclaro**
- El núcleo del design system, como submódulo (ver la idea de abajo), en `addons/design_system/`.
- La capa del juego:
  - `design_system.json`;
  - un `tokens.json` propio que `"extends"` el del núcleo, con su paleta, sus letras y tokens para pantallas en vertical;
  - un `UiTheme extends DsTheme`;
  - sus docs.

  Después se genera `UiTokens` y se activa el hook de pre-commit (`git config core.hooksPath .githooks`).
- Las piezas que sirven:
  - `CreatureBuilder` y los aspectos de las criaturas que se usen;
  - el audio generado por código;
  - `RunFlags`, `Device` y `DisplaySettings`;
  - el guardado (`SaveStore`), simplificado;
  - `WebUpdate`.

  Lo que no se use no se copia.
- Un `CLAUDE.md` con las reglas de Villaclaro:
  - no hay tests;
  - no hay autoloads;
  - los tres tipos de script (reglas puras, constructores y nodos);
  - las escenas solo con la raíz y su script;
  - `RunFlags` como único lector de opciones;
  - la partida automática para comprobar el juego;
  - gitflow y commits sin atribución;
  - la partida real nunca se toca;
  - el juego, solo en castellano.

**3. Diseñar antes de programar**
- Hacer un brainstorming y luego el spec. Tiene que dejar cerrado:
  - el nombre;
  - la cadena de criaturas;
  - el tamaño y la forma del tarro;
  - cómo se puntúa y los combos;
  - cuándo se pierde;
  - las ayudas;
  - el estilo visual (3D con los aspectos de Villaclaro, o 2D).
- Escribir un documento maestro con las versiones (0.1.0, 0.2.0…) y el plan de la primera.

**4. La primera versión jugable (0.1.0)**

Se sigue la arquitectura y el orden de «La arquitectura», más abajo.
- Las reglas puras: la cadena de evolución, los puntos, los combos y cuándo se pierde.
- La escena del tarro:
  - criaturas con física;
  - apuntar arrastrando el dedo y soltar;
  - las fusiones con sonido, vibración y partículas;
  - la línea de peligro;
  - el game over.
- El récord y el bestiario guardados.
- El bot de partida automática para equilibrar.

**5. Publicarlo en la web**
- Exportarlo como app instalable con el preset Web de Villaclaro, cambiado a orientación vertical. Hay que mantener lo de su `html/head_include`:
  - `preserveDrawingBuffer` a false, por la pantalla negra de Chrome en Android;
  - el aviso «El navegador ha cortado los gráficos» con su botón «Recargar»;
  - el nombre del icono en iOS.
- Copiar `pages.yml` para publicarlo en GitHub Pages en cada push a `main`. Necesita `submodules: true` en el checkout.
- Probarlo en un móvil de verdad: instalarlo en la pantalla de inicio y comprobar que arrastrar y soltar se siente bien.

## 2026-11-16 · La arquitectura (skill `structuring-godot-code`)

Se sigue la skill global `structuring-godot-code`, la misma de Villaclaro. Cada script es de uno de tres tipos, y el código nuevo va al tipo que le toca:

| Tipo | Base | ¿Toca nodos? | Qué guarda |
|---|---|---|---|
| **Regla** | `RefCounted` / `Resource` | Nunca | Reglas, números, umbrales y textos; devuelve resultados |
| **Constructor** | `RefCounted`, solo estático | Los crea para quien lo llama y no guarda estado | Mallas, el tarro, el tema |
| **Nodo** | `Node` / `Control` / `Node3D`… | Sí | Reproduce: llama a las reglas, enseña los resultados y emite señales |

**Reglas que siempre se cumplen:**
- **No hay autoloads.** La pantalla de título es dueña del audio y las opciones. `Game` es dueño de una partida: su `GameState`, el tarro, el guardado y la pausa. Los dos pasan lo que haga falta con `setup()`.
- **Señales hacia arriba, llamadas hacia abajo.** Una pieza nunca guarda a su dueño: recibe en `setup()` lo que necesita (el estado y `Callable`s) y emite señales.
- **Un fichero grande no recibe trabajo nuevo:** lo nuevo va en una pieza aparte.
- **Las opciones de línea de comandos se leen solo en `RunFlags`.**
- **Las escenas (`.tscn`) solo llevan la raíz y su script;** el resto se crea en código.
- **El `CLAUDE.md` se actualiza en el mismo commit que el código.**

**Cómo quedaría el proyecto:**

```
project.godot                # escena principal = el título; sin autoloads
scenes/title/title.tscn      # raíz + script
scenes/game/game.tscn
scripts/
  title/  title_screen.gd    # dueño de AudioDirector y opciones; crea Game y lo libera
  game/   game.gd            # la partida: GameState, el tarro, guardar, pausa
          game_state.gd      # RefCounted: puntos, récord, ayudas, siguiente criatura, bestiario
          save_data.gd       # pura: estado <-> Dictionary, versión 1, is_valid()
          save_store.gd      # ficheros en user://: récord, bestiario, opciones
          run_flags.gd       # pura: las opciones de línea de comandos, leídas una vez
          chain.gd           # regla: la cadena de evolución (qué sale al fusionar dos iguales)
          scoring.gd         # regla: puntos por fusión y multiplicador de combo
          spawner.gd         # regla: qué criatura cae después (1 a 5), con semilla para el reto del día
          danger.gd          # regla: cuántos segundos sobre la línea hacen perder
          helpers.gd         # regla: cuántas ayudas hay y cuándo se gana una
          bestiary.gd        # regla: qué criaturas están descubiertas
  jar/    jar.gd             # nodo: el tarro y sus criaturas con física; dueño de sus piezas
          drop_aim.gd        # pieza: sigue el dedo y suelta la criatura
          merge_watcher.gd   # pieza: ve dos iguales tocándose, pregunta a Chain y emite merged
          danger_line.gd     # pieza: mide el tiempo sobre la línea y emite overflowed
          fusion_fx.gd       # pieza: «plop», vibración, partículas y el saltito de la criatura nueva
          jar_builder.gd     # constructor: paredes, fondo y línea del tarro
          creature_builder.gd # constructor: traído de Villaclaro, solo los aspectos usados
  ui/     ui_tokens.gd       # generado por el design system
          ui_theme.gd        # UiTheme extends DsTheme
          hud.gd             # puntos, récord, siguiente y ayudas
          game_over_window.gd
          bestiary_window.gd
  audio/  audio_director.gd + sus librerías (sintetizado, de Villaclaro)
  tools/  scripts fuera de línea (excluidos de la exportación)
data/creatures/<id>.tres     # CreatureData: nombre, radio, aspecto, texto del bestiario
addons/design_system/        # el núcleo, como submódulo
docs/                        # ideas, specs, planes, documento maestro, CHANGELOG
```

**Quién decide y quién enseña:**
- La física la mueve el motor: el tarro solo informa de qué ocurre (dos criaturas que se tocan, una por encima de la línea).
- Las reglas deciden: qué sale de la fusión, cuántos puntos da y si se ha perdido.
- `Game` es dueño del tiempo de la partida y del combo: recibe las señales del tarro, llama a las reglas y emite `merged`, `score_changed` o `game_over`, que el HUD y las ventanas escuchan.

**Partida automática desde el primer día:**
- `--autoplay`: un bot (`GameAutoplay`, una pieza de `Game`) suelta criaturas con una estrategia sencilla, sin esperar a nadie. Imprime hitos: `Fusión: slime_azul`, `Partida: 1240 puntos, máxima gólem`.
- Variantes, que también son opciones de `RunFlags`:
  - `--autoplay-games=N` juega N partidas y saca medias;
  - `--seed=<n>` repite la misma secuencia de criaturas;
  - un recorrido de menús;
  - la ida y vuelta del guardado.
- La física no es exacta entre ejecuciones, así que el bot mide medias de muchas partidas, no una sola.
- El código de la partida automática va junto: en su pieza o en un `#region Autoplay` al final de la clase.

**Primeros pasos, en el orden de la skill:**
1. La pantalla de título, dueña del audio y las opciones, que crea `Game`.
2. `Game`, con su `GameState` y un tarro vacío.
3. `SaveData` (versión 1) y `SaveStore`.
4. `RunFlags` con `--autoplay`.
5. La partida automática jugando el bucle básico: soltar, fusionar y perder.
6. Después, cada función nueva como una regla más una pieza.

## 2026-11-16 · El design system como submódulo

Con dos juegos ya compensa sacar el núcleo del design system (`addons/design_system/` de Villaclaro) a su propio repo y usarlo como submódulo en los dos.

**Lo que se gana:**
- Hay una sola copia: un arreglo en `DsTheme` o `MenuCursor` llega a los dos juegos.
- Cada juego apunta a una versión concreta del núcleo (una etiqueta como `v1.0.0`), así que un cambio para un juego no rompe el otro hasta que se actualiza.
- La regla de «el núcleo nunca se edita desde un juego» pasa a ser real.

**Lo que cuesta:**
- Al clonar hay que traer el submódulo (`git clone --recursive` o `git submodule update --init`). Si no, la carpeta sale vacía y el juego no arranca.
- Para cambiar el núcleo hay que hacer commit y push en su repo, y luego, en cada juego, actualizar el puntero y hacer commit.
- `pages.yml` y `release.yml` necesitan `submodules: true` en el checkout. Si el repo del núcleo es privado, además hace falta un token, así que lo más fácil es que sea público.
- El hook de pre-commit llama a `addons/design_system/hooks/pre-commit`, así que también necesita el submódulo inicializado.

**Pasos:**
1. Crear un repo nuevo, por ejemplo `godot-design-system`, con el contenido de `addons/design_system/`. Arranca limpio; su historial anterior se queda en Villaclaro.
2. Poner la etiqueta `v1.0.0`.
3. En Villaclaro, en una `feature/`: quitar la carpeta y añadirla como submódulo en la misma ruta, así que Godot y las rutas no cambian.
4. En Villaclaro: actualizar `pages.yml`, `release.yml`, `CLAUDE.md` (cómo clonar y cómo actualizar el núcleo) y el documento maestro, como una versión 3.x.y.
5. En Villaclaro: comprobar que el juego arranca, que `gen_ui_tokens.gd -- --check` y `check_ui_values.gd` pasan, que el hook funciona y que el build web de Actions sale bien.
6. Este juego nace ya con el submódulo.

**Cuándo:** cuando acabe el trabajo en curso de Villaclaro, porque toca `.github/`, `CLAUDE.md` y `addons/`. Encaja como una versión pequeña de Villaclaro justo antes de empezar este juego.
