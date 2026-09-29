# 04 · Jugador: controles, movimiento, combate y estadísticas

## Controles

| Acción                          | Teclado        | Mando                                 | Acción en código                                      |
| ------------------------------- | -------------- | ------------------------------------- | ----------------------------------------------------- |
| Moverse                         | A / D          | Stick izq. / cruceta                  | `move_left`, `move_right`                             |
| Bajar de plataforma atravesable | S (+ salto)    | Abajo + A                             | `move_down`                                           |
| Saltar                          | Espacio        | A / Cruz                              | `jump`                                                |
| Disparar ↑ ↓ ← →                | Flechas        | Stick derecho (4 direcciones) / X Y B | `shoot_up`, `shoot_down`, `shoot_left`, `shoot_right` |
| Túnel (esquiva)                 | Shift          | RB / R1                               | `dash`                                                |
| Usar operador                   | E              | LB / L1                               | `use_active`                                          |
| Interactuar (tienda, pedestal)  | W              | Arriba / Y                            | `interact`                                            |
| Ver build / estadísticas        | Tab (mantener) | Select / Back                         | `show_build`                                          |
| Pausa                           | Esc            | Start                                 | `pause`                                               |

- Todos los controles son **remapeables** desde Opciones.
- Con mando, disparar hacia abajo en el aire es un recurso de movilidad (ver "Retroceso del disparo").

## Movimiento

El objetivo es un movimiento **preciso y agradable**, a la altura de un plataformas moderno.

| Mecánica                 | Valor inicial                     | Descripción                                                                                           |
| ------------------------ | --------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Aceleración / frenado    | ~0,08 s hasta la velocidad máxima | No instantáneo, pero con respuesta inmediata                                                          |
| Salto de altura variable | —                                 | Soltar el botón antes corta el salto                                                                  |
| _Coyote time_            | 0,1 s                             | Se puede saltar poco después de dejar un borde                                                        |
| _Jump buffer_            | 0,12 s                            | Un salto pulsado justo antes de tocar el suelo se ejecuta al aterrizar                                |
| Saltos cuánticos         | 2                                 | El primer salto en el aire consume un salto extra; salir de un borde sin saltar no consume el primero |
| Gravedad de caída        | ×1,6                              | Se cae más rápido de lo que se sube: sensación de peso                                                |
| Velocidad terminal       | limitada                          | Evita atravesar plataformas y caídas incontrolables                                                   |
| Plataformas atravesables | —                                 | Se atraviesan desde abajo; Abajo + salto para bajar                                                   |

### Túnel (esquiva)

Mecánica base: una esquiva horizontal corta que Wilas recorre en "estado de onda".

- 0,15 s de duración con invulnerabilidad (_i-frames_), 0,6 s de recarga.
- Atraviesa enemigos y proyectiles, pero no paredes (salvo con ciertas interacciones u observables).
- También sirve para revelar **tramos secretos**: las paredes sospechosas se atraviesan con el Túnel.
- Es una ranura de interacción (como el dash de Hades), así que da mucho juego a los builds.

## Combate

### Disparo

- 4 direcciones fijas. Mantener pulsado dispara de forma continua según la **Frecuencia**.
- Los proyectiles heredan una parte pequeña de la velocidad del jugador (como en Isaac).
- Se destruyen al superar el **Alcance** o al chocar con una plataforma (salvo con modificadores).
- **Retroceso del disparo:** disparar hacia abajo en el aire frena un poco la caída. No es un salto extra, pero da control.

### Recibir daño

- Daño de contacto con enemigos, proyectiles enemigos, peligros y la Decoherencia.
- Tras recibir daño: 1 s de invulnerabilidad con parpadeo y un pequeño retroceso.
- `daño_final = daño × (1 − apantallamiento)`, con el apantallamiento limitado al 60 %.

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
