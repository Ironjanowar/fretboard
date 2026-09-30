# Estado de la ejecución del plan, y todo lo necesario para retomarlo

Este documento es el estado real de la ejecución —medido contra los repositorios, no de memoria— y
el relevo: lo que queda, cómo se retoma cada pieza y qué se aprendió por el camino.

Unidad de "hecho": **mergeado en `main` de su repositorio y verificado con el comando que se cita**.

| Repositorio | `main` | Verificación |
|---|---|---|
| `Ironjanowar/fretboard-core` | `8124e1f` | `cargo test --workspace --locked` **355 pasan, 0 fallan**; clippy y fmt limpios; 27 tests de scripts |
| `Ironjanowar/fretboard-android` | `f9eb2d0` (release `app-v0.8.3`) | `:app:testDebugUnitTest` **229 pasan, 0 fallan**; `boundaries hold`; `release rules hold` (APK incluido) |

## 1. Qué está hecho

**Core: C00-C21 completos**, con las revisiones de contrato 1-8 y las releases `engine-v0.6.0`,
`engine-v0.7.0` y `engine-v0.8.0` — cada AAR re-descargado y verificado con `sha256sum -c`.
**Delivery: D00-D02 completos.**

**Android: A00-A20 completos.** A19 en tres partes (parser del intent, camino entrante, pegado
explícito) y A20 con el origen aprobado por el usuario, `https://cuwano.gramos.me/`, verificado en
vivo desde la máquina de trabajo: 200 en la ruta de página, 200 en la query heredada y 200 con
`?chords=C%23maj`.

**A22 completo** salvo el workflow de CI, descartado por decisión del usuario y registrado en
`fretboard-android/docs/open-questions.md` para que nadie lo reconstruya desde la lista de ficheros
de la tarea: los dos comprobadores con sus casos RED, el checklist de release y la decisión.

## 2. Qué queda, con lo necesario para retomarlo

### A21 — App Links (no es código)

**Estado:** el fichero está escrito y su huella **verificada byte a byte** contra el certificado del
APK release: `fretboard-android/docs/app-links.md`.

**Lo que falta, en orden:**

1. Publicar exactamente el JSON de ese documento en
   `https://cuwano.gramos.me/.well-known/assetlinks.json`, servido como `application/json`, por
   HTTPS, sin redirección.
2. En un dispositivo con el **APK release** instalado:
   `adb shell pm get-app-links dev.ironjanowar.fretboard` → el dominio debe responder `verified`.
3. Solo entonces, añadir el filtro `ACTION_VIEW` a `fretboard-android/app/src/main/AndroidManifest.xml`
   para `https` en ese host, **sin comodines** (el plan los prohíbe: un comodín es exactamente la
   afirmación que no se puede verificar).
4. Comprobar de extremo a extremo que un enlace real abre la aplicación **con la sesión que el
   enlace describe**, y reportar el `pm get-app-links` real, no la presencia del filtro.

**Cuidado:** la huella del certificado de *debug* no debe entrar en el fichero (el plan: reinstallation
with another signer must never be the test shortcut). Si algún día se rota la clave de firma, el
fichero hay que republicarlo.

### A23 — mitad instrumentada (necesita hardware)

**Estado:** hechos los seis assets congelados con `provenance.json` (commit de origen, digest y
número de casos de cada uno) y el replay JVM del lado cliente sobre 140 casos
(`app/src/test/.../session/FullSessionRegressionTest.kt`).

**Lo que falta:** el test instrumentado que reproduce los **valores del motor** —que es donde el
motor se carga— y el `release/OfflineParityTest.kt`. La lista de familias del corpus aún sin mapear
está medida en `fretboard-android/docs/parity-matrix.md`.

**Por qué no se hizo:** no hay dispositivo ni emulador (`/dev/kvm` ausente) y, con una sola ABI
publicada (`DEC-10`), un emulador x86_64 tampoco cargaría la biblioteca nativa. Escribirlo sin poder
ejecutarlo produciría algo que compila y no verifica.

### A24 — release nativo, accesibilidad y upgrade (necesita hardware)

**Estado:** hecho el soporte de build para apuntar las instrumentadas a la variante release
(`-PtestBuildType=release`), verificado sin dispositivo: con el parámetro aparece
`connectedReleaseAndroidTest` y sin él sigue apareciendo `connectedDebugAndroidTest`.

**Lo que falta:** los tres tests instrumentados —`release/AccessibilityAuditTest.kt`,
`release/UpgradeSmokeTest.kt`, `release/ReleaseNativeLoadingTest.kt`— y su ejecución contra el
release firmado y minificado. Ojo: el *shrink* sigue desactivado (`isMinifyEnabled = false`) y el
comprobador `check_release.py` **solo permite encenderlo cuando exista**
`ReleaseNativeLoadingTest.kt`, que es la regla que impide activarlo sin haberlo probado.

### A25 — reproducibilidad en checkout limpio y entrega final (sin empezar)

**Lo que significa:** que un checkout limpio prepare el motor desde su release, construya y pase la
suite, con el procedimiento escrito. Los pasos que hay que convertir en comprobación están hoy
repartidos entre `fretboard-android/scripts/prepare_core.py`, `docs/release-checklist.md` y las
recetas de la sección 3 de este documento. No depende de dispositivo ni del usuario.

### C22 (core) — cierre de propiedades/golden/seguridad (sin empezar)

**Verificado ausente** en `fretboard-core`: no existen `crates/domain/tests/properties.rs`,
`golden_matrix.rs`, `scripts/verify-fixtures.py`, `deny.toml`, `docs/licenses.md` ni el
`docs/release-checklist.md` del core.

**Lo que pide la tarea:** invariantes del estado validado a través de secuencias de acciones,
invariancia por transposición y por permutación de alturas, idempotencia canónica del códec,
round-trip de snapshot, ausencia de pánico ante entradas malformadas y límites sin actualización
parcial; una matriz golden en la que **cada caso congelado sea consumido por su comparación**, con
excepciones de superficie no soportada explícitas y desviaciones aprobadas citadas una a una; y un
comprobador de fixtures que valide hash, procedencia, recuentos e identificadores.

### Decisiones abiertas

- **DEC-10 — ABIs.** Solo se publica `arm64-v8a`; es lo que impide el emulador x86_64 y lo que
  bloquea las instrumentadas fuera de un runner arm64.
- **DEC-06 — límites de recursos del motor.** Abiertos; el límite de 4096 caracteres del cliente es
  una guardia del cliente y está documentado como tal, no como decisión del motor.
- **Sin CI, por decisión del usuario** (registrado).

## 3. Entorno de trabajo y recetas

```bash
export JAVA_HOME="$(/usr/local/bin/mise where java)"
export ANDROID_HOME=/workspace/tools/android-sdk
export KOTLIN_HOME=/workspace/tools/kotlin/kotlinc
export JNA_JAR=/workspace/tools/maven/jna-5.17.0.jar      # lo exige build_aar.sh del core
export PATH="$HOME/.cargo/bin:$PATH"
```

- Repositorios: `/workspace/repos/fretboard-core`, `/workspace/repos/fretboard-android`,
  y este plan en `/workspace/repos/fretboard/.hermes/plans/native-core-android/`.
- Material de firma: `~/.fretboard-signing/keystore.properties`. **Nunca se imprime ni se comitea.**
- Android que consume el motor: `core-release.lock.json` +
  `python3 scripts/prepare_core.py --from <aar>` y `--offline`; sin el AAR instalado, la suite cae.
- Release del motor: `bash scripts/build_aar.sh` (escribe `dist/` y `dist/SHA256SUMS`), tag manual en
  el commit de `main`, y `gh release create` con AAR + `artifact-manifest.json` + `SHA256SUMS`.
- Release del cliente: `./gradlew --offline :app:assembleRelease`, copia a `artifacts/`, `SHA256SUMS`
  y `gh release create` con el APK release y el `SHA256SUMS`.
- Comprobadores a ejecutar antes de cualquier release:
  `python3 scripts/check_boundaries.py` y `python3 scripts/check_release.py [apk]` desde
  `fretboard-android`.

## 4. Trampas aprendidas (esto ahorra tiempo la próxima vez)

- `gh release create --target <sha>` devuelve **HTTP 422**. Hay que crear y empujar el tag a mano en
  el commit y luego crear la release sin `--target`.
- `SHA256SUMS` debe generarse **desde dentro de `dist/`/`artifacts/`** (rutas sin prefijo), o
  `sha256sum -c` falla a quien lo descarga.
- `git commit --amend --only <ruta>` **no** es un amend parcial: commitea esa ruta encima y deja un
  asunto duplicado. Usar `--amend` a secas.
- Los **backticks dentro de mensajes de commit pasados por el shell** se interpretan como sustitución
  de comandos y corrompen el mensaje: escribir el mensaje a un fichero y usar `git commit -F`.
- No mergear nunca con la suite en rojo aunque el script siga adelante: encadenar la comprobación con
  la condición de éxito, no solo con el echo.
- El terminal SSH destroza algunos comandos que empiezan por `cd <ruta>;` o contienen ciertos
  caracteres: usar el parámetro `workdir` y evitar backticks/comillas anidadas.
- El token de GitHub en uso **no tiene el ámbito `workflow`**, así que no se puede empujar nada bajo
  `.github/workflows/`. Da igual mientras no haya CI (decisión registrada), pero explica por qué el
  fichero de workflow quedó fuera.
- `apksigner` y `aapt2` necesitan `JAVA_HOME` exportado y las build-tools en el `PATH`
  (`/workspace/tools/android-sdk/build-tools/36.0.0`); si no, `check_release.py` no puede inspeccionar
  el APK y lo dice en vez de fingir que lo hizo.
- `readelf --dyn-syms` trunca los nombres: usar `-W` para ver los símbolos UniFFI completos.

## 5. Límite transversal, dicho una vez

Todo lo instrumentado (21 tests en `app/src/androidTest`) **se ha compilado y nunca se ha ejecutado**:
no hay dispositivo ni emulador. Cualquier afirmación que dependa de ellos es una afirmación sobre
compilación, y así está escrito en `fretboard-android/docs/release-checklist.md` y en
`docs/parity-matrix.md`.

## 6. Manchas de proceso, registradas y no escondidas

- Una vez se mergeó **con la suite en rojo** (el run falló y el script siguió). Se corrigió en el PR
  siguiente y `main` volvió a verde, verificado con la suite completa.
- Los mensajes de commit del PR `p19/dismissible-notice` de `fretboard-android` salieron **corruptos**
  por los backticks. El contenido está bien y el PR describe el cambio; `main` no se ha reescrito.
- Un **valor inventado** (el `source_commit` del lock del motor, escrito desde el hash corto en lugar
  de leerse del artefacto) llegó a un PR: lo cazó `scripts/prepare_core.py` y se corrigió leyéndolo
  del artefacto. La regla queda: **un valor que se puede leer, se lee**.
- Dos afirmaciones mías resultaron **falsas** y quedaron corregidas en el sitio: que el core no tenía
  codificador (existía, en `page_params.rs`), y una cifra de RED mal contada (9 de 12, no 11).
