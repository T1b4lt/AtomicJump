# ROADMAP

Plan para llevar AtomicJump desde el prototipo actual (v0.4) hasta la **v0.99.0**: el juego descrito en la [documentación de diseño](README.md#documentación-de-diseño), completo, jugable y publicado en itch.io.

La **v1.0** llegará después de la 0.99.0. Antes faltan cosas que quedan **fuera de este roadmap** (la música y el pulido final a partir del feedback de los jugadores), recogidas junto al resto de ideas en [99-ideas a futuro](docs/99-future-ideas.md).

## Cómo usar este roadmap

- Las fases van **en orden**: cada una se apoya en las anteriores. Dentro de una fase, las tareas pueden reordenarse.
- Cada fase se trabaja en una o varias ramas con PR a `main`, con commits convencionales (release-please genera la versión y el CHANGELOG).
- Una fase está **terminada** cuando se cumplen sus _criterios de terminado_, pasan los tests y la documentación refleja cualquier cambio de diseño.
- Si durante una fase cambia una decisión de diseño, se actualiza primero el documento en `docs/` y después el código.
- Marca las tareas con `[x]` al completarlas.
- El arte se produce **a la vez** que cada sistema, con el generador de `art/` y el estilo final ([13-dirección de arte](docs/13-art-style.md)). No hay fase de arte provisional: las tareas marcadas con **Arte:** van dentro de cada fase.
- Lo que no está aquí (música, semilla diaria, guardar a mitad de partida, diálogos completos, Steam…) está en [99-ideas a futuro](docs/99-future-ideas.md).

## Hitos

| Hito                           | Fases | Resultado                                                                                                      |
| ------------------------------ | ----- | -------------------------------------------------------------------------------------------------------------- |
| **A · Cimientos**              | 0–3   | Proyecto limpio, sin bugs conocidos, arquitectura y semillas correctas. Jugablemente similar al prototipo.     |
| **B · Demo Capa K**            | 4–9   | Una capa completa jugable con combate, objetos, interacciones, tienda y jefe. Publicable en itch.io como demo. |
| **C · Juego completo (alpha)** | 10–12 | Núcleo con meta-progresión, 4 capas, victoria, personajes, Entropía y Modo Plasma. Arte con el estilo final, aún sin pulir. |
| **D · v0.99.0**                | 13–15 | Pasada final de arte y SFX, pulido, accesibilidad, idiomas, balance y publicación de la 0.99.0 en itch.io.     |

---

## Fase 0 · Puesta a punto del proyecto

**Objetivo:** dejar el repositorio y las herramientas listos para trabajar con seguridad.

- [x] Commitear la migración a Godot 4.7 (`project.godot`, `*.import`, `*.gd.uid`).
- [x] Revisar `.gitignore` (mantener `.godot/`; añadir `*.tmp`, `export/` y builds).
- [x] Añadir `.editorconfig` (tabs en `.gd`, LF, UTF-8).
- [x] Activar avisos de GDScript como error: `untyped_declaration`, `unsafe_*` y `unused_*` (ajustar si son demasiado ruidosos).
- [x] Instalar **gdtoolkit** (`gdformat`, `gdlint`) con configuración en el repo; formatear el código existente.
- [x] Instalar **gdUnit4** y crear un test trivial que pase en modo _headless_.
- [x] Workflow de CI: lint + tests en cada PR.
- [x] Ampliar `AGENTS.md` con convenciones, comandos (ejecutar, testear, lint) y enlace a `docs/`.
- [x] Crear presets de exportación (Windows y Linux) y comprobar que el proyecto exporta.

**Terminado cuando:** CI en verde en una PR de prueba y el juego se ejecuta y exporta con 4.7.

## Fase 1 · Corrección de bugs del prototipo

**Objetivo:** arreglar los fallos detectados antes de refactorizar, para tener una referencia de comportamiento correcto.

- [x] Reiniciar el estado de partida también al volver al menú desde la pausa (hoy solo se reinicia desde Game Over).
- [x] Hacer que las semillas generadas se puedan volver a introducir. Solución provisional hasta la Fase 3: generar siempre números de 9 dígitos positivos, o aceptar cualquier entero.
- [x] Permitir reanudar con Esc desde la pausa (`process_mode` del manejo de input).
- [x] Hacer explícita la lógica de saltos: contar los saltos aéreos sin depender de que `is_on_floor()` sea verdadero justo después de saltar.
- [x] Pinchos: daño continuo con invulnerabilidad mientras se está en contacto, en lugar de un único golpe al entrar.
- [x] Corregir la vida inicial (100) frente a la máxima (110), o documentar por qué son distintas.
- [x] Corregir comentarios erróneos (por ejemplo, "Go to game over screen" al ir al menú en `level.gd`).

**Terminado cuando:** todos los bugs de la lista están corregidos y comprobados jugando.

## Fase 2 · Refactor de fundamentos

**Objetivo:** sustituir los patrones del prototipo por la arquitectura de [12-arquitectura](docs/12-architecture.md), manteniendo la misma jugabilidad.

- [x] Reorganizar carpetas según la estructura objetivo (mover escenas desde el editor de Godot para que se actualicen las referencias).
- [x] Sustituir el autoload `game` por `RunManager` + `RunState` (se crea uno nuevo por partida; se elimina `reset_game()`).
- [x] Sistema de estadísticas: `StatBlock`, `StatModifier`, `Stats` con caché y señal `stat_changed`; `CharacterData` para Wilas.
- [x] HUD y barra de vida actualizados por **señales**; eliminar el refresco en `_process`.
- [x] Autoloads `Events`, `SceneRouter` (con transición) y `Settings` (con carga y guardado, aunque las opciones aún sean pocas).
- [x] Sustituir números mágicos (`670`, `/11`, `+50`) por constantes o `@export`; `get_viewport_rect()` en lugar de `get_viewport().size`.
- [x] `preload()` para escenas fijas.
- [x] Nodos con nombre único (`%Nombre`) en la UI.
- [x] Capas de física según la tabla de la arquitectura.
- [x] Migrar el viewport de 1160×670 a 1280×720 con `canvas_items` / `keep_width` ([13-dirección de arte](docs/13-art-style.md)).
- [x] Renombrar acciones de input (`move_left`, `move_right`…) y añadir las de mando.
- [x] Localización: CSV de traducción, `tr()` en todos los textos visibles, idioma inicial español.
- [x] Tipado estático en todo el código (adelantado a la Fase 0: era necesario al activar los avisos como error).
- [x] Tests unitarios de `Stats` y `RunState`.

**Terminado cuando:** el juego se comporta como tras la Fase 1, no quedan avisos de tipado y los tests de estadísticas pasan.

## Fase 3 · Sistema de semillas

**Objetivo:** reproducibilidad real según [08-semillas](docs/08-seeds.md).

- [ ] `SeedCode`: generación de 8 caracteres en base32 Crockford, formato `XXXX-XXXX`, normalización de texto libre y conversión a entero de 64 bits.
- [ ] `SeedHash`: hash estable propio (FNV-1a + SplitMix64) con tests de valores conocidos.
- [ ] `WorldRng`: `roll`, `roll_int`, `pick_weighted` (_rendezvous hashing_) y `local_rng`.
- [ ] Constante `GENERATION_VERSION`.
- [ ] Migrar la generación actual (elección de plataforma y colocación de objetos) a tiradas direccionadas.
- [ ] Colocación de objetos sin bucles potencialmente infinitos (barajar huecos de forma determinista).
- [ ] UI de semilla: campo que acepta texto libre, botones Aleatoria y Pegar; mostrar `semilla · gN` en HUD y Game Over, con botón Copiar.
- [ ] Tests: semillas doradas, monotonía e independencia del orden.

**Terminado cuando:** la misma semilla produce la misma partida en dos ejecuciones y los tres tipos de test pasan.

---

## Fase 4 · Movimiento, cámara y Decoherencia

**Objetivo:** que moverse sea un placer y sustituir la cámara con auto-scroll por la amenaza ascendente.

- [ ] Máquina de estados del jugador (`idle`, `run`, `jump`, `fall`, `dash`, `hurt`, `dead`).
- [ ] `MovementConfig` (recurso): aceleración, frenado, gravedad de subida y de caída, velocidad terminal.
- [ ] Salto variable, _coyote time_, _jump buffer_ y saltos cuánticos configurables.
- [ ] Plataformas atravesables y bajar con Abajo + salto.
- [ ] Túnel (esquiva): 0,15 s con invulnerabilidad, 0,6 s de recarga ([04-jugador](docs/04-player.md#túnel-esquiva)).
- [ ] Cámara que sigue al jugador con _look-ahead_ vertical y límites laterales.
- [ ] `RisingThreat`: velocidad base, goma elástica, pausa en tramos seguros, daño del 25 % y reaparición en plataforma segura.
- [ ] Indicador de distancia a la Decoherencia en el HUD.
- [ ] Escena de depuración de movimiento (sala de pruebas con distintos saltos).
- [ ] **Arte:** `build_game_assets.py` que exporta a `assets/generated/` (SVG sin filtros ni texto, manifiesto).
- [ ] **Arte:** Wilas final por piezas (núcleo, orbital, electrón, ojos) con sus animaciones en el motor; verificar el glow en *Compatibility* (o shader de bloom); shader de la Decoherencia.

**Terminado cuando:** el movimiento se siente preciso en la sala de pruebas y morir por la Decoherencia funciona según [03-partida](docs/03-run.md#la-decoherencia-amenaza-ascendente).

## Fase 5 · Pipeline de tramos y generación de capas

**Objetivo:** poder diseñar tramos rápidamente y encadenarlos según [05-mundo](docs/05-world.md).

- [ ] **Arte:** tileset de la Capa K generado (niveles de energía, niveles virtuales, retícula, picos de potencial) con colisiones y tiles atravesables.
- [ ] `chunk_template.tscn` con TileMapLayers, marcadores de entrada y salida, huecos y script `Chunk`.
- [ ] `ChunkData` (metadatos) y `ChunkLibrary` (indexa los tramos por capa, tipo y dificultad).
- [ ] Validador `@tool` en el editor (marcadores obligatorios, límites, huecos solapados).
- [ ] Variación: espejo y plataformas opcionales.
- [ ] `LayerData` para la Capa K y `LayerGenerator` (secuencia, ramas y compatibilidad entrada/salida).
- [ ] Instanciación perezosa y liberación de tramos (sustituye al sistema actual de las señales `screen_entered`/`screen_exited` de `Chunk`).
- [ ] Tramos de bifurcación con dos salidas, iconos de recompensa y colapso de la rama no elegida.
- [ ] Tramos especiales: entrada de capa, recompensa y descanso.
- [ ] **Arte:** shader del fondo orbital 1s de la Capa K.
- [ ] Convertir `initial`, `platform_1` y `platform_2` al nuevo formato y crear hasta 8 tramos normales de la Capa K.
- [ ] Escena de depuración para jugar un tramo suelto.
- [ ] Tests de generación: la secuencia respeta la plantilla y la compatibilidad, y es determinista.

**Terminado cuando:** una partida recorre una Capa K generada con bifurcaciones y todo es reproducible por semilla.

## Fase 6 · Combate y enemigos

**Objetivo:** disparar y enfrentarse a los enemigos de la Capa K.

- [ ] `HealthComponent`, `Hitbox`, `Hurtbox`, `DamageInfo`.
- [ ] Invulnerabilidad y retroceso al recibir daño; _hitstop_ básico.
- [ ] `Shooter` en 4 direcciones con Frecuencia, Alcance y Carga; `ProjectileSpec`; proyectiles con herencia de velocidad; retroceso al disparar hacia abajo.
- [ ] `EnemyData` y enemigo base con comportamientos reutilizables (patrulla, órbita, carga).
- [ ] Enemigos de la Capa K: electrón orbital, neutrón libre (con decaimiento) y partícula alfa.
- [ ] Huecos de enemigo rellenados por semilla; caídas direccionadas.
- [ ] Sistema de estados alterados (base para Inestable, Dilatado, etc.).
- [ ] Contadores de partida: enemigos eliminados y causa de muerte.
- [ ] **Arte:** enemigos de la Capa K, proyectiles, impactos y trazas de cámara de burbujas.

**Terminado cuando:** se puede superar la Capa K combatiendo contra los 3 enemigos, con daño en ambos sentidos.

## Fase 7 · Economía y objetos

**Objetivo:** divisas, contenedores, tienda y observables según [06-economía](docs/06-economy.md) y [07-objetos](docs/07-items.md).

- [ ] Recogibles: `coin` (1/5/10) con atracción, `key` y `heal_pickup`.
- [ ] Contenedores: `chest` común (paga fotones), `chest` especial (positrón), `choice_pedestal`, `item_pedestal`.
- [ ] `ItemData` y sistema de **efectos** (stat, on-hit, on-pickup, projectile modifier…).
- [ ] Pools, rarezas y efecto de la Amplitud, con las reglas de monotonía.
- [ ] ~15 observables (incluidos los de estadísticas simples y 5 con efectos) y 1 transformación por etiqueta.
- [ ] Operadores: ranura, recarga por tramos y 2 operadores (Efecto Zenón, Colapso).
- [ ] Tramo de Intercambio con el Pión: inventario por semilla, compra y reroll.
- [ ] Tramo de Estado fundamental: elegir entre curar el 40 % o +10 de coherencia máxima.
- [ ] Pantalla de build (Tab / pausa) con desglose de estadísticas.
- [ ] **Arte:** recogibles, contenedores y sistema de iconos (marco + glifo + joya) con los iconos de esta fase y de la siguiente.

**Terminado cuando:** una partida de la Capa K tiene economía completa y los objetos cambian el estilo de juego de forma perceptible.

## Fase 8 · Interacciones

**Objetivo:** el sistema de bendiciones estilo Hades.

- [ ] `BoonData`, ranuras (Disparo, Salto, Túnel, Campo), pasivas y niveles.
- [ ] Hooks del jugador para las ranuras (al disparar, al saltar en el aire, al hacer el Túnel, aura).
- [ ] UI de elección (1 de 3), aviso de sustitución y pausa durante la elección.
- [ ] Recompensas de rama `reward_boon` conectadas a los bosones mensajeros (representación provisional).
- [ ] 3–4 interacciones por familia (EM, Fuerte, Débil, Gravitatoria) y 2 cuánticas.
- [ ] 2 unificaciones (Electrodébil y Lente gravitatoria) con su lógica de requisitos.

**Terminado cuando:** se pueden construir builds claramente distintos centrados en cada familia.

## Fase 9 · Vertical slice: Capa K completa ★ Hito B

**Objetivo:** una capa pulida de principio a fin que sirva de demo y de referencia para las demás.

- [ ] Jefe **Par de Pauli** con 2 fases y arena propia.
- [ ] ~15 tramos normales de la Capa K + 1 excitado + 1 secreto.
- [ ] Curva de dificultad de la capa y velocidad de la Decoherencia ajustadas.
- [ ] Transición de capa (presentación "CAPA K — 1s").
- [ ] **Tarjeta de partida** final completa ([11-interfaz](docs/11-ui.md#tarjeta-de-partida-pantalla-final)) con puntuación, build y copiar o rejugar semilla.
- [ ] Menú principal simplificado (Jugar, Opciones, Salir).
- [ ] **Arte:** Par de Pauli, transición de capa y tarjeta de partida.
- [ ] SFX de la Capa K sintetizados por código (la demo no lleva música).
- [ ] Primera pasada de balance y 3–5 sesiones de _playtest_ con otras personas.
- [ ] Publicar la demo en itch.io (build Windows/Linux).

**Terminado cuando:** otra persona puede jugar la demo sin explicaciones, entiende la bifurcación, la Decoherencia y la semilla, y quiere repetir.

---

## Fase 10 · Meta-progresión y el Núcleo

**Objetivo:** el bucle entre partidas según [10-meta](docs/10-meta.md).

- [ ] `MetaProgress` + `SaveSystem` (JSON versionado, migraciones y tests).
- [ ] Quarks y bosones de Higgs: caídas, recompensas de rama y bonus final.
- [ ] Escena jugable del **Núcleo**; al morir se vuelve aquí.
- [ ] Estación **Salto al orbital 1s** (inicio de partida y semilla).
- [ ] **Campo de Higgs** con ~10 mejoras iniciales y reembolso.
- [ ] **Acelerador**: pool inicial reducido y síntesis de desbloqueos.
- [ ] **Cámara de burbujas** básica: estadísticas globales e historial de semillas.
- [ ] Mejoras aplicadas a la partida respetando la monotonía de las semillas (test).
- [ ] **Arte:** escena del Núcleo y sus estaciones.

**Terminado cuando:** 5 partidas seguidas muestran una progresión permanente clara y el guardado sobrevive a cerrar el juego.

## Fase 11 · Capas L, M y N ★ Hito C (parte 1)

**Objetivo:** el resto del átomo. Una sub-fase por capa, con el mismo esquema que la Fase 9.

Por cada capa (L, M, N):

- [ ] **Arte:** tileset, shader del fondo orbital (2p, 3d, 4f), enemigos y jefe de la capa.
- [ ] Peligros nuevos de la capa.
- [ ] 3 enemigos de la capa ([09-enemigos](docs/09-enemies.md)).
- [ ] ~15 tramos normales + especiales.
- [ ] Jefe con sus fases.
- [ ] `LayerData` y balance de la capa.

Al terminar las tres:

- [ ] **Ionización** (victoria), con secuencia final y tarjeta de victoria.
- [ ] Desbloqueos por primera victoria.

**Terminado cuando:** se puede ganar una partida completa K→N.

## Fase 12 · Profundidad y rejugabilidad ★ Hito C (parte 2)

- [ ] Contenido hasta el objetivo v1.0: ~60 observables, ~8 operadores, ~30 interacciones y todas las unificaciones.
- [ ] Transformaciones por etiqueta.
- [ ] Personajes Muón, Neutrino y Tau, y la estación **Espectro**.
- [ ] **Entropía**: Generador de Entropía y ~10 perturbaciones con su multiplicador.
- [ ] Campo de Higgs completo (~20 mejoras).
- [ ] Logros y registro de trazas (colección) en la Cámara de burbujas.
- [ ] **Modo Plasma** (capas O, P, Q y ciclo infinito) con su propia tabla de puntuación, separada de las partidas normales.
- [ ] Tramos secretos y excitados en todas las capas.
- [ ] Frases cortas de los bosones mensajeros y del Pión al ofrecer interacciones y en la tienda (los diálogos completos quedan en [ideas a futuro](docs/99-future-ideas.md)).

**Terminado cuando:** el juego tiene contenido para más de 20 horas y cada partida se siente distinta.

---

## Fase 13 · Pasada final de arte y SFX

El arte se ha ido produciendo en cada fase; esta es la pasada de coherencia y pulido. La música no entra (ver [ideas a futuro](docs/99-future-ideas.md)).

- [x] Dirección de arte decidida: [13-dirección de arte](docs/13-art-style.md) y [propuesta visual](docs/assets/art-direction/index.html).
- [ ] Revisión de coherencia global con una hoja de contactos de todos los assets.
- [ ] Estelas de proyectil por familia de interacción y VFX de estados alterados.
- [ ] VFX de alto impacto: muertes de jefe, Ionización, transiciones de capa.
- [ ] Tema de UI final (fuentes, paneles, botones).
- [ ] SFX completos (uno por familia de interacción).
- [ ] Eliminar los assets de Kenney y cualquier asset huérfano del manifiesto.
- [ ] Validar la paleta con un simulador de daltonismo.

## Fase 14 · Pulido, opciones y accesibilidad

- [ ] Menú de opciones completo ([11-interfaz](docs/11-ui.md#opciones)).
- [ ] Remapeo de controles de teclado y mando.
- [ ] Traducción al inglés completa.
- [ ] Accesibilidad: modo daltónico, tamaño de texto, reducir destellos y sacudida de cámara.
- [ ] _Game feel_: hitstop, squash & stretch, partículas y transiciones.
- [ ] Tutorial integrado en los primeros tramos de la Capa K (sin pantallas de texto).
- [ ] Menú o consola de depuración excluida de las builds de release.

## Fase 15 · Beta, balance y publicación de la v0.99.0 ★ Hito D

- [ ] Beta cerrada con testers: formulario de feedback y registro local de estadísticas de partida exportable.
- [ ] Pasada de balance global: economía, curvas de dificultad, rarezas y Entropía.
- [ ] Rendimiento: perfilado en hardware modesto (60 FPS estables).
- [ ] Pipeline de release: CI que exporta Windows y Linux y los adjunta a la GitHub Release.
- [ ] Página de itch.io (capturas, GIFs, descripción). Steam queda para más adelante.
- [ ] Revisar y fijar `GENERATION_VERSION` para la 0.99.0.
- [ ] **Publicar la v0.99.0** en itch.io.

---

## Después de la v0.99.0

El camino hasta la v1.0 (música y pulido final) y el resto de ideas (semilla diaria, guardar a mitad de partida, diálogos completos, Steam, Steam Deck, más contenido) están en [99-ideas a futuro](docs/99-future-ideas.md).
