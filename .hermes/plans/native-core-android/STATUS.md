# Estado de la ejecución del plan

Este documento es el estado real de la ejecución, medido contra los repositorios y no de memoria.
Se actualiza en esta misma rama. La unidad de "hecho" es: **mergeado en `main` de su repositorio y
verificado con el comando que se cita**.

- `fretboard-core` — `main` `8124e1f` · `cargo test --workspace --locked` **355 pasan, 0 fallan** · clippy y fmt limpios · `python3 -m unittest discover -s scripts/tests` 27 OK
- `fretboard-android` — `main` `f9eb2d0` (release `app-v0.8.3`) · `:app:testDebugUnitTest` **229 pasan, 0 fallan** · `check_boundaries.py` `boundaries hold` · `check_release.py` `release rules hold`

## Qué queda, en detalle

### Bloqueado en trabajo que no es código

**A21 — App Links.** El fichero que hay que publicar está escrito y su huella **verificada byte a
byte** contra el certificado del APK release, en `fretboard-android/docs/app-links.md`; se publica
en `https://cuwano.gramos.me/.well-known/assetlinks.json` (HTTPS, `application/json`, sin
redirección). Después hace falta, en un dispositivo con el APK release:

```bash
adb shell pm get-app-links dev.ironjanowar.fretboard
```

El dominio debe responder `verified`. Solo entonces se añade el filtro `ACTION_VIEW` (sin comodines
de host, como manda el plan) y se comprueba de extremo a extremo que un enlace real abre la
aplicación **con la sesión que el enlace describe**. Hasta entonces la asociación queda
explícitamente diferida —el plan lo permite— y abrir un enlace en el navegador lleva a la web, no a
la app.

### Bloqueado en hardware

**A23 (mitad instrumentada) y A24 (release nativo, accesibilidad, upgrade).** Los valores del motor
solo se pueden reproducir donde el motor se carga, y en este entorno **no hay dispositivo ni
emulador** (`/dev/kvm` ausente). Además, con una sola ABI publicada (`DEC-10`), un emulador x86_64
tampoco podría cargar la biblioteca nativa. Lo que sí está hecho:

- A23: los seis assets congelados con `provenance.json` (commit de origen, digest y número de casos)
  y el replay JVM del lado cliente sobre 140 casos (`session/FullSessionRegressionTest.kt`).
- A24: el soporte de build para apuntar las instrumentadas a la variante release
  (`-PtestBuildType=release`, verificado: aparece `connectedReleaseAndroidTest` y sin el parámetro
  sigue apareciendo `connectedDebugAndroidTest`).

Escribir los tres tests instrumentados sin poder ejecutarlos produciría artefactos que *compilan*
y no *verifican*; queda anotado como deuda visible, no como cobertura.

### Sin empezar

**A25 — reproducibilidad en checkout limpio y entrega final.** Es lo siguiente que se puede hacer
sin dispositivo: que un checkout limpio prepare el motor desde su release, construya y pase la
suite, con el procedimiento escrito.

**C22 (core) — cierre de propiedades/golden/seguridad.** Verificado ausente en el repositorio:
no existen `crates/domain/tests/properties.rs`, `golden_matrix.rs`, `scripts/verify-fixtures.py`,
`deny.toml`, `docs/licenses.md` ni el `docs/release-checklist.md` del core. Es el que cierra la
paridad del lado del motor (invariantes del estado validado a través de secuencias de acciones,
transposición, idempotencia del códec, round-trip de snapshot, matriz golden con cada caso congelado
consumido por su comparación).

### Decisiones abiertas

- **DEC-10 — ABIs.** Solo se publica `arm64-v8a`. Es lo que impide emulador x86_64 y lo que bloquea
  las instrumentadas fuera de un runner arm64.
- **DEC-06 — límites de recursos del motor.** Siguen abiertos; el límite de 4096 caracteres del
  cliente está documentado como guardia propia del cliente, no como decisión del motor.
- **Sin CI, por decisión del usuario.** Registrado en `fretboard-android/docs/open-questions.md`
  para que no se reconstruya desde la lista de ficheros de A22.

## Qué está hecho

Core: **C00-C21** completos, con las revisiones de API 1-8 y las releases `engine-v0.6.0`,
`engine-v0.7.0` y `engine-v0.8.0` (AAR re-descargado y verificado con `sha256sum -c` cada una).
Delivery: **D00-D02** completos.

Android: **A00-A20** completos, incluida A19 en sus tres partes (parser del intent, camino entrante,
pegado explícito) y A20 con el origen aprobado (`https://cuwano.gramos.me/`, verificado en vivo:
200 en la ruta de página, 200 en la query heredada, 200 con `%23`). Publicada la release
**`app-v0.8.3`** (versionCode 16) con su APK release firmado y `SHA256SUMS`.

**A22** completo salvo el workflow de CI, descartado por decisión: los dos comprobadores
(`check_boundaries.py`, `check_release.py`) con sus casos RED, el checklist de release y la
decisión registrada.

## Verificación que respalda lo anterior

| Qué | Comando | Resultado |
|---|---|---|
| Core, suite completa | `cargo test --workspace --locked --jobs 2` | 355 pasan, 0 fallan |
| Core, contrato | `python3 -m unittest discover -s scripts/tests` | 27 OK |
| Android, suite JVM | `./gradlew --offline :app:testDebugUnitTest` | 229 pasan, 0 fallan |
| Android, fronteras y release | `python3 scripts/check_boundaries.py` · `check_release.py [apk]` | `boundaries hold` · `release rules hold` |
| Release del motor | re-descarga + `sha256sum -c` | OK en cada release |
| Release del APK | re-descarga + `sha256sum -c` | OK |

## Límite transversal, dicho una vez

Todo lo instrumentado (21 tests en `app/src/androidTest`) **se ha compilado y nunca se ha
ejecutado**: no hay dispositivo ni emulador en el entorno de trabajo. Cualquier afirmación que
dependa de ellos es una afirmación sobre compilación, y así está escrito en
`fretboard-android/docs/release-checklist.md` y en `docs/parity-matrix.md`.

## Manchas de proceso que quedan registradas

- Una vez se mergeó con la suite en rojo (el run falló y se siguió adelante). Se corrigió en el PR
  siguiente y `main` volvió a verde, verificado.
- Los mensajes de commit del PR `p19/dismissible-notice` en `fretboard-android` salieron corruptos:
  el shell interpretó los backticks como sustitución de comandos. El contenido está bien y el PR
  describe el cambio; la historia de `main` no se ha reescrito.
- Un valor inventado (`source_commit` del lock del motor, escrito desde el hash corto en lugar de
  leerse del artefacto) llegó a un PR: lo cazó `scripts/prepare_core.py` y se corrigió leyéndolo del
  artefacto. La regla queda: un valor que se puede leer, se lee.
