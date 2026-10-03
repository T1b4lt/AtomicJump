# 03 · Estructura de una partida

## Bucle general

```
Núcleo (lobby) ──► Salto al orbital 1s ──► Capa K ──► Capa L ──► Capa M ──► Capa N ──► Ionización (victoria)
     ▲                                        │          │          │          │
     └──────────── decoherencia (muerte) ◄────┴──────────┴──────────┴──────────┘
```

1. En el **Núcleo** el jugador gasta la moneda permanente, elige personaje, configura la Entropía y, si quiere, introduce una semilla.
2. Empieza la partida en la base de la **Capa K** con las estadísticas del personaje más las mejoras permanentes. Todo lo demás (objetos, interacciones, fotones, positrones) empieza a cero.
3. Asciende tramo a tramo, eligiendo ruta en las bifurcaciones, hasta el **tramo del jefe** de la capa.
4. Al derrotar al jefe pasa a la siguiente capa.
5. Al derrotar al jefe de la Capa N se produce la **Ionización**: victoria.
6. Al morir, o al ganar, vuelve al Núcleo con los quarks y los bosones de Higgs conseguidos.

## Anatomía de una capa

Cada capa es una secuencia de **tramos** (una pantalla de alto cada uno, ver [05-mundo](05-world.md)). Estructura propuesta para v1.0 (unos 16 tramos por capa):

```
[Jefe]                    ← arena, la Decoherencia se detiene
[Estado fundamental]      ← tramo seguro: curación, Decoherencia en pausa
[Tramo] [Tramo]
[Bifurcación]  ← elige recompensa
[Tramo] [Tramo] [Tramo]
[Intercambio]             ← tienda garantizada a mitad de capa
[Bifurcación]
[Tramo] [Tramo] [Tramo]
[Bifurcación]
[Tramo] [Tramo]
[Entrada de capa]         ← tramo seguro, presentación del bioma
```

- La longitud y el número de bifurcaciones son **datos** de cada capa (`LayerData`), no están fijados en el código.
- Las capas superiores tienen más tramos, más enemigos y tramos más difíciles.

## Bifurcaciones (estilo Hades)

- Una bifurcación es un tramo cuya parte superior tiene **dos salidas** (izquierda y derecha). Sobre cada una flota un **icono de recompensa**: el jugador ve qué obtendrá antes de elegir.
- Al cruzar una salida, la otra **colapsa** (se cierra con un efecto visual).
- La recompensa aparece en el siguiente tramo (el **tramo de recompensa**, al final de la rama) y se obtiene al superarlo.
- Cada rama puede ser de distinta longitud y dificultad. Las recompensas mejores tienden a estar tras las ramas más difíciles.

### Tipos de recompensa de rama

| Icono                 | Recompensa                                                                                    | Código             |
| --------------------- | --------------------------------------------------------------------------------------------- | ------------------ |
| Símbolo de la familia | Interacción de un bosón mensajero (elige 1 de 3)                                              | `reward_boon`      |
| Ojo                   | Observable (pedestal o Superposición)                                                         | `reward_item`      |
| γ                     | Montón de fotones                                                                             | `reward_coins`     |
| e⁺                    | Positrón                                                                                      | `reward_key`       |
| Corazón-onda          | Aumento de coherencia máxima                                                                  | `reward_max_hp`    |
| q                     | Quarks (moneda permanente)                                                                    | `reward_meta`      |
| ⚠ + recompensa        | **Tramo excitado**: reto más difícil (Decoherencia rápida, más enemigos) con doble recompensa | `reward_challenge` |
| Balanza               | Intercambio (tienda extra)                                                                    | `reward_shop`      |

## La Decoherencia (amenaza ascendente)

- Es una franja que sube desde abajo. Tocarla quita **el 25 % de la coherencia máxima** y teletransporta a Wilas a la última plataforma segura sobre ella. Si ya no tiene coherencia, muere.
  - Ese daño **no** se reduce con el apantallamiento ni lo evita la invulnerabilidad (tampoco la del Túnel): si no, se podría hundir uno en ella.
  - La plataforma segura es el último punto de suelo que pisó Wilas (se recuerdan los 16 más recientes, separados al menos 48 px y nunca durante la invulnerabilidad) que queda **al menos 96 px por encima** del frente y que **todavía tiene suelo**. Si no hay ninguno, se busca el suelo más cercano por encima del frente. Tras reaparecer, 1 s de invulnerabilidad.
- **La velocidad es variable**:
  - Velocidad base por capa (K lenta → N rápida). En la Capa K, 45 px/s.
  - Si el jugador está muy por encima, se acelera para acercarse ("goma elástica"): a más de 900 px, +0,6 px/s por cada píxel de más, hasta 420 px/s. Cerca (menos de 220 px) va más despacio, hasta la mitad de la base. Lejos nunca da respiro, cerca no es injusta.
  - **Se detiene** en los tramos seguros (entrada de capa, Estado fundamental, Intercambio) y en los jefes. Hoy el único tramo seguro es el inicial, que hace de entrada de capa: la Decoherencia espera, 500 px por debajo del suelo, a que Wilas salga de él.
  - Las perturbaciones de Entropía y algunas mejoras la modifican.
- En el HUD, un **indicador de distancia** en el borde inferior muestra lo cerca que está: la distancia en pm desde los pies de Wilas y un brillo que se intensifica por debajo de 8 pm.
- La cámara **sigue al jugador** con suavizado, un poco por encima de él (en un juego vertical importa más ver hacia arriba) y con _look-ahead_ vertical: mira hacia donde se mueve, más al caer que al subir. No enseña más allá de los lados del área de juego ni por debajo del fondo del nivel. La Decoherencia es la que mete prisa, no la cámara: caer ya no mata por salirse de la pantalla.
- Valores en `RisingThreat` (`world/rising_threat/`); la velocidad base pasará a `LayerData` con la generación de capas (Fase 5).

## Jefes

- Un jefe por capa, en un **tramo arena** de mayor tamaño (hasta 1,5–2 pantallas).
- La Decoherencia se detiene durante el combate.
- Al derrotarlo: quarks garantizados; bosón de Higgs la primera vez y con cierta probabilidad las siguientes; y una recompensa elegida (interacción u observable).
- Detalles en [09-enemigos](09-enemies.md).

## Victoria, derrota y puntuación

### Derrota

La coherencia llega a 0. Se muestra la **tarjeta de partida** (ver [11-interfaz](11-ui.md)) y se vuelve al Núcleo.

### Victoria (Ionización)

Derrotar al jefe de la Capa N. La primera victoria desbloquea:

- el **Modo Plasma** (infinito),
- el **Generador de Entropía**,
- un nuevo personaje.

### Modo Plasma (infinito)

- Tras la Capa N se continúa por capas **O, P, Q**, y después un ciclo sin fin con dificultad creciente.
- La puntuación sigue sumando. El objetivo es la altura máxima.
- Se elige al terminar la Capa N ("¿Ionizar o seguir en el plasma?"), así que no hay un menú aparte.
- Tiene su **propia tabla de puntuación**, separada de la de las partidas normales, y su propio historial en la Cámara de burbujas.

### Puntuación (valores iniciales, a balancear)

```
puntuación = (altura_pm
            + 25  × enemigos_eliminados
            + 500 × jefes_derrotados
            + 50  × objetos_recogidos
            + bonus_tiempo)
            × (1 + 0.05 × entropía)
```

- `bonus_tiempo`: puntos extra por completar cada capa por debajo de un tiempo de referencia.
- La puntuación es **comparable entre jugadores que usan la misma semilla** (ver [08-semillas](08-seeds.md)). Las mejoras permanentes forman parte legítima de la progresión y también se reflejan.

## Pausa y abandono

- Pausa en cualquier momento (Esc / Start). Desde la pausa se puede ver el build completo, las estadísticas, la semilla, las opciones y abandonar.
- Abandonar cuenta como derrota: se conservan los quarks recogidos. Esto evita trampas y es coherente con que morir tampoco penaliza la moneda permanente.
- **Guardar y salir** a mitad de partida: no está previsto; queda en [ideas a futuro](99-future-ideas.md).
