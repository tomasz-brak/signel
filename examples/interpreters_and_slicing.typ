#import "@local/signel:0.1.1": render-vcd, themes

#set page(width: auto, height: auto, margin: 1.5cm)

= Signal Slicing, Interpreters & Warning System

This example demonstrates the advanced signal slicing, data interpreters (including 7-segment display auto-decoding), and warning indicators in *signel*.

== 1. Bit Slicing: Single Bits and Sub-Bus Ranges

In standard VCD files, signals like `count [3:0]` are declared as multi-bit vectors. *signel* allows you to slice individual bits (`count[0]`, `count[1]`, etc.) to view them as 1-bit digital waveforms, or extract sub-bus slices (`count[3:2]`) as buses without modifying the simulation source.

#render-vcd(
  read("sample_counter.vcd"),
  title: "Synchronous Counter — Bit Slicing Demo",
  signals: (
    "clk",
    "rst_n",
    "en",
    (name: "count[0]", label: "count[0] (LSB)"),
    (name: "count[1]", label: "count[1]"),
    (name: "count[3:2]", label: "count[3:2] (Upper 2 bits)", format: "hex"),
    (name: "count[3:0]", label: "count[3:0] (Full Bus)", format: "dec"),
  ),
  time-step-width: 3.5pt,
  theme: themes.academic,
)

#v(1cm)

== 2. 7-Segment Display Auto-Decoding & Interpreters

When designing FPGA or digital circuits driving 7-segment displays (such as on Altera/Intel DE-series or Xilinx boards), signals represent segment activations ($a, b, c, d, e, f, g$).
*signel* includes dedicated interpreters that decode active-low or active-high 7-segment patterns into readable hex characters (`0`--`F`). If an invalid pattern is encountered, *signel* highlights the error in the waveform and logs a warning!

#let demo-vcd = "$date Wed Oct 14 $end
$version signel demo $end
$timescale 1ns $end
$scope module tb $end
$var wire 1 ! clk $end
$var wire 7 \" hex_low [6:0] $end
$var wire 7 # hex_high [6:0] $end
$var wire 4 $ signed_data [3:0] $end
$var wire 4 % one_hot [3:0] $end
$upscope $end
$enddefinitions $end
#0
0!
b1000000 \"
b0111111 #
b0000 $
b0001 %
#10
1!
b1111001 \"
b0000110 #
b0111 $
b0010 %
#20
0!
b0100100 \"
b1011011 #
b1111 $
b0100 %
#30
1!
b0011001 \"
b1100110 #
b1000 $
b1000 %
#40
0!
b1010101 \"
b1110001 #
b1101 $
b0011 %
#50
1!
b0000000 \"
b1111111 #
b0010 $
b0000 %
#60
0!
"

#render-vcd(
  demo-vcd,
  title: "Interpreters Demo: 7-Segment, Signed 2's Complement & One-Hot",
  signals: (
    "clk",
    (name: "hex_low", label: "HEX Low (0=ON)", format: "7segment-low"),
    (name: "hex_high", label: "HEX High (1=ON)", format: "7segment-high"),
    (name: "signed_data", label: "Signed ALU Out", format: "signed"),
    (name: "one_hot", label: "One-Hot State", format: "one-hot"),
  ),
  time-step-width: 4.5pt,
  theme: themes.default,
  show-warnings: true,
)

#v(1cm)

== 3. Robust Error Reporting & Missing Signal Warnings

If a signal cannot be found or if an index is out of bounds, *signel* produces an in-place visual warning banner with the list of available signals, without crashing your document build. You can also enforce strict verification with `strict: true`.

#render-vcd(
  demo-vcd,
  title: "Waveform with Signal Warnings",
  signals: (
    "clk",
    (name: "one_hot", label: "One-Hot Valid"),
    "missing_sensor_bus",
    "signed_data[8]",
  ),
  time-step-width: 4.5pt,
  theme: themes.nord,
  show-warnings: true,
  strict: false,
)
