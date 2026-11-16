# Versión 0.2.0: más cómodo

La segunda versión de *¡Plop!* no cambia el juego: lo hace más cómodo en un móvil. Antes, la capa del design system del juego sale de `docs/` a su propia carpeta, `design/`. Las criaturas nuevas se descubren en silencio, la partida se pausa sola cuando el juego pasa a segundo plano, un tarro a medias sobrevive a cerrar el juego, y se pulen tres cosas que salieron en las revisiones de la 0.1.0. Cubre M-10 a M-13 (y la mudanza de la capa del design system) del [documento maestro](../../documento-maestro.md) y sale con M-09 (las pruebas unitarias, ya hechas). Sale de [ideas.md](../../ideas.md) («Pausar sola al pasar a segundo plano» y «Descubrir criaturas en silencio») y de la fila 0.2.0 del documento maestro («seguir un tarro a medias»).

Las ayudas (Romper y Cambiar) y la música, que el documento maestro ponía también en la 0.2.0, pasan a la [0.3.0](2026-11-16-version-0-3-0-design.md): juntas eran demasiado para una versión.

## Decisiones tomadas

Se tomaron sin preguntar, con la opción que parecía mejor; cualquiera se puede cambiar antes de empezar el plan:

| Pregunta | Decisión |
|---|---|
| ¿Dónde va la capa del design system? | En `design/`, en la raíz, y es lo primero que se hace, para que todo lo demás ya escriba ahí |
| ¿Qué queda del descubrimiento en la partida? | Nada que se vea o se oiga. Se guarda en el momento, como antes, y la partida automática sigue imprimiendo `Nueva:` |
| ¿Qué pausa sola? | Perder el foco o pasar a segundo plano (`NOTIFICATION_APPLICATION_FOCUS_OUT`, `NOTIFICATION_WM_WINDOW_FOCUS_OUT` y, en móvil, `NOTIFICATION_APPLICATION_PAUSED`). En la web, cambiar de pestaña o de app quita el foco a la página y Godot lo manda como `APPLICATION_FOCUS_OUT`; no hace falta escuchar `visibilitychange` aparte |
| ¿Cuándo se guarda el tarro a medias? | Al abrirse la pausa (a mano o sola), al cerrar la ventana y, por tanto, al salir al título desde la pausa. No hay guardado cada pocos segundos |
| ¿Cómo vuelve un tarro guardado? | Con la pausa abierta, para que el jugador vuelva con calma y elija «Seguir» |
| ¿«Jugar» con un tarro guardado pregunta? | Sí, una vez: perder un tarro a medias sin querer es peor que un toque más |
| ¿Qué se guarda del tarro? | Cada criatura (nivel, posición, giro, velocidad, giro de su velocidad y edad), los puntos, el combo y su reloj, lo que espera y la siguiente, la espera tras soltar, la x de la criatura que espera, el tiempo de la partida, la criatura más grande, la cuenta del peligro y el estado del generador de `Spawner`. La física de después no será idéntica (no lo es ni entre dos partidas con la misma semilla) |
| ¿Por qué `SaveData` versión 2? | El tarro es un campo nuevo, `"round"`; se sube la versión para que el formato diga qué lleva. Una partida de la versión 1 (la de la 0.1.0) se lee como una 2 sin tarro |
| Un tarro guardado que no es válido | Solo se pierde el tarro: se carga el récord, el bestiario y las opciones, el tarro se descarta (con un aviso en el registro) y no hay «Seguir». El fichero no se rechaza por él |
| Las alas | Del murciélago y del dragón, levantadas sobre los hombros para que se vean por encima del cuerpo, sin pasar nunca del radio por los lados |

## 0. La capa del design system, a `design/`, y Dependabot para el núcleo

- **La capa del juego** (lo que no es del núcleo) deja `docs/design-system/` y pasa a una carpeta propia en la raíz, **`design/`**: `tokens.json`, el `tokens.css` generado, `2-fundamentos.md`, `4-accesibilidad.md`, `components/bundle.css` y `maqueta.html`. `docs/` queda para el documento maestro, las ideas, los specs, los planes y el registro.
- **Se cambia solo la configuración del juego:** `design_system.json` (todas las rutas que leen las herramientas del núcleo, que nunca se editan), el filtro de exclusión del preset `Web` (`design/*` no entra en la exportación), los enlaces de los documentos de la capa al núcleo, `CLAUDE.md` y el enlace vivo a la maqueta del spec de la 0.1.0 (el resto del registro conserva sus rutas tal como se escribieron). El gancho de pre-commit y los flujos de GitHub no nombran rutas de la capa.
- **Se regeneran** `ui_tokens.gd` y `tokens.css`, y `gen_ui_tokens.gd -- --check` y `check_ui_values.gd` salen con 0.
- **Dependabot sigue al núcleo:** `.github/dependabot.yml` (`gitsubmodule`, directorio `/`, cada semana, hacia `develop` y nunca hacia `main`, que publica en Pages) abre una petición de cambio cuando `apergas/godot-design-system` tiene un commit o una etiqueta nuevos; solo mueve el puntero de `addons/design_system`. Se fusiona a mano, después de mirarla, nunca sola.
- **`tests.yml` corre también en cada petición de cambio a `develop`** y, tras importar, hace por este orden las dos comprobaciones del design system (hasta ahora solo estaban en `pages.yml`), las pruebas unitarias y una partida automática corta sin cabeza (dos partidas con semilla, con tiempo límite, que falla con cualquier ERROR o WARNING salvo el conocido de Jolt). Así un cambio del núcleo que rompe el juego se ve en la petición, no al publicar.
- **`CLAUDE.md` explica cómo se actualiza el núcleo:** qué es la petición de Dependabot; a mano, `git -C addons/design_system fetch --tags` y `checkout <etiqueta>`, regenerar con `gen_ui_tokens.gd`, las dos comprobaciones y un commit con el puntero y los ficheros regenerados; y `git submodule update` tras un `pull` en otro clon.
- **Cada entrada del `CHANGELOG.md` desde la 0.2.0 dice con qué núcleo sale:** «Con el design system v1.0.0», sacado de la etiqueta del submódulo (`git -C addons/design_system describe --tags`). El núcleo etiqueta cada versión (`vX.Y.Z`); si el puntero no está en una etiqueta, la entrada da el commit corto.

## 1. Descubrir criaturas en silencio (M-10)

- **Al conseguir una criatura nueva no sale nada:** ni el aviso «¡Nueva criatura: …!», ni su sonido, ni nada en la ventana final.
- **Lo descubierto solo se ve en el Bestiario,** como en la 0.1.0: las que ya has visto con su ficha y el resto como «???».
- **Se sigue guardando igual,** en el momento en que se descubre.
- **Se quita lo que deja de usarse,** sin código muerto: `Bestiary.NEW_TEXT`, el aviso del `Hud` (`show_notice()` y su panel), el efecto `SfxLibrary.NEW` y el token `hud-notice-top`, con sus documentos.
- **La partida automática** sigue imprimiendo `Nueva: lobo`.

## 2. Pausar sola al pasar a segundo plano (M-11)

- **Cuando el juego pierde el foco** (cambio de app en el móvil, pestaña oculta en la web, otra ventana en el ordenador) se abre la pausa, igual que con el botón.
- **Solo durante una partida:** no si ya se acabó (la ventana de fin está abierta), no si la pausa ya está abierta y **nunca con `--autoplay`**, que se graba en una ventana que no siempre tiene el foco.
- Así, la física y la cuenta del peligro ya no siguen corriendo mientras no miras.

## 3. Seguir un tarro a medias (M-12)

### Qué pasa

- **Al salir de una partida que sigue,** el tarro se guarda: al abrirse la pausa (con el botón, con Esc o sola), al salir al título desde la pausa y al cerrar la ventana.
- **El título ofrece «Seguir»** encima de «Jugar» mientras haya un tarro guardado. «Seguir» vuelve a ese tarro con la pausa abierta.
- **«Jugar» con un tarro guardado pregunta antes,** en una ventana del núcleo:
  - título: «¿Tarro nuevo?»;
  - texto: «El tarro a medias se perderá.»;
  - botones: **Empezar** (borra el tarro guardado y empieza uno nuevo) y **Volver** (el velo y Esc también).
- **Un tarro se olvida** al perderlo (en el mismo guardado del récord), al empezar uno nuevo («Empezar de nuevo» en la pausa, «Otra vez» al final, «Empezar» en la pregunta) y no vuelve a ofrecerse.
- «Salir» desde la ventana de fin no guarda nada: esa partida ya se acabó.

### Qué se guarda

Una regla pura nueva, `RoundSnapshot`, convierte la partida en un `Dictionary` y al revés; el `Jar` da cada criatura y reconstruye sus cuerpos a partir de él.

| Clave | Qué es |
|---|---|
| `score`, `combo`, `max_level` | los puntos, el combo y la criatura más grande de la partida |
| `since_merge` | el reloj del combo, como mucho `Scoring.COMBO_WINDOW` (1,0 s): más tarde da igual, y JSON no sabe escribir el infinito con el que empieza |
| `current`, `next`, `can_drop`, `wait_left`, `aim_x` | lo que espera arriba, la siguiente, si ya se puede soltar, lo que queda de la espera de 0,5 s y la x de la que espera |
| `danger_time`, `elapsed` | la cuenta del peligro y los segundos de la partida |
| `rng_state` | el estado del generador de `Spawner`, **como texto** (JSON redondearía un número de 64 bits) |
| `creatures` | una lista; cada criatura con `level`, `x`, `y`, `angle` (su giro), `vx`, `vy` (su velocidad), `spin` (la velocidad de su giro) y `age` (lo que lleva en el tarro) |

- **No es válido** (y entonces no lo es el fichero entero): un nivel desconocido, unos puntos negativos, una criatura que espera que `Spawner` no puede dar, una cuenta del peligro que ya perdió, un número que no es un número, un estado del generador que no es un entero o más de 120 criaturas.
- **Al reconstruirlo,** la x de cada criatura se devuelve dentro del tarro.

### El guardado: `SaveData` versión 2

- `save.json` lleva `{"version": 2, "best_score", "discovered", "options", "round"}`. `"round"` es el tarro (`{}` si no hay).
- **Una partida de la versión 1** (sin `"round"`) se lee entera y se trata como una 2 sin tarro; el próximo guardado ya la escribe como 2. Una de la versión 1 que traiga `"round"` se lee ignorándolo; una de la 3 o más no es válida.
- Sigue la regla de la 0.1.0 para todo salvo el tarro: lo que no es válido no se aplica y se guarda una vez como `save.json.bak`. Un tarro roto no rechaza el fichero: `apply()` lo deja vacío.
- El tarro vive en el `Profile` (`saved_round`), con el récord y el bestiario.

## 4. Pulido de la 0.1.0 (M-13)

Solo lo barato y visible:

- **La línea de puntería se ve mejor:** el token `aim-line` pasa del 25 % al 45 % de blanco y la línea, de 0,04 a 0,06 m de ancho.
- **Las alas del murciélago y del dragón se leen** sin salir del radio: se levantan sobre los hombros, inclinadas hacia fuera (35° el murciélago, 40° el dragón), así que asoman por encima del cuerpo. Ninguna punta pasa de 0,9 radios por los lados, así que nada atraviesa la pared del tarro.
- **La pausa no se transparenta detrás de Opciones:** mientras Opciones está abierta sobre la pausa, la pausa (y su velo) se ocultan, en los dos temas; al cerrar Opciones vuelve.
- **Los comentarios de documentación largos** de los ficheros que se tocan se recortan a 100 columnas.

## La partida automática

- Sigue igual: `Suelta:`, `Fusión:`, `Nueva:`, `Partida:` y `Media de …`.
- **Nueva opción `--autoplay-resume`:** a los 20 s de la primera partida guarda el tarro como si el jugador saliera, lo vuelve a leer del fichero en un perfil nuevo y sigue jugando desde él. Imprime `Tarro guardado: …` y `Tarro leído: …`, que deben ser idénticas, y `Tarro seguido: N criaturas, P puntos`.
- **El recorrido de menús** (`--autoplay-menu`) con un tarro guardado enseña «Seguir» en el título, abre la pregunta de «Jugar» y la cierra, y empieza el juego siguiendo el tarro.
- La partida automática nunca pausa sola al perder el foco.

## Pruebas unitarias

Las de la 0.1.0 siguen; esta versión añade o cambia:

- `tests/game/test_round_snapshot.gd`, nuevo: una partida pasa por JSON y vuelve igual (el generador da las mismas criaturas siguientes); el reloj del combo nunca es infinito y un combo viejo vuelve a empezar; lo que una partida que sigue no puede tener se rechaza; una criatura fuera del tarro vuelve dentro; falta un campo y se rechaza.
- `tests/game/test_save_data.gd`, cambiado: la versión 2 con su tarro va y vuelve; una de la versión 1 (como la escribía la 0.1.0) se lee sin tarro; la versión 3 se rechaza; la 1 con tarro se lee sin él; un tarro roto (o que falta, o no es un diccionario) se descarta y el récord, el bestiario y las opciones se cargan.
- `tests/fixtures.gd`, nuevo: la partida de ejemplo que usan los dos.
- Ninguna prueba toca nodos, escenas, ficheros ni lo que se ve.

## Ajustes del plan

Cambios que las rondas de arreglos hicieron respecto al plan:

- Las figuras se quedan siempre derechas mientras sus cuerpos ruedan.
- Las alas en V van encima de la cabeza y el murciélago no lleva orejas.
- Un tarro guardado roto se descarta (con un aviso en la salida) y el resto de la partida se carga siempre.

## Fuera de la 0.2.0

- **0.3.0:** las ayudas Romper y Cambiar, y la música.
- **Más adelante:** las criaturas 9 y 10 (Coloso y Albor), tarros distintos y el reto del día.
- Guardar el tarro cada pocos segundos (por si el sistema mata el juego sin avisar); la vuelta atrás de Android (no es un objetivo: el juego es la web).

## Verificación

- `--check-only` en cada script cambiado o nuevo; `--import` sin errores.
- `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`, ya con la capa en `design/`; ninguna ruta viva nombra `docs/design-system` y la exportación no lleva nada de `design/`.
- Las pruebas unitarias (GUT) salen con 0.
- Una partida automática con `--autoplay-resume`: las dos líneas del tarro idénticas, la partida sigue hasta el final sin un ERROR ni un WARNING.
- `--autoplay --autoplay-games=20 --fixed-fps 60 --headless` sin un ERROR ni un WARNING (salvo el del sistema de trabajos de Jolt): media de 2 a 8 minutos y la criatura 6 o más en al menos 11 de 20.
- Fotogramas, a 720 × 1280 y con la forma de un móvil: el título con «Seguir», la pregunta de «Jugar», un tarro seguido, la pausa con Opciones encima (sin la pausa detrás) en los dos temas, la línea de puntería y el murciélago y el dragón en el bestiario y contra una pared.
- A mano en el ordenador: con una partida en marcha, cambiar a otra ventana abre la pausa; cerrar la ventana a media partida y volver a abrir ofrece «Seguir». En un móvil de verdad (cambiar de app, recargar la página) lo comprueba el usuario.
