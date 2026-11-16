# Ideas

Ideas y pasos pendientes del juego. Cuando una idea pasa a un spec y al [documento maestro](documento-maestro.md), se borra de aquí.

La idea del juego, su arquitectura y la preparación ya están en el [spec de la 0.1.0](legacy/specs/2026-11-16-version-0-1-0-design.md), en el documento maestro y en [CLAUDE.md](../CLAUDE.md).

## 2026-11-16 · Lo que hay que mirar en un móvil de verdad

- **Los botones de las ayudas y la barra de gestos.** Romper y Cambiar están en las esquinas de abajo con un margen fijo: en un móvil con barra de gestos o esquinas redondeadas podrían quedar debajo. Si pasa, dejar margen con el área segura de la pantalla (`DisplayServer.get_display_safe_area()`).
- **La música al abrir la web.** El navegador no deja sonar nada hasta el primer toque, así que la melodía del título puede empezar de golpe, sin su entrada suave. Si se nota, empezarla con el primer toque.
- **El tirón al crear la música.** Cada melodía se genera una vez (unos 100 ms en el ordenador); en un móvil lento podría notarse al abrir el título o la primera partida. Si se nota, prepararla antes.
- **Ganar una ayuda.** Ahora solo cambia el número del botón; quizá merezca un pequeño destello o sonido.
