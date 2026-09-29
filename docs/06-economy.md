# 06 · Economía

Hay dos niveles de economía: la de **partida**, que se pierde al terminar, y la **permanente**, que se conserva en el Núcleo. La correspondencia de nombres con el código está en [02-universo](02-universe.md#economía).

## Divisas de partida

| Divisa            | Código | Cómo se consigue                                                                    | Para qué sirve                                                                      |
| ----------------- | ------ | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Fotón (γ)**     | `coin` | Huecos de recogibles, enemigos (probabilidad), recompensas de rama, pozos cuánticos | Abrir pozos cuánticos, comprar en el Intercambio                                    |
| **Positrón (e⁺)** | `key`  | Rara: huecos de recogibles (baja probabilidad), recompensas de rama, tienda         | Aniquilar electrones ligados (contenedor especial) y abrir ciertas puertas secretas |

- Los fotones son **atraídos** hacia Wilas a corta distancia (radio ampliable con observables).
- Los fotones de valor alto se muestran como un fotón más grande o de otro color (valor 1, 5 o 10).

## Contenedores

| Contenedor          | Código              | Cómo se abre                                                                       | Contenido                                                         |
| ------------------- | ------------------- | ---------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| **Pozo cuántico**   | `chest` (`common`)  | Pagando fotones: la "energía de excitación". Cuesta 5 en la Capa K y sube por capa | Fotones, cuantos, positrón (raro) u observable común (poco común) |
| **Electrón ligado** | `chest` (`special`) | Tocándolo con un positrón en el inventario: aniquilación                           | Observable raro u operador; a veces una interacción cuántica      |
| **Superposición**   | `choice_pedestal`   | Gratis: al coger uno de los dos objetos, el otro colapsa                           | Dos observables; solo te quedas uno                               |
| **Pedestal**        | `item_pedestal`     | Gratis                                                                             | Un observable (recompensa de rama, secretos)                      |

## Intercambio (tienda)

- Lo atiende el **Pión**. Hay uno garantizado a mitad de cada capa y puede aparecer como recompensa de rama.
- Inventario (determinado por la semilla, ver [08-semillas](08-seeds.md)):
  - 2–3 observables (15–30 γ según rareza y capa),
  - 1 operador (25–40 γ, no siempre),
  - 1 cuanto de energía (8 γ),
  - 1 positrón (12 γ),
  - 1 **reintento** (_reroll_) del inventario (5 γ, y cada uso duplica el precio).
- Mejoras del Campo de Higgs y observables pueden aplicar descuentos.

## Curación

| Fuente                              | Código            | Efecto                                                                        |
| ----------------------------------- | ----------------- | ----------------------------------------------------------------------------- |
| Cuanto de energía                   | `heal_pickup`     | +20 coherencia                                                                |
| Cuanto grande                       | `heal_pickup_big` | +50 coherencia                                                                |
| Estado fundamental                  | `chunk_rest`      | El jugador elige: +40 % de la coherencia máxima **o** +10 de coherencia máxima (como las fuentes de Hades) |
| Algunas interacciones y observables | —                 | Robo de vida, curación al subir de capa…                                      |

## Divisas permanentes

| Divisa             | Código               | Cómo se consigue                                                                                                     | Para qué sirve                                                                 |
| ------------------ | -------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Quark**          | `meta_currency`      | Enemigos (poca probabilidad), recompensas de rama (`reward_meta`), jefes (garantizado), bonus por altura al terminar | Mejoras del Campo de Higgs y desbloqueos del Acelerador                        |
| **Bosón de Higgs** | `rare_meta_currency` | Primera derrota de cada jefe, logros, jefes con probabilidad baja, victorias con Entropía alta                       | Personajes (Espectro), capas y modos, mejoras del Campo de Higgs de nivel alto |

- Las divisas permanentes **se conservan siempre**, tanto al morir como al abandonar.
- La Entropía multiplica los quarks obtenidos (ver [10-meta](10-meta.md#entropía)).

## Curva orientativa (a balancear)

| Momento            | Fotones acumulados (aprox.) | Quarks por partida |
| ------------------ | --------------------------- | ------------------ |
| Final de la Capa K | 40–70                       | Muerte en K: 5–15  |
| Final de la Capa L | 100–160                     | Muerte en L: 20–40 |
| Final de la Capa M | 180–280                     | Muerte en M: 45–80 |
| Victoria           | —                           | 120–200            |

El objetivo es que la primera mejora del Campo de Higgs llegue tras 1–2 partidas y que la primera victoria sea plausible en 8–15 horas de juego.
