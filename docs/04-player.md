# 04 · Jugador: controles, movimiento, combate y estadísticas

## Controles

| Acción                          | Teclado        | Mando                                      | Acción en código                                      |
| ------------------------------- | -------------- | ------------------------------------------ | ----------------------------------------------------- |
| Moverse                         | A / D          | Stick izq. / cruceta                       | `move_left`, `move_right`                             |
| Bajar de plataforma atravesable | S (+ salto)    | Stick izq. abajo / cruceta abajo (+ A)     | `move_down`                                           |
| Saltar                          | Espacio        | A / Cruz                                   | `jump`                                                |
| Disparar ↑ ↓ ← →                | Flechas        | Stick derecho (4 direcciones); X ←, B →    | `shoot_up`, `shoot_down`, `shoot_left`, `shoot_right` |
| Túnel (esquiva)                 | Shift          | RB / R1                                    | `dash`                                                |
| Usar operador                   | E              | LB / L1                                    | `use_active`                                          |
| Interactuar (tienda, pedestal)  | W              | Cruceta arriba / Y                         | `interact`                                            |
| Ver build / estadísticas        | Tab (mantener) | Select / Back                              | `show_build`                                          |
| Pausa                           | Esc            | Start                                      | `pause`                                               |

- Todos los controles son **remapeables** desde Opciones (Fase 14).
- Las acciones están definidas en `project.godot` desde la Fase 2, con teclado y mando (cualquier dispositivo). Y no dispara hacia arriba porque ya interactúa; con mando, arriba se dispara con el stick derecho.
- Con mando, disparar hacia abajo en el aire es un recurso de movilidad (ver "Retroceso del disparo").

## Movimiento

El objetivo es un movimiento **preciso y agradable**, a la altura de un plataformas moderno. Los valores viven en el recurso `MovementConfig` (`data/movement/wilas_movement.tres`); la velocidad, el impulso y los saltos cuánticos son estadísticas (`speed`, `jump_force`, `max_jumps`), así que los objetos los modifican.

| Mecánica                 | Valor                                              | Descripción                                                                                           |
| ------------------------ | -------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Aceleración / frenado    | 0,08 s / 0,06 s en el suelo; 0,12 s / 0,16 s en el aire | Tiempo de 0 a la velocidad máxima (y al revés). No instantáneo, pero con respuesta inmediata; en el aire hay algo menos de agarre |
| Gravedad de subida       | 980 px/s²                                          | Con el impulso base (450 px/s) un salto desde el suelo sube unos 100 px                               |
| Gravedad de caída        | ×1,6                                               | Se cae más rápido de lo que se sube: sensación de peso                                                |
| Velocidad terminal       | 820 px/s                                           | Evita atravesar plataformas y caídas incontrolables                                                   |
| Salto de altura variable | conserva el 45 %                                   | Soltar el botón mientras se sube recorta la velocidad vertical una vez (también en los saltos aéreos) |
| _Coyote time_            | 0,1 s                                              | Se puede saltar desde el suelo poco después de dejar un borde, sin gastar saltos aéreos               |
| _Jump buffer_            | 0,12 s                                             | Un salto pulsado justo antes de tocar el suelo se ejecuta al aterrizar                                |
| Saltos cuánticos         | 2 (`max_jumps`)                                    | Cuentan el salto desde el suelo: hay `max_jumps − 1` saltos en el aire, con el 92 % del impulso. Salir de un borde sin saltar no gasta ninguno |
| Plataformas atravesables | 0,2 s                                              | Se atraviesan desde abajo; Abajo + salto sobre una de ellas la ignora 0,2 s (y hasta haberla cruzado del todo). Abajo + salto en suelo sólido es un salto normal |

- Un salto pulsado en el aire usa un salto cuántico en ese momento si queda alguno; si no queda, se guarda en el _buffer_ para el aterrizaje.
- Al tocar el suelo se recuperan los saltos cuánticos y el Túnel aéreo.

### Túnel (esquiva)

Mecánica base: una esquiva horizontal corta que Wilas recorre en "estado de onda".

- 0,15 s a 900 px/s (unos 135 px) con invulnerabilidad (_i-frames_) y sin gravedad; 0,6 s de recarga desde que termina. Sale del Túnel a la velocidad de carrera, no frenado en seco.
- Va en la dirección pulsada o, sin dirección, hacia donde mira Wilas. En el aire solo se puede hacer **un Túnel** hasta volver a tocar el suelo (`air_dashes`).
- Atraviesa enemigos y proyectiles (es invulnerable), pero no paredes (salvo con ciertas interacciones u observables).
- También sirve para revelar **tramos secretos**: las paredes sospechosas se atraviesan con el Túnel.
- Es una ranura de interacción (como el dash de Hades), así que da mucho juego a los builds.

### Estados

El jugador es una máquina de estados pequeña: `idle`, `run`, `jump` (sube), `fall` (cae), `dash` (Túnel), `hurt` (retroceso tras un golpe) y `dead`. Cada cambio emite `state_changed` y decide la expresión y la animación de Wilas.

### Sala de pruebas de movimiento

`world/debug/movement_test_room.tscn` (ejecútala con F6) sirve para ajustar el movimiento: plataformas a 60, 100, 150 y 190 px de altura (un salto llega a ~100; con el salto cuántico, a ~190), huecos de 140, 200 y 240 px, un hueco de 470 px que pide doble salto y Túnel, una pila de plataformas atravesables y pinchos. Muestra el estado del jugador (velocidad, _coyote_, _buffer_, saltos y recarga del Túnel) y dibuja su trayectoria. **R** vuelve al inicio, **T** activa o desactiva la Decoherencia y **F** muestra u oculta la trayectoria. En la sala no se muere: la coherencia se rellena al bajar de la mitad.

## Combate

### Disparo

- 4 direcciones fijas. Mantener pulsado dispara de forma continua según la **Frecuencia**.
- Los proyectiles heredan una parte pequeña de la velocidad del jugador (como en Isaac).
- Se destruyen al superar el **Alcance** o al chocar con una plataforma (salvo con modificadores).
- **Retroceso del disparo:** disparar hacia abajo en el aire frena un poco la caída. No es un salto extra, pero da control.

Implementado en la Fase 6:

- `PlayerInput.shoot_direction` lee los ejes de `shoot_*`; el `Shooter` del jugador (`combat/shooter.gd`) lo ajusta a 4 direcciones (en diagonal gana la vertical) y dispara mientras se mantenga, con `1 / attack_rate` segundos entre disparos (2,5 disparos/s de base). Cada disparo crea un `ProjectileSpec` con la Carga (`attack_power`, daño) y el Alcance (`attack_range`, distancia) del momento; los modificadores de proyectil lo transformarán desde la Fase 7.
- El proyectil vuela a 900 px/s más el **25 %** de la velocidad de Wilas y nace a 18 px de su centro. Atraviesa las plataformas atravesables y se detiene en las paredes y niveles de energía (un rayo por fotograma, así que no los atraviesa aunque vaya rápido), en el primer enemigo (más `pierce` si lo tiene) o al agotar su alcance.
- Se dispara en reposo, corriendo y en el aire, pero no durante el Túnel ni en el retroceso de un golpe. Disparar hacia un lado gira a Wilas.
- **Retroceso del disparo:** cada disparo hacia abajo en el aire, si Wilas cae, le resta 140 px/s de velocidad de caída (`MovementConfig.shoot_down_recoil`) sin llegar nunca a impulsarla hacia arriba.

### Recibir daño

- Daño de contacto con enemigos, proyectiles enemigos, peligros y la Decoherencia.
- Tras recibir daño: 1 s de invulnerabilidad con parpadeo y un pequeño retroceso (0,2 s sin control, alejándose del golpe y un poco hacia arriba).
- La Decoherencia es la excepción: quita siempre el 25 % de la coherencia máxima, sin apantallamiento ni invulnerabilidad (ver [03-partida](03-run.md#la-decoherencia-amenaza-ascendente)).
- `daño_final = daño × (1 − apantallamiento)`, con el apantallamiento limitado al 60 %.
- Implementación (Fase 6): Wilas recibe los golpes en su `Hurtbox` (24×32 px, algo menor que su colisión, para que los roces no cuenten), que llama a `Player.take_hit(DamageInfo)`. Los enemigos, sus proyectiles y los peligros llevan un `Hitbox`. Cada golpe guarda su origen, que es la **causa de la muerte** si la coherencia llega a 0. Al recibir daño hay un _hitstop_ de 60 ms (ver [12-arquitectura](12-architecture.md#combate)).

### Ranuras de interacción

Las interacciones (ver [07-objetos](07-items.md)) ocupan **ranuras** asociadas a acciones, como en Hades:

| Ranura  | Código      | Qué modifica                         |
| ------- | ----------- | ------------------------------------ |
| Disparo | `slot_shot` | Los proyectiles                      |
| Salto   | `slot_jump` | Efecto al saltar o en el salto aéreo |
| Túnel   | `slot_dash` | Efecto de la esquiva                 |
| Campo   | `slot_aura` | Efecto pasivo constante o por evento |

Una ranura solo admite una interacción. Si se elige otra para la misma ranura, **sustituye** a la anterior (se avisa antes de aceptar).

## Estadísticas

Los nombres temáticos y los de código están en [02-universo](02-universe.md#protagonista-y-estadísticas).

| Estadística       | Código         | Base (Wilas) | Límite  | Nota                                                                |
| ----------------- | -------------- | ------------ | ------- | ------------------------------------------------------------------- |
| Coherencia máxima | `max_hp`       | 100          | 400     |                                                                     |
| Amplitud          | `luck`         | 0            | 100     | Cada punto modifica probabilidades (ver [08-semillas](08-seeds.md)) |
| Momento           | `speed`        | 300 px/s     | 550     |                                                                     |
| Impulso           | `jump_force`   | 450 px/s     | 750     |                                                                     |
| Saltos cuánticos  | `max_jumps`    | 2            | 5       |                                                                     |
| Longitud de onda  | `size`         | 1,0          | 0,6–1,4 | Escala del sprite y de la colisión                                  |
| Carga             | `attack_power` | 5            | —       |                                                                     |
| Frecuencia        | `attack_rate`  | 2,5 disp/s   | 10      |                                                                     |
| Alcance           | `attack_range` | 450 px       | 1200    |                                                                     |
| Apantallamiento   | `defense`      | 0 %          | 60 %    |                                                                     |

### Cómo se calculan las estadísticas

```
valor_final = (base_personaje + Σ sumas) × Π (1 + multiplicadores) , limitado a [mín, máx]
```

- `base_personaje` viene de `CharacterData`.
- Las **sumas** y los **multiplicadores** vienen de: mejoras del Campo de Higgs, observables, interacciones y efectos temporales.
- Cada modificador lleva su **origen** (qué objeto o mejora lo aplica), para poder quitarlo y para mostrar el desglose en la pantalla de build.

## Personajes

Se desbloquean en el **Espectro** con bosones de Higgs (ver [10-meta](10-meta.md)).

| Personaje    | Código     | Estilo               | Diferencias                                                                                             |
| ------------ | ---------- | -------------------- | ------------------------------------------------------------------------------------------------------- |
| **Wilas**    | `wilas`    | Equilibrado          | Estadísticas base de la tabla anterior                                                                  |
| **Muón**     | `muon`     | Tanque               | +60 % coherencia, −15 % momento, proyectiles lentos y grandes (+40 % carga, −30 % frecuencia)           |
| **Neutrino** | `neutrino` | Frágil y escurridizo | 60 de coherencia, +25 % momento, el Túnel atraviesa paredes finas, casi invisible para algunos enemigos |
| **Tau**      | `tau`      | Riesgo y recompensa  | Estadísticas altas, pero la coherencia **decae** lentamente; eliminar enemigos la restaura              |
