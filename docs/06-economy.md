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
| **Pozo cuántico**   | `chest` (`common`)  | Pagando fotones: la "energía de excitación". Cuesta 5 en la Capa K y sube por capa | Fotones, cuantos, positrón (raro) u observable (poco común; su rareza la mejora la Amplitud) |
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

## Implementación (Fase 7)

La economía de partida de la Capa K está completa; las divisas permanentes llegan en la Fase 10. Los objetos y su sistema de efectos están en [07-objetos](07-items.md#implementación-fase-7) y las tiradas en [08-semillas](08-seeds.md#economía-y-objetos-fase-7).

### Recogibles (`items/pickups/`)

| Recogible | Escena (id de hueco) | Efecto |
| --- | --- | --- |
| Fotón ×1 / ×5 / ×10 | `coin.tscn` (`coin`), `coin_5.tscn` (`coin_5`), `coin_10.tscn` (`coin_10`) | +1 / +5 / +10 γ por `Events.coin_collected` |
| Positrón | `key.tscn` (`key`) | +1 e⁺ por `Events.key_collected` |
| Cuanto de energía / grande | `heal_pickup.tscn` (`heal_pickup`), `heal_pickup_big.tscn` (`heal_pickup_big`) | +20 / +50 de coherencia |

- Todos heredan de `Pickup` (`Area2D` en la capa `pickups`): se recogen al tocarlos si `can_collect()` lo permite. Un **cuanto de energía no se recoge con la coherencia llena**: espera, y se coge en cuanto deja de estarlo sin tener que salir y volver a entrar.
- Los fotones son **magnéticos**: cuando Wilas está dentro de su **radio de atracción** vuelan hacia ella con aceleración constante (unos 200 ms desde el borde). El radio es la estadística `pickup_radius` (Atracción, 80 px de base; ver [04-jugador](04-player.md#estadísticas)), así que los observables lo amplían (Condensado de Bose-Einstein: ×3).
- `PickupScenes` reúne las escenas por id para que contenedores, tablas de botín y efectos las creen sin depender de `Chunk`.
- En los huecos de recogible de la Capa K (40 %) los pesos son fotón 12, fotón ×5 1,5, fotón ×10 0,3, positrón 1 y cuanto de energía 1,2.

### Interacción

Pedestales, pozos cuánticos, puestos de la tienda y la elección del Estado fundamental se usan con **interactuar** (W / Y). Cada uno lleva un `Interactable` (en la capa `pickups`); el `InteractionArea` de Wilas (radio 40 px) los detecta y solo **el más cercano** tiene el foco y muestra su aviso encima (`[W] Masa efectiva`, `[W] Excitar`). El electrón ligado no necesita interactuar: se abre al tocarlo con un positrón.

### Contenedores (`items/containers/`)

| Contenedor | Escena (id de hueco) | Cómo se abre | Contenido (`data/loot/`) |
| --- | --- | --- | --- |
| Pozo cuántico | `common_chest.tscn` (`chest`, `CommonChest`) | Interactuar pagando `5 + 5 × índice de capa` fotones; sin bastantes, el precio parpadea | `chest_common.tres`: 3–6 fotones (45), un fotón ×5 (10), un cuanto de energía (20), un positrón (10) u observable de `pool_container` (15) |
| Electrón ligado | `special_chest.tscn` (`chest_special`, `SpecialChest`) | Tocarlo con un positrón: aniquilación (destello y traza) | `chest_special.tres`: observable de `pool_special` de rareza Excitado o mejor (3) u operador (1) |
| Superposición | `choice_pedestal.tscn` (`choice_pedestal`) | Gratis: al coger un pedestal, el otro colapsa | Dos observables distintos de `pool_container` |
| Pedestal | `item_pedestal.tscn` | Gratis, interactuando | Un observable (recompensa de rama, cofres) |

- Los que ocupan un hueco heredan de `LootContainer`: el tramo les da la dirección de su hueco, las tiradas de la partida (`LootRoller`) y el índice de capa. Al abrirse, los recogibles saltan por encima del contenedor y el objeto aparece en un pedestal en su sitio.
- Coger un **operador** llevando otro deja el antiguo en el pedestal (como en Isaac).
- Huecos de contenedor de la Capa K: 40 % de que haya algo; pozo cuántico 6, electrón ligado 2 y Superposición 1,5. Siete tramos normales tienen un hueco de contenedor sobre una plataforma.
- La recompensa de rama **`reward_item`** (icono de un ojo) es un pedestal o, la mitad de las veces, una Superposición.

### Intercambio (`items/shop/`)

- El tramo `k_shop` (seguro) va en mitad de la Capa K. Su `Shop` (en `Props/`) pone al **Pión** y una fila de puestos (`ShopStand`) sobre una repisa sólida.
- `ShopInventory` decide el inventario con tiradas del dominio `shop` en la clave del tramo: 2–3 observables de `pool_shop` distintos, un operador la mitad de las veces, un cuanto de energía, un positrón y el reintento.
- Precios (más 5 por índice de capa): observables 15 / 20 / 25 / 30 γ y operadores 25 / 30 / 35 / 40 γ según su rareza; cuanto de energía 8 γ (solo se compra con la coherencia por debajo del máximo); positrón 12 γ; reintento 5 γ, que se duplica en cada uso.
- El **reintento** vuelve a tirar los observables y el operador que no se han comprado con el número de reintentos en la dirección: el reintento _n_ de una tienda es siempre el mismo para una semilla (con la misma Amplitud y los mismos objetos llevados).
- Las mejoras de descuento llegarán con el Campo de Higgs.

### Estado fundamental

El tramo de descanso (`k_rest`) tiene un `RestShrine` con dos elecciones (`RestChoice`): **Relajarse** (+40 % de la coherencia máxima) o **Estabilizarse** (+10 de coherencia máxima, que llega llena). Al coger una, la otra colapsa. El modificador de coherencia máxima tiene el origen `rest_max_hp` (en el desglose de la pantalla de build aparece como «Estado fundamental»).
