# `signel` Styling & Theming Guide

This guide covers all styling options available in `signel`, from pre-built color themes to bus formatting, timing markers, and custom layouts.

---

## 1. Built-in Themes

`signel` comes with 7 built-in themes for diverse use cases:

| Theme Name | Access | Purpose / Appearance |
|---|---|---|
| **Default** | `themes.default` | Modern engineering palette with blue signals and cyan buses |
| **Dark** | `themes.dark` | Cyberpunk / dark-mode EDA oscilloscope style with dark slate background |
| **Academic** | `themes.academic` | Black-and-white, print-ready monochrome design for papers and theses |
| **Nord** | `themes.nord` | Arctic cool palette inspired by the Nord design system |
| **Dracula** | `themes.dracula` | Vibrant dark theme with purple, pink, and cyan accents |
| **Emerald** | `themes.emerald` | Fresh forest green and mint tones |
| **Amber** | `themes.amber` | Retro amber phosphor CRT display aesthetic |

### Applying a Theme

```typst
#import "@local/signel:0.1.0": render-vcd, themes

#render-vcd(
  read("sim.vcd"),
  theme: themes.dark,
)
```

---

## 2. Building Custom Themes (`vcd-theme`)

Use the `vcd-theme` helper to override specific theme properties while inheriting defaults:

```typst
#import "@local/signel:0.1.0": render-vcd, themes, vcd-theme

#let custom-theme = vcd-theme(
  base: themes.default,
  background: rgb("f8fafc"),
  signal-color: rgb("0284c7"),
  clock-color: rgb("9333ea"),
  bus-stroke: rgb("0284c7"),
  bus-fill: rgb("e0f2fe"),
  bus-text-color: rgb("0369a1"),
  unknown-color: rgb("ef4444"),
  unknown-fill: rgb("fee2e2"),
  high-z-color: rgb("94a3b8"),
  grid-color: rgb("cbd5e1"),
  ruler-color: rgb("475569"),
  stroke-width: 1.5pt,
  font-size: 8pt,
)

#render-vcd(read("sim.vcd"), theme: custom-theme)
```

---

## 3. Bus Value Formatting

For multi-bit signals, `signel` draws hexagonal beveled envelopes and places formatted labels inside each segment. You can choose from built-in formats or supply a custom callback function:

| Format Option | Description | Example Input | Formatted Output |
|---|---|---|---|
| `"hex"` (default) | Hexadecimal with `0x` prefix | `10101011` | `0xAB` |
| `"dec"` or `"decimal"` | Unsigned decimal integer | `10101011` | `171` |
| `"bin"` or `"binary"` | Binary with `b` prefix | `10101011` | `b10101011` |
| `"ascii"` | Decodes 8-bit bytes to ASCII characters | `01000001` | `A` |
| `"raw"` | Exact string as recorded in the dump | `10101011` | `10101011` |
| Callback Function | Custom formatting logic | `val => "Reg[" + val + "]"` | `Reg[10101011]` |

### Per-Signal Format Specification

```typst
signals: (
  (name: "addr [15:0]", format: "hex"),
  (name: "data [7:0]", format: "dec"),
  (name: "cmd [7:0]", format: "ascii"),
)
```

---

## 4. Signal Grouping & Dividers

Use `type: "divider"` to insert labeled section headers across the waveform canvas:

```typst
signals: (
  (type: "divider", label: "Clock & Reset"),
  "clk",
  "rst_n",

  (type: "divider", label: "Control Bus"),
  (name: "cs_n", label: "CS#"),
  (name: "we_n", label: "WE#"),

  (type: "divider", label: "Data Path"),
  "data [7:0]",
)
```

---

## 5. Timing Markers & Cursors

### Vertical Markers

Markers pinpoint key clock edges or triggers with a vertical line and a framed badge:

```typst
markers: (
  (time: 15, label: "Reset Released", stroke: 1pt + rgb("16a34a")),
  (time: 45, label: "Transfer Complete", stroke: 1pt + rgb("dc2626")),
)
```

### Shaded Cursors ($\Delta t$)

Cursors highlight a continuous simulation interval with a soft transparent fill and duration text:

```typst
cursors: (
  (
    start: 20,
    end: 60,
    label: "Burst Transfer (40 ns)",
    fill: rgb("3b82f6").transparentize(90%),
  ),
)
```

---

## 6. Time Slicing & Zooming

Use `time-range: (start, end)` to focus on specific portions of a large simulation:

```typst
#render-vcd(
  read("large_simulation.vcd"),
  time-range: (100, 350),   // Zoom in between 100 ns and 350 ns
  time-step: 50,            // Ticks every 50 ns
  time-step-width: 3pt,
)
```

---

## 7. Custom Time Unit Display (`time-unit`)

Some simulators (like GHDL) output traces in very small timescale units such as femtoseconds (`1 fs`), causing timestamps to appear as large numbers like `10000000 fs`.

Use `time-unit` to convert the displayed numbers and axis label to your preferred unit without altering internal simulation times:

```typst
#render-vcd(
  read("wave.vcd"),
  time-unit: "ns",     // Displays 10000000 fs as 10 ns
)
```

Supported units:
- `"fs"` (femtoseconds)
- `"ps"` (picoseconds)
- `"ns"` (nanoseconds)
- `"us"` or `"µs"` (microseconds)
- `"ms"` (milliseconds)
- `"s"` or `"sec"` (seconds)
- `"min"` (minutes)
- `"h"` (hours)
