#import "@local/signel:0.1.0": render-vcd, themes, vcd-theme

#set page(width: auto, height: auto, margin: 1.5cm)

= Custom Styling Showcase

`signel` supports complete styling flexibility, including pre-built themes, custom palettes, time slicing, and signal-level customizations.

== 1. Dark EDA Theme (`themes.dark`)

#render-vcd(
  read("sample_counter.vcd"),
  title: "Dark Mode Oscilloscope View",
  theme: themes.dark,
  time-step-width: 4pt,
  signal-height: 18pt,
  signal-gap: 8pt,
  label-width: 80pt,
)

#v(1cm)

== 2. Academic / Publication Theme (`themes.academic`) with Time Slicing

Optimized for academic publications (IEEE transactions, ACM, thesis) with monochrome print-ready lines and time-range zoom $[15, 65]$.

#render-vcd(
  read("sample_counter.vcd"),
  title: "Synchronous Counter Waveform (Time Zoom: 15 ns to 65 ns)",
  time-range: (15, 65),
  theme: themes.academic,
  time-step: 10,
  time-step-width: 6pt,
  signal-height: 16pt,
  signal-gap: 8pt,
  label-width: 75pt,
  markers: (
    (time: 25, label: "Count Enabled", stroke: 1pt + black),
    (time: 65, label: "Count Disabled", stroke: 1pt + black),
  ),
  cursors: (
    (start: 25, end: 65, label: "Active Counting Window (40 ns)", fill: rgb("000000").transparentize(94%)),
  ),
)

#v(1cm)

== 3. Nord Theme (`themes.nord`) with Custom Signal Formats

Nord theme displaying the CPU memory bus, formatting the data bus in decimal (`format: "dec"`), custom divider sections, and custom label colors.

#render-vcd(
  read("sample_cpu_bus.vcd"),
  title: "Nord Palette - CPU Bus Analysis",
  theme: themes.nord,
  time-step-width: 5pt,
  signals: (
    (type: "divider", label: "Control Lines"),
    (name: "clk", label: "CLK"),
    (name: "cs_n", label: "CS#", color: rgb("88c0d0")),
    (name: "we_n", label: "WE#", color: rgb("bf616a")),
    (type: "divider", label: "Buses"),
    (name: "addr [15:0]", label: "ADDR (hex)", format: "hex"),
    (name: "data [7:0]", label: "DATA (dec)", format: "dec", color: rgb("a3be8c"), bus-fill: rgb("4c566a")),
  ),
  signal-height: 18pt,
  label-width: 90pt,
)
