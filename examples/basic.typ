#import "@local/signel:0.1.0": render-vcd, themes

#set page(width: auto, height: auto, margin: 1.5cm)

= Basic Waveform Example

This example demonstrates embedding a standard IEEE Std 1364-2001 VCD simulation waveform of a 4-bit synchronous counter directly into a Typst document.

#render-vcd(
  read("sample_counter.vcd"),
  title: "4-Bit Synchronous Counter Timing Diagram",
  time-step-width: 3.5pt,
  signal-height: 18pt,
  signal-gap: 10pt,
  label-width: 80pt,
)
