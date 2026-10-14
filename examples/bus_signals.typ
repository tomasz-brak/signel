#import "@local/signel:0.1.0": render-vcd, themes, vcd-theme

#set page(width: auto, height: auto, margin: 1.5cm)

= CPU Memory Bus Transaction

This example demonstrates memory read and write bus cycles from `sample_cpu_bus.vcd`, showing:
- Multi-bit address (`16-bit`) and data (`8-bit`) buses.
- High-impedance (`Z`) states between bus transfers.
- Vertical timing markers and shaded cursor intervals ($t_"read"$, $t_"write"$).
- Custom signal grouping with dividers.

#let custom-theme = vcd-theme(
  base: themes.default,
  bus-fill: rgb("e0f2fe"),
  bus-stroke: rgb("0284c7"),
  signal-color: rgb("1d4ed8"),
  clock-color: rgb("7c3aed"),
)

#render-vcd(
  read("sample_cpu_bus.vcd"),
  title: "Microprocessor Memory Bus Timing",
  signals: (
    (type: "divider", label: "Clock & Status"),
    "clk",
    (name: "ready", label: "READY"),
    (type: "divider", label: "Control Bus"),
    (name: "cs_n", label: "CS#", color: rgb("dc2626")),
    (name: "we_n", label: "WE#", color: rgb("ea580c")),
    (type: "divider", label: "Address & Data Buses"),
    (name: "addr [15:0]", label: "ADDR [15:0]", format: "hex"),
    (name: "data [7:0]", label: "DATA [7:0]", format: "hex", bus-fill: rgb("fef08a")),
  ),
  markers: (
    (time: 10, label: "Read Start", stroke: 1pt + rgb("2563eb")),
    (time: 40, label: "Write Start", stroke: 1pt + rgb("dc2626")),
  ),
  cursors: (
    (start: 10, end: 30, label: "Read Cycle (200 ns)", fill: rgb("3b82f6").transparentize(90%)),
    (start: 40, end: 60, label: "Write Cycle (200 ns)", fill: rgb("ef4444").transparentize(90%)),
  ),
  time-step-width: 6pt,
  signal-height: 19pt,
  signal-gap: 8pt,
  label-width: 95pt,
  theme: custom-theme,
)
