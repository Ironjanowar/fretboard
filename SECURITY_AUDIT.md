# Auditoría de Seguridad — Fretboard (Phoenix LiveView)

**Proyecto:** Fretboard — Visualizador de acordes/escalas de guitarra (Phoenix LiveView + SVG)
**Repo:** `/workspace/repos/fretboard` · commit analizado: `751f903`
**Fecha:** 2026-08-02
**Alcance:** secrets, CSRF, LiveView, validación de entrada, cabeceras HTTP, sesión, Docker, dependencias, info-disclosure, SSL/TLS.
**Contexto:** App stateless, sin Ecto, sin DB, sin autenticación de usuarios. Desplegada vía Docker.

---

## Resumen ejecutivo

Fretboard es una aplicación de **baja criticidad** (sin datos sensibles, sin autenticación, sin persistencia). No se encontraron vulnerabilidades **Críticas** ni **Altas** que permitan compromiso del host o robo de datos. Los hallazgos principales son de severidad **Media/Baja** y se concentran en:

1. `check_origin: false` en producción (debilita la protección del WebSocket de LiveView).
2. Ausencia de TLS/HSTS y cookie de sesión sin flag `secure` en el despliegue por defecto.
3. Secretos de desarrollo/test commiteados en el repo (práctica habitual de Phoenix, pero conviene revisar).

**Puntuación global: 7 / 10** — Adecuado para una app pública stateless; mejorar los puntos 1–3 antes de cualquier despliegue con datos sensibles o autenticación.

---

## Hallazgos por categoría

### 1. Gestión de secretos

#### 1.1 — `secret_key_base` de desarrollo y test commiteados en el repo
- **Severidad:** Low
- **OWASP:** A05:2021 — Security Misconfiguration
- **Refs:** `config/dev.exs:17`, `config/test.exs:7`
- **Detalle:** Se commitearon valores reales de `secret_key_base` para dev (`xNASJPAArkXsZEx9...`) y test (`q+nVwtCK+DUWvXqb...`). El historial de git confirma que `dev.exs` se añadió en el commit inicial `3b3b01d` y nunca se rotó. Es la práctica por defecto de `mix phx.gen` y **no afecta a producción** (que exige `SECRET_KEY_BASE` por env, `runtime.exs:33-37`), pero:
  - Si alguien ejecuta `MIX_ENV=dev` con esa clave en un entorno semi-público, las cookies de sesión firmadas con esa clave podrían ser falsificadas.
  - `dev.exs:13` bindea a `{0,0,0,0}` (todas las interfaces), aumentando la exposición.
- **Recomendación:**
  - Generar las claves dev/test con `mix phx.gen.secret` y, si se desea mayor higiene, cargarlas desde env en dev/test también, o documentar explícitamente que son de un solo uso local.
  - Rotar las claves actuales (ya están en el historial público).
  - Considerar `git filter-repo` / BFG si el repo es público y se quiere limpiar el historial.

#### 1.2 — `signing_salt` de LiveView y de sesión commiteados
- **Severidad:** Info
- **Refs:** `config/config.exs:22` (`live_view: [signing_salt: "IPM4wKvG"]`), `lib/fretboard_web/endpoint.ex:10` (`signing_salt: "OEqBErZ+"`)
- **Detalle:** Los *signing salts* no son secretos por sí mismos en Phoenix — su propósito es diferenciar dominios de firma; la seguridad real proviene del `secret_key_base`. Phoenix los commitea por defecto. **No es un problema** siempre que el `secret_key_base` de producción no se filtre.
- **Recomendación:** Mantener. Asegurar que `SECRET_KEY_BASE` de prod nunca se commitea (hoy se gestiona bien vía `runtime.exs` + `System.get_env/1`).

#### 1.3 — `.env.example` con placeholder débil
- **Severidad:** Low
- **OWASP:** A07:2021 — Identification and Authentication Failures
- **Refs:** `.env.example:1` (`SECRET_KEY_BASE=change_me_run_mix_phx_gen_secret`)
- **Detalle:** El placeholder es legítimo como ejemplo, pero un operador que copie `.env.example` a `.env` y lo use tal cual en producción tendría un `SECRET_KEY_BASE` predecible y débil → falsificación de cookies/firma.
- **Recomendación:** Añadir una validación en `runtime.exs` que rechace valores débiles:
  ```elixir
  if byte_size(secret_key_base) < 64 do
    raise "SECRET_KEY_BASE demasiado corta (mín 64 bytes). Ejecuta: mix phx.gen.secret"
  end
  ```
  Y/o rechazar el valor literal del placeholder.

---

### 2. Protección CSRF

#### 2.1 — `protect_from_forgery` habilitado correctamente
- **Severidad:** Good
- **Refs:** `lib/fretboard_web/router.ex:9`
- **Detalle:** El pipeline `:browser` incluye `plug :protect_from_forgery`, lo que inyecta y valida el token CSRF en formularios POST/PUT/DELETE. Las operaciones que cambian estado se canalizan vía eventos LiveView (`phx-click`), que viajan por el WebSocket autenticado por el token de LiveView — no requieren CSRF adicional, pero el endpoint HTTP está protegido.
- **Recomendación:** Ninguna. Correcto.

---

### 3. Seguridad LiveView

#### 3.1 — Sin autenticación del socket LiveView
- **Severidad:** Info
- **Refs:** `lib/fretboard_web/router.ex:17-21`, `lib/fretboard_web/endpoint.ex:14-16`
- **Detalle:** El LiveView en `live "/"` es público y el socket `/live` no requiere auth. Es **por diseño** (app stateless de visualización). No hay datos sensibles que proteger.
- **Recomendación:** Documentar que esta es una decisión consciente. Si en el futuro se añaden preferencias de usuario o state persistente, introducir `on_mount` de autenticación antes de cualquier callback que muta estado.

#### 3.2 — Eventos LiveView sin validación de entrada numérica
- **Severidad:** Low
- **OWASP:** A03:2021 — Injection (validación de entrada)
- **Refs:** `lib/fretboard_web/live/fretboard_live.ex:132` (`String.to_integer(index_str)` en `remove_chord`), `:190` (`String.to_integer(string_str)` en `change_string`), `:283` (`String.to_integer(index_str)` en `highlight_chord`)
- **Detalle:** El payload de un evento `phx-click`/`phx-change` es **controlable por el cliente**. Si un cliente malicioso envía `phx-value-index="abc"`, `String.to_integer/1` lanza `ArgumentError` y **mata el proceso LiveView** del atacante (DoS local a su propia sesión — no del servidor). `List.replace_at/3` con índices fuera de rango no corrompe la lista. `String.to_existing_atom/1` (`:112`, `:232`, `:267`, `:302`) es **seguro** contra agotamiento de tabla de átomos (lanza en lugar de crear).
- **Impacto real:** Bajo. La validación final de estado ocurre en `URLCodec.decode_params/1` (`lib/fretboard/music/url_codec.ex:198-204`) que rechaza notas/acordes no válidos, por lo que no hay inyección de estado persistente.
- **Recomendación:** Envolver las conversiones con `with` defensivo para evitar crashes:
  ```elixir
  def handle_event("remove_chord", %{"index" => index_str}, socket) do
    case Integer.parse(index_str) do
      {index, ""} when index >= 0 and index < length(socket.assigns.active_chords) ->
        # ...
      _ -> {:noreply, socket}
    end
  end
  ```
  Lo mismo para `change_string` (validar `string_idx` en `[0, string_count)` y `note` ∈ `@chromatic_notes`).

#### 3.3 — Manipulación de estado LiveView vía eventos
- **Severidad:** Info
- **Detalle:** Los eventos solo mutan el *socket assign* y luego disparan `push_patch` con parámetros URL. El estado autoritativo se reconstruye **siempre** desde los params en `handle_params` (`:87-103`) → `Music.decode_params/1` → `URLCodec.decode_params/1`, que valida notas/acordes/instrumento contra listas cerradas (`@valid_notes`, `@labels_to_quality`, `@string_to_instrument`). No hay path donde un evento inyecte estado no validado que sobreviva a un reconnect/reload.
- **Recomendación:** Ninguna. Arquitectura sana (estado derivado, no mutado directamente).

---

### 4. Validación y sanitización de entrada

#### 4.1 — Validación robusta de params URL
- **Severidad:** Good
- **Refs:** `lib/fretboard/music/url_codec.ex:153-204`
- **Detalle:** `decode_chords/1` ignora silenciosamente acordes irreconocibles (`parse_chord/1` devuelve `[]`); `decode_tuning/3` valida que el número de notas coincida con el instrumento **y** que cada nota esté en `@valid_notes`, devolviendo la afinación estándar si no; `decode_instrument/1` usa `Map.get/3` con default `:guitar`. Sin inyección posible.

#### 4.2 — Sin riesgo XSS vía HEEx
- **Severidad:** Good
- **Refs:** `lib/fretboard_web/live/fretboard_live.ex` (render, `:316-820`)
- **Detalle:** Toda salida dinámica usa la sintaxis `{...}` de HEEx, que **escapa automáticamente** HTML y atributos. No se usa `raw/1`, `innerHTML`, ni `Phoenix.HTML.raw`. Los valores de `style={"background-color: #{...}"}` provienen de `@chord_colors` (lista cerrada de hex). Las notas de afinación, aunque provienen de entrada, se renderizan escapadas. El SVG usa atributos `{...}` que HEEx escapa.
- **Recomendación:** Ninguna. Mantener la disciplina de no introducir `raw/1`.

#### 4.3 — `String.to_existing_atom/1` en entrada de usuario
- **Severidad:** Good
- **Refs:** `fretboard_live.ex:112,232,267,302`
- **Detalle:** Uso correcto de `to_existing_atom` (no `to_atom`) — no permite agotamiento de la tabla de átomos. Átomos desconocidos → `ArgumentError` → crash controlado del LV.
- **Recomendación:** Validar contra listas cerradas antes de convertir (ver 3.2) para mejor UX y evitar crashes.

---

### 5. Cabeceras HTTP

#### 5.1 — Cabeceras seguras por defecto presentes
- **Severidad:** Good
- **Refs:** `lib/fretboard_web/router.ex:10` (`plug :put_secure_browser_headers`)
- **Detalle:** `put_secure_browser_headers` inyecta por defecto: `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, y un **Content-Security-Policy** conservador (`default-src 'self'`).
- **Recomendación:** Verificar que la CSP por defecto no rompe el renderizado (el SVG usa `style=` inline extensivamente — `:514,532,549,...`). Si la CSP bloquea estilos inline, la UI se verá mal; en ese caso añadir `'unsafe-inline'` **solo para `style-src`**:
  ```elixir
  plug :put_secure_browser_headers, %{
    "content-security-policy" =>
      "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; ..."
  }
  ```
  Preferible: mover estilos inline a clases CSS.

#### 5.2 — Ausencia de HSTS
- **Severidad:** Medium
- **OWASP:** A05:2021 — Security Misconfiguration / Criptografía (SSL/TLS)
- **Refs:** `config/prod.exs:10-19` (force_ssl comentado), `config/runtime.exs:85-91` (comentado)
- **Detalle:** `force_ssl` con `hsts: true` está **comentado** en ambos ficheros. En el despliegue por defecto (sin reverse proxy con TLS) la app sirve HTTP plano → sin HSTS → susceptible a downgrade/MITM.
- **Recomendación:** Detrás de un reverse proxy que termine TLS, descomentar en `config/prod.exs`:
  ```elixir
  config :fretboard, FretboardWeb.Endpoint,
    force_ssl: [rewrite_on: [:x_forwarded_proto], hsts: true]
  ```
  Si no hay reverse proxy, configurar `https:` directamente en `runtime.exs`.

---

### 6. Configuración de sesión

#### 6.1 — Cookie de sesión sin flag `secure`
- **Severidad:** Medium
- **OWASP:** A05:2021 — Security Misconfiguration
- **Refs:** `lib/fretboard_web/endpoint.ex:7-12`
- **Detalle:** La config de sesión es:
  ```elixir
  @session_options [
    store: :cookie,
    key: "_fretboard_key",
    signing_salt: "OEqBErZ+",
    same_site: "Lax"
  ]
  ```
  Falta `secure: true`. Sin TLS y sin `secure`, la cookie viaja en claro. Aunque la sesión no contiene datos sensibles (app stateless), `secure: true` es defensa-en-profundidad.
- **Recomendación:**
  ```elixir
  @session_options [
    store: :cookie,
    key: "_fretboard_key",
    signing_salt: "OEqBErZ+",
    same_site: "Lax",
    secure: true   # requerir HTTPS
  ]
  ```
  (Solo si la app se sirve siempre por HTTPS. Si se sirve HTTP plano por ahora, priorizar primero habilitar TLS — ver 5.2 — y entonces activar `secure`.)

#### 6.2 — `http_only` no explícito
- **Severidad:** Good
- **Refs:** `endpoint.ex:7-12`
- **Detalle:** Phoenix/Plug.Session pone `http_only: true` por defecto para el store `:cookie`. Correcto implícitamente.
- **Recomendación:** Añadirlo explícitamente por claridad: `http_only: true`.

#### 6.3 — Sesión firmada pero no cifrada
- **Severidad:** Info
- **Refs:** `endpoint.ex:4-6` (comentario)
- **Detalle:** La sesión está firmada (no cifrada) → el contenido es legible por el cliente. No hay datos sensibles, así que es aceptable.
- **Recomendación:** Ninguna. Si se añaden datos sensibles en sesión, añadir `encryption_salt`.

---

### 7. Seguridad de despliegue en producción

#### 7.1 — `check_origin: false` en producción
- **Severidad:** Medium
- **OWASP:** A05:2021 — Security Misconfiguration / A08:2021 — Software and Data Integrity Failures (CSWSH)
- **Refs:** `config/runtime.exs:58`
- **Detalle:** En el bloque `if config_env() == :prod do`, `check_origin: false` desactiva la verificación del header `Origin` en las conexiones WebSocket de LiveView. Esto permite **Cross-Site WebSocket Hijacking (CSWSH)**: un sitio malicioso puede abrir un WebSocket LiveView al servidor víctima desde el navegador del usuario y enviar eventos como si fueran legítimos. Dado que no hay auth ni datos sensibles, el impacto es bajo hoy, pero:
  - Es un control de seguridad estándar para LiveView en prod.
  - Si se añade auth en el futuro, CSWSH escalará a secuestro de sesión.
- **Recomendación:** Configurar origins explícitos en `runtime.exs`:
  ```elixir
  check_origin: [
    "//#{host}",
    "https://#{host}"
  ]
  # o, si hay múltiples hosts conocidos, leerlos de env:
  check_origin: System.get_env("ALLOWED_ORIGINS", "") |> String.split(",", trim: true)
  ```
  Mantener `false` **solo** si el despliegue es estrictamente local/red interna y se documenta.

#### 7.2 — Endpoint bindea a `0.0.0.0` (todas las interfaces) en prod
- **Severidad:** Low
- **Refs:** `config/runtime.exs:48-56`
- **Detalle:** Por defecto bindea en `{0,0,0,0}` (o `::` si `FRETBOARD_IP=::`). Adecuado para un contenedor detrás de un reverse proxy, pero conviene confirmar que el puerto 4000 no quede expuesto directamente a Internet sin TLS.
- **Recomendación:** Documentar la topología esperada (reverse proxy → contenedor). En despliegues bare-metal, bindear a `127.0.0.1` y exponer solo vía el proxy.

#### 7.3 — `SECRET_KEY_BASE` manejado de forma segura
- **Severidad:** Good
- **Refs:** `config/runtime.exs:32-37`, `docker-compose.yml:7`
- **Detalle:** En prod, `SECRET_KEY_BASE` se exige desde env y el proceso `raise` si falta — correcto. `docker-compose.yml` lo pasa desde `${SECRET_KEY_BASE}`. `.gitignore` excluye `.env` (línea 39).
- **Recomendación:** Verificar en el pipeline de CI que `SECRET_KEY_BASE` se inyecta desde un gestor de secretos (Vault, GitHub Secret, etc.), no de un `.env` commiteado.

#### 7.4 — Dockerfile ejecuta como no-root
- **Severidad:** Good
- **Refs:** `Dockerfile:81` (`chown nobody /app`), `:87` (`--chown=nobody:root`), `:89` (`USER nobody`)
- **Detalle:** La imagen final corre como `nobody` — correcto. Build multi-stage, imágenes versionadas fijas (no `:latest`).
- **Recomendación:** Considerar añadir `tini` como init (líneas 91-97 lo documentan) para reap zombie processes en contenedor. Añadir un `HEALTHCHECK` en `Dockerfile` o `docker-compose.yml`.

#### 7.5 — Sin init process (tini) en el contenedor
- **Severidad:** Low
- **Refs:** `Dockerfile:91-97` (comentado)
- **Detalle:** Sin PID 1 adecuado, el contenedor puede acumular procesos zombie.
- **Recomendación:** Seguir la guía comentada: instalar `tini` y `ENTRYPOINT ["/tini","--"]`.

---

### 8. Seguridad de dependencias

#### 8.1 — Dependencias versionadas y aparentemente actuales
- **Severidad:** Good (con reserva)
- **Refs:** `mix.lock`

| Paquete | Versión (mix.lock) | Nota |
|---|---|---|
| phoenix | 1.8.9 | Actual |
| phoenix_live_view | 1.1.32 | Actual |
| phoenix_html | 4.3.0 | Actual |
| plug | 1.20.3 | Actual |
| plug_crypto | 2.2.0 | Actual |
| bandit | 1.12.4 | Actual (corrige issues de request smuggling de versiones < 1.6) |
| jason | 1.4.5 | Actual |
| hpax | 1.0.4 | — |
| thousand_island | 1.5.0 | — |
| websock / websock_adapter | 0.5.3 / 0.6.0 | — |
| phoenix_live_dashboard | 0.8.7 | Solo dev/test (gated por `dev_routes`) |
| lazy_html | 0.1.12 | Solo :test |

- **Detalle:** No se identificaron CVEs conocidos que afecten a las versiones pinadas. `bandit 1.12.4` está muy por encima de los rangos afectados por issues de smuggling anteriores.
- **Reserva:** No se pudo ejecutar `mix hex.audit` (sin red ni toolchain mix en este entorno). Se recomienda correrlo en CI:
  ```bash
  mix hex.audit          # advisories conocidos
  mix deps.audit         # (si está disponible)
  ```
- **Recomendación:** Añadir `mix hex.audit` al alias `precommit` en `mix.exs:74-80`.

---

### 9. Divulgación de información

#### 9.1 — `debug_errors: true` en dev
- **Severidad:** Info (dev-only)
- **Refs:** `config/dev.exs:16`
- **Detalle:** En dev, Phoenix muestra stacktraces detalladas en el navegador. Adecuado para desarrollo. **No** llega a producción (`prod.exs` no lo activa y el release usa `config/runtime.exs`).
- **Recomendación:** Confirmar que el release de prod no compila con `dev.exs` (el Dockerfile usa `MIX_ENV=prod`, `Dockerfile:33` — correcto).

#### 9.2 — LiveDashboard deshabilitado en producción
- **Severidad:** Good
- **Refs:** `lib/fretboard_web/router.ex:29` (`if Application.compile_env(:fretboard, :dev_routes) do`), `config/dev.exs:46` (`dev_routes: true`)
- **Detalle:** `dev_routes` solo se activa en dev. `prod.exs` **no** lo activa → `compile_env` resuelve a `nil`/`false` en un release de prod → el scope `/dev/dashboard` **no se compila** en el release. Correcto.
- **Recomendación:** Ninguna.

#### 9.3 — `Phoenix.LiveDashboard.RequestLogger` montado incondicionalmente
- **Severidad:** Low
- **OWASP:** A05:2021 — Security Misconfiguration
- **Refs:** `lib/fretboard_web/endpoint.ex:36-38`
- **Detalle:** A diferencia del dashboard (que está gated), el plug `Phoenix.LiveDashboard.RequestLogger` se monta **siempre** (incluso en prod) sin estar dentro de `if code_reloading? do`. Permite togglear request logging vía cookie/param `request_logger`. No expone datos sensibles por sí mismo, pero es una superficie innecesaria en prod.
- **Recomendación:** Envolverlo tras `code_reloading?` o tras `dev_routes`:
  ```elixir
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.LiveDashboard.RequestLogger,
      param_key: "request_logger",
      cookie_key: "request_logger"
  end
  ```

#### 9.4 — Manejo de errores sin stacktrace en prod
- **Severidad:** Good
- **Refs:** `lib/fretboard_web/controllers/error_html.ex:21-23`, `error_json.ex:18-20`, `config/config.exs:17-20` (`render_errors` con `layout: false`)
- **Detalle:** Los errores HTML devuelven solo el status message (`Phoenix.Controller.status_message_from_template/1`); los JSON devuelven `{errors: %{detail: ...}}`. Sin stacktrace, sin detalles internos. `config/prod.exs:22` pone `logger: :info` (no `:debug`).
- **Recomendación:** Ninguna.

---

### 10. SSL/TLS

#### 10.1 — TLS no configurado activamente; solo documentado
- **Severidad:** Medium
- **OWASP:** A02:2021 — Cryptographic Failures
- **Refs:** `config/prod.exs:10-19` (force_ssl comentado), `config/runtime.exs:61-91` (https comentado)
- **Detalle:** No hay `https:` configurado ni `force_ssl` activo. El despliegue por defecto (docker-compose) sirve **HTTP plano en el puerto 4000**. Se asume un reverse proxy externo para TLS, pero no está documentado ni garantizado.
- **Impacto:** Sin TLS, todo el tráfico (incluida la cookie de sesión firmada) viaja en claro; sin HSTS, susceptible a downgrade.
- **Recomendación:**
  1. **Preferido:** Usar un reverse proxy (Caddy/Traefik/nginx) con certificados automáticos (Let's Encrypt) frente al contenedor. Entonces activar `force_ssl: [rewrite_on: [:x_forwarded_proto], hsts: true]` en `config/prod.exs`.
  2. **Alternativa:** Configurar `https:` directamente en `runtime.exs` con `keyfile`/`certfile` desde env.
  3. Añadir a la documentación del repo la topología de TLS esperada.

---

## Tabla resumen

| # | Hallazgo | Severidad | OWASP | Refs |
|---|---|---|---|---|
| 1.1 | `secret_key_base` dev/test commiteados | Low | A05 | `dev.exs:17`, `test.exs:7` |
| 1.2 | `signing_salt` commiteados | Info | — | `config.exs:22`, `endpoint.ex:10` |
| 1.3 | `.env.example` placeholder débil | Low | A07 | `.env.example:1` |
| 2.1 | `protect_from_forgery` habilitado | **Good** | — | `router.ex:9` |
| 3.1 | Sin auth en socket LiveView (por diseño) | Info | — | `router.ex:17` |
| 3.2 | Eventos sin validación numérica | Low | A03 | `fretboard_live.ex:132,190,283` |
| 3.3 | Estado derivado/validado en `handle_params` | **Good** | — | `fretboard_live.ex:87` |
| 4.1 | Validación robusta de params URL | **Good** | — | `url_codec.ex:153-204` |
| 4.2 | Sin XSS (HEEx escapa todo) | **Good** | A03 | `fretboard_live.ex` render |
| 4.3 | `to_existing_atom` seguro | **Good** | — | `fretboard_live.ex:112,...` |
| 5.1 | Cabeceras seguras por defecto (CSP, X-Frame, etc.) | **Good** | — | `router.ex:10` |
| 5.2 | HSTS no habilitado | Medium | A05 | `prod.exs:10-19` |
| 6.1 | Cookie de sesión sin `secure: true` | Medium | A05 | `endpoint.ex:7-12` |
| 6.2 | `http_only` implícito correcto | **Good** | — | `endpoint.ex:7-12` |
| 6.3 | Sesión firmada, no cifrada | Info | — | `endpoint.ex:4-6` |
| 7.1 | `check_origin: false` en prod | Medium | A05/A08 | `runtime.exs:58` |
| 7.2 | Bind `0.0.0.0` en prod | Low | A05 | `runtime.exs:48-56` |
| 7.3 | `SECRET_KEY_BASE` seguro vía env | **Good** | A05 | `runtime.exs:32-37` |
| 7.4 | Dockerfile corre como `nobody` | **Good** | — | `Dockerfile:89` |
| 7.5 | Sin init (tini) en contenedor | Low | — | `Dockerfile:91-97` |
| 8.1 | Dependencias actuales, sin CVEs conocidos | **Good** | A06 | `mix.lock` |
| 9.1 | `debug_errors` solo en dev | Info | — | `dev.exs:16` |
| 9.2 | LiveDashboard deshabilitado en prod | **Good** | — | `router.ex:29` |
| 9.3 | `RequestLogger` montado siempre | Low | A05 | `endpoint.ex:36-38` |
| 9.4 | Errores sin stacktrace en prod | **Good** | — | `error_html.ex`, `prod.exs:22` |
| 10.1 | TLS no activo, solo documentado | Medium | A02 | `prod.exs:10-19` |

---

## Prioridades de remediación

### Alta prioridad (antes de cualquier despliegue con exposición pública)
1. **TLS/HSTS (5.2, 10.1):** Activar `force_ssl` detrás de reverse proxy, o configurar `https:` directamente. Es el control que más reduce riesgo.
2. **`check_origin` (7.1):** Reemplazar `false` por una lista de origins permitidos en `runtime.exs`.
3. **Cookie `secure` (6.1):** Una vez TLS activo, añadir `secure: true` a `@session_options`.

### Media prioridad
4. **Validación numérica en eventos (3.2):** Envolver `String.to_integer` en `Integer.parse` con guards.
5. **`RequestLogger` (9.3):** Envolver tras `code_reloading?`.
6. **Validar fortaleza de `SECRET_KEY_BASE` (1.3).**
7. **`mix hex.audit` en CI (8.1).**

### Baja prioridad / higiene
8. Rotar claves dev/test (1.1) y limpiar historial si el repo es público.
9. Añadir `tini` + `HEALTHCHECK` al Dockerfile (7.5).
10. Hacer explícito `http_only: true` en sesión (6.2).

---

## Puntuación global: 7 / 10

**Justificación:** Para una app stateless de visualización sin datos sensibles ni autenticación, Fretboard implementa correctamente las prácticas estándar de Phoenix: CSRF habilitado, cabeceras seguras por defecto (incluida CSP), HEEx con escaping automático (sin XSS), validación robusta de params URL, secretos de prod vía env, contenedor no-root, LiveDashboard gated en dev, y manejo de errores sin stacktraces. Los **3 puntos deducidos** corresponden a: (a) `check_origin: false` en prod debilita LiveView WS (–1.5), (b) ausencia de TLS/HSTS/cookie-secure en el despliegue por defecto (–1), y (c) secretos dev/test commiteados + placeholder débil en `.env.example` + `RequestLogger` siempre montado (–0.5). Ninguno es explotable para compromiso serio dado el perfil de la app, pero conviene cerrarlos antes de añadir cualquier feature con datos de usuario. Si se introdujera autenticación o persistencia, la puntuación debería re-evaluarse y los puntos 1–3 pasarían a ser **Críticos/Altos**.