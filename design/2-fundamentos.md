# Fundamentos de ¡Plop!

Las escalas, las medidas genéricas, los diez estilos de texto y el papel de cada semántico están en los [fundamentos del núcleo](../addons/design_system/docs/2-fundamentos.md). Aquí está lo del juego: un fondo morado oscuro para que las criaturas destaquen, ventanas moradas translúcidas con marco claro, un acento amarillo para los puntos y lo importante, y texto blanco. Los contrastes están en [accesibilidad](4-accesibilidad.md).

## Los valores que el juego da al núcleo

En el `"overrides"` de `tokens.json`:

| Token | `juego` | `alto-contraste` |
| --- | --- | --- |
| `surface-window` | #1d1238e6 (`purple-900` al 90 %: el tarro se ve detrás) | `purple-950` |
| `surface-window-solid` | `purple-900` | `purple-950` |
| `surface-selected` | `purple-800` | `purple-700` |
| `surface-track` | #0000008c | `black` |
| `surface-scrim` | #00000080 | #000000b3 |
| `border-window` | `white` | `white` |
| `border-subtle` | `purple-600` | `grey-400` |
| `border-focus` | `yellow-300` | `yellow-300` |
| `text-primary` | `white` | `white` |
| `text-secondary` | `grey-300` | `grey-200` |
| `text-disabled` | `grey-500` | `grey-400` |
| `text-accent` | `yellow-300` | `yellow-300` |
| `text-positive` | `green-300` | `green-300` |

Los demás semánticos del núcleo (`text-money`, `text-negative`, `text-danger`, `text-info`, `text-on-fill`, `text-outline`) se quedan con el valor del núcleo: la 0.1.0 no los usa, salvo `text-outline` (negro), el contorno del texto del HUD.

## Paleta base

Colores en bruto: la interfaz usa los semánticos, que apuntan a estos. Ninguno se escribe a mano en un script.

| Token | Papel |
| --- | --- |
| `purple-950` | ventanas opacas en alto contraste |
| `purple-900` | el morado del juego: base de las ventanas |
| `purple-800`, `purple-700` | lo elegido (normal, alto contraste) |
| `purple-600` | separadores |
| `white`, `black` | texto principal y marco; contornos |
| `grey-200`, `grey-300` | texto secundario (alto contraste, normal) |
| `grey-400`, `grey-500` | texto desactivado (alto contraste, normal) |
| `yellow-300` | el acento: puntos, combo, títulos |
| `green-300` | el récord nuevo |
| `red-500` | la línea de peligro cuando cuenta |

## La escena

No son de la interfaz, pero son la paleta del juego: `JarBuilder`, `DropAim`, `DangerLine` y `CreatureLooks` los leen con `UiTokens.color()`.

| Token | Para |
| --- | --- |
| `scene-top`, `scene-bottom` | el degradado morado del fondo, de arriba abajo (`scene-bottom` es también el fondo de la web y de su arranque) |
| `scene-mote` | las motas de luz que flotan despacio |
| `jar-back` | el fondo del tarro, algo más oscuro que la escena |
| `jar-frame` | el marco claro del tarro, como de cristal |
| `aim-line` | la línea tenue que marca dónde caerá la criatura |
| `danger-line` | la línea de peligro en calma |
| `danger-line-alert` | la línea de peligro mientras cuenta: parpadea, más deprisa cuanto menos falta |
| `creature-silhouette` | la silueta de una criatura sin descubrir |

## Letras

- **Baloo 2** (`display`): redondeada y con cuerpo, como las criaturas. Para el nombre del juego, los puntos y el combo.
- **Nunito** (`ui`): redondeada y muy legible en pequeño. Para todo lo demás.

Las dos son libres (OFL, licencias en `assets/fonts/`) y variables; las dos vienen de Villaclaro.

## Tamaño

Toda la interfaz se dibuja 1,25 veces más grande que sus tokens (`DisplaySettings.UI_SCALE`): el lienzo mide 720 de ancho y un móvil en vertical lo enseña a unos 360 puntos. Las medidas de abajo están en esas unidades.

| Token | Medida | Para |
| --- | --- | --- |
| `button-big-w` × `button-big-h` | 400 × 80 | todo botón grande: título, fin, pausa, ventanas (más que `touch-target`) |
| `hud-button` | 64 | el botón de pausa del HUD |
| `next-view` | 80 | la criatura de «Siguiente» |
| `bestiary-view` | 160 | la criatura de una ficha del bestiario |
| `slider-w` | 240 | el deslizador de efectos |
| `hud-notice-top` | 136 | dónde empieza el aviso, bajo la fila del HUD |
| `hud-combo-top` | 196 | dónde empieza «¡Combo ×n!», sobre la boca del tarro |

## Capas

`layer-hud` 1 (el HUD y el menú del título) · `layer-window` 5 (las ventanas con velo). Una pantalla nueva elige su capa de esta lista; si no encaja, se añade aquí antes de usarla.
