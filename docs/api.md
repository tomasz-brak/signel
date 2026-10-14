# `signel` API Reference

This document provides complete documentation for all exported functions, parameters, and data structures in `signel`.

---

## Table of Contents

- [Core Rendering Functions](#core-rendering-functions)
  - [`render-vcd`](#render-vcd)
  - [`render-waveform`](#render-waveform)
- [Parsing Functions](#parsing-functions)
  - [`parse-vcd`](#parse-vcd)
  - [`decode-evcd-char`](#decode-evcd-char)
  - [`decode-evcd-value`](#decode-evcd-value)
- [Theming Functions](#theming-functions)
  - [`themes`](#themes)
  - [`vcd-theme`](#vcd-theme)
- [Utility Functions](#utility-functions)
  - [`bin-to-hex`](#bin-to-hex)
  - [`bin-to-dec`](#bin-to-dec)
  - [`bin-to-ascii`](#bin-to-ascii)
  - [`format-bus-val`](#format-bus-val)
  - [`parse-timescale`](#parse-timescale)

---

## Core Rendering Functions

### `render-vcd`

Renders a waveform from a VCD/EVCD content string. In Typst, packages are sandboxed and cannot access files outside their package directory directly, so files should be read using `read("path/to/file.vcd")` within your document.

```typst
#render-vcd(
  read("wave.vcd"),
  signals: "all",
  time-range: none,
  time-step: auto,
  time-step-width: 1.5pt,
  width: auto,
  signal-height: 18pt,
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
)
```

#### Parameters:

- **`content`** (`str`, required): The VCD or EVCD file content, typically loaded via `read("file.vcd")`.
- **`signals`** (`"all"` | `array`, default: `"all"`): Array of signal names or configuration dictionaries to render.
- **`time-range`** (`none` | `(int, int)`, default: `none`): A tuple `(start_time, end_time)` to zoom in on a specific simulation time window.
- **`time-step`** (`auto` | `int`, default: `auto`): Grid and ruler interval. If `auto`, a readable interval is computed automatically.
- **`time-step-width`** (`length`, default: `1.5pt`): Width allocated per time unit.
- **`width`** (`auto` | `length`, default: `auto`): Total box width. When set to a length (e.g. `100%` or `500pt`), `time-step-width` scales to fit the available width.
- **`signal-height`** (`length`, default: `18pt`): Height of each signal track.
- **`signal-gap`** (`length`, default: `8pt`): Vertical spacing between adjacent signal tracks.
- **`label-width`** (`auto` | `length`, default: `auto`): Width allocated for the signal name column on the left. When set to `auto`, it dynamically fits the longest signal label.
- **`label-align`** (`"left"` | `"right"`, default: `"left"`): Horizontal alignment of signal names within the label column. `"left"` aligns labels flush with the document margin.
- **`slant`** (`length`, default: `3pt`): Width of the transition bevel on bus envelopes.
- **`theme`** (`dictionary`, default: `themes.default`): Theme dictionary.
- **`markers`** (`array`, default: `()`): Array of vertical timing markers (see [Markers](#markers)).
- **`cursors`** (`array`, default: `()`): Array of shaded interval spans (see [Cursors](#cursors)).
- **`show-grid`** (`bool`, default: `true`): Whether to display vertical dashed grid lines.
- **`show-ruler`** (`bool`, default: `true`): Whether to display the time scale axis and tick labels.
- **`show-timescale`** (`bool`, default: `true`): Whether to print the timescale unit in the title header.
- **`title`** (`none` | `content` | `str`, default: `none`): Optional title text.
- **`evcd-mode`** (`"composite"` | `"input"` | `"output"` | `"raw"`, default: `"composite"`): Decoding mode for EVCD ports.
- **`time-unit`** (`auto` | `str`, default: `auto`): Overrides the displayed time unit on the time ruler (e.g. `"fs"`, `"ps"`, `"ns"`, `"us"`, `"ms"`, `"s"`). Internally preserves waveform time ticks while converting the displayed numbers.

---

### `render-waveform`

Renders an already-parsed VCD data dictionary (produced by `parse-vcd`).

```typst
#let parsed = parse-vcd(read("trace.vcd"))
#render-waveform(parsed, signals: ("clk", "data"))
```

---

## Signal Configuration Dictionary

Inside the `signals` array, you can pass strings or dictionaries with per-signal overrides:

```typst
signals: (
  // String shorthand:
  "clk",

  // Custom configuration dictionary:
  (
    name: "data [7:0]",       // Name in VCD (exact or base name)
    label: "DATA BUS",        // Custom display label
    color: rgb("1d4ed8"),     // Signal stroke color
    bus-stroke: rgb("1d4ed8"),// Custom bus border
    bus-fill: rgb("e0f2fe"),  // Custom bus interior fill
    format: "hex",            // "hex" | "bin" | "dec" | "ascii" | "raw" | function
    is-bus: true,             // Force bus interpretation
    is-clock: false,          // Force clock styling
  ),

  // Section divider / header:
  (
    type: "divider",
    label: "Memory Control Signals",
  ),
)
```

---

## Markers & Cursors

### Markers

Vertical lines placed at specific simulation timestamps:

```typst
markers: (
  (
    time: 40,                      // Timestamp
    label: "Read Asserted",        // Label in badge
    stroke: 1pt + rgb("dc2626"),   // Line style
    color: rgb("dc2626"),          // Badge & text color
    dy: 0pt,                       // Optional vertical badge offset
  ),
)
```

### Cursors

Shaded time intervals highlighting intervals ($\Delta t$):

```typst
cursors: (
  (
    start: 20,
    end: 60,
    label: "Hold Time (40 ns)",
    fill: rgb("38bdf8").transparentize(85%),
  ),
)
```

---

## Parsing Functions

### `parse-vcd`

Parses a VCD or EVCD string into an AST dictionary.

```typst
#let parsed = parse-vcd(content, evcd-mode: "composite")
```

#### Returns:
```typst
(
  type: "vcd" | "evcd",
  date: str,
  version: str,
  timescale: (number: int, unit: str, factor: float),
  signals: dictionary,
  signals-by-id: dictionary,
  all-signals: array,
  time-min: int,
  time-max: int,
)
```

---

## Theming

### `vcd-theme`

Helper function to customize or create themes:

```typst
#let my-theme = vcd-theme(
  base: themes.default,
  signal-color: rgb("059669"),
  bus-fill: rgb("ecfdf5"),
  stroke-width: 1.5pt,
  font-size: 9pt,
)
```
