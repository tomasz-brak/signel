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
- **`strict`** (`bool`, default: `false`): When `true`, causes compilation to panic if any signal is not found, sliced out of bounds, or encoded wrong. When `false` (default), renders clear visual warning banners in the waveform without halting compilation.
- **`show-warnings`** (`bool`, default: `true`): Whether to display warning badges and alert banners when signals are missing or values are encoded wrong.

---

### `render-waveform`

Renders an already-parsed VCD data dictionary (produced by `parse-vcd`).

```typst
#let parsed = parse-vcd(read("trace.vcd"))
#render-waveform(parsed, signals: ("clk", "data"))
```

---

## Signal Configuration Dictionary & Slicing

Inside the `signals` array, you can pass strings or dictionaries with per-signal overrides.

### 1. Signal Slicing

You can slice any multi-bit signal from the VCD by specifying bit indices or ranges directly in the signal query:
- **Single Bit**: `"count[0]"` or `"sw[1]"` — automatically rendered as a digital 1-bit waveform with logic transitions (`0`, `1`, `x`, `z`).
- **Sub-Bus Range**: `"count[3:1]"` or `"data[7:4]"` — automatically rendered as a multi-bit bus with specified width.
- **Whitespace Flexibility**: Matches whether the VCD declared `sw [1:0]` with a space or `sw[1:0]` without.

### 2. Configuration Options & Interpreters

```typst
signals: (
  // 1. String shorthands (supports direct slicing):
  "clk",
  "count[0]",     // Sliced 1-bit signal
  "count[3:1]",   // Sliced sub-bus

  // 2. 7-Segment Display Auto-Decoding (Active-Low & Active-High):
  (
    name: "hex0 [6:0]",
    label: "HEX0",
    format: "7segment-low",    // Decodes active-low 7-segment (0=ON, e.g. 0x40 -> 0)
    // or: format: "7segment-high" (1=ON, common cathode)
    // or: format: "7segment" (auto-detects active-low or active-high)
    // or: format: (type: "7segment", active: "low", order: "g-to-a")
  ),

  // 3. Signed Two's Complement Integer Interpreter:
  (
    name: "alu_out [7:0]",
    label: "ALU Output",
    format: "signed",          // Displays signed decimal (-128 to +127)
  ),

  // 4. One-Hot State Interpreter:
  (
    name: "state [3:0]",
    label: "FSM One-Hot",
    format: "one-hot",         // Displays active bit index (0..3); warns if invalid
  ),

  // 5. Gray Code Interpreter:
  (
    name: "gray_cnt [3:0]",
    format: "gray",            // Converts Gray code to decimal value
  ),

  // 6. Enum / State Name Mapping:
  (
    name: "fsm [1:0]",
    format: (0: "IDLE", 1: "FETCH", 2: "DECODE", 3: "EXEC"),
  ),

  // 7. Standard number formats:
  // "hex" | "hex-raw" | "dec" | "bin" | "octal" | "ascii" | "bool" | "raw" | function
  (
    name: "data [7:0]",
    label: "DATA BUS",
    color: rgb("1d4ed8"),
    bus-stroke: rgb("1d4ed8"),
    bus-fill: rgb("e0f2fe"),
    format: "hex",
    is-bus: true,
  ),

  // 8. Section divider / header:
  (
    type: "divider",
    label: "Memory Control Signals",
  ),
)
```

---

## Warning System

*signel* includes an integrated warning and diagnostics system:
- **Missing Signal**: If a signal query does not match any signal in the VCD, a prominent warning track replaces the signal row, listing all available signal names from the simulation.
- **Index Out of Bounds**: If a bit slice index exceeds the signal's declared `[msb:lsb]` range (e.g. `count[8]` on a 4-bit counter), a warning banner displays the valid range.
- **Invalid Encoding**: If an interpreter receives a pattern that does not match any valid digit (such as an illegal 7-segment display code or a one-hot vector with multiple/zero active bits), the affected segment is highlighted in warning red (`⚠️ ?` or `⚠️ ERR`), and the error is logged.
- **Strict Mode (`strict: true`)**: When enabled, any missing signal, out-of-bounds slice, or encoding error triggers a Typst compilation `panic`, making it ideal for CI and verification tests.


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

---

## Utility & Interpreter Functions

### `decode-7segment(bin-val, active: "auto", order: "g-to-a")`

Decodes a 7-segment display vector (7-bit or 8-bit with DP) into a hexadecimal digit character (`0`--`F`, `-`, or blank).
- **`active`**: `"low"` (common anode, 0=ON), `"high"` (common cathode, 1=ON), or `"auto"` (auto-detects).
- **`order`**: `"g-to-a"` (bit 6 = g, bit 0 = a, default) or `"a-to-g"` (bit 6 = a, bit 0 = g).
- **Returns**: `(val: str, ok: bool, error: none | str)`. If invalid, `ok` is `false`.

### `bin-to-signed(bin-str)`

Decodes a two's complement binary string to a signed decimal string (e.g. `"1111"` -> `"-1"`, `"0111"` -> `"7"`).
- **Returns**: `(val: str, ok: bool, error: none | str)`.

### `decode-one-hot(bin-str)`

Decodes a one-hot binary string into the integer index of the active bit (e.g. `"0001"` -> `"0"`, `"0010"` -> `"1"`).
- **Returns**: `(val: str, ok: bool, error: none | str)`. If multiple bits or zero bits are active, returns `ok: false`.

### `gray-to-bin(bin-str)`

Converts a Gray code binary string to standard binary and integer decimal value.
- **Returns**: `(val: str, bin: str, ok: bool, error: none | str)`.

### `bin-to-oct(bin-str, prefix: "0o")`

Converts a binary string to octal format with optional prefix.

### `resolve-signal(parsed, query)`

Finds a signal in parsed data or dynamically slices a single bit or range.
- Matches exact names (`"clk"`), base names (`"sw"` for `"sw [1:0]"`), normalized names (`"sw[1:0]"` for `"sw [1:0]"`), scoped names (`"top.sw[0]"`), and slices (`"count[0]"`, `"data[7:4]"`).
- **Returns**: `(signal: dictionary | none, warning: str | none)`.

