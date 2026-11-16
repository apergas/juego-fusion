# Ideas

Ideas y pasos pendientes del juego. Cuando una idea pasa a un spec y al [documento maestro](documento-maestro.md), se borra de aquí.

La idea del juego, su arquitectura y la preparación ya están en el [spec de la 0.1.0](specs/2026-11-16-version-0-1-0-design.md), en el documento maestro y en [CLAUDE.md](../CLAUDE.md).

## 2026-11-16

- **Pausar sola al pasar a segundo plano (0.2.0).** Cuando el juego pierde el foco (cambio de app en el móvil, pestaña oculta en la web), pausar la partida con `NOTIFICATION_APPLICATION_FOCUS_OUT` / `NOTIFICATION_WM_WINDOW_FOCUS_OUT`: ahora la física y la cuenta del peligro siguen corriendo y se puede perder sin mirar.
- **Descubrir criaturas en silencio.** Al conseguir una criatura nueva no sale nada: ni el aviso «¡Nueva criatura: …!» en la partida, ni su sonido, ni nada en la ventana final. Lo descubierto solo se ve al entrar en el Bestiario, donde aparecen las que ya has visto y el resto sigue como «???». Se sigue guardando igual. Quitarlo toca `Game` (el aviso y el sonido al descubrir), `Bestiary.NEW_TEXT` y el aviso del `Hud` si nadie más lo usa; la línea `Nueva:` de la partida automática se queda.
