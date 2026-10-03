# 02 · Universo, tema y glosario

## Premisa

**Wilas** es una partícula consciente que nace en el **Núcleo** de un átomo. Su objetivo es escapar: ascender por las capas electrónicas (K, L, M, N) hasta alcanzar la **energía de ionización** y salir del átomo.

Cada vez que su **coherencia** se agota, Wilas _decoherea_ y vuelve a formarse en el Núcleo. No recuerda lo que llevaba encima, pero conserva lo que invirtió en el Núcleo. Esto justifica narrativamente el bucle roguelike, igual que Zagreus vuelve a la Casa de Hades.

La **Decoherencia** es una onda que asciende desde el Núcleo y colapsa todo lo que alcanza. Es la amenaza que obliga a subir.

## Regla de nombres: código vs juego

- **Código, carpetas, escenas, recursos y commits** usan nombres **funcionales en inglés**, fáciles de entender: `coin`, `key`, `chest`, `hp`, `luck`, `shop`, `boss`, `item`…
- **Todo lo que ve el jugador** (UI, descripciones, diálogos, README de cara al jugador) usa el **nombre temático** del imaginario cuántico.
- Los textos visibles se sacan siempre de claves de traducción (`tr("ITEM_...")`), nunca se escriben a mano en el código. Así el nombre temático vive en un único sitio y puede cambiar sin tocar lógica.
- Esta tabla es la **fuente de verdad** de la correspondencia. Si un nombre temático cambia, se cambia aquí y en la traducción.

## Glosario

### Partida y mundo

| En juego          | En código       | Qué es                                                     | Inspiración física             |
| ----------------- | --------------- | ---------------------------------------------------------- | ------------------------------ |
| Núcleo            | `lobby`         | Base entre partidas                                        | Núcleo atómico                 |
| Capa (K, L, M, N) | `layer`         | Bioma, una sección grande de la partida con jefe al final  | Capas electrónicas             |
| Tramo             | `chunk`         | Segmento vertical de una pantalla de alto, diseñado a mano | Nivel de energía               |
| Bifurcación       | `fork`          | Tramo con dos salidas; cada una muestra su recompensa      | Transición entre estados       |
| Decoherencia      | `rising_threat` | Onda que asciende y mata al tocar                          | Pérdida de coherencia cuántica |
| Ionización        | `victory`       | Escapar del átomo, es decir, ganar la partida              | Energía de ionización          |
| Modo Plasma       | `endless_mode`  | Modo infinito tras la primera victoria                     | Gas ionizado                   |
| Altura (pm)       | `altitude`      | Distancia recorrida, se mide en picómetros                 | Radio atómico (~30–300 pm)     |
| Semilla           | `seed`          | Código que determina el mundo                              | —                              |

### Protagonista y estadísticas

| En juego          | En código      | Qué es                                                              |
| ----------------- | -------------- | ------------------------------------------------------------------- |
| Coherencia        | `hp`           | Vida; a 0 Wilas decoherea                                           |
| Coherencia máxima | `max_hp`       | Vida máxima                                                         |
| Amplitud          | `luck`         | Suerte: modifica probabilidades de aparición y calidad              |
| Momento           | `speed`        | Velocidad horizontal                                                |
| Impulso           | `jump_force`   | Fuerza del salto                                                    |
| Saltos cuánticos  | `max_jumps`    | Número de saltos encadenados (2 = doble salto)                      |
| Longitud de onda  | `size`         | Tamaño del personaje (menor = más difícil de golpear)               |
| Carga             | `attack_power` | Daño por proyectil                                                  |
| Frecuencia        | `attack_rate`  | Disparos por segundo                                                |
| Alcance           | `attack_range` | Distancia que recorren los proyectiles                              |
| Apantallamiento   | `defense`      | Reducción de daño recibido (%)                                      |
| Atracción         | `pickup_radius`| Radio al que los fotones vuelan hacia Wilas (desde la Fase 7)       |
| Túnel             | `dash`         | Esquiva corta con invulnerabilidad (ver [04-jugador](04-player.md)) |

### Economía

| En juego          | En código            | Qué es                                                                          | Por qué                                                       |
| ----------------- | -------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Fotón (γ)         | `coin`               | Moneda común de partida                                                         | Cuanto de energía: pagas energía para excitar cosas           |
| Positrón (e⁺)     | `key`                | Llave especial de partida                                                       | Antimateria que se aniquila con electrones                    |
| Pozo cuántico     | `chest` (común)      | Contenedor que se abre pagando fotones                                          | Una partícula atrapada sale si recibe energía de excitación   |
| Electrón ligado   | `chest` (especial)   | Contenedor que se abre con un positrón                                          | e⁺ + e⁻ → aniquilación → libera lo que había                  |
| Superposición     | `choice_pedestal`    | Dos objetos superpuestos: al observar (tocar) uno, el otro colapsa y desaparece | Colapso de la función de onda                                 |
| Cuanto de energía | `heal_pickup`        | Recupera coherencia                                                             | —                                                             |
| Intercambio       | `shop`               | Tienda de la partida                                                            | Partículas de intercambio (piones)                            |
| Pión              | `shopkeeper`         | Tendero                                                                         | El pión media la fuerza entre nucleones: "el que intercambia" |
| Estado fundamental | `chunk_rest`        | Tramo de descanso: curar o subir la coherencia máxima                           | El estado de menor energía                                    |
| Quark             | `meta_currency`      | Moneda permanente común                                                         | Constituyentes del núcleo: vuelven al Núcleo contigo          |
| Bosón de Higgs    | `rare_meta_currency` | Moneda permanente rara                                                          | Da "masa": desbloqueos grandes                                |

### Objetos y mejoras

| En juego        | En código      | Qué es                                                  | Referencia             |
| --------------- | -------------- | ------------------------------------------------------- | ---------------------- |
| Observable      | `passive_item` | Objeto pasivo permanente durante la partida             | Objetos de Isaac       |
| Operador        | `active_item`  | Objeto activo con recarga                               | Objeto activo de Isaac |
| Interacción     | `boon`         | Mejora de una familia de fuerza que modifica una acción | Bendiciones de Hades   |
| Unificación     | `duo_boon`     | Interacción que requiere dos (o más) familias           | Duos de Hades          |
| Bosón mensajero | `boon_giver`   | Personaje que ofrece interacciones de su familia        | Dioses de Hades        |

### Familias de interacción

| Familia                  | Mensajero       | Código            | Tema de efectos                                       |
| ------------------------ | --------------- | ----------------- | ----------------------------------------------------- |
| Electromagnética         | el Fotón        | `electromagnetic` | Cadenas, rebotes, electrificar                        |
| Fuerte                   | el Gluón        | `strong`          | Daño alto, explosiones (fisión), perforar             |
| Débil                    | los Bosones W/Z | `weak`            | Decaimiento (daño en el tiempo), transmutar           |
| Gravitatoria             | el Gravitón     | `gravity`         | Atracción, ralentizar (dilatación temporal), órbitas  |
| Cuántica (sin mensajero) | —               | `quantum`         | Rarezas: superposición, entrelazamiento, túnel, espín |

### Estados alterados (en enemigos)

| En juego    | En código        | Efecto                                         |
| ----------- | ---------------- | ---------------------------------------------- |
| Cargado     | `status_charged` | Al acumular X cargas descarga daño en área     |
| Inestable   | `status_decay`   | Daño por segundo acumulable                    |
| Dilatado    | `status_slow`    | Ralentizado                                    |
| Confinado   | `status_root`    | Inmovilizado                                   |
| Entrelazado | `status_linked`  | Recibe una copia del daño que reciba su pareja |
| Observado   | `status_observed`| Congelado por el operador Efecto Zenón         |
| Aturdido    | `status_stunned` | Inmovilizado un instante por el operador Colapso |

### Meta y Núcleo

| En juego              | En código            | Qué es                                                  |
| --------------------- | -------------------- | ------------------------------------------------------- |
| Campo de Higgs        | `upgrade_station`    | Mejoras permanentes de estadísticas y reglas            |
| Acelerador            | `unlock_station`     | Desbloquea objetos e interacciones para el pool         |
| Espectro              | `character_select`   | Selección y desbloqueo de personajes                    |
| Cámara de burbujas    | `records`            | Estadísticas, logros y registro de objetos descubiertos |
| Generador de Entropía | `difficulty_station` | Configurar las perturbaciones                           |
| Entropía              | `heat`               | Nivel de dificultad total                               |
| Perturbación          | `heat_modifier`      | Cada modificador de dificultad                          |
| Salto al orbital 1s   | `run_start`          | Portal para empezar una partida (con o sin semilla)     |

### Peligros

| En juego             | En código        | Qué es                                         |
| -------------------- | ---------------- | ---------------------------------------------- |
| Pico de potencial    | `spike`          | Superficie que daña al tocarla                 |
| Barrera de potencial | `hazard_wall`    | Pared que empuja o daña                        |
| Campo magnético      | `force_field`    | Zona que desvía al jugador y a los proyectiles |
| Lluvia de muones     | `falling_hazard` | Partículas que caen desde arriba               |
