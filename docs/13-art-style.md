# 13 · Dirección de arte: "Luz sobre el vacío"

Guía de estilo visual de AtomicJump y documentación del generador de arte programático (`art/`).

> **Propuesta visual completa, con imágenes y animaciones:** [`docs/assets/art-direction/index.html`](assets/art-direction/index.html) (ábrela en un navegador). Este documento es la referencia escrita; la propuesta es la referencia visual.

## Resumen

Todo el arte del juego es **vectorial, geométrico y luminoso sobre un fondo casi negro**, y se **genera por código**. Las partículas brillan, las órbitas se curvan, los fondos son nubes de probabilidad reales y los efectos imitan las trazas de una cámara de burbujas. La personalidad sale de la forma, el color, el movimiento y el *game feel*, no del detalle.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Estilo | Vectorial geométrico con brillo ("neón de cámara de burbujas"). |
| Resolución | Referencia **1280×720**, `stretch/mode = canvas_items`, `aspect = keep_width`. |
| Producción | Todo el arte se genera con código Python en `art/` (paleta central + generadores). No hay arte pintado a mano. |
| Arte provisional | Desaparece: cada asset nace con el estilo final. Los assets de Kenney se eliminan a medida que se sustituyen (la Fase 5 quitó los de los tramos; quedan los de fotones, positrones y cofres). |
| Brillo (*glow*) | Lo pone el motor, no el SVG: el importador SVG de Godot no soporta filtros. Verificado en la Fase 4: HDR 2D + glow del `WorldEnvironment` funcionan en *Compatibility*. |
| Animación | En el motor (tweens, AnimationPlayer, shaders y partículas) sobre formas vectoriales. No hay hojas de sprites. |
| Fondos | Shaders que calculan el orbital de cada capa en tiempo real. Las imágenes generadas con NumPy son la referencia. |
| Tipografía | **Space Grotesk** (títulos, UI) y **JetBrains Mono** (números, datos, semillas). Ambas con licencia OFL (Google Fonts). |
| SFX | Sintetizados por código (estilo sfxr), con la misma filosofía de paleta y coherencia. |
| Música | Externa (librería o encargo). Fuera del roadmap: necesaria para la v1.0, recogida en [ideas a futuro](99-future-ideas.md). |

## Pilares visuales

1. **Luz sobre el vacío.** Fondo casi negro; todo lo importante emite luz. El contraste máximo guía el ojo hacia el jugador, el peligro y las recompensas.
2. **Física de verdad.** Fondos con orbitales reales, colores por carga eléctrica, trazas de cámara de burbujas y diagramas de Feynman en los iconos. Coherente para quien sabe física e intuitivo para quien no.
3. **Legible a 60 FPS.** Siluetas únicas, código de color estricto y avisos antes de cada ataque. En el caos se entiende todo sin leer texto.

## Paleta

**Fuente de verdad:** `art/atomic_art/palette.py`. Las tablas de aquí la reflejan; si hay discrepancia, manda el código. En Godot, la paleta es la clase `Palette` (`core/palette.gd`, constantes `Color` como `Palette.PLAYER` o `Palette.LAYER_K_ACCENT`), que **genera** `art/build_game_assets.py` desde el mismo fichero: no se edita a mano.

### Vacío y luz

| Token | Hex | Uso |
|---|---|---|
| `VOID` | `#05070F` | Fondo base |
| `VOID_2` | `#0B1022` | Paneles, paredes |
| `VOID_3` | `#141B36` | Rellenos elevados (plataformas, contenedores) |
| `GRID` | `#1C2547` | Retículas |
| `INK` | `#EAF2FF` | Luz: texto, líneas principales |
| `INK_DIM` | `#8C97B8` | Texto y líneas secundarias |

### Identidad y carga

| Token | Hex | Uso |
|---|---|---|
| `PLAYER` | `#6BFFB8` | **Exclusivo del jugador**: Wilas, sus proyectiles y su barra de coherencia |
| `PLAYER_DEEP` | `#1FAE7A` | Sombra del núcleo del jugador |
| `NEGATIVE` | `#3DE8FF` | Carga negativa: electrones, muones, tau, antiprotón |
| `POSITIVE` | `#FF3D8B` | Carga positiva: protones, alfa, positrón. También **peligro** (picos, proyectiles enemigos) |
| `NEUTRAL` | `#DCE3F5` | Neutras: neutrón, neutrino, kaón, bosón Z |
| `DECOHERENCE` | `#C9D2FF` | La amenaza ascendente |

### Familias, rarezas, divisas y capas

| Grupo | Tokens |
|---|---|
| Familias | Electromagnética `#FFE45C` · Fuerte `#FF6A3D` · Débil `#C6FF3D` · Gravitatoria `#8F7BFF` · Cuántica `#FF7BF1` |
| Rarezas | Fundamental `#EAF2FF` · Excitado `#4DA3FF` · Resonante `#B06BFF` · Unificado `#FFD25A` |
| Divisas | Fotón = amarillo EM · Positrón = `POSITIVE` · Quark = colores `#FF4D4D` `#4DFF88` `#4D7BFF` · Higgs `#FFD25A` |
| Capas (tinte / acento) | K `#2F6BFF` / `#7FB0FF` · L `#12C9B4` / `#7CF5E4` · M `#8C4DFF` / `#C7A6FF` · N `#FF3D62` / `#FF9DB0` |

El acento de la capa colorea las plataformas, los textos de la capa y los detalles de la interfaz de esa capa.

## Lenguaje visual: reglas que no se rompen

1. **El color es la carga.** Cian negativa, magenta positiva, blanco frío neutra. El menta es solo del jugador.
2. **Relleno es materia; hueco es antimateria.** La antimateria es un núcleo de vacío con contorno luminoso (su imagen en negativo).
3. **Ojos redondos solo para el jugador.** Los enemigos tienen dos ojos rasgados inclinados hacia dentro.
4. **La traza anticipa el movimiento.** Cada enemigo muestra la huella de cómo se mueve (órbita, estela, líneas de velocidad).
5. **La forma del marco es la familia** (ver [Iconografía](#iconografía)).
6. **La joya es la rareza.** El color de rareza no se usa para nada más.

Reglas complementarias:
- **Avisar antes de golpear:** todo ataque tiene un aviso de 300–500 ms (línea, anillo o parpadeo).
- **Nada vivo está quieto** (ver [Animación](#animación)).
- **La forma también comunica, no solo el color**: requisito de accesibilidad (ver [Accesibilidad](#accesibilidad)).

## Formas, escala y trazo

| Elemento | Tamaño de referencia (a 1280×720) |
|---|---|
| Rejilla de tiles | 32 px |
| Wilas | Núcleo de 40 px de diámetro (orbital de ~62 px) |
| Enemigos normales | 20–56 px |
| Élites | 50–60 px |
| Jefes | 100–250 px |
| Iconos | 64 px (marco de ~56 px) |
| Recogibles | 20–34 px |

- Trazos de 1–3 px con **extremos y uniones redondeados**. Los contornos importantes miden 2–2,5 px.
- Primitivas: círculos, elipses, arcos, polígonos regulares, ondas senoidales y muelles (gluones).
- Esquinas redondeadas en elementos "construidos" (plataformas `rx=3`, marcos cuadrados `rx=10`).
- Degradados radiales **solo** en los núcleos de las partículas (blanco en el centro → color → color atenuado).
- Nada de texturas, sombras proyectadas ni perspectiva: todo es plano y emite luz.

## Personajes

### Wilas

- **Anatomía:** núcleo esférico menta con degradado radial y halo tenue, un **orbital inclinado −25°** que lo rodea (la mitad trasera pasa por detrás del núcleo y la delantera por delante), un **electrón** blanco que recorre el orbital y **dos ojos** grandes.
- **Expresiones:** `neutral`, `blink`, `happy`, `jump`, `focus`, `hurt`.
- **Deformación:** el núcleo se aplasta y estira (*squash & stretch*) anclado a la base; el orbital no se deforma.
- **Daño:** destello blanco sobre el núcleo (parámetro `flash`).
- **En el juego** (Fase 4): Wilas se compone de piezas exportadas por separado (núcleo con halo, orbital, mitad delantera del orbital, electrón y unos ojos por expresión) y `PlayerVisual` las anima: el electrón da 1 vuelta/s y pasa por detrás del núcleo en la mitad superior del orbital, el núcleo respira en reposo y se aplasta o estira anclado a la base, los ojos miran hacia donde va y cambian con el estado (`jump` al subir, `focus` en el Túnel, `hurt` al recibir daño, `happy` al aterrizar, `blink` cada 2–4 s). El salto cuántico lanza un anillo elíptico bajo Wilas y el Túnel lo vuelve semitransparente con una estela. El núcleo, el orbital y el electrón brillan (HDR).

### Personajes desbloqueables

Todos comparten el menta del jugador y los ojos redondos; se distinguen por la silueta.

| Personaje | Silueta |
|---|---|
| Muón | Núcleo cuadrado redondeado y doble anillo grueso: pesado |
| Neutrino | Pequeño, semitransparente, contorno punteado y ecos detrás |
| Tau | Rombo afilado que suelta fragmentos: se desintegra |

## Enemigos

Construcción: esfera (o forma) con el color de su carga + ojos rasgados + traza que indica su movimiento. La lista completa y el comportamiento están en [09-enemigos](09-enemies.md); la clave visual:

En el juego (Fase 6, Capa K): cada enemigo es un SVG sin filtros (`enemies.*_sprite()` en `atomic_art/enemies.py`) que brilla con `modulate` HDR (×1,35). Su traza se dibuja en el motor cuando depende del movimiento: el electrón orbital pinta su órbita punteada y un arco que se desvanece detrás de él; la partícula alfa enseña sus líneas de velocidad al embestir. El cuerpo respira (±4 %), destella en blanco 100 ms al recibir un disparo, parpadea durante el aviso de 0,45 s de la embestida y toma el color de la familia del estado alterado activo (Inestable = débil, Dilatado = gravitatoria, Confinado = fuerte). El electrón de desintegración del neutrón es un electrón orbital más pequeño.

| Enemigo | Clave visual |
|---|---|
| Electrón orbital | Esfera cian sobre una órbita punteada con estela |
| Neutrón libre | Cápsula neutra con sus tres quarks de color dentro y una grieta |
| Partícula alfa | Racimo de 2 protones magenta + 2 neutrones blancos, líneas de velocidad |
| Muón | Gota cian con estela vertical larga |
| Kaón | Mitad sólido, mitad contorno punteado; onda encima |
| Antiprotón | Antimateria (hueco) con púas cian |
| Neutrino | Mira punteada casi invisible |
| Partículas virtuales | Pareja materia/antimateria unida por un bucle discontinuo |
| Monopolo | Mitad magenta, mitad cian, con líneas de campo índigo |
| Trío de quarks | Tres esferas R/G/B unidas por muelles de gluón naranjas |
| Tau (enemigo) | Estrella cian de 12 puntas con núcleo oscuro |
| Bosón Z | Hexágono neutro con una Z y ondas emitidas en abanico |
| **Par de Pauli** (jefe) | Dos esferas cian grandes con coronas de luz, flechas de espín ↑↓ y escudo punteado que cambia de gemelo |

## Mundo

### Fondos orbitales

Cada capa muestra la densidad de probabilidad |ψ|² de su orbital característico (átomo de hidrógeno, corte 2D, en unidades de radio de Bohr):

| Capa | Orbital | ψ (sin normalizar) | Forma |
|---|---|---|---|
| K | 1s | `e^(−r)` | Nube esférica |
| L | 2p | `y · e^(−r/2)` | Dos lóbulos |
| M | 3d | `x·y · e^(−r/3)` | Trébol de cuatro lóbulos |
| N | 4f | `x(x² − 3y²) · e^(−r/4)` | Seis pétalos |

La densidad se comprime con `pow(d, 0.45)`, se tiñe con el color de la capa y se le superponen "mediciones" (puntos muestreados según la densidad) con el color de acento, anillos concéntricos tenues y una viñeta. En el juego: shader con respiración lenta de la nube (±12 %) y parpadeo de las mediciones. **Capa K implementada** (Fase 5): `world/backgrounds/orbital_background.gdshader` en una `CanvasLayer` (capa −100) fija en pantalla (`OrbitalBackground`, colores de `Palette`); las mediciones son una rejilla de celdas de 6 px con un punto en las que pasan una prueba de hash contra la densidad, respiran con la nube y brillan un poco (HDR).

### Tiles y peligros

| Elemento | En juego | Aspecto |
|---|---|---|
| Plataforma sólida | Nivel de energía | Barra `VOID_3` con borde superior brillante del acento de capa y marcas de escala |
| Plataforma atravesable | Nivel virtual | Línea discontinua brillante con una sombra punteada |
| Pared | Retícula | Relleno `VOID_2`, rejilla de 16 px `GRID` con nodos y borde `INK_DIM` |
| Pico de potencial | Peligro | Gráfica en diente de sierra `POSITIVE` sobre una línea base |

En el juego (Fase 5), `world.tileset_atlas(capa)` dibuja el atlas de tiles de 32 px de cada capa (8 × 3, importado al doble): las 16 combinaciones de lados expuestos de la retícula (el borde solo se dibuja hacia el hueco, rejilla de 16 px desfasada para que case entre tiles), el nivel de energía suelto, izquierdo, central y derecho (barra de 14 px con extremos redondeados; colisiona la mitad superior del tile) y el nivel virtual (raya discontinua de periodo 16, sin costuras). El TileSet de Godot (`world/tilesets/layer_k_tileset.tres`) asigna colisiones, la plataforma atravesable y los terrenos sobre esa distribución, así que **la distribución del atlas no se cambia sin actualizar el TileSet**. Las capas de tiles se dibujan a escala 0,5 y la de plataformas con `self_modulate` 1,4, para que brille su borde. El pico de potencial es un sprite (`hazards/potential_spikes.svg`, 2 tiles) dentro de la escena `Spike`.

### Decoherencia

Lo contrario del resto del juego: **ausencia de forma**. Un frente de ruido pálido (`DECOHERENCE`) con un borde ondulado brillante, bloques de 4 px que se desprenden por delante y líneas de escaneo. En el juego: shader de ruido animado con el frente como suma de senoidales desfasadas (`world/rising_threat/decoherence.gdshader`, Fase 4: traducción directa de `decoherence_strip()`; el ruido y los bloques cambian 12 veces por segundo y el borde brilla en HDR).

### Bifurcaciones

Cada salida del techo tiene una línea discontinua del acento de capa y el icono de su recompensa flotando. Al cruzar una, la otra **colapsa**: la pared se cierra desde los lados, el icono se encoge y se disuelve en fragmentos. Implementado en la Fase 5 (`ForkGate`). Los iconos de recompensa (`rewards/reward_<tipo>.svg`) son el recogible de la recompensa dentro de un marco cuadrado de 40 px.

## Objetos

| Objeto | Aspecto |
|---|---|
| Fotón (×1/×5/×10) | Paquete de ondas amarillo; más valor = más periodos y más halos |
| Positrón | Antimateria magenta con un signo + |
| Cuanto de energía | Rombo menta con ħ |
| Quark | Tres cargas de color R/G/B |
| Bosón de Higgs | Esfera dorada con H y halo discontinuo (propagador escalar) |
| Pozo cuántico | Pozo de potencial en U con tres niveles de energía y el objeto en el fondo; precio encima |
| Electrón ligado | Objeto dentro de dos órbitas cian con su electrón; icono de e⁺ encima |
| Superposición | Dos objetos semitransparentes solapados bajo \|ψ⟩ y una onda cuántica |

## Iconografía

Gramática fija para los más de 100 iconos: **marco + glifo + joya**.

| Marco | Familia / tipo |
|---|---|
| Círculo | Electromagnética |
| Hexágono | Fuerte |
| Triángulo | Débil |
| Rombo | Gravitatoria |
| Estrella de 5 puntas | Cuántica |
| Cuadrado redondeado (blanco) | Observables y operadores |

- **Marco:** relleno `VOID_2`, contorno de 2,4 px del color de la familia.
- **Glifo:** el efecto, preferiblemente como **mini diagrama de Feynman** (fermión = línea recta, fotón/W/Z = onda, gluón = muelle, Higgs = discontinua) o un símbolo físico (espiral, flechas de espín, ondas).
- **Joya:** rombo de 8 px bajo el marco con el color de la rareza.
- Un icono nuevo es una combinación nueva de piezas existentes; solo hace falta un glifo nuevo cuando el efecto no encaja en ninguno.

## Efectos visuales

- **Firma:** trazas de cámara de burbujas. Espirales que se cierran (`r = r₀ · e^(−k·t)`), vértices de desintegración en V e hileras de burbujas diminutas. Se usan en impactos, muertes, transiciones de capa y como decoración de fondo muy tenue.
- **Proyectil del jugador:** paquete de ondas menta (cabeza brillante + estela ondulada). Cada familia de interacción cambiará el color y la forma de la estela: **el build se ve en los disparos**.
- **Impacto:** destello blanco en el objetivo, empujón, anillo que se expande y dos espirales de cargas opuestas. En el juego (Fase 6) es `ImpactEffect`, dibujado con `_draw()` en 0,35 s: un disco blanco que se encoge, el anillo, dos espirales `r = r₀ · e^(−k·t)` que crecen y una hilera de burbujas; el del proyectil del jugador es menta y blanco, y la muerte de un enemigo usa uno mayor (0,5 s) en cian y magenta. Con _hitstop_ de 30–60 ms.
- **Aniquilación:** destello blanco y dos fotones gamma en direcciones opuestas (e⁺ + e⁻ → γ γ).

## Animación

### Principios

1. **Nada está quieto.** Todo lo vivo respira, orbita o vibra; el vacío es lo único inmóvil.
2. **Anticipar y deformar.** Aplastar antes de saltar y al aterrizar; estirar al subir.
3. **Avisar antes de golpear.** 300–500 ms de aviso legible.
4. **Los impactos se sienten.** Destello, retroceso, *hitstop* y traza.
5. **La física manda.** Órbitas elípticas, espirales de carga, desintegraciones con sentido.
6. **Todo en el motor.** Tweens, AnimationPlayer y shaders sobre vectores.

### Tiempos de referencia

Las animaciones de la propuesta (`art/atomic_art/anim.py`) son la referencia visual y estos son los valores objetivo para el juego:

| Animación | Valor |
|---|---|
| Órbita del electrón de Wilas | 1 vuelta/s |
| Respiración en reposo | ±2,5 % de escala, 2 s por ciclo |
| Parpadeo | Cada 2–4 s, 100 ms |
| Anticipación del salto | 60 ms, escala (1,25 ; 0,78). En el juego se omite: retrasaría el salto, y la respuesta inmediata manda |
| Estiramiento al subir | (0,84 ; 1,22) → (1 ; 1) con *ease-out* |
| Aterrizaje | 80 ms, hasta (1,28 ; 0,75) |
| Pulso del salto cuántico | Anillo elíptico que se expande en 150 ms |
| Destello de daño | 100 ms; invulnerabilidad 1 s parpadeando a 15 Hz |
| *Hitstop* | 40–60 ms |
| Aviso de ataque enemigo | 300–500 ms |
| Electrón orbital | 1,5 s por vuelta |
| Caída del muón | Aviso 500 ms, caída 200 ms con *ease-in* |
| Kaón | Ciclo sólido/intangible de 2 s |
| Atracción de fotones | *Ease-in* hacia el jugador, ~200 ms |
| Colapso de bifurcación | 250 ms con *ease-out* |

### Implementación en Godot

| Qué | Cómo |
|---|---|
| Deformación, flotación, parpadeo, destellos | `Tween` (o `AnimationPlayer` para secuencias fijas) |
| Órbitas, rotaciones continuas | `_process` con ángulo acumulado o `AnimationPlayer` en bucle |
| Fondos orbitales, Decoherencia | `.gdshader` (CanvasItem) |
| Trazas, polvo, estelas | `GPUParticles2D` / `CPUParticles2D` + `Line2D` |
| Muelles de gluón, líneas de campo | `Line2D` recalculado en código |
| Brillo | Glow del `WorldEnvironment` en 2D (**verificado en la Fase 4** con *Compatibility*, sin shader de *bloom* propio): `rendering/viewport/hdr_2d = true`, `Environment` con fondo `Canvas`, glow aditivo y umbral HDR 1,0 (`world/environment/glow_environment.tres`). Solo brilla lo que se pinta por encima de 1: el brillo se elige por pieza multiplicando su color (`modulate`/`self_modulate` > 1 o colores HDR en los shaders), así que la UI y el arte normal no brillan |

## Interfaz

- **Fuentes:** Space Grotesk para títulos y UI, JetBrains Mono para números, semillas, contadores y etiquetas. Van incluidas en el proyecto (licencia OFL).
- **Paneles:** `VOID_2` con borde `GRID` y esquinas de 12–16 px.
- **HUD:** ver [11-interfaz](11-ui.md). La barra de coherencia usa `PLAYER`.
- **Tarjeta de partida:** la semilla en JetBrains Mono a gran tamaño con brillo, el build en iconos y la composición 16:9 limpia para capturas.

## Accesibilidad

- **La forma también comunica:** familias por forma de marco, rarezas por joya y antimateria por hueco. El color nunca es la única señal.
- **Daltonismo:** cian y magenta se distinguen en las formas más comunes de daltonismo, pero se validará la paleta completa con un simulador antes de la Fase 14. Se incluirá un modo daltónico que refuerce las formas.
- **Destellos:** opción "reducir destellos" que atenúa los destellos blancos de daño, impacto y aniquilación.
- **Movimiento:** la sacudida de cámara se puede ajustar (0–100 %).

## Generador programático: `art/`

### Qué es

Un proyecto Python independiente (gestionado con **uv**) que genera todo el arte a partir de una paleta y de funciones de dibujo. Se revisa renderizando a PNG y mirando el resultado, en ciclos de minutos.

- **Dependencias:** `numpy` (orbitales, ruido), `pillow` (imágenes, WebP animado) y `resvg-py` (render SVG → PNG).
- **Aislado de Godot:** `art/` y `docs/` contienen un `.gdignore` para que el editor no importe su contenido; `art/.gitignore` excluye `.venv/`.

### Comandos

```bash
cd art
uv sync                                  # instala dependencias
uv run build_art_direction.py            # regenera imágenes y animaciones de la propuesta (~2 min)
uv run build_art_direction.py --anim     # solo las animaciones
uv run build_game_assets.py              # exporta el arte del juego a assets/generated/ y la paleta a core/palette.gd
uv add <paquete>                         # añadir dependencias
```

### Estructura

| Fichero | Contenido |
|---|---|
| `atomic_art/palette.py` | Paleta: única fuente de verdad de los colores |
| `atomic_art/svg.py` | Primitivas SVG (`circle`, `path`, `g`, `wave`, `coil`…), filtros de brillo para previsualización y `save` (SVG + PNG) |
| `atomic_art/characters.py` | Wilas (parametrizado: expresión, escala, fase del electrón, destello) y personajes |
| `atomic_art/enemies.py` | Enemigos por capa (`ROSTER`) y jefes |
| `atomic_art/items.py` | Recogibles, contenedores y sistema de iconos (`icon(familia, glifo, rareza)`, `GLYPHS`) |
| `atomic_art/world.py` | Fondos orbitales (NumPy), Decoherencia, tiles, trazas de cámara de burbujas, proyectil |
| `atomic_art/mockups.py` | Composiciones: escena de juego, tarjeta de partida, hoja de modelo |
| `atomic_art/anim.py` | Escenas animadas `t → SVG` en bucle, curvas de *easing* y exportación a WebP |
| `build_art_direction.py` | Genera la propuesta en `docs/assets/art-direction/img/` |
| `build_game_assets.py` | Exporta el arte del juego a `assets/generated/` y la paleta a `core/palette.gd` |

### Convenciones

- Cada asset es una **función que devuelve un fragmento SVG centrado en (0, 0)**. La composición se hace con `g(..., x, y, scale, rotate)`.
- **Los colores salen siempre de `palette.py`.** Nunca se escribe un hexadecimal en un generador.
- Los degradados necesitan un **`uid` único** por documento (parámetro `uid`), porque los ids SVG son globales.
- Todo es **determinista**: lo aleatorio usa `numpy.random.default_rng(seed)` con semilla fija.
- Los filtros de brillo (`glow=`) son **solo para previsualizar**. Los SVG destinados a Godot se generan sin filtros (`doc(..., glow=False)`), y sin texto (en el juego se usan `Label` con las fuentes del tema).
- Una línea horizontal tiene alto 0 y su caja de filtro se recorta: se le añade un `rect` invisible que le dé alto.
- Las animaciones son funciones de `t ∈ [0, 1)` que hacen bucle; se construyen con `seg`, `ease_in/out/io`, `lerp` y `bump`.

### Añadir un asset nuevo

1. Escribir la función en el módulo que corresponda, respetando las reglas del lenguaje visual.
2. Renderizarla en una hoja de prueba (PNG) y **revisarla visualmente**, también junto a assets existentes para comprobar la coherencia.
3. Si es un asset del juego, añadirlo a `ASSETS` en `build_game_assets.py`, regenerar y comprobar en Godot (ver siguiente apartado).
4. Si introduce una regla o un color nuevos, actualizar primero `palette.py` y este documento.

### Exportación a Godot

`art/build_game_assets.py` (desde la Fase 4) exporta el arte del juego:

- A `assets/generated/` (sí importado por Godot) los SVG **sin filtros ni texto**, con nombres funcionales en inglés agrupados por carpeta (`player/player_core.svg`…). Hoy: las piezas de Wilas (`player_core`, `player_orbital`, `player_orbital_front`, `player_electron` y `player_eyes_<expresión>`), que comparten el centro del núcleo para colocarlas sin cálculos; el atlas de tiles de la Capa K (`tilesets/layer_k_tiles.svg`), el pico de potencial (`hazards/potential_spikes.svg`), los iconos de recompensa de bifurcación (`rewards/`), los enemigos de la Capa K (`enemies/`: `orbital_electron`, `decay_electron`, `free_neutron`, `alpha_particle` y las líneas de velocidad `alpha_speed_lines`, que se muestran al embestir) y el proyectil del jugador (`combat/player_projectile.svg`, con la cabeza a 16 px del centro del lienzo). Para reutilizar en el juego una función de previsualización que lleva brillo, `svg.without_glow()` le quita los filtros.
- Cada pieza animable se exporta **por partes** para animarlas por separado en Godot.
- Los SVG se importan con `svg/scale = 2` (en su `.import`) y se dibujan con escala 0,5: quedan nítidos aunque la ventana sea mayor que 1280×720. Para un SVG nuevo, el script escribe un `.import` mínimo con esa escala que Godot completa al importar.
- Un manifiesto (`assets/generated/manifest.json`) lista cada asset con su tamaño y su origen; `tests/generated_assets_test.gd` comprueba que coincide con los ficheros, que no hay filtros ni texto y que se importan al doble de tamaño. Al regenerar se borran los `.import` de los assets que ya no existen.
- `core/palette.gd`: la paleta como clase `Palette` de GDScript.
- La salida es regenerable, pero **se versiona en git**: así quien abra el proyecto en Godot no necesita Python. Los `.import` también se versionan (guardan la escala y el uid de cada asset).

Las texturas de ruido o atlas aún no hacen falta: la Decoherencia y los fondos son shaders.

## Limitaciones y riesgos

| Riesgo | Mitigación |
|---|---|
| Techo minimalista: no habrá ilustraciones ni retratos detallados | Asumido como identidad; la personalidad sale de la forma, la animación y el *game feel* |
| El brillo depende del motor y del renderer *Compatibility* | Verificado en la Fase 4: el glow del `WorldEnvironment` con HDR 2D funciona en *Compatibility* |
| El importador SVG de Godot (ThorVG) no soporta filtros y tiene soporte limitado de algunas funciones SVG | SVG de juego simples: formas, trazos y degradados radiales, sin filtros ni texto |
| Rendimiento con muchos elementos brillantes y partículas | Medido en la Fase 6 en la sala de combate: 40 enemigos y disparo continuo cuestan ~1,6 ms de CPU por fotograma. Perfilar el render en hardware modesto en la Fase 15 |
| Ruido (Decoherencia, fondos) pesado como imagen | En el juego son shaders, no texturas |
| Música fuera del alcance del generador | Librería o encargo externo ([ideas a futuro](99-future-ideas.md)) |
