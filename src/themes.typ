// src/themes.typ
// Custom styling themes for signel waveform renderer

#let theme-default = (
  name: "default",
  background: none,
  text-color: rgb("1e293b"),
  signal-color: rgb("2563eb"),
  clock-color: rgb("0284c7"),
  bus-stroke: rgb("0284c7"),
  bus-fill: rgb("f0f9ff"),
  bus-text-color: rgb("0369a1"),
  unknown-color: rgb("ef4444"),
  unknown-fill: rgb("fee2e2"),
  high-z-color: rgb("94a3b8"),
  grid-color: rgb("e2e8f0"),
  ruler-color: rgb("64748b"),
  marker-color: rgb("dc2626"),
  divider-color: rgb("cbd5e1"),
  divider-fill: rgb("f8fafc"),
  stroke-width: 1.2pt,
  font: (),
  font-size: 8pt,
  time-font-size: 7.5pt,
)

#let theme-dark = (
  name: "dark",
  background: rgb("0f172a"),
  text-color: rgb("f8fafc"),
  signal-color: rgb("38bdf8"),
  clock-color: rgb("c084fc"),
  bus-stroke: rgb("38bdf8"),
  bus-fill: rgb("1e293b"),
  bus-text-color: rgb("7dd3fc"),
  unknown-color: rgb("f87171"),
  unknown-fill: rgb("450a0a"),
  high-z-color: rgb("64748b"),
  grid-color: rgb("334155"),
  ruler-color: rgb("94a3b8"),
  marker-color: rgb("f43f5e"),
  divider-color: rgb("475569"),
  divider-fill: rgb("1e293b"),
  stroke-width: 1.2pt,
  font: (),
  font-size: 8pt,
  time-font-size: 7.5pt,
)

#let theme-academic = (
  name: "academic",
  background: none,
  text-color: black,
  signal-color: black,
  clock-color: black,
  bus-stroke: black,
  bus-fill: rgb("f3f4f6"),
  bus-text-color: black,
  unknown-color: rgb("4b5563"),
  unknown-fill: rgb("e5e7eb"),
  high-z-color: rgb("6b7280"),
  grid-color: rgb("e5e7eb"),
  ruler-color: rgb("374151"),
  marker-color: rgb("1f2937"),
  divider-color: rgb("d1d5db"),
  divider-fill: rgb("f9fafb"),
  stroke-width: 1pt,
  font: (),
  font-size: 8pt,
  time-font-size: 7pt,
)

#let theme-nord = (
  name: "nord",
  background: rgb("2e3440"),
  text-color: rgb("eceff4"),
  signal-color: rgb("88c0d0"),
  clock-color: rgb("81a1c1"),
  bus-stroke: rgb("88c0d0"),
  bus-fill: rgb("3b4252"),
  bus-text-color: rgb("eceff4"),
  unknown-color: rgb("bf616a"),
  unknown-fill: rgb("4c566a"),
  high-z-color: rgb("d8dee9"),
  grid-color: rgb("434c5e"),
  ruler-color: rgb("d8dee9"),
  marker-color: rgb("ebcb8b"),
  divider-color: rgb("4c566a"),
  divider-fill: rgb("3b4252"),
  stroke-width: 1.2pt,
  font: (),
  font-size: 8pt,
  time-font-size: 7.5pt,
)

#let theme-dracula = (
  name: "dracula",
  background: rgb("282a36"),
  text-color: rgb("f8f8f2"),
  signal-color: rgb("50fa7b"),
  clock-color: rgb("bd93f9"),
  bus-stroke: rgb("8be9fd"),
  bus-fill: rgb("44475a"),
  bus-text-color: rgb("f8f8f2"),
  unknown-color: rgb("ff5555"),
  unknown-fill: rgb("6272a4"),
  high-z-color: rgb("6272a4"),
  grid-color: rgb("44475a"),
  ruler-color: rgb("f1fa8c"),
  marker-color: rgb("ff79c6"),
  divider-color: rgb("6272a4"),
  divider-fill: rgb("44475a"),
  stroke-width: 1.2pt,
  font: (),
  font-size: 8pt,
  time-font-size: 7.5pt,
)

#let theme-emerald = (
  name: "emerald",
  background: none,
  text-color: rgb("064e3b"),
  signal-color: rgb("059669"),
  clock-color: rgb("047857"),
  bus-stroke: rgb("059669"),
  bus-fill: rgb("ecfdf5"),
  bus-text-color: rgb("065f46"),
  unknown-color: rgb("dc2626"),
  unknown-fill: rgb("fee2e2"),
  high-z-color: rgb("9ca3af"),
  grid-color: rgb("d1fae5"),
  ruler-color: rgb("047857"),
  marker-color: rgb("b91c1c"),
  divider-color: rgb("a7f3d0"),
  divider-fill: rgb("f0fdf4"),
  stroke-width: 1.2pt,
  font: (),
  font-size: 8pt,
  time-font-size: 7.5pt,
)

#let theme-amber = (
  name: "amber",
  background: rgb("18181b"),
  text-color: rgb("fef3c7"),
  signal-color: rgb("f59e0b"),
  clock-color: rgb("fbbf24"),
  bus-stroke: rgb("f59e0b"),
  bus-fill: rgb("27272a"),
  bus-text-color: rgb("fde68a"),
  unknown-color: rgb("ef4444"),
  unknown-fill: rgb("450a0a"),
  high-z-color: rgb("71717a"),
  grid-color: rgb("3f3f46"),
  ruler-color: rgb("fbbf24"),
  marker-color: rgb("f87171"),
  divider-color: rgb("52525b"),
  divider-fill: rgb("27272a"),
  stroke-width: 1.2pt,
  font: (),
  font-size: 8pt,
  time-font-size: 7.5pt,
)

#let themes = (
  default: theme-default,
  dark: theme-dark,
  academic: theme-academic,
  nord: theme-nord,
  dracula: theme-dracula,
  emerald: theme-emerald,
  amber: theme-amber,
)

/// Helper to customize or extend a theme
#let vcd-theme(
  base: theme-default,
  background: auto,
  text-color: auto,
  signal-color: auto,
  clock-color: auto,
  bus-stroke: auto,
  bus-fill: auto,
  bus-text-color: auto,
  unknown-color: auto,
  unknown-fill: auto,
  high-z-color: auto,
  grid-color: auto,
  ruler-color: auto,
  marker-color: auto,
  divider-color: auto,
  divider-fill: auto,
  stroke-width: auto,
  font: auto,
  font-size: auto,
  time-font-size: auto,
) = {
  let res = base
  if background != auto { res.background = background }
  if text-color != auto { res.text-color = text-color }
  if signal-color != auto { res.signal-color = signal-color }
  if clock-color != auto { res.clock-color = clock-color }
  if bus-stroke != auto { res.bus-stroke = bus-stroke }
  if bus-fill != auto { res.bus-fill = bus-fill }
  if bus-text-color != auto { res.bus-text-color = bus-text-color }
  if unknown-color != auto { res.unknown-color = unknown-color }
  if unknown-fill != auto { res.unknown-fill = unknown-fill }
  if high-z-color != auto { res.high-z-color = high-z-color }
  if grid-color != auto { res.grid-color = grid-color }
  if ruler-color != auto { res.ruler-color = ruler-color }
  if marker-color != auto { res.marker-color = marker-color }
  if divider-color != auto { res.divider-color = divider-color }
  if divider-fill != auto { res.divider-fill = divider-fill }
  if stroke-width != auto { res.stroke-width = stroke-width }
  if font != auto { res.font = font }
  if font-size != auto { res.font-size = font-size }
  if time-font-size != auto { res.time-font-size = time-font-size }
  return res
}
