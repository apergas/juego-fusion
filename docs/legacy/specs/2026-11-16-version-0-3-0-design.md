# Versión 0.3.0: ayudas y música

La tercera versión de *¡Plop!* añade dos ayudas para salir de un apuro, **Romper** y **Cambiar**, y música hecha en el propio juego para el título y para el tarro. Cubre M-14 y M-15 del [documento maestro](../../documento-maestro.md). Las dos venían de la fila 0.2.0 del documento maestro y de «Fuera de la 0.1.0» del [spec de la 0.1.0](2026-11-16-version-0-1-0-design.md), que solo las nombraba; se pasaron aquí al repartir la 0.2.0 ([spec](2026-11-16-version-0-2-0-design.md)). Empieza cuando la 0.2.0 está en `develop`.

## Decisiones tomadas

Ni el spec de la 0.1.0 ni las ideas decían cómo eran las ayudas, así que se diseñan aquí. Se tomaron sin preguntar; cualquiera se puede cambiar antes de empezar el plan:

| Pregunta | Decisión |
|---|---|
| ¿Qué hace Romper? | Quita del tarro la criatura que tocas, con un estallido de su color. No da puntos |
| ¿Qué hace Cambiar? | Cambia la criatura que espera arriba por la de «Siguiente». Se eligió **cambiar** y no **volver a sortear**: se ve lo que vas a conseguir, es una decisión y no un dado, y no toca el generador de `Spawner` |
| ¿Cuántas hay? | Cada partida empieza con **1 de cada**; ninguna guarda más de **3** |
| ¿Cómo se ganan? | **Cambiar:** una cada **1000 puntos**. **Romper:** una cada vez que la criatura más grande de la partida llega a un nivel nuevo **desde el 6** (Lobo de niebla, Gólem de musgo, Dragón pequeño): como mucho tres por partida. Romper es la fuerte, así que se gana poco y por logros; Cambiar, a menudo |
| ¿El tiempo corre mientras eliges qué romper? | No: mientras eliges se para todo, como en la pausa; así se piensa con calma |
| ¿Dónde van los botones? | En las esquinas de abajo, bajo el tarro: Romper a la izquierda y Cambiar a la derecha. Todo lo que se toca queda en la mitad de abajo o en las esquinas de arriba |
| ¿Se guardan? | Sí, con el tarro a medias de la 0.2.0. Un tarro guardado por la 0.2.0, sin ayudas, vuelve con 1 de cada |
| ¿Música de quién? | Melodías propias, con el mismo método de Villaclaro (tablas de notas sintetizadas en código), no sus melodías |
| ¿Cuánta música? | Dos melodías que se repiten: una tranquila para el título y otra algo más viva para el tarro. Unos 20 segundos cada una, para que la web las calcule deprisa |
| ¿La música en la pausa? | Sigue sonando, como los botones |

## 1. Las ayudas Romper y Cambiar (M-14)

### Romper

- **Tocar «Romper»** empieza a elegir: el tarro se para (la física, la cuenta del peligro, el reloj de la partida y el del combo), el botón se queda pulsado y sale la pista «Toca la criatura que quieres romper» sobre la boca del tarro.
- **Tocar una criatura** la quita: desaparece con un estallido de partículas de su color y un sonido seco, gasta una carga y el tarro sigue.
- **Tocar donde no hay ninguna** no hace nada: se sigue eligiendo.
- **Tocar «Romper» otra vez, o Esc,** deja de elegir sin gastar nada.
- **Si se abre la pausa mientras se elige** (con el foco, por ejemplo), se deja de elegir primero.
- **No se puede** sin cargas, sin criaturas en el tarro o con la partida acabada: el botón se apaga.
- Si dos criaturas se solapan bajo el dedo, se rompe la que tiene el centro más cerca.

### Cambiar

- **Tocar «Cambiar»** pone arriba la de «Siguiente» y en «Siguiente» la que esperaba, con un sonido corto; gasta una carga.
- **No se puede** sin cargas, si las dos son iguales (no cambiaría nada) o con la partida acabada: el botón se apaga.

### Las cargas

| | Al empezar | Se gana | Máximo |
|---|---|---|---|
| Romper | 1 | una cada vez que la más grande de la partida llega a un nivel nuevo desde el 6 | 3 |
| Cambiar | 1 | una cada 1000 puntos (al pasar de 999 a 1000, de 1999 a 2000…) | 3 |

- Lo decide una regla pura nueva, `PowerUps`, sobre dos campos nuevos del `GameState`, `breaks` y `swaps`.
- Con una carga ganada sobre el máximo no pasa nada: se pierde.
- Los números se ajustan con la partida automática (ver más abajo) si las partidas se alargan demasiado.

### El HUD

- **Dos botones** en las esquinas de abajo, al menos del tamaño de un dedo (`hud-button` de alto, un token nuevo `power-button-w` de ancho), del estilo del botón de pausa (el `MENU_BUTTON` del núcleo): «Romper ×1» y «Cambiar ×2», con lo que queda.
- **Apagados** cuando no se pueden usar; Romper, **pulsado** mientras se elige.
- **La pista** usa el sitio de «¡Combo ×n!» (`hud-combo-top`): mientras se elige no hay combos.

### Con el tarro a medias

- `RoundSnapshot` guarda también `breaks` y `swaps`. Si faltan (un tarro de la 0.2.0), vuelven a 1; un valor fuera de 0 a 3 no es válido.

## 2. Música sintetizada en código (M-15)

- **Dos melodías que se repiten,** escritas como tablas de notas y sintetizadas en código, como en Villaclaro: la melodía en onda cuadrada, el bajo en triangular y, en la del tarro, un charles suave de ruido.
  - **Título** (`title`): tranquila, en do mayor, a 84 pulsos por minuto, sin percusión.
  - **Tarro** (`jar`): algo más viva, en sol mayor, a 100 pulsos por minuto, con el charles a contratiempo.
- **Las tablas son una regla pura nueva,** `MusicScore` (en `scripts/audio/`), con su lectura de notas; las convierte en sonido un constructor nuevo, `MusicLibrary`, copiado de Villaclaro y recortado a lo que usan estas dos.
- **El título** pone la suya al abrirse y **el tarro** la suya al empezar la partida; al pasar de una a otra se funden en 0,5 s.
- **Ligera para la web:** a 22 050 Hz en mono, unos 20 s por melodía, cada una se calcula una vez, la primera vez que suena. Si en el ordenador tarda más de 0,4 s, se baja a 11 025 Hz.
- **Opciones** gana un deslizador **«Música»**, encima de «Efectos», en pasos del 10 %, con su porcentaje. Empieza en el 60 %.
- **Se guarda** en las opciones de `save.json` (`"music"`). Es una clave nueva y opcional: una partida que no la tiene coge el 60 %, sin cambiar de versión.
- **Con `--autoplay`** suena igual pero en silencio, y sin cabeza (`--headless`) o grabando fotogramas no se llega a reproducir, como los efectos. La partida automática imprime `Música: jar (N ms)`, con lo que tardó en calcularse.

## La partida automática

- **Usa las ayudas con una regla sencilla,** para que la prueba del equilibrio las cuente:
  - **Cambiar** antes de soltar, si la que espera no tiene pareja asentada en el tarro y la de «Siguiente» sí.
  - **Romper** cuando cuenta el peligro: la criatura asentada que más alto llega.
- Imprime `Cambia: gota por seta` y `Rompe: lobo`, y tras cada `Partida:` una línea `Ayudas: 2 Romper, 5 Cambiar`. Con `--autoplay-games=N`, tras la media, `Ayudas de media: 1.8 Romper, 6.2 Cambiar`.
- Las líneas `Partida:` y `Media de …` no cambian de forma.

## Pruebas unitarias

- `tests/game/test_power_ups.gd`, nuevo: cada partida empieza con 1 de cada; Cambiar se gana al cruzar cada 1000 y Romper con cada nivel nuevo desde el 6, nunca más de 3; cambiar intercambia y gasta, y no se puede sin cargas, sin criatura esperando, con dos iguales o con la partida acabada; romper gasta y no se puede sin cargas; qué criatura está bajo el dedo (dentro de una, la más cercana de dos que se solapan, ninguna).
- `tests/game/test_round_snapshot.gd`, cambiado: las cargas van y vuelven; un tarro sin ellas vuelve con 1 de cada; una carga fuera de 0 a 3 se rechaza.
- `tests/audio/test_music_score.gd`, nuevo: cada compás de cada voz mide 16 semicorcheas; la melodía mide un múltiplo del bajo y del charles (los bucles cuadran); toda nota se lee (y «A4» son 440 Hz); cada melodía va de 60 a 110 pulsos y dura de 10 a 40 segundos.
- `tests/game/test_game_options.gd` y `test_save_data.gd`, cambiados: el volumen de la música va y vuelve, falta y coge el 60 %, fuera de rango se recorta.

## Fuera de la 0.3.0

- Más ayudas, ayudas que se compran o se ganan fuera de la partida.
- Más melodías, música por tarro o que cambia con el peligro.
- **Más adelante:** las criaturas 9 y 10 (Coloso y Albor), tarros distintos y el reto del día.

## Verificación

- `--check-only` en cada script cambiado o nuevo; `--import` sin errores.
- `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`.
- Las pruebas unitarias (GUT) salen con 0.
- `--autoplay --autoplay-games=20 --fixed-fps 60 --headless`, ya con las ayudas, sin un ERROR ni un WARNING (salvo el de Jolt): media de 2 a 8 minutos y la criatura 6 o más en al menos 11 de 20. Si se pasa de 8 minutos, se ajustan las cargas: primero Cambiar cada 2000 puntos, luego Romper desde el 7, luego un máximo de 2.
- Las líneas `Música:` con su tiempo de cálculo por debajo de 0,4 s en el ordenador.
- Fotogramas, a 720 × 1280 y con la forma de un móvil: los dos botones bajo el tarro sin tapar su marco, Romper eligiendo con su pista, un estallido de Romper, Opciones con «Música».
- A mano: Romper y Cambiar con el ratón y con `-- --touch`; la música suena en el título y en el tarro, se funde al cambiar y su volumen cambia al moverlo. En un móvil de verdad lo comprueba el usuario.
