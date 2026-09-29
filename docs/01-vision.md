# 01 · Visión y pilares

## Concepto en una frase

**AtomicJump** es un roguelike de plataformas vertical: una partícula consciente debe escapar del átomo ascendiendo desde el núcleo a través de sus capas electrónicas, mientras una onda de decoherencia sube desde abajo y la obliga a no detenerse.

## Referencias

| Referencia                           | Qué tomamos                                                                                                                                                                                                                                                          |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Hades I y II**                     | Bucle de huida y regreso al hogar (el Núcleo), mejoras permanentes entre partidas, bendiciones de "dioses" por familias (aquí: las interacciones fundamentales), combinaciones dobles, elección de recompensa antes de entrar, pacto de dificultad (aquí: Entropía). |
| **The Binding of Isaac**             | Objetos pasivos con sinergias sorprendentes, objeto activo con recarga, disparo en 4 direcciones, cofres y llaves (aquí: pozos cuánticos y positrones), tiendas, salas secretas, registro de objetos descubiertos, desbloqueos que amplían el pool.                  |
| **Icy Tower / Downwell / Jump King** | Ascensión vertical como eje, la altura como puntuación natural, movimiento preciso y con buen _game feel_.                                                                                                                                                           |

La diferencia clave con las referencias: en lugar de **salas** hay **tramos** verticales, y la prisa la pone la **Decoherencia** que asciende desde abajo.

## Pilares de diseño

1. **Subir siempre.** Todo empuja hacia arriba: la Decoherencia, la puntuación por altura y las recompensas. Pararse es una decisión con coste.
2. **Cada partida es un build.** El jugador empieza desde cero y construye su personaje con interacciones, observables y operadores. Las combinaciones deben sentirse potentes y a veces rotas.
3. **La semilla es sagrada.** Una semilla determina por completo el mundo que el jugador se encuentra. Compartir una semilla es compartir una partida (ver [08-semillas](08-seeds.md)).
4. **Progresión que se nota.** Morir nunca es perder del todo: siempre se vuelve al Núcleo con algo que invertir.
5. **Imaginario cuántico coherente.** Nada de llaves, cofres ni monedas genéricas. Todo elemento del juego tiene un nombre y una función inspirados en la física de partículas y la mecánica cuántica (ver [02-universo](02-universe.md)).
6. **Lo social ocurre fuera del juego.** No hay multijugador. El juego facilita compartir: semillas fáciles de copiar y una pantalla final pensada para hacerle captura.

## Decisiones tomadas

| Tema                  | Decisión                                                                                                                     |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Estructura de partida | Finita: 4 capas (K, L, M, N) con jefe cada una. Al escapar se desbloquea un modo infinito.                                   |
| Presión               | Amenaza ascendente (la Decoherencia) de velocidad variable. La cámara sigue al jugador.                                      |
| Tramos                | Diseñados a mano (_chunks_) con variación procedural. Bifurcaciones estilo Hades con la recompensa visible.                  |
| Combate               | Disparo en 4 direcciones (flechas / stick derecho).                                                                          |
| Semilla y meta        | La semilla fija el mundo. Las mejoras permanentes siempre se aplican y modifican las probabilidades sobre esa misma semilla. |
| Dificultad avanzada   | Sistema de Entropía (tipo Pacto de Hades) con multiplicador de puntuación y recompensas.                                     |
| Economía de partida   | Fotones (moneda común), positrones (llave especial) y tiendas.                                                               |
| Meta                  | Mejoras de estadísticas, objetos al pool, capas y modos, y personajes.                                                       |
| Multijugador          | Ninguno.                                                                                                                     |
| Plataformas v1.0      | PC (Windows / Linux) con teclado y mando. Build web opcional para pruebas.                                                   |
| Dirección de arte | Vectorial geométrico luminoso ("Luz sobre el vacío"), generado por código en `art/`, a 1280×720. Ver [13](13-art-style.md). |
| Túnel (esquiva)       | Mecánica base: esquiva corta con invulnerabilidad, ranura de interacción y acceso a secretos. |
| Nombres               | El juego se mantiene como **AtomicJump** y el protagonista como **Wilas**. |
| Estado fundamental    | El jugador elige entre curarse o aumentar su coherencia máxima (como las fuentes de Hades). |
| Modo Plasma           | Tiene su propia tabla de puntuación, separada de las partidas normales. |
| Personalidad          | Frases cortas de los bosones mensajeros y del Pión. Los diálogos completos quedan como idea a futuro. |
| Distribución          | itch.io. Steam queda como idea a futuro. |
| Alcance del roadmap   | Hasta la v0.99.0. La música y el pulido final para la v1.0 quedan fuera ([99-ideas a futuro](99-future-ideas.md)). |

## Público y alcance

- **Público:** jugadores de roguelikes de acción que valoran la rejugabilidad y la maestría mecánica.
- **Duración objetivo:** 6–8 min por capa, es decir, 25–35 min una partida completa con victoria. Una partida fallida típica dura 5–15 min.
- **Alcance de contenido v1.0** (orientativo; el [ROADMAP](../ROADMAP.md) lo completa en la v0.99.0, y la v1.0 añade la música y el pulido final):
  - 4 capas con unos 15 tramos diseñados cada una, más tramos especiales.
  - 4 jefes y unos 12 tipos de enemigo.
  - Unos 60 observables, unas 8 operadores y unas 30 interacciones (incluidas unificaciones).
  - 4 personajes.
  - Unas 20 mejoras del Campo de Higgs y unas 10 perturbaciones de Entropía.

## Dirección artística

Estilo **"Luz sobre el vacío"**: vectorial, geométrico y luminoso sobre fondo casi negro, generado íntegramente por código. Fondos con los orbitales reales de cada capa, colores por carga eléctrica y efectos inspirados en las trazas de una cámara de burbujas. Los assets actuales de Kenney son provisionales y se sustituyen a medida que se generan los nuevos.

Guía completa en [13-dirección de arte](13-art-style.md) y propuesta visual en [`assets/art-direction/index.html`](assets/art-direction/index.html).
