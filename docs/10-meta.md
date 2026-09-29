# 10 · Meta-progresión: el Núcleo

El **Núcleo** es el lobby entre partidas, equivalente a la Casa de Hades. Es una escena jugable: Wilas camina y salta por ella, no es un menú plano, y cada estación es un punto con el que interactuar.

## Estaciones

| Estación                  | Código               | Moneda                           | Función                                                          | Disponible                   |
| ------------------------- | -------------------- | -------------------------------- | ---------------------------------------------------------------- | ---------------------------- |
| **Salto al orbital 1s**   | `run_start`          | —                                | Empezar partida: semilla aleatoria o introducida                 | Desde el inicio              |
| **Campo de Higgs**        | `upgrade_station`    | Quarks (+ Higgs en rangos altos) | Mejoras permanentes                                              | Desde el inicio              |
| **Acelerador**            | `unlock_station`     | Quarks                           | Añadir observables, operadores e interacciones al pool           | Tras la primera partida      |
| **Espectro**              | `character_select`   | Bosones de Higgs                 | Elegir y desbloquear personajes                                  | Tras derrotar al primer jefe |
| **Cámara de burbujas**    | `records`            | —                                | Estadísticas, logros, registro de objetos, historial de semillas | Desde el inicio              |
| **Generador de Entropía** | `difficulty_station` | —                                | Perturbaciones                                                   | Tras la primera victoria     |

## Campo de Higgs (mejoras permanentes)

Mejoras con **rangos**; el coste de cada rango crece. Objetivo v1.0: unas 20. Algunas son de estadísticas, otras cambian reglas y otras afectan a la economía.

| Mejora                  | Código               | Rangos | Efecto por rango                                                     | Coste (quarks)              |
| ----------------------- | -------------------- | ------ | -------------------------------------------------------------------- | --------------------------- |
| Masa en reposo          | `meta_max_hp`        | 5      | +10 coherencia máxima                                                | 10, 20, 35, 55, 80          |
| Amplitud residual       | `meta_luck`          | 5      | +3 amplitud                                                          | 15, 30, 50, 75, 110         |
| Momento inicial         | `meta_speed`         | 3      | +4 % momento                                                         | 15, 35, 60                  |
| Carga elemental         | `meta_attack`        | 5      | +5 % carga                                                           | 15, 30, 50, 75, 110         |
| Apantallamiento interno | `meta_defense`       | 3      | +3 % apantallamiento                                                 | 20, 45, 80                  |
| Energía de punto cero   | `meta_start_coins`   | 3      | Empiezas con +10 γ                                                   | 10, 25, 45                  |
| Antimateria residual    | `meta_start_key`     | 1      | Empiezas con 1 e⁺                                                    | 60                          |
| Densidad de pozos       | `meta_chest_rate`    | 3      | +10 % probabilidad de pozos cuánticos                                | 25, 50, 90                  |
| Resonancia              | `meta_pickup_rate`   | 3      | +10 % probabilidad de recogibles                                     | 20, 40, 70                  |
| Descuento del Pión      | `meta_shop_discount` | 3      | −8 % precios del Intercambio                                         | 20, 45, 80                  |
| Superposición vital     | `meta_revive`        | 2      | Revivir 1 vez por partida con 30 % / 50 % de coherencia              | 80 + 1 Higgs, 150 + 2 Higgs |
| Coherencia prolongada   | `meta_threat_slow`   | 3      | −5 % velocidad de la Decoherencia                                    | 30, 60, 100                 |
| Tercera opción          | `meta_boon_choice`   | 1      | Las recompensas de interacción ofrecen 4 opciones                    | 100 + 2 Higgs               |
| Reroll cuántico         | `meta_reroll`        | 3      | 1 reroll de interacciones por partida (por rango)                    | 40, 80, 130                 |
| Memoria de sabor        | `meta_boon_start`    | 1      | Empiezas con una interacción común aleatoria de una familia a elegir | 120 + 1 Higgs               |

**Reembolso:** se puede reiniciar el Campo de Higgs en cualquier momento y recuperar el 100 %, para fomentar experimentar (como el Espejo de Hades).

## Acelerador (desbloqueos al pool)

- El pool inicial es reducido: unos 20 observables, 3 operadores y las interacciones comunes y raras.
- En el Acelerador se "sintetizan" objetos nuevos con quarks. Cada síntesis añade 1–3 objetos al pool.
- Algunos desbloqueos se consiguen con **logros** en lugar de quarks (por ejemplo, "derrota al Par de Pauli sin recibir daño" desbloquea _Principio de exclusión_), como en Isaac.
- También se desbloquean **tipos de tramo** (tramo secreto, tramo excitado) y **capas o modos** (Modo Plasma).

## Espectro (personajes)

| Personaje | Coste   | Requisito                     |
| --------- | ------- | ----------------------------- |
| Wilas     | —       | —                             |
| Muón      | 1 Higgs | Derrotar al Par de Pauli      |
| Neutrino  | 2 Higgs | Llegar a la Capa M            |
| Tau       | 3 Higgs | Primera Ionización (victoria) |

Estadísticas y diferencias en [04-jugador](04-player.md#personajes).

## Entropía

Sistema de dificultad voluntaria (como el Pacto de Castigo de Hades). Se desbloquea tras la primera victoria.

- Cada **perturbación** tiene rangos, y cada rango suma puntos de Entropía.
- La Entropía total multiplica la **puntuación** (+5 % por punto) y los **quarks** obtenidos (+3 % por punto).
- La primera victoria con cada nivel de Entropía redondo (5, 10, 15, 20…) da bosones de Higgs.
- La configuración de Entropía **no cambia la semilla**, solo el comportamiento sobre ese mundo. Se muestra en la tarjeta de partida.

| Perturbación               | Código                | Rangos | Efecto por rango                                            | Puntos |
| -------------------------- | --------------------- | ------ | ----------------------------------------------------------- | ------ |
| Decoherencia acelerada     | `heat_threat_speed`   | 3      | +15 % velocidad de la Decoherencia                          | 1      |
| Partículas pesadas         | `heat_enemy_hp`       | 3      | +20 % vida de los enemigos                                  | 1      |
| Interacción intensa        | `heat_enemy_damage`   | 3      | +20 % daño de los enemigos                                  | 1      |
| Vacío poblado              | `heat_enemy_density`  | 2      | +25 % huecos de enemigo activos                             | 2      |
| Inflación                  | `heat_prices`         | 2      | +30 % precios                                               | 1      |
| Pérdida de coherencia      | `heat_less_heal`      | 2      | −35 % curación                                              | 1      |
| Jefes excitados            | `heat_boss_phase`     | 1      | Los jefes tienen una fase extra                             | 3      |
| Ruido cuántico             | `heat_fewer_chests`   | 2      | −25 % pozos cuánticos                                       | 1      |
| Sin observador             | `heat_no_hud`         | 1      | El HUD solo muestra la coherencia                           | 1      |
| Principio de incertidumbre | `heat_hidden_rewards` | 1      | Los iconos de recompensa de las bifurcaciones están ocultos | 2      |

## Cámara de burbujas (registros)

- **Estadísticas globales:** partidas jugadas, victorias, mejor altura, mejor puntuación, total de saltos, fotones, quarks, enemigos eliminados, jefes derrotados, muertes por causa…
- **Registro de trazas:** colección de observables, operadores, interacciones y enemigos descubiertos (siluetas para lo no visto), como la colección de Isaac.
- **Mejores puntuaciones:** una tabla para las partidas normales y otra, separada, para el Modo Plasma.
- **Historial de partidas:** las últimas 50 partidas con semilla, personaje, Entropía, capa alcanzada y puntuación, y un botón para **copiar la semilla** o **rejugarla**.
- **Logros:** lista con progreso. Los logros pueden desbloquear objetos o dar Higgs.

### Logros v1.0 (ejemplos)

| Logro              | Condición                                | Recompensa                                             |
| ------------------ | ---------------------------------------- | ------------------------------------------------------ |
| Primera excitación | Realiza tu primer salto                  | —                                                      |
| Emisión            | Realiza tu primer disparo                | —                                                      |
| Primera medida     | Recoge tu primer observable              | —                                                      |
| Aniquilación       | Abre un electrón ligado                  | Desbloquea _Antimateria residual_ en el Campo de Higgs |
| Exclusión          | Derrota al Par de Pauli sin recibir daño | Desbloquea _Principio de exclusión_                    |
| Unificación        | Consigue tu primera unificación          | 1 Higgs                                                |
| Ionización         | Gana una partida                         | Modo Plasma, Generador de Entropía                     |
| Gran Unificación   | Consigue _Gran Unificación_              | 2 Higgs                                                |
| Cero absoluto      | Gana sin comprar nada en el Intercambio  | Observable _Energía de punto cero_                     |

## Persistencia

- Guardado en `user://save.json`, con versión de esquema y migraciones.
- Se guarda al volver al Núcleo, al comprar mejoras y al terminar una partida (también al abandonar), nunca a mitad de partida (guardar a mitad de partida es una [idea a futuro](99-future-ideas.md)).
- Opciones en un archivo aparte (`user://settings.cfg`).
