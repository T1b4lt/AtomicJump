# Coding Agent Guidelines

Guía para agentes de código que trabajan en **AtomicJump**, un roguelike de plataformas vertical hecho con **Godot 4.7** (GDScript, renderer _Compatibility_).

- Mantén actualizada la documentación en docs/\*\*\* y README.md con todas las decisiones que se vayan tomando. Asegurate de comprobarlo al terminar cada tarea para que reflejen fielmente el estado actual del proyecto.
- Usa las mejores prácticas de codificación y sigue las convenciones establecidas por el desarrollo tipico en Godot.
- Sigue las mejores practicas en desarrollo y diseño de videojuegos.

## Documentación

- Diseño y arquitectura: [`docs/`](docs/) (índice en el [README](README.md#documentación-de-diseño)). La referencia técnica es [`docs/12-architecture.md`](docs/12-architecture.md) y la de arte [`docs/13-art-style.md`](docs/13-art-style.md).
- Plan de trabajo: [`ROADMAP.md`](ROADMAP.md). Marca con `[x]` las tareas completadas.
- Si cambia una decisión de diseño, actualiza primero el documento de `docs/` y después el código.

## Entorno

El desarrollo se hace desde **WSL**, pero el editor de Godot que usa el autor está instalado en **Windows** (`C:\Program Files\Godot_v4.7.2-stable\`) y abre el proyecto desde ahí.

Para ejecutar Godot desde WSL (tests, importar, exportar), los comandos usan `GODOT_BIN`. Si no hay un Godot de Linux instalado, **descarga uno temporal** en el directorio temporal de la sesión y bórralo al terminar:

```sh
TMP_GODOT=$(mktemp -d)
curl -sSL -o "$TMP_GODOT/godot.zip" https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -q "$TMP_GODOT/godot.zip" -d "$TMP_GODOT"
export GODOT_BIN="$TMP_GODOT/Godot_v4.7.2-stable_linux.x86_64"
# ... usar Godot ...
rm -rf "$TMP_GODOT"
```

- La versión debe coincidir con la del editor de Windows (4.7.2) para no alterar los ficheros del proyecto.
- Ejecutar Godot crea datos de usuario en `~/.local/share/godot/app_userdata/AtomicJump/`; puedes borrarlos al terminar.
- Exportar necesita las plantillas de exportación de la 4.7.2 en `~/.local/share/godot/export_templates/4.7.2.stable/`. **Ya están instaladas en WSL** (solo las x86_64 de Windows y Linux, unos 350 MB) y se conservan entre sesiones: cualquier Godot 4.7.2, aunque sea temporal, las encuentra ahí. No las borres. Si faltan, extrae esos ficheros del `.tpz` oficial (1,3 GB) y borra el `.tpz` después. Para tests, lint o importar no hacen falta.

## Comandos

| Tarea | Comando |
| --- | --- |
| Instalar herramientas de lint | `pip install -r requirements-dev.txt` (o `uv tool install gdtoolkit==4.5.0`) |
| Ejecutar el juego | `$GODOT_BIN --path .` |
| Abrir el editor | `$GODOT_BIN --path . --editor` |
| Importar el proyecto (sin ventana) | `$GODOT_BIN --headless --import` |
| Formatear | `gdformat .` |
| Comprobar formato | `gdformat --check .` |
| Lint | `gdlint .` |
| Tests (gdUnit4, _headless_) | `addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://tests` |
| Regenerar las semillas doradas | `UPDATE_GOLDEN_SEEDS=1 addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://tests/generation_test.gd` |
| Exportar Linux | `$GODOT_BIN --headless --export-release "Linux" export/linux/AtomicJump.x86_64` |
| Exportar Windows | `$GODOT_BIN --headless --export-release "Windows Desktop" export/windows/AtomicJump.exe` |

- `runtest.sh` lee `GODOT_BIN` (o `--godot_binary <ruta>`). Desde Windows existe `addons\gdUnit4\runtest.cmd`, y los tests también se lanzan desde el panel de gdUnit4 del editor.
- Los informes de los tests se generan en `reports/` (ignorado por git). Las builds van a `export/` (ignorado por git).
- La CI (`.github/workflows/ci.yml`) ejecuta `gdformat --check`, `gdlint` y los tests en cada PR y en cada push a `main`.

## Convenciones

- **Tipado estático en todo** (variables, parámetros y retornos). Los avisos `untyped_declaration`, `unsafe_*` y `unused_*` están configurados como **error** en `project.godot`: un script con avisos no compila.
- Formato con `gdformat` (tabs, líneas de 100 caracteres) y lint con `gdlint` (configuración en `gdformatrc` y `gdlintrc`). `.editorconfig` fija tabs en `.gd`, LF y UTF-8.
- Nombres funcionales en inglés en el código; `snake_case` en ficheros, variables y funciones, `PascalCase` en `class_name`, `CONSTANT_CASE` en `const`. Evita `class_name` que choquen con tipos globales de Godot (por eso la llave es `KeyPickup` y no `Key`).
- Orden dentro de un script (lo comprueba `gdlint`): `class_name`, `extends`, señales, enums, constantes, `@export`, variables, `@onready`, funciones.
- "Llamar hacia abajo, señales hacia arriba"; nombres únicos (`%Nodo`) en la UI; `preload()` para escenas que se instancian; nada de números mágicos.
- Autoloads (`core/autoload/`): `Events`, `Settings`, `RunManager` y `SceneRouter`. El estado de la partida vive en un `RunState` nuevo por partida (`RunManager.run`); se cambia de pantalla con `SceneRouter.go_to(...)`, nunca con `change_scene_to_file`.
- Textos visibles: claves de `localization/translations.csv` (columnas `es` y `en`), nunca texto literal. Capas de física con `PhysicsLayers`.
- Tests con **gdUnit4** en `tests/`, ficheros `*_test.gd` que extienden `GdUnitTestSuite`.
- Aleatoriedad del mundo **solo** con `RunManager.run.world_rng` (tiradas direccionadas, ver [`docs/08-seeds.md`](docs/08-seeds.md)): nunca `randi()`, `randf()`, `seed()` ni `Array.shuffle()` globales para generar. Si un cambio altera lo que genera una semilla, sube `WorldRng.GENERATION_VERSION` y regenera las semillas doradas.
- Commits con _Conventional Commits_ (release-please genera versión y CHANGELOG; configuración en `release-please-config.json` y `.release-please-manifest.json`, no edites la versión a mano). Trabaja en ramas con PR a `main`.
- No edites `addons/gdUnit4/` (dependencia de terceros, v6.2.1) ni `.godot/`.
- El arte se genera con el generador de `art/` (Python, `uv`); ver [`art/README.md`](art/README.md).
