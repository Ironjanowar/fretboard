/**
 * FretboardPanZoom — Phoenix LiveView JS hook for zoom/pan on the SVG fretboard.
 *
 * Manipulates the SVG `viewBox` attribute directly (no CSS transforms) to keep
 * strokes crisp and text sharp. Supports one-finger drag pan, two-finger pinch
 * zoom, and mouse wheel zoom. Taps (pointerdown→pointerup with minimal movement)
 * pass through to child elements so phx-click handlers fire normally.
 */
export const FretboardPanZoom = {
  mounted() {
    const container = this.el
    const svg = container.querySelector("svg")

    if (!svg) return

    // --- State ---
    // Read the initial viewBox from the container's data attribute.
    // The server does NOT render a viewBox attribute on the <svg> itself,
    // so morphdom never patches it — the hook owns it entirely.
    const vb = container.dataset.initialViewBox
    const parts = vb ? vb.split(/\s+/).map(Number) : [0, 0, 1310, 180]

    const initial = { x: parts[0], y: parts[1], w: parts[2], h: parts[3] }
    const state = { ...initial }

    // On narrow viewports (mobile), start with a 12-fret window instead
    // of the full 24-fret neck so notes are legible without zooming.
    const isMobile = window.matchMedia("(max-width: 1279px)").matches
    if (isMobile && initial.w > 0) {
      const fretWidth = initial.w / 25 // approximate fret width in viewBox units
      state.w = 12 * fretWidth
      state.h = initial.h
      state.x = 0
      state.y = initial.y
    }

    // Set the initial viewBox on the SVG — the server doesn't render it
    svg.setAttribute("viewBox", `${state.x} ${state.y} ${state.w} ${state.h}`)

    const MIN_ZOOM = 1
    const MAX_ZOOM = 4
    const DRAG_THRESHOLD = 5 // px movement before pan is consumed (taps pass through)

    let pointers = new Map() // pointerId → {x, y}
    let dragging = false
    let dragMoved = false
    let lastPan = null
    let pinchStart = null // { dist, cx, cy, vbX, vbY, vbW, vbH }

    // --- Helpers ---
    function clamp(v, min, max) {
      return Math.max(min, Math.min(max, v))
    }

    function applyViewBox() {
      svg.setAttribute("viewBox", `${state.x} ${state.y} ${state.w} ${state.h}`)
    }

    function distance(a, b) {
      const dx = a.x - b.x
      const dy = a.y - b.y
      return Math.sqrt(dx * dx + dy * dy)
    }

    function midpoint(a, b) {
      return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 }
    }

    // Convert client px → SVG viewBox units using current viewBox
    function clientToSvg(clientX, clientY) {
      const rect = svg.getBoundingClientRect()
      const sx = (clientX - rect.left) / rect.width * state.w + state.x
      const sy = (clientY - rect.top) / rect.height * state.h + state.y
      return { x: sx, y: sy }
    }

    // Zoom toward a focal point (in SVG coordinates), clamped to [MIN_ZOOM, MAX_ZOOM]
    function zoomAt(focalSvg, factor) {
      const newW = clamp(state.w / factor, initial.w / MAX_ZOOM, initial.w / MIN_ZOOM)
      const newH = clamp(state.h / factor, initial.h / MAX_ZOOM, initial.h / MIN_ZOOM)

      // Keep the focal point fixed: ratio of focal within viewBox stays same
      const fx = (focalSvg.x - state.x) / state.w
      const fy = (focalSvg.y - state.y) / state.h

      state.x = clamp(focalSvg.x - fx * newW, 0, initial.w - newW)
      state.y = clamp(focalSvg.y - fy * newH, 0, initial.h - newH)
      state.w = newW
      state.h = newH
      applyViewBox()
    }

    function panBy(dxPx, dyPx) {
      const rect = svg.getBoundingClientRect()
      const dxSvg = dxPx / rect.width * state.w
      const dySvg = dyPx / rect.height * state.h

      state.x = clamp(state.x - dxSvg, 0, initial.w - state.w)
      state.y = clamp(state.y - dySvg, 0, initial.h - state.h)
      applyViewBox()
    }

    // --- Pointer events (touch + mouse via Pointer Events API) ---
    // Pointer capture is NOT used: capturing redirects pointerup/click to the
    // container, which would swallow clicks on child elements (phx-click on
    // note positions). Instead, down is tracked on the container and
    // move/up are tracked on window — the standard pan/zoom pattern.
    function onPointerDown(e) {
      pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })
      dragMoved = false

      if (pointers.size === 1) {
        dragging = true
        lastPan = { x: e.clientX, y: e.clientY }
      } else if (pointers.size === 2) {
        dragging = false
        const pts = [...pointers.values()]
        pinchStart = {
          dist: distance(pts[0], pts[1]),
          midX: midpoint(pts[0], pts[1]).x,
          midY: midpoint(pts[0], pts[1]).y,
          vbX: state.x,
          vbY: state.y,
          vbW: state.w,
          vbH: state.h,
        }
      }
    }

    function onPointerMove(e) {
      if (pointers.has(e.pointerId)) {
        pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })
      }

      if (pointers.size >= 2 && pinchStart) {
        const pts = [...pointers.values()]
        const dist = distance(pts[0], pts[1])
        const factor = dist / pinchStart.dist
        const mid = midpoint(pts[0], pts[1])

        // Reset to pinch-start state — avoids drift across frames
        state.w = pinchStart.vbW
        state.h = pinchStart.vbH
        state.x = pinchStart.vbX
        state.y = pinchStart.vbY
        applyViewBox()

        // Pan first: follow midpoint movement in start-state SVG coords
        const startMidSvg = clientToSvg(pinchStart.midX, pinchStart.midY)
        const currentMidSvg = clientToSvg(mid.x, mid.y)
        state.x = clamp(state.x + (startMidSvg.x - currentMidSvg.x), 0, initial.w - state.w)
        state.y = clamp(state.y + (startMidSvg.y - currentMidSvg.y), 0, initial.h - state.h)
        applyViewBox()

        // Then zoom toward the current midpoint
        const focalSvg = clientToSvg(mid.x, mid.y)
        zoomAt(focalSvg, factor)

        dragMoved = true
        e.preventDefault()
        return
      }

      if (dragging && pointers.size === 1) {
        const dx = e.clientX - lastPan.x
        const dy = e.clientY - lastPan.y
        const moved = Math.abs(dx) + Math.abs(dy)

        if (moved > DRAG_THRESHOLD) {
          dragMoved = true
          panBy(dx, dy)
          e.preventDefault()
        }

        lastPan = { x: e.clientX, y: e.clientY }
      }
    }

    function onPointerUp(e) {
      pointers.delete(e.pointerId)

      if (pointers.size < 2) {
        pinchStart = null
      }

      if (pointers.size === 1) {
        dragging = true
        const remaining = [...pointers.values()][0]
        lastPan = { x: remaining.x, y: remaining.y }
      }

      if (pointers.size === 0) {
        dragging = false
        // dragMoved is intentionally NOT reset here: the click event fires
        // after pointerup, and the capture-phase click suppressor below needs
        // to know whether this interaction was a drag. It is reset on the
        // next pointerdown instead.
      }
    }

    // Swallow the click that follows a drag/pan so releasing over a note
    // position does not toggle it. Taps (no significant movement) pass through.
    function onClickCapture(e) {
      if (dragMoved) {
        e.stopPropagation()
        e.preventDefault()
      }
    }

    // --- Wheel zoom (desktop) ---
    let wheelTimer = null
    function onWheel(e) {
      e.preventDefault()
      const focalSvg = clientToSvg(e.clientX, e.clientY)
      const factor = e.deltaY < 0 ? 1.1 : 1 / 1.1
      zoomAt(focalSvg, factor)
      clearTimeout(wheelTimer)
    }

    // --- LiveView event: set_viewport (quick-jump) ---
    function handleSetViewport(payload) {
      const startFret = payload.start_fret
      if (typeof startFret !== "number" || !isFinite(startFret)) return

      // Show 12 frets starting at startFret
      const fretsToShow = 12
      const fretW = initial.w / 25 // approximate fret width in viewBox units
      const newX = startFret * fretW
      const newW = fretsToShow * fretW

      // Clamp
      const clampedX = clamp(newX, 0, Math.max(0, initial.w - newW))
      const clampedW = clamp(newW, initial.w / MAX_ZOOM, initial.w)
      const ratio = state.h / state.w

      // Animate
      const startX = state.x
      const startY = state.y
      const startW = state.w
      const startH = state.h
      const targetW = clampedW
      const targetH = clampedW * ratio
      const targetX = clamp(newX, 0, initial.w - targetW)
      const targetY = clamp(0, 0, initial.h - targetH)

      const duration = 300
      const t0 = performance.now()

      function tick(now) {
        const elapsed = now - t0
        const t = Math.min(elapsed / duration, 1)
        // ease-out
        const eased = 1 - Math.pow(1 - t, 3)

        state.x = startX + (targetX - startX) * eased
        state.y = startY + (targetY - startY) * eased
        state.w = startW + (targetW - startW) * eased
        state.h = startH + (targetH - startH) * eased
        applyViewBox()

        if (t < 1) requestAnimationFrame(tick)
      }

      requestAnimationFrame(tick)
    }

    // --- Register ---
    // down on the container; move/up/cancel on window so drags continue even
    // when the pointer leaves the container (and no capture is needed).
    container.addEventListener("pointerdown", onPointerDown)
    window.addEventListener("pointermove", onPointerMove)
    window.addEventListener("pointerup", onPointerUp)
    window.addEventListener("pointercancel", onPointerUp)
    container.addEventListener("wheel", onWheel, { passive: false })
    container.addEventListener("click", onClickCapture, true)

    this.handleEvent("set_viewport", handleSetViewport)

    // Store cleanup refs and state for updated() callback
    this._panZoom = {
      onPointerDown,
      onPointerMove,
      onPointerUp,
      onWheel,
      onClickCapture,
      handleSetViewport,
      container,
      state,
    }
  },

  destroyed() {
    const ctx = this._panZoom
    if (!ctx) return
    ctx.container.removeEventListener("pointerdown", ctx.onPointerDown)
    window.removeEventListener("pointermove", ctx.onPointerMove)
    window.removeEventListener("pointerup", ctx.onPointerUp)
    window.removeEventListener("pointercancel", ctx.onPointerUp)
    ctx.container.removeEventListener("wheel", ctx.onWheel)
    ctx.container.removeEventListener("click", ctx.onClickCapture, true)
  },

  updated() {
    // Re-apply cached viewBox after LiveView re-renders the SVG content.
    // morphdom patches inner nodes (note circles, strings) but since the
    // server no longer renders a viewBox attribute on the <svg>, it won't
    // be overwritten. This callback ensures the hook's state stays in sync
    // if the SVG element itself is replaced.
    const ctx = this._panZoom
    if (!ctx) return
    const svg = ctx.container.querySelector("svg")
    if (svg) {
      svg.setAttribute("viewBox", `${ctx.state.x} ${ctx.state.y} ${ctx.state.w} ${ctx.state.h}`)
    }
  },
}