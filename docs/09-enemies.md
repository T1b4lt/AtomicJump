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
