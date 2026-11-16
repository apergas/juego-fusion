# Ideas

Ideas y pasos pendientes del juego. Cuando una idea pasa a un spec y al [documento maestro](documento-maestro.md), se borra de aquí.

La idea del juego, su arquitectura y la preparación ya están en el [spec de la 0.1.0](specs/2026-11-16-version-0-1-0-design.md), en el documento maestro y en [CLAUDE.md](../CLAUDE.md).

## 2026-11-16 · Lo que queda de la preparación

- En GitHub, en Settings → Pages del repo `apergas/juego-fusion`, poner como Source «GitHub Actions» antes de la primera publicación.

## 2026-11-16 · El nombre del juego

*Fusión de criaturas* es provisional. Propuestas:

| Nombre | Por qué |
|---|---|
| **¡Plop!** | El sonido de cada fusión. Corto, se recuerda y queda bien bajo un icono del móvil. |
| **Gota a gota** | Todo empieza por la Gota de rocío y se llena poco a poco, como el tarro. |
| **Bichos en el tarro** | Dice de qué va sin explicar nada. |
| **Apilabichos** | Una palabra inventada, de las que piden jugar. |
| **El tarro de Villaclaro** | Lo une al primer juego: las criaturas son de allí. |
| **Pompas y bichos** | Suena ligero y redondo, como las criaturas. |
| **Fusiolandia** | Un mundo de fusiones; da para más tarros y retos. |
| **Rocío** | El nombre de la primera criatura. Íntimo y fácil de decir. |
| **Mezclamonstruos** | Más gamberro y con el humor de Villaclaro. |
| **Tarro lleno** | Lo que dice la ventana de fin: se recuerda porque es lo que te pasa. |

La recomendación es **¡Plop!**: cabe entero bajo el icono de la app, es el sonido del juego y no necesita traducción. Antes de decidir, conviene buscarlo en las tiendas de apps y en itch.io por si ya existe un juego con ese nombre.

Al decidirlo cambian `config/name`, el `short_name` de `pages.yml`, el `apple-mobile-web-app-title` del preset `Web`, el `name` de `tokens.json`, `CLAUDE.md` y los docs. La carpeta y el repo pueden quedarse como `juego-fusion`.

## 2026-11-16 · Lo que enseñó la maqueta

La [maqueta de pantallas](design-system/maqueta.html) propone la paleta y la colocación. Al pasarla al juego:
- **Las alas y los cuernos salen del radio de la criatura:** las del dragón y el murciélago asoman por fuera del tarro cuando la criatura toca la pared. O bien caben dentro del radio de colisión, o bien el tarro las recorta.
- **Las opciones también están en la pausa**, no solo en el título, para cambiar el sonido o la vibración sin salir de la partida. El spec de la 0.1.0 solo las pone en el título.
- **«Siguiente» se ve en pequeño:** la criatura del HUD va a escala reducida, no a su tamaño en el tarro.

## 2026-11-16 · Villaclaro con el núcleo como submódulo

Se hace en Villaclaro (en una `feature/` de allí, cuando acabe lo que está en curso):
- quitar su carpeta `addons/design_system/` y añadirla como submódulo del repo del núcleo en la misma ruta;
- `submodules: true` en sus `pages.yml`, `release.yml` y `autoplay.yml`;
- actualizar su `CLAUDE.md` y el README del núcleo («Como submódulo de git»: ya no es «cuando haya un segundo»);
- comprobar el juego, las dos comprobaciones del design system y el build web.

Desde entonces un cambio del núcleo se hace en su repo y cada juego actualiza su puntero.
