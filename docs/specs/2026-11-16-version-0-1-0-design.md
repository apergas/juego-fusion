# Versión 0.1.0: el tarro jugable

La primera versión jugable de *Fusión de criaturas*: un tarro, ocho criaturas en la cadena, puntos, récord, game over, el bestiario guardado y la versión web en vertical. Cubre M-01 a M-08 del [documento maestro](../documento-maestro.md). Sale de [ideas.md](../ideas.md) («El juego: fusión de criaturas» y «La arquitectura»).

Lo que importa de esta versión es el **tacto** de las fusiones: soltar, rodar, juntarse y el «¡plop!». Si eso no gusta, todo lo demás da igual.

## Decisiones tomadas

Se tomaron sin preguntar, con la opción recomendada; cualquiera se puede cambiar antes del plan:

| Pregunta | Decisión |
|---|---|
| Nombre | *Fusión de criaturas*, provisional (carpeta `juego-fusion`) |
| 2D o 3D | **3D** con cámara ortográfica de frente: las criaturas son low-poly facetadas, como las de Villaclaro, y la física es la de Jolt, encerrada en un plano |
| Criaturas | Un constructor nuevo y pequeño (`CreatureLooks`), no el `CreatureBuilder` de Villaclaro: aquel cuelga de `BattleActor` y `ActorLooks`. Se copia `LowPoly`, recortado a lo que se usa |
| Ayudas (Romper, Cambiar) | Fuera de la 0.1.0; van en la 0.2.0 |
| Música | Fuera de la 0.1.0: solo efectos sintetizados. La música va en la 0.2.0 |
| Guardar la partida a medias | Fuera de la 0.1.0: se guardan el récord, el bestiario y las opciones. Seguir un tarro a medias va en la 0.2.0 |
| Letras | Baloo 2 (rótulos y números) y Nunito (el resto), las de Villaclaro, con sus licencias OFL |

## 1. El tarro (M-01)

- **Medidas, en metros del mundo:** el interior mide 6,0 de ancho y 8,4 de alto. La línea de peligro está a 7,4 del fondo y la criatura que va a caer espera a 8,0.
- **Las paredes y el fondo** son cuerpos estáticos. El tarro se ve como cristal: un marco claro y un fondo algo más oscuro que la escena.
- **Las criaturas son `RigidBody3D` con una esfera de colisión.** Están bloqueadas en el eje Z, el de profundidad, y solo pueden girar alrededor de él, así que ruedan sin salirse del plano.
- **Física:** gravedad normal, rozamiento 0,4 y rebote 0,1. Ruedan algo pero se asientan pronto. El plan ajusta estos valores mirando cómo se siente.
- **La cámara es ortográfica y mira de frente.** Encuadra el tarro con margen para el HUD arriba y abajo, en una pantalla de 720 × 1280 y en cualquier móvil en vertical (`aspect` expand).

## 2. Soltar (M-02)

- **Con el dedo:** al tocar en cualquier parte de la pantalla, la criatura que espera arriba se coloca en la X del dedo, limitada para que no se salga del tarro, y lo sigue mientras arrastras. Una línea vertical tenue marca dónde caerá. **Al levantar el dedo cae.**
- **Con el ratón** funciona igual. **En el ordenador, para probar:** flechas o A/D para moverla y espacio para soltar.
- **Tras soltar** hay 0,5 s de espera antes de que aparezca la siguiente arriba, para que no se puedan tirar diez de golpe.
- **La que espera** se ve arriba del tarro. **La siguiente** se ve en el HUD, en «Siguiente».
- **Lo que cae** son las criaturas 1 a 4 de la cadena, al azar, y la 4 menos a menudo: pesos 4, 3, 2 y 1. Lo decide `Spawner`, con un generador con semilla.

## 3. Fusionar (M-03)

- **Cuando dos criaturas del mismo nivel se tocan,** las dos desaparecen y en el punto medio aparece la del nivel siguiente. Hereda la media de sus velocidades y da un saltito: escala de 0,6 a 1,1 y a 1,0 en 0,2 s.
- **Cada criatura se fusiona solo una vez por contacto.** Si tres iguales se tocan a la vez, se fusionan dos y la tercera espera al siguiente contacto.
- **Las dos más grandes** (dos de la 8) se funden en nada: desaparecen con un destello y dan un premio de puntos.
- **Las fusiones encadenan solas:** la criatura nueva puede tocar otra igual y fusionarse otra vez.
- **Cada fusión lleva:**
  - un «¡plop!» sintetizado, más grave cuanto más grande es la criatura;
  - una vibración corta, de 20 ms más 5 ms por nivel, si está activada;
  - partículas del color de la criatura;
  - el número de puntos, que sube y se desvanece.

## 4. Puntos y combos (M-04)

- **Fusionar en el nivel n da los puntos de la tabla de `Chain`.** Son números triangulares por diez: nivel 2 → 10, 3 → 30, 4 → 60, 5 → 100, 6 → 150, 7 → 210 y 8 → 280. Las dos de la 8 juntas dan 500.
- **Combo:** una fusión menos de 1,0 s después de la anterior aumenta el combo. Los puntos se multiplican por 1 + 0,25 × (combo − 1), hasta ×3. El HUD enseña «¡Combo ×n!» desde el 2. El reloj del combo lo lleva `Game`; `Scoring` solo hace la cuenta.
- **El récord** es la mejor puntuación de siempre. Se guarda al acabar cada partida y el HUD lo enseña al lado de los puntos.

## 5. Perder (M-05)

- **Cuenta una criatura asentada** que ya cayó y lleva 1,0 s en el tarro. Si la parte de arriba de una de ellas está por encima de la línea de peligro, empieza a contar el tiempo.
- **Mientras cuenta, la línea parpadea en rojo,** y más deprisa cuanto menos falta.
- **Si pasan 3,0 s seguidos se pierde.** Si en ese tiempo baja (por una fusión o porque rueda), el tiempo vuelve a cero.
- **Al perder:**
  - las criaturas se congelan;
  - suena un efecto grave;
  - aparece la ventana de fin con los puntos, la criatura más grande de la partida y «¡Nuevo récord!» si lo es;
  - hay dos botones grandes: **Otra vez** y **Salir**, que vuelve al título.

## 6. Las criaturas (M-06)

Ocho criaturas, cada una un `CreatureData` en `data/creatures/<id>.tres` con su id, nombre, nivel, radio, color, aspecto y texto del bestiario:

| Nivel | Id | Nombre | Radio (m) | Aspecto |
|---|---|---|---|---|
| 1 | `gota` | Gota de rocío | 0,30 | gota azul clara, ojos |
| 2 | `slime_verde` | Slime verde | 0,40 | slime facetado verde, ojos y boca |
| 3 | `slime_azul` | Slime azul | 0,52 | slime azul, mejillas |
| 4 | `seta` | Seta saltarina | 0,66 | bola crema con sombrero rojo de lunares |
| 5 | `murcielago` | Murciélago | 0,82 | bola morada con dos alas pequeñas y orejas |
| 6 | `lobo` | Lobo de niebla | 1,00 | bola gris con orejas y hocico |
| 7 | `golem` | Gólem de musgo | 1,22 | bola de piedra con musgo encima |
| 8 | `dragon` | Dragón pequeño | 1,48 | bola roja con cuernos y alas |

- **Todas son una bola facetada** (`LowPoly`) con una o dos cosas que las distinguen. Se ven bien de frente, desde lejos y en una pantalla pequeña.
- **Las construye `CreatureLooks`,** un constructor, a partir de su `CreatureData`.
- **Los colores se eligen distintos entre niveles vecinos,** para que no se confunda una con la siguiente.
- **Los textos del bestiario** son una línea con el humor de Villaclaro. Por ejemplo, para la Gota de rocío: «Lo más pequeño del tarro. No te fíes: todo empieza por una gota».

## 7. El bestiario y el título (M-07)

- **La pantalla de título** muestra el nombre del juego y tres botones grandes: **Jugar**, **Bestiario** y **Opciones**.
- **El Bestiario** es una cuadrícula de 8 fichas. Una descubierta lleva la criatura girando, su nombre, su nivel y su texto. Una sin descubrir lleva la silueta y «???».
- **Una criatura se descubre** la primera vez que sale en el tarro, al caer o por una fusión. En la partida, la primera vez que aparece, sale un aviso corto: «¡Nueva criatura: Lobo de niebla!».
- **Opciones:** volumen de efectos (deslizador), vibración (sí o no) y alto contraste (sí o no; el tema del núcleo).
- **La pausa:** un botón en la esquina superior del HUD abre una ventana con **Seguir**, **Empezar de nuevo** y **Salir al título**. Con la ventana abierta, el tarro se detiene.

## 8. Guardado, web y partida automática (M-08)

- **Guardado:** `SaveData` versión 1, un solo fichero, `user://save.json`. Lleva el récord, los ids descubiertos y las opciones. `SaveStore` lo lee y escribe. Un fichero dañado o de una versión desconocida se ignora y la partida empieza de cero, sin romper nada.
- **Web:** el preset `Web` ya está preparado (en vertical, como app instalable). Faltan los iconos de `assets/pwa/` (144, 180 y 512 px), que serán la Gota de rocío sobre el fondo del juego, renderizados con una herramienta de `scripts/tools/`.
- **Partida automática** (`GameAutoplay`, una pieza de `Game`):
  - `--autoplay` juega una partida sin esperar a nadie. Para soltar busca la criatura asentada del mismo nivel que la que espera más cercana a la superficie y suelta encima. Si no hay ninguna, suelta donde el montón está más bajo.
  - Imprime hitos: `Suelta: gota en x=1.2`, `Fusión: slime_azul (combo 2)`, `Nueva: lobo` y, al acabar, `Partida: 1240 puntos, máxima golem, 3 min 10 s`.
  - `--autoplay-games=N` juega N partidas seguidas e imprime la media de puntos, la criatura máxima más frecuente y la duración media.
  - `--seed=<n>` fija la semilla de `Spawner`.
  - Guarda en `user://save_autoplay.json` y nunca toca el del jugador.
  - Corre también con `--headless` y con `--fixed-fps`, para que dure lo mismo en cualquier equipo.
- **`--touch`:** el ratón hace de dedo, para probar en el ordenador.

## La interfaz

- **Pantalla en vertical, con todo lo que se toca en la mitad de abajo** o en las esquinas de arriba.
- **El HUD:**
  - arriba a la izquierda, los puntos y el récord;
  - arriba a la derecha, «Siguiente» con la criatura y el botón de pausa;
  - el combo, centrado y encima del tarro.
- **Las ventanas** (fin, pausa, opciones) son las del núcleo. Sus botones tienen el tamaño del token del núcleo `touch-target` o más.
- **La paleta de la capa del juego (`docs/design-system/tokens.json`):** fondo morado oscuro, para que las criaturas destaquen; ventanas moradas translúcidas con marco claro; acento amarillo para los puntos y lo importante; texto blanco. El plan fija los valores y los tokens, los documenta en `docs/design-system/2-fundamentos.md` y comprueba los contrastes, que pide el núcleo (`4-accesibilidad.md`).
- **El fondo de la escena:** degradado morado con unas pocas motas de luz que flotan despacio. Es decoración y no distrae.

## La arquitectura

La de [ideas.md](../ideas.md) («La arquitectura») y [CLAUDE.md](../../CLAUDE.md):
- **Reglas puras:** `Chain`, `Scoring`, `Spawner`, `Danger`, `Bestiary`, `GameState`, `SaveData` y `RunFlags`.
- **Constructores:** `JarBuilder`, `CreatureLooks` y `LowPoly`.
- **`Jar` y sus piezas:** `DropAim`, `MergeWatcher`, `DangerLine` y `FusionFx`.
- **`Game` y sus piezas:** `GameAutoplay` y las ventanas.
- **`TitleScreen`,** dueña del `AudioDirector` y de las opciones.

**De Villaclaro se copian, recortados a lo que se usa,** y se dice en la cabecera de cada uno de dónde vienen:
- `LowPoly`;
- `RunFlags` (solo sus opciones);
- `Device`;
- el `AudioDirector` y su `SfxLibrary` (sin música ni ambiente);
- `SaveStore` (sin ranuras);
- las letras.

## Fuera de la 0.1.0

- **0.2.0:** las ayudas (Romper y Cambiar), la música y seguir un tarro a medias.
- **Más adelante:** las criaturas 9 y 10 (Coloso y Albor), tarros distintos y el reto del día.

## Verificación (a mano; el proyecto no tiene tests)

- `--check-only` en cada script nuevo; `--import` sin errores.
- `gen_ui_tokens.gd -- --check` y `check_ui_values.gd`.
- `--autoplay --autoplay-games=20 --fixed-fps 60 --headless` termina sin un ERROR ni un WARNING. La media debe dar partidas de 2 a 8 minutos y llegar al menos a la criatura 6 en la mayoría. Si no, se ajustan los pesos de `Spawner`, los radios o el tarro.
- Capturas o fotogramas (`--write-movie`) de:
  - el título;
  - el tarro a media partida;
  - una fusión;
  - la línea de peligro en rojo;
  - la ventana de fin;
  - el bestiario;

  a 720 × 1280 y a 360 × 740.
- `-- --touch` en el ordenador: soltar arrastrando, la pausa y los botones de las ventanas.
- La exportación web arranca en un navegador, en vertical. Se instala en un móvil de verdad y se juega con un dedo; eso lo comprueba el usuario a mano.
