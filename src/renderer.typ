// src/renderer.typ
// Waveform rendering engine for signel

#import "util.typ": format-bus-val, format-time, parse-signal-name, convert-time, format-time-val
#import "themes.typ": theme-default, themes
#import "parser.typ": decode-evcd-char, decode-evcd-value

/// Find the signal object from parsed data by exact or suffix/base match
#let find-signal(parsed, query) = {
  if query in parsed.signals {
    return parsed.signals.at(query)
  }
  // Try matching by base name
  for (name, sig) in parsed.signals {
    if sig.name == query or sig.base-name == query {
      return sig
    }
  }
  // Try matching end of full-name (e.g. "clk" in "top.clk")
  for (name, sig) in parsed.signals {
    if name.ends-with("." + query) {
      return sig
    }
  }
  return none
}

/// Compute value of a signal at or just before time t
#let get-val-at-time(changes, t, default-val: "x") = {
  if changes.len() == 0 {
    return default-val
  }
  let last-val = default-val
  for chg in changes {
    if chg.time <= t {
      last-val = chg.val
    } else {
      break
    }
  }
  return last-val
}

/// Build list of contiguous segments within [t-start, t-end]
#let build-segments(changes, t-start, t-end, default-val: "x") = {
  let initial-val = get-val-at-time(changes, t-start, default-val: default-val)
  let relevant-changes = ()

  for chg in changes {
    if chg.time > t-start and chg.time <= t-end {
      relevant-changes.push(chg)
    }
  }

  let segments = ()
  let cur-t = t-start
  let cur-val = initial-val

  for chg in relevant-changes {
    if chg.time > cur-t {
      segments.push((
        start: cur-t,
        end: chg.time,
        val: cur-val,
      ))
      cur-t = chg.time
      cur-val = chg.val
    } else {
      cur-val = chg.val
    }
  }

  // Final segment up to t-end
  if cur-t < t-end {
    segments.push((
      start: cur-t,
      end: t-end,
      val: cur-val,
    ))
  }

  return segments
}

/// Render waveforms from parsed VCD/EVCD data
#let render-waveform(
  parsed,
  signals: "all",
  time-range: none,
  time-step: auto,
  time-step-width: 1.5pt,
  width: auto,
  signal-height: 18pt,
  signal-gap: 8pt,
  label-width: auto,
  label-align: "left",
  slant: 3pt,
  theme: theme-default,
  markers: (),
  cursors: (),
  show-grid: true,
  show-ruler: true,
  show-timescale: true,
  title: none,
  evcd-mode: "composite",
  time-unit: auto,
) = {
  // Resolve time range
  let t-min = if time-range != none { time-range.at(0) } else { parsed.time-min }
  let t-max = if time-range != none { time-range.at(1) } else { parsed.time-max }
  if t-max <= t-min {
    t-max = t-min + 10
  }
  let total-duration = t-max - t-min

  // Resolve signals to display
  let sig-entries = ()
  if signals == "all" or signals == none {
    for name in parsed.all-signals {
      sig-entries.push((name: name))
    }
  } else {
    for item in signals {
      if type(item) == str {
        sig-entries.push((name: item))
      } else if type(item) == dictionary {
        sig-entries.push(item)
      }
    }
  }

  // Resolve label width automatically if set to auto
  let resolved-label-width = 75pt
  if label-width != auto and type(label-width) == length {
    resolved-label-width = label-width
  } else {
    let max-len = 1
    for entry in sig-entries {
      if entry.at("type", default: "signal") != "divider" {
        let sig-query = entry.at("name", default: "")
        let sig-obj = find-signal(parsed, sig-query)
        let display-label = entry.at("label", default: if sig-obj != none { sig-obj.name } else { sig-query })
        let l = str(display-label).len()
        if l > max-len {
          max-len = l
        }
      }
    }
    // Estimated text width + 8pt gap before timeline starts
    let text-est = max-len * theme.font-size * 0.58
    resolved-label-width = text-est + 8pt
  }

  // Calculate horizontal scale factor
  // If user specified fixed width, compute time-step-width accordingly
  let wave-width = 0pt
  let px-per-unit = time-step-width
  if width != auto and type(width) == length {
    let available = width - resolved-label-width - 8pt
    if available > 50pt {
      px-per-unit = available / total-duration
      wave-width = available
    }
  } else {
    wave-width = total-duration * px-per-unit
  }

  // Compute time step for ticks & grid
  let resolved-step = 10
  if time-step != auto and time-step != none {
    resolved-step = time-step
  } else {
    // Automatic step based on total duration: aim for ~5-10 intervals
    let raw-step = total-duration / 8.0
    let mag = calc.pow(10, calc.floor(calc.log(calc.max(raw-step, 1.0))))
    let norm = raw-step / mag
    if norm < 1.5 {
      resolved-step = int(1 * mag)
    } else if norm < 3.5 {
      resolved-step = int(2 * mag)
    } else if norm < 7.5 {
      resolved-step = int(5 * mag)
    } else {
      resolved-step = int(10 * mag)
    }
    if resolved-step < 1 { resolved-step = 1 }
  }

  // Prepare list of time ticks
  let ticks = ()
  let first-tick = calc.ceil(t-min / resolved-step) * resolved-step
  let cur-tick = first-tick
  while cur-tick <= t-max {
    ticks.push(cur-tick)
    cur-tick += resolved-step
  }

  // Layout metrics
  let ruler-height = if show-ruler { if markers.len() > 0 { 32pt } else { 20pt } } else { 0pt }
  let title-height = if title != none { 24pt } else { 0pt }
  let header-height = title-height + ruler-height

  // Compute total height
  let num-channels = sig-entries.len()
  let track-y-positions = ()
  let current-y = header-height

  for entry in sig-entries {
    let is-divider = entry.at("type", default: "signal") == "divider"
    let h = if is-divider { signal-height * 0.8 } else { signal-height }
    track-y-positions.push((y: current-y, height: h, is-divider: is-divider))
    current-y += h + signal-gap
  }

  let total-height = current-y + 10pt
  let total-box-width = resolved-label-width + wave-width + 8pt

  // Render the canvas box
  box(
    width: if width != auto { width } else { total-box-width },
    height: total-height,
    fill: theme.background,
    radius: 4pt,
    inset: if theme.background != none { 4pt } else { (x: 0pt, y: 2pt) },
  )[
    // 1. Optional Title
    #if title != none {
      place(top + left, dx: if theme.background != none { 4pt } else { 0pt }, dy: 2pt)[
        #text(size: theme.font-size + 2pt, weight: "bold", fill: theme.text-color)[#title]
        #if show-timescale [
          #h(1em)
          #text(size: theme.time-font-size, fill: theme.ruler-color)[
            #if time-unit != auto and time-unit != none and time-unit != parsed.timescale.unit [
              (Timescale: #parsed.timescale.number #parsed.timescale.unit, displayed in #time-unit)
            ] else [
              (Timescale: #parsed.timescale.number #parsed.timescale.unit)
            ]
          ]
        ]
      ]
    }

    // 2. Vertical Grid Lines
    #if show-grid {
      for t in ticks {
        let x = resolved-label-width + (t - t-min) * px-per-unit
        place(
          top + left,
          line(
            start: (x, header-height - 4pt),
            end: (x, total-height - 8pt),
            stroke: (paint: theme.grid-color, thickness: 0.5pt, dash: "dotted"),
          )
        )
      }
    }

    // 3. Time Ruler / Axis
    #if show-ruler {
      let axis-y = header-height - 4pt
      // Horizontal baseline
      place(
        top + left,
        line(
          start: (resolved-label-width, axis-y),
          end: (resolved-label-width + wave-width, axis-y),
          stroke: 0.8pt + theme.ruler-color,
        )
      )
      // Ticks and labels
      for t in ticks {
        let x = resolved-label-width + (t - t-min) * px-per-unit
        // Tick mark
        place(
          top + left,
          line(
            start: (x, axis-y - 4pt),
            end: (x, axis-y),
            stroke: 0.8pt + theme.ruler-color,
          )
        )
        // Tick label
        let conv = convert-time(t, parsed.timescale, time-unit)
        let display-t = format-time-val(conv.val)
        place(
          top + left,
          dx: x - 20pt,
          dy: axis-y - 14pt,
          block(width: 40pt, align(center)[
            #text(size: theme.time-font-size, fill: theme.ruler-color)[#display-t]
          ])
        )
      }
      // Timescale unit label at right end
      let display-unit = if time-unit != auto and time-unit != none { time-unit } else { parsed.timescale.unit }
      place(
        top + left,
        dx: resolved-label-width + wave-width + 4pt,
        dy: axis-y - 10pt,
        text(size: theme.time-font-size, fill: theme.ruler-color, weight: "medium")[
          #display-unit
        ]
      )
    }

    // 4. Render Signal Tracks
    #for idx in range(sig-entries.len()) {
      let entry = sig-entries.at(idx)
      let pos = track-y-positions.at(idx)
      let y-top = pos.y
      let y-h = pos.height
      let y-bot = y-top + y-h
      let y-mid = y-top + y-h / 2

      if pos.is-divider {
        // Divider Header
        let d-label = entry.at("label", default: entry.at("name", default: ""))
        place(
          top + left,
          dx: 0pt,
          dy: y-top,
          block(
            width: resolved-label-width + wave-width,
            height: y-h,
            fill: theme.divider-fill,
            radius: 2pt,
            inset: (x: 4pt, y: 2pt),
            align(left + horizon)[
              #text(size: theme.font-size, weight: "bold", fill: theme.text-color)[#d-label]
            ]
          )
        )
        place(
          top + left,
          line(
            start: (0pt, y-bot),
            end: (resolved-label-width + wave-width, y-bot),
            stroke: 0.5pt + theme.divider-color,
          )
        )
      } else {
        // Regular Signal
        let sig-query = entry.at("name")
        let sig-obj = find-signal(parsed, sig-query)

        // Custom label or signal name
        let display-label = entry.at("label", default: if sig-obj != none { sig-obj.name } else { sig-query })
        let custom-color = entry.at("color", default: auto)
        let custom-fill = entry.at("bus-fill", default: auto)
        let custom-format = entry.at("format", default: "hex")

        // Draw Signal Label on Left
        place(
          top + left,
          dx: 0pt,
          dy: y-top,
          block(
            width: resolved-label-width - 4pt,
            height: y-h,
            align(if label-align == "left" { left + horizon } else { right + horizon })[
              #text(size: theme.font-size, weight: "medium", fill: theme.text-color)[#display-label]
            ]
          )
        )

        if sig-obj != none {
          let is-bus = entry.at("is-bus", default: sig-obj.is-bus)
          let is-clock = entry.at("is-clock", default: sig-obj.is-clock)
          let segments = build-segments(sig-obj.changes, t-min, t-max)

          if is-bus {
            // RENDER BUS (MULTI-BIT)
            let b-stroke = if custom-color != auto { custom-color } else { theme.bus-stroke }
            let b-fill = if custom-fill != auto { custom-fill } else { theme.bus-fill }

            for seg in segments {
              let x0 = resolved-label-width + (seg.start - t-min) * px-per-unit
              let x1 = resolved-label-width + (seg.end - t-min) * px-per-unit
              let seg-w = x1 - x0
              let cur-val = seg.val
              let val-lower = lower(str(cur-val))
              let is-all-z = val-lower != "" and val-lower.replace("z", "").len() == 0
              let is-all-x = val-lower != "" and val-lower.replace("x", "").len() == 0

              if is-all-z {
                // High-Z on bus: single dashed center line
                place(
                  top + left,
                  line(
                    start: (x0, y-mid),
                    end: (x1, y-mid),
                    stroke: (paint: theme.high-z-color, thickness: theme.stroke-width, dash: "dashed"),
                  )
                )
                if seg-w > 20pt {
                  place(
                    top + left,
                    dx: x0,
                    dy: y-top,
                    block(
                      width: seg-w,
                      height: y-h,
                      align(center + horizon)[
                        #text(size: theme.font-size - 1pt, weight: "bold", fill: theme.high-z-color)[Z]
                      ]
                    )
                  )
                }
              } else if is-all-x or "x" in val-lower {
                // Unknown state: shaded warning block
                let sl = calc.min(slant, seg-w / 3.0)
                place(
                  top + left,
                  polygon(
                    fill: theme.unknown-fill,
                    stroke: theme.stroke-width + theme.unknown-color,
                    (x0 + sl, y-top + 1pt),
                    (x1 - sl, y-top + 1pt),
                    (x1, y-mid),
                    (x1 - sl, y-bot - 1pt),
                    (x0 + sl, y-bot - 1pt),
                    (x0, y-mid),
                  )
                )
                if seg-w > 14pt {
                  place(
                    top + left,
                    dx: x0,
                    dy: y-top,
                    block(
                      width: seg-w,
                      height: y-h,
                      align(center + horizon)[
                        #text(size: theme.font-size - 1pt, weight: "bold", fill: theme.unknown-color)[X]
                      ]
                    )
                  )
                }
              } else {
                // Valid Bus Segment: Hexagonal Polygon
                let sl = calc.min(slant, seg-w / 3.0)
                place(
                  top + left,
                  polygon(
                    fill: b-fill,
                    stroke: theme.stroke-width + b-stroke,
                    (x0 + sl, y-top + 1pt),
                    (x1 - sl, y-top + 1pt),
                    (x1, y-mid),
                    (x1 - sl, y-bot - 1pt),
                    (x0 + sl, y-bot - 1pt),
                    (x0, y-mid),
                  )
                )
                // Formatted Label
                let formatted = format-bus-val(cur-val, format: custom-format)
                // Check if segment is wide enough to display text
                if seg-w > 20pt {
                  place(
                    top + left,
                    dx: x0,
                    dy: y-top,
                    block(
                      width: seg-w,
                      height: y-h,
                      align(center + horizon)[
                        #text(
                          size: theme.font-size - 1pt,
                          weight: "medium",
                          fill: if custom-color != auto { custom-color } else { theme.bus-text-color }
                        )[#formatted]
                      ]
                    )
                  )
                } else if seg-w > 10pt {
                  place(
                    top + left,
                    dx: x0,
                    dy: y-top,
                    block(
                      width: seg-w,
                      height: y-h,
                      align(center + horizon)[
                        #text(size: theme.font-size - 2pt, fill: theme.bus-text-color)[..]
                      ]
                    )
                  )
                }
              }
            }
          } else {
            // RENDER 1-BIT DIGITAL SIGNAL
            let s-color = if custom-color != auto {
              custom-color
            } else if is-clock {
              theme.clock-color
            } else {
              theme.signal-color
            }

            let prev-level = none

            for seg in segments {
              let x0 = resolved-label-width + (seg.start - t-min) * px-per-unit
              let x1 = resolved-label-width + (seg.end - t-min) * px-per-unit
              let seg-w = x1 - x0
              let cur-val = lower(str(seg.val))

              let cur-level = if cur-val == "1" {
                y-top + 1pt
              } else if cur-val == "0" {
                y-bot - 1pt
              } else if cur-val == "z" {
                y-mid
              } else {
                "x"
              }

              // Draw transition line from previous level
              if prev-level != none and prev-level != cur-level {
                if prev-level != "x" and cur-level != "x" {
                  place(
                    top + left,
                    line(
                      start: (x0, prev-level),
                      end: (x0, cur-level),
                      stroke: theme.stroke-width + s-color,
                    )
                  )
                } else if prev-level != "x" and cur-level == "x" {
                  place(
                    top + left,
                    line(
                      start: (x0, prev-level),
                      end: (x0, y-mid),
                      stroke: theme.stroke-width + theme.unknown-color,
                    )
                  )
                } else if prev-level == "x" and cur-level != "x" {
                  place(
                    top + left,
                    line(
                      start: (x0, y-mid),
                      end: (x0, cur-level),
                      stroke: theme.stroke-width + s-color,
                    )
                  )
                }
              }

              // Draw horizontal segment
              if cur-level == "x" {
                // Unknown state: shaded band with top and bottom lines
                place(
                  top + left,
                  rect(
                    fill: theme.unknown-fill,
                    stroke: (y: theme.stroke-width + theme.unknown-color),
                    width: seg-w,
                    height: y-h - 2pt,
                  ),
                  dx: x0,
                  dy: y-top + 1pt,
                )
                if seg-w > 12pt {
                  place(
                    top + left,
                    dx: x0,
                    dy: y-top,
                    block(
                      width: seg-w,
                      height: y-h,
                      align(center + horizon)[
                        #text(size: theme.font-size - 1pt, weight: "bold", fill: theme.unknown-color)[X]
                      ]
                    )
                  )
                }
              } else if cur-val == "z" {
                // High-Z: dashed line in the middle
                place(
                  top + left,
                  line(
                    start: (x0, y-mid),
                    end: (x1, y-mid),
                    stroke: (paint: theme.high-z-color, thickness: theme.stroke-width, dash: "dashed"),
                  )
                )
              } else {
                // Logic 0 or 1
                place(
                  top + left,
                  line(
                    start: (x0, cur-level),
                    end: (x1, cur-level),
                    stroke: theme.stroke-width + s-color,
                  )
                )
              }

              prev-level = cur-level
            }
          }
        }
      }
    }

    // 5. Vertical Markers
    #for marker in markers {
      let m-t = marker.time
      if m-t >= t-min and m-t <= t-max {
        let mx = resolved-label-width + (m-t - t-min) * px-per-unit
        let m-stroke = marker.at("stroke", default: 1pt + theme.marker-color)
        let m-label = marker.at("label", default: none)

        place(
          top + left,
          line(
            start: (mx, header-height - 4pt),
            end: (mx, total-height - 8pt),
            stroke: m-stroke,
          )
        )

        if m-label != none {
          place(
            top + left,
            dx: mx + 3pt,
            dy: header-height - 30pt,
            block(
              fill: if theme.background != none { theme.background } else { white },
              stroke: 0.5pt + theme.marker-color,
              radius: 2pt,
              inset: (x: 3pt, y: 1pt),
              text(size: theme.time-font-size - 0.5pt, fill: theme.marker-color, weight: "bold")[
                #m-label
              ]
            )
          )
        }
      }
    }

    // 6. Cursors / Spans
    #for cursor in cursors {
      let c-start = cursor.start
      let c-end = cursor.end
      if c-end >= t-min and c-start <= t-max {
        let cx0 = resolved-label-width + (calc.max(c-start, t-min) - t-min) * px-per-unit
        let cx1 = resolved-label-width + (calc.min(c-end, t-max) - t-min) * px-per-unit
        let c-label = cursor.at("label", default: none)
        let c-fill = cursor.at("fill", default: rgb("38bdf8").transparentize(85%))

        place(
          top + left,
          rect(
            fill: c-fill,
            width: cx1 - cx0,
            height: total-height - header-height - 4pt,
          ),
          dx: cx0,
          dy: header-height,
        )

        if c-label != none {
          place(
            top + left,
            dx: cx0,
            dy: total-height - 18pt,
            block(width: cx1 - cx0, align(center)[
              #text(size: theme.time-font-size, weight: "bold", fill: theme.text-color)[#c-label]
            ])
          )
        }
      }
    }
  ]
}
