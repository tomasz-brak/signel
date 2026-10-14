#import "@local/signel:0.1.0": render-vcd, themes, vcd-theme

#set page(width: auto, height: auto, margin: 1.5cm)

= IEEE Std 1364-2001 Extended VCD (EVCD) Demo

Extended VCD files generated with `$dumpports` record port directionality and driver source strengths in addition to logic values.

This example renders `sample_ports.evcd` showing:
- Input port signals driven by test fixture (`req_in`).
- Output port signals driven by the Device Under Test (`ack_out`).
- Bidirectional 4-bit port (`data_io [3:0]`).

#render-vcd(
  read("sample_ports.evcd"),
  title: "EVCD Port Activity & Directionality ($dumpports)",
  signals: (
    (name: "clk", label: "CLK (in)"),
    (name: "req_in", label: "REQ (in)", color: rgb("0284c7")),
    (name: "ack_out", label: "ACK (out)", color: rgb("16a34a")),
    (name: "data_io [3:0]", label: "DATA [3:0] (bidir)", format: "hex"),
  ),
  time-step-width: 4pt,
  signal-height: 19pt,
  signal-gap: 10pt,
  label-width: 120pt,
  theme: themes.default,
  markers: (
    (time: 20, label: "Req Asserted", stroke: 1pt + rgb("0284c7")),
    (time: 30, label: "Ack Handshake", stroke: 1pt + rgb("16a34a")),
  ),
)
