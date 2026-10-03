# 09 · Enemigos y jefes

Todos los enemigos son partículas (o fenómenos) subatómicas. Cada tipo tiene un recurso `EnemyData` con sus estadísticas, y comportamientos reutilizables (patrullar, orbitar, perseguir, disparar) implementados como componentes o estados.

## Principios

- **Legibles:** silueta y color únicos; un aviso visual de 0,3–0,5 s antes de cada ataque.
- **Pensados para lo vertical:** amenazas que vienen de arriba, de abajo y de los lados. Algunas penalizan quedarse quieto.
- **Mecánica con significado físico:** el comportamiento se inspira en la partícula (decaimiento, órbitas, aniquilación…).
- **Escalado:** vida y daño escalan por capa y por Entropía (`×(1 + 0,25 × índice_capa)`).

## Bestiario v1.0

### Capa K

| Enemigo              | Código             | Comportamiento                                                                                                      | Vida | Daño |
| -------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------- | ---- | ---- |
| **Electrón orbital** | `orbital_electron` | Orbita en círculo alrededor de un punto fijo. Daño por contacto. Algunas variantes orbitan en elipse.               | 10   | 10   |
| **Neutrón libre**    | `free_neutron`     | Patrulla una plataforma. Al morir **decae**: suelta un electrón orbital pequeño que orbita en su lugar durante 5 s. | 15   | 10   |
| **Partícula alfa**   | `alpha_particle`   | Pesada y lenta. Al verte en su fila, carga en horizontal y choca con la pared.                                      | 30   | 15   |

### Capa L

| Enemigo        | Código       | Comportamiento                                                                                                  | Vida | Daño |
| -------------- | ------------ | --------------------------------------------------------------------------------------------------------------- | ---- | ---- |
| **Muón**       | `muon`       | Cae desde arriba en picado, con aviso previo (_lluvia de muones_). Rebota una vez al tocar el suelo.            | 12   | 15   |
| **Kaón**       | `kaon`       | **Oscila** entre dos formas cada 2 s: sólida (vulnerable, dispara) e intangible (se mueve hacia ti).            | 20   | 10   |
| **Antiprotón** | `antiproton` | Vuela despacio hacia ti. Si te toca, **se aniquila**: gran daño, pero él muere. Hay que eliminarlo a distancia. | 18   | 30   |

### Capa M

| Enemigo                  | Código         | Comportamiento                                                                                     | Vida  | Daño           |
| ------------------------ | -------------- | -------------------------------------------------------------------------------------------------- | ----- | -------------- |
| **Neutrino**             | `neutrino`     | Atraviesa paredes y plataformas; casi invisible, solo destella cada 1,5 s.                         | 15    | 10             |
| **Partículas virtuales** | `virtual_pair` | Aparecen **en pareja**. Si no eliminas a las dos en 4 s, se aniquilan entre sí y explotan en área. | 8 + 8 | 25 (explosión) |
| **Monopolo**             | `monopole`     | Crea un campo que **desvía tus proyectiles** alrededor de él; hay que acercarse o usar el Túnel.   | 35    | 15             |

### Capa N

| Enemigo            | Código          | Comportamiento                                                                                                                                                                                   | Vida   | Daño |
| ------------------ | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ | ---- |
| **Trío de quarks** | `quark_triplet` | Tres quarks unidos por hilos de gluón. Si separas uno (por daño o retroceso), el hilo se estira y, al romperse, **crea un nuevo par** (hadronización). Hay que matar a los tres a la vez o casi. | 12 × 3 | 10   |
| **Tau**            | `tau_enemy`     | Élite. Rápida y agresiva; al morir decae en un muón.                                                                                                                                             | 60     | 20   |
| **Bosón Z**        | `z_boson`       | Torreta pesada. Dispara ráfagas en abanico y es inmóvil.                                                                                                                                         | 50     | 15   |

### Implementación de la Capa K (Fase 6)

| Enemigo | Escena | Comportamiento | Detalles |
| --- | --- | --- | --- |
| Electrón orbital | `actors/enemies/orbital_electron/` | `OrbitBehavior` | Órbita de 56 px de radio alrededor de su hueco, 1,5 s por vuelta. La fase inicial, el sentido y si es una elipse (35 %, con 0,55 de proporción) salen de su hueco. Dibuja su traza: la órbita punteada y un arco que se desvanece detrás. Atraviesa los tiles |
| Neutrón libre | `actors/enemies/free_neutron/` | `PatrolBehavior` | 50 px/s; da la vuelta en paredes y bordes (nunca cae de su plataforma) con una pausa de 0,25 s. Al morir **decae** en un electrón de desintegración (`decay_electron`: 4 de vida, 5 de daño, órbita de 28 px en 1 s) que vive 5 s y se desvanece sin contar como eliminado ni soltar nada |
| Partícula alfa | `actors/enemies/alpha_particle/` | `ChargeBehavior` | Patrulla a 35 px/s. Si ve a Wilas en su fila (±40 px, hasta 560 px y sin paredes en medio) parpadea 0,45 s (aviso), embiste a 520 px/s con líneas de velocidad y se queda aturdida 0,9 s al chocar con una pared (o descansa 0,6 s si llega a un borde). Resiste el 80 % del retroceso |

- **Datos**: `EnemyData` (`data/enemies/*.tres`): id, clave de nombre, vida, daño por contacto, velocidad, resistencia al retroceso, caídas y producto de decaimiento. La vida y el daño escalan con `× (1 + 0,25 × índice_capa)` (`EnemyData.scale_for_layer`).
- **Escena base** (`Enemy`, `actors/enemies/enemy.gd`): un `CharacterBody2D` sin capa de física (solo choca con el mundo) con `HealthComponent`, `StatusEffects`, un `Hurtbox` en la capa `enemies` (lo alcanzan los disparos) y un `Hitbox` de contacto con máscara `player`, y un hijo `Behavior` (`EnemyBehavior`) que lo mueve. Los enemigos de suelo tienen el origen en los pies; los aéreos, en el centro. Buscan a Wilas por el grupo `player`.
- **Al recibir un disparo**: destello blanco (HDR) de 100 ms, retroceso que se amortigua y los estados alterados del golpe. Nada vivo está quieto: el cuerpo respira y toma el tinte del estado alterado activo.
- **Al morir**: emite `Events.enemy_killed` (cuenta para la partida y da _hitstop_), se dibuja una traza de cámara de burbujas y el tramo suelta sus caídas y su producto de decaimiento.
- **Aparición**: los huecos `slot_enemy_ground` (sobre la superficie de una plataforma; el validador lo comprueba) y `slot_enemy_air` de los tramos normales y de bifurcación. La `LayerData` de la Capa K los rellena con un 55 % y un 50 % de probabilidad: en el suelo, neutrón libre (peso 2) o partícula alfa (peso 1); en el aire, electrón orbital. Ver [05-mundo](05-world.md#implementación-fase-5).
- **Caídas**: 30 % de soltar 1–2 fotones (la alfa, 1–3), con la tirada direccionada por su hueco (dominio `drop`, ver [08-semillas](08-seeds.md#combate-y-enemigos-fase-6)). Los quarks y los cuantos de energía llegan con sus sistemas (Fases 7 y 10).

### Sala de pruebas de combate

`world/debug/combat_test_room.tscn` (F6): un suelo, una plataforma larga, una atravesable y Wilas. **1**, **2** y **3** sacan un electrón orbital, un neutrón libre o una partícula alfa; **4**, **5** y **6** aplican Inestable, Dilatado y Confinado a todos; **K** los elimina y **R** devuelve a Wilas al inicio. Con `-- --spawn=all` empieza con uno de cada. Los enemigos viven en un `Chunk` vacío, así que caídas y decaimiento funcionan como en la partida; Wilas no muere (se cura al bajar de la mitad).

## Jefes

Cada jefe tiene 2–3 fases, una arena propia y un patrón que enseña la mecánica principal de su capa.

### Capa K — **Par de Pauli** (`boss_pauli_pair`)

- Dos electrones 1s gemelos con **espín opuesto**. Se mueven **en espejo** respecto al eje central de la arena.
- **Principio de exclusión:** nunca pueden estar en el mismo "estado". Mientras uno es vulnerable, el otro está blindado, y se alternan cada pocos segundos o al recibir X daño.
- Fase 2: al 50 %, las órbitas se aceleran y disparan pulsos al cruzarse.
- Enseña: leer patrones, cambiar de objetivo y moverse en vertical.

### Capa L — **Orbital p** (`boss_p_orbital`)

- Tres lóbulos en forma de haltera (px, py, pz) que **rotan** alrededor del centro de la arena; las plataformas son los propios lóbulos.
- Hay que destruir los tres lóbulos, cada uno con un comportamiento distinto (disparo, embestida, campo).
- Enseña: plataformas móviles y combate en el aire.

### Capa M — **Cascada de Auger** (`boss_auger_cascade`)

- Un átomo excitado gigante. Cada vez que recibe cierta cantidad de daño **emite electrones** (efecto Auger) que se convierten en enemigos menores.
- Fase 2: campos magnéticos que desvían proyectiles; hay que colocarse bien.
- Enseña: gestionar adds y el control del espacio.

### Capa N — **Barrera de Coulomb** (`boss_coulomb_barrier`)

- La fuerza del propio átomo que no quiere dejarte ir. **Atrae** a Wilas hacia abajo de forma continua, mientras la arena asciende lentamente con la Decoherencia _activa_.
- Hay que combatir mientras se sube. Al derrotarla se produce la **Ionización**.
- Fase final: plataformas virtuales que parpadean y ataques de todas las familias anteriores.

## Recompensas

| Fuente         | Fotones       | Quarks         | Otros                                             |
| -------------- | ------------- | -------------- | ------------------------------------------------- |
| Enemigo normal | 30 % de 1–2 γ | 5 % de 1 quark | 2 % de cuanto de energía                          |
| Élite          | 3–6 γ         | 1–2 quarks     | 10 % de positrón                                  |
| Jefe           | 15–25 γ       | 10–25 quarks   | Recompensa elegida y bosón de Higgs (primera vez) |

Las probabilidades de caída siguen las reglas de [08-semillas](08-seeds.md). La tirada de caída de cada enemigo se direcciona con el hueco en el que apareció, así que es reproducible.
