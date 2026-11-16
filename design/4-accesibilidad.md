# Accesibilidad en ¡Plop!

Las reglas generales (4,5:1 en el tema normal, 7:1 en el de alto contraste, nunca solo color) están en la [accesibilidad del núcleo](../addons/design_system/docs/4-accesibilidad.md). Aquí, los pares comprobados con los valores del juego.

## Contraste

Sobre `surface-window-solid` (contraste WCAG):

| Texto | `juego` (`purple-900`) | `alto-contraste` (`purple-950`) |
| --- | --- | --- |
| `text-primary` | 17,6:1 | 19,2:1 |
| `text-secondary` | 8,9:1 | 13,6:1 |
| `text-disabled` | 4,8:1 | 7,0:1 |
| `text-accent` | 12,7:1 | 13,9:1 |
| `text-positive` | 10,6:1 | 11,6:1 |
| `border-focus` sobre `surface-selected` | 10,9:1 (`purple-800`) | 8,7:1 (`purple-700`) |
| `border-subtle` (separadores) | 2,2:1 (decorativo) | 7,0:1 |

Sobre la escena (el HUD no lleva ventana; todo su texto lleva contorno negro):

| Texto | `scene-top` | `scene-bottom` |
| --- | --- | --- |
| `text-primary` | 15,8:1 | 19,6:1 |
| `text-accent` | 11,4:1 | 14,1:1 |

## Tema «Alto contraste»

La opción de Opciones: ventanas opacas (`purple-950`), texto secundario y desactivado más claros, separadores visibles (7:1) y lo elegido más claro.

## Nunca solo color

- La línea de peligro, además de ponerse roja, parpadea, y más deprisa cuanto menos falta.
- El récord nuevo se dice con palabras: «¡Nuevo récord!».
- Una criatura sin descubrir es una silueta con «???».
- En un selector, la opción activa va rellena y dice «Sí» o «No».
