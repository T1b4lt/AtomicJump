# 07 · Objetos y mejoras de partida

Hay cuatro categorías de cosas que mejoran a Wilas **durante una partida**:

| Categoría         | Código         | Referencia               | Cuántos lleva          | Cómo se obtiene                               |
| ----------------- | -------------- | ------------------------ | ---------------------- | --------------------------------------------- |
| **Observables**   | `passive_item` | Objetos pasivos de Isaac | Ilimitados             | Contenedores, pedestales, tienda, recompensas |
| **Operador**      | `active_item`  | Objeto activo de Isaac   | 1 (se intercambia)     | Electrones ligados, tienda, secretos          |
| **Interacciones** | `boon`         | Bendiciones de Hades     | 1 por ranura + pasivas | Recompensas de rama (elige 1 de 3)            |
| **Cuantos**       | `pickup`       | Consumibles              | Instantáneos           | Huecos de recogibles, enemigos                |

Los datos de cada objeto viven en recursos `.tres` (`ItemData`, `BoonData`…) dentro de `data/`, nunca escritos en el código. Los nombres visibles salen de las traducciones (ver [02-universo](02-universe.md#regla-de-nombres-código-vs-juego)).

## Rareza

| Rareza en juego | Código      | Color   | Probabilidad base                           |
| --------------- | ----------- | ------- | ------------------------------------------- |
| Fundamental     | `common`    | Blanco  | 65 %                                        |
| Excitado        | `rare`      | Azul    | 27 %                                        |
| Resonante       | `epic`      | Violeta | 7 %                                         |
| Unificado       | `legendary` | Dorado  | 1 % (o por requisito, en las unificaciones) |

La **Amplitud** (suerte) desplaza estas probabilidades hacia rarezas altas (ver [08-semillas](08-seeds.md#modificadores-y-monotonía)).

## Pools

Cada objeto pertenece a uno o varios **pools** (`pool_container`, `pool_shop`, `pool_special`, `pool_secret`, `pool_boss`). Muchos objetos arrancan **bloqueados** y se añaden al pool al desbloquearlos en el Acelerador (ver [10-meta](10-meta.md)). En una misma partida un objeto no se repite (salvo los marcados como apilables).

## Observables (pasivos) — ejemplos

Objetivo v1.0: unos 60. Una parte son mejoras de estadística simples y el resto tienen efectos que generan sinergias.

| Observable                  | Código                 | Rareza      | Efecto                                                                                    |
| --------------------------- | ---------------------- | ----------- | ----------------------------------------------------------------------------------------- |
| Masa efectiva               | `effective_mass`       | Fundamental | +25 coherencia máxima                                                                     |
| Espín alto                  | `high_spin`            | Excitado    | +1 salto cuántico                                                                         |
| Constante de Planck         | `planck_constant`      | Fundamental | +5 % a todas las estadísticas                                                             |
| Momento lineal              | `linear_momentum`      | Fundamental | +40 momento                                                                               |
| Longitud de Compton         | `compton_length`       | Excitado    | −15 % longitud de onda                                                                    |
| Apantallamiento nuclear     | `nuclear_shielding`    | Excitado    | +10 % apantallamiento                                                                     |
| Efecto fotoeléctrico        | `photoelectric_effect` | Excitado    | Cada 10 fotones recogidos lanzan una ráfaga de proyectiles                                |
| Efecto Compton              | `compton_effect`       | Fundamental | Los proyectiles que impactan tienen un 10 % de soltar 1 fotón                             |
| Condensado de Bose-Einstein | `bose_einstein`        | Fundamental | Radio de atracción de fotones ×3                                                          |
| Efecto Doppler              | `doppler_effect`       | Excitado    | +30 % de daño al disparar en la dirección en la que te mueves                             |
| Onda estacionaria           | `standing_wave`        | Excitado    | +50 % frecuencia mientras estás quieto                                                    |
| Radiación de Cherenkov      | `cherenkov`            | Resonante   | A velocidad máxima dejas una estela que daña                                              |
| Dualidad onda-partícula     | `wave_particle`        | Resonante   | Los disparos alternan entre "onda" (atraviesa y hace poco daño) y "partícula" (daño alto) |
| Principio de exclusión      | `exclusion_principle`  | Resonante   | No puedes recibir daño de la misma fuente dos veces en 2 s                                |
| Vida media                  | `half_life`            | Excitado    | Los enemigos golpeados quedan **Inestables**                                              |
| Gato de Schrödinger         | `schrodinger_cat`      | Resonante   | Al recibir un golpe mortal, 50 % de sobrevivir con 1 de coherencia (una vez por capa)     |
| Supersimetría               | `supersymmetry`        | Unificado   | Cada observable recogido cuenta dos veces para las sinergias de familia                   |
| Energía del vacío           | `vacuum_energy`        | Resonante   | Al empezar cada tramo aparece un cuanto de energía                                        |
| Túnel resonante             | `resonant_tunneling`   | Resonante   | El Túnel atraviesa paredes finas                                                          |

### Sinergias por etiqueta (tipo Isaac)

Los observables llevan **etiquetas** (`photon`, `wave`, `mass`, `spin`, `decay`…). Reunir **3 con la misma etiqueta** activa una transformación visible con bonus, como las transformaciones de Isaac:

- 3 × `wave` → **Paquete de ondas**: los proyectiles ondulan y atraviesan a 1 enemigo.
- 3 × `mass` → **Agujero negro en miniatura**: tu disparo atrae ligeramente a los enemigos.
- 3 × `photon` → **Láser**: el disparo pasa a ser un rayo continuo.

## Operadores (activos) — ejemplos

Tienen **recarga por tramos superados**, o por enemigos en algunos casos. Objetivo v1.0: unos 8.

| Operador                   | Código                | Recarga  | Efecto                                                               |
| -------------------------- | --------------------- | -------- | -------------------------------------------------------------------- |
| Efecto Zenón               | `zeno_effect`         | 2 tramos | "Observar" congela a todos los enemigos en pantalla 3 s              |
| Colapso                    | `collapse`            | 3 tramos | Destruye todos los proyectiles enemigos en pantalla y aturde         |
| Teleportación cuántica     | `quantum_teleport`    | 1 tramo  | Primer uso: deja una marca. Segundo uso: vuelves a ella              |
| Emisión estimulada         | `stimulated_emission` | 2 tramos | Rayo láser vertical durante 2 s                                      |
| Trampa de Penning          | `penning_trap`        | 3 tramos | Captura a un enemigo; al soltarlo se convierte en un aliado temporal |
| Retardo de la Decoherencia | `decoherence_delay`   | 4 tramos | Hace retroceder la Decoherencia media pantalla                       |

## Interacciones (tipo bendiciones de Hades)

Las ofrecen los **bosones mensajeros** en las recompensas de rama (`reward_boon`). Siempre se elige **1 de 3**. Cada interacción pertenece a una **familia** y ocupa una **ranura** (Disparo, Salto, Túnel, Campo; ver [04-jugador](04-player.md#ranuras-de-interacción)) o es **pasiva** (sin ranura).

Las interacciones tienen **nivel**: coger la misma otra vez la sube de nivel (mejora de sus números), como el _Pom of Power_ de Hades.

Cada bosón mensajero tiene **personalidad** a través de frases cortas al ofrecer sus interacciones (y el Pión, en la tienda). Los diálogos completos con historia entre partidas quedan en [ideas a futuro](99-future-ideas.md).

### Electromagnética — el Fotón

| Interacción        | Ranura  | Efecto                                                                      |
| ------------------ | ------- | --------------------------------------------------------------------------- |
| Descarga en cadena | Disparo | Los impactos saltan a 2 enemigos cercanos                                   |
| Reflexión          | Disparo | Los proyectiles rebotan en las paredes 2 veces (−15 % daño)                 |
| Salto iónico       | Salto   | El salto aéreo emite un pulso que deja **Cargados** a los enemigos cercanos |
| Arco voltaico      | Túnel   | El Túnel deja una línea eléctrica que daña                                  |
| Campo de Faraday   | Campo   | Cada 8 s bloqueas un golpe                                                  |
| Inducción          | Pasiva  | +20 % daño contra enemigos Cargados                                         |

### Fuerte — el Gluón

| Interacción         | Ranura  | Efecto                                                                      |
| ------------------- | ------- | --------------------------------------------------------------------------- |
| Fisión              | Disparo | Los proyectiles explotan al impactar (daño en área)                         |
| Penetración         | Disparo | Los proyectiles atraviesan enemigos (−20 % daño)                            |
| Confinamiento       | Salto   | Al aterrizar tras un salto, los enemigos cercanos quedan **Confinados** 1 s |
| Carga nuclear       | Túnel   | El Túnel hace mucho daño a quien atraviesas                                 |
| Color               | Pasiva  | +25 % carga                                                                 |
| Libertad asintótica | Pasiva  | Cuanto más cerca del enemigo, más daño                                      |

### Débil — los Bosones W/Z

| Interacción         | Ranura  | Efecto                                                                         |
| ------------------- | ------- | ------------------------------------------------------------------------------ |
| Desintegración beta | Disparo | Los impactos aplican **Inestable** (daño por segundo)                          |
| Transmutación       | Disparo | 5 % de convertir a un enemigo normal en fotones                                |
| Neutrino fantasma   | Salto   | El salto aéreo te hace intangible 0,3 s                                        |
| Cambio de sabor     | Túnel   | Tras el Túnel, tu siguiente disparo aplica el estado del último enemigo tocado |
| Radiactividad       | Campo   | Aura que aplica Inestable a los enemigos cercanos                              |

### Gravitatoria — el Gravitón

| Interacción             | Ranura  | Efecto                                                         |
| ----------------------- | ------- | -------------------------------------------------------------- |
| Singularidad            | Disparo | Cada 5.º disparo crea un pequeño pozo que atrae a los enemigos |
| Dilatación temporal     | Disparo | Los impactos aplican **Dilatado**                              |
| Asistencia gravitatoria | Salto   | +1 salto cuántico y el salto aéreo es más alto                 |
| Onda gravitacional      | Túnel   | El Túnel empuja a los enemigos                                 |
| Órbita                  | Campo   | 2 partículas orbitan a tu alrededor y dañan                    |
| Masa inercial           | Pasiva  | Retroceso reducido y +10 % apantallamiento                     |

### Cuántica — sin mensajero, raras

Aparecen como opción extra en cualquier recompensa de interacción (probabilidad baja, aumentada por la Amplitud) o en secretos.

| Interacción            | Ranura  | Efecto                                              |
| ---------------------- | ------- | --------------------------------------------------- |
| Superposición          | Disparo | Disparas 2 proyectiles (con nivel 2, 3)             |
| Espín                  | Disparo | Cada disparo sale en las 4 direcciones (−40 % daño) |
| Penetración de barrera | Disparo | Los proyectiles atraviesan plataformas              |
| Entrelazamiento        | Pasiva  | Los enemigos aparecen **Entrelazados** por parejas  |
| Incertidumbre          | Pasiva  | Daño aleatorio entre ×0,5 y ×2,5                    |

### Unificaciones (dobles y triples)

Aparecen solo si tienes los requisitos. Son la recompensa de comprometerse con dos familias.

| Unificación              | Requisitos                                    | Efecto                                                                                |
| ------------------------ | --------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Electrodébil**         | EM + Débil                                    | Las cadenas eléctricas aplican Inestable y el daño de Inestable salta como una cadena |
| **Cromodinámica**        | Fuerte + Fuerte (2 de nivel ≥2)               | Las explosiones de Fisión dejan Confinados                                            |
| **Lente gravitatoria**   | Gravitatoria + EM                             | Los proyectiles se curvan hacia los enemigos (autoapuntado suave)                     |
| **Radiación de Hawking** | Gravitatoria + Débil                          | Las singularidades dañan y aplican Inestable                                          |
| **Gran Unificación**     | EM + Fuerte + Débil                           | Cada 3 s tu siguiente disparo tiene los efectos de las tres familias                  |
| **Gravedad cuántica**    | Gravitatoria + cualquier Cuántica + (secreto) | La unificación "imposible": todos tus proyectiles son singularidades. Muy rara        |

## Cuantos (consumibles instantáneos)

| Cuanto                                  | Código            | Efecto                       |
| --------------------------------------- | ----------------- | ---------------------------- |
| Fotón / fotón brillante / fotón intenso | `coin_1/5/10`     | +1 / +5 / +10 γ              |
| Positrón                                | `key`             | +1 e⁺                        |
| Cuanto de energía                       | `heal_pickup`     | +20 coherencia               |
| Cuanto grande                           | `heal_pickup_big` | +50 coherencia               |
| Quark                                   | `meta_pickup`     | +1 quark (moneda permanente) |

## Implementación (Fase 7)

### Datos y efectos

- **`ItemData`** (`items/item_data.gd`, recursos en `data/items/`): `id`, tipo (`PASSIVE` observable / `ACTIVE` operador), rareza, pools, etiquetas, icono, efectos, peso dentro de su rareza, si es apilable y, en los operadores, `charge_chunks`. El nombre y la descripción son las claves `ITEM_<ID>_NAME` e `ITEM_<ID>_DESC`.
- **`ItemCatalog`** (`data/items/item_catalog.tres`): todos los objetos y transformaciones. `get_pool(pool, tipo)` los devuelve **ordenados por id**, así que el orden de la lista nunca cambia una tirada. `RunManager.CATALOG` lo pasa a cada `RunState`.
- **Efectos** (`items/effects/`), recursos que responden a _hooks_. `Build` duplica cada plantilla al aplicarla, así que un efecto guarda su propio estado:

| Efecto | Hook | Qué hace |
| --- | --- | --- |
| `StatEffect` | al ganarlo / perderlo | Añade sus `StatModifier` con el objeto como origen |
| `StillStatEffect` | cada fotograma | Sus modificadores solo cuentan con Wilas quieta en el suelo |
| `ProjectileModifierEffect` | al disparar | Multiplica el daño, añade perforación, estados y ondulación al `ProjectileSpec` |
| `DirectionalDamageEffect` | al disparar | Más daño si Wilas se mueve (≥ 60 px/s) en la dirección del disparo |
| `CoinBurstEffect` | al recoger fotones | Cada N fotones, una ráfaga de proyectiles en todas direcciones |
| `HitDropEffect` | al impactar | Probabilidad de soltar un recogible donde impacta (tirada de `combat`) |
| `ChunkSpawnEffect` | al entrar en un tramo nuevo | Hace aparecer un recogible junto a Wilas |
| `ScreenStatusEffect` | al usar el operador | Aplica un estado a los enemigos en pantalla y puede destruir los proyectiles enemigos |

- **`Build`** (`items/build.gd`, en `RunState.build`): observables, operador con su carga y transformaciones. Aplica los efectos y les pasa los _hooks_: el `Player` lo llama al disparar (`Shooter.spec_modifier`), cuando sus proyectiles impactan y en cada fotograma; el `RunState`, al recoger fotones y al entrar en un tramo. Los efectos que hacen aparecer cosas usan `Build.spawner`, que el `Level` conecta al tramo correspondiente.

### Observables de la Fase 7

Además de los de la tabla de ejemplos, se añaden tres de estadística simple (Constante de estructura fina, Recorrido libre medio y Energía de enlace).

| Observable | Código | Rareza | Pools | Etiquetas | Efecto |
| --- | --- | --- | --- | --- | --- |
| Masa efectiva | `effective_mass` | Fundamental | contenedor, tienda | `mass` | +25 coherencia máxima |
| Espín alto | `high_spin` | Excitado | contenedor, tienda, especial | `spin` | +1 salto cuántico |
| Constante de Planck | `planck_constant` | Fundamental | contenedor, tienda | `quantum` | +5 % a coherencia máxima, momento, impulso, carga, frecuencia y alcance |
| Momento lineal | `linear_momentum` | Fundamental | contenedor, tienda | `mass` | +40 momento |
| Longitud de Compton | `compton_length` | Excitado | contenedor, tienda | `wave` | −15 % longitud de onda |
| Apantallamiento nuclear | `nuclear_shielding` | Excitado | contenedor, tienda, especial | `mass` | +10 % apantallamiento |
| Constante de estructura fina | `fine_structure` | Fundamental | contenedor, tienda | `photon` | +0,5 frecuencia |
| Recorrido libre medio | `mean_free_path` | Fundamental | contenedor, tienda | `wave` | +150 alcance |
| Energía de enlace | `binding_energy` | Excitado | contenedor, tienda, especial | `mass` | +2 carga |
| Condensado de Bose-Einstein | `bose_einstein` | Fundamental | contenedor, tienda | `photon` | Radio de atracción ×3 |
| Efecto fotoeléctrico | `photoelectric_effect` | Excitado | contenedor, tienda, especial | `photon` | Cada 10 fotones, ráfaga de 8 proyectiles |
| Efecto Compton | `compton_effect` | Fundamental | contenedor, tienda | `photon`, `wave` | 10 % de soltar 1 fotón al impactar |
| Efecto Doppler | `doppler_effect` | Excitado | contenedor, tienda, especial | `wave` | +30 % de daño en la dirección del movimiento |
| Onda estacionaria | `standing_wave` | Excitado | contenedor, tienda, especial | `wave` | +50 % frecuencia quieta en el suelo |
| Vida media | `half_life` | Excitado | contenedor, tienda, especial | `decay` | Los impactos aplican Inestable |
| Energía del vacío | `vacuum_energy` | Resonante | tienda, especial | `quantum` | Un cuanto de energía al entrar en cada tramo nuevo |

### Transformación: Paquete de ondas

`TransformationData` (`data/transformations/`): al llevar **3 observables con la etiqueta `wave`** se gana una vez **Paquete de ondas**: los proyectiles ondulan (6 px a 6 ciclos por segundo, con el rayo de las paredes siguiendo la trayectoria real) y atraviesan a 1 enemigo más. El HUD lo anuncia como un objeto. Las de `mass` y `photon` llegarán con más contenido (Fase 12).

### Operadores

- Wilas lleva **uno**: coger otro lo sustituye y deja el antiguo en el pedestal (o en uno nuevo, si se compró).
- **Recarga por tramos:** cada tramo **nuevo** al que sube Wilas (más alto que el más alto alcanzado) suma una carga hasta `charge_chunks`. Un operador recién cogido llega **cargado**. Se usa con **E** / LB solo si está cargado y deja la carga a 0.
- **Efecto Zenón** (`zeno_effect`, 2 tramos): aplica Observado (`status_observed`, inmovilizado 3 s, tinte cian) a los enemigos en pantalla. **Colapso** (`collapse`, 3 tramos): destruye los proyectiles enemigos en pantalla (grupo `enemy_projectiles`) y aplica Aturdido (`status_stunned`, 1 s).

### Pools, rarezas y Amplitud

- `LootRoller` hace las tiradas de objetos de una partida. Primero la **rareza** (dominio `rarity`), comparada desde la más alta con la probabilidad de obtener **al menos** esa rareza: `1 − (1 − base)^(1 + Amplitud / 50)`, con base 35 % (Excitado o mejor), 8 % (Resonante o mejor) y 1 % (Unificado). Con la misma tirada, más Amplitud da la misma rareza o una mejor (con 100 de Amplitud, Excitado o mejor sube al 72,5 %).
- Después, el objeto: _rendezvous hashing_ (`pick_weighted`) entre los de esa rareza del pool, sin los que Wilas ya lleva (salvo los apilables) ni los excluidos (los otros objetos de la misma tienda o Superposición). Si no queda ninguno de esa rareza se prueban las inferiores y luego las superiores.
- Pools usados hoy: `pool_container` (pozos, Superposiciones, recompensas de rama), `pool_special` (electrón ligado) y `pool_shop`. El bloqueo de objetos hasta desbloquearlos en el Acelerador llega en la Fase 10.

### Sala de pruebas de objetos

`world/debug/item_test_room.tscn` (F6): todos los recogibles, un pozo cuántico, un electrón ligado, una Superposición y un pedestal sobre un suelo, con el HUD y la pantalla de build. **C** da fotones y un positrón, **I** / **O** ponen en el pedestal el siguiente observable / operador del catálogo, **H** quita coherencia, **1** hace aparecer un neutrón libre (para probar los operadores) y **R** reconstruye la sala con otra semilla.
