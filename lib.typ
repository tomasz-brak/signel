// lib.typ - signel package entrypoint
// IEEE Std 1364-2001 VCD & EVCD Waveform Embedding for Typst

#import "src/parser.typ": parse-vcd, decode-evcd-char, decode-evcd-value
#import "src/renderer.typ": render-waveform, resolve-signal, find-signal
#import "src/themes.typ": themes, vcd-theme, theme-default, theme-dark, theme-academic, theme-nord, theme-dracula, theme-emerald, theme-amber
#import "src/util.typ": bin-to-hex, bin-to-dec, bin-to-ascii, bin-to-oct, bin-to-signed, decode-one-hot, gray-to-bin, decode-7segment, interpret-bus-val, format-bus-val, parse-timescale, format-time, parse-signal-name, normalize-signal-name, get-bit-at-index, get-slice-range

#let interpreters = (
  seven-segment: decode-7segment,
  "7seg": decode-7segment,
  signed: bin-to-signed,
  one-hot: decode-one-hot,
  octal: bin-to-oct,
  gray: gray-to-bin,
)

/// Render a VCD/EVCD directly from a string with custom options.
#let render-vcd(
  content,
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
  strict: false,
  show-warnings: true,
) = {
  if not (content.contains("$") or content.contains("#")) {
    panic("render-vcd expects VCD content string. In Typst, packages cannot read files from your document directory. Please wrap your file path with read(): #render-vcd(read(\"" + content + "\"))")
  }
  let parsed = parse-vcd(content, evcd-mode: evcd-mode)
  render-waveform(
    parsed,
    signals: signals,
    time-range: time-range,
    time-step: time-step,
    time-step-width: time-step-width,
    width: width,
    signal-height: signal-height,
    signal-gap: signal-gap,
    label-width: label-width,
    label-align: label-align,
    slant: slant,
    theme: theme,
    markers: markers,
    cursors: cursors,
    show-grid: show-grid,
    show-ruler: show-ruler,
    show-timescale: show-timescale,
    title: title,
    evcd-mode: evcd-mode,
    time-unit: time-unit,
    strict: strict,
    show-warnings: show-warnings,
  )
}

/// Helper for rendering a VCD file.
/// Note: Due to Typst's compiler sandbox, packages cannot read files from your document root.
/// Use `#render-vcd(read("path/to/file.vcd"))` instead.
#let render-vcd-file(
  path,
  ..args,
) = {
  panic("In Typst, packages cannot read files from your document root due to compiler sandboxing. Please call read() directly in your document: #render-vcd(read(\"" + path + "\"), ..args)")
}
