// src/util.typ
// Utility functions for signel VCD/EVCD package

/// Convert a binary string to a hexadecimal string.
/// Preserves unknown ('x'/'X') and high-impedance ('z'/'Z') states.
#let bin-to-hex(bin-str, prefix: "0x") = {
  if bin-str == none or bin-str == "" {
    return ""
  }
  let s = bin-str.trim()
  if s.starts-with("b") or s.starts-with("B") {
    s = s.slice(1)
  }
  if s == "" {
    return prefix + "0"
  }
  // Check if entirely unknown or high-z
  if s.replace("z", "").replace("Z", "") == "" { return "Z" }
  if s.replace("x", "").replace("X", "") == "" { return "X" }

  // Pad to multiple of 4
  let rem = calc.rem(s.len(), 4)
  if rem != 0 {
    s = "0" * (4 - rem) + s
  }

  let hex-table = (
    "0000": "0", "0001": "1", "0010": "2", "0011": "3",
    "0100": "4", "0101": "5", "0110": "6", "0111": "7",
    "1000": "8", "1001": "9", "1010": "A", "1011": "B",
    "1100": "C", "1101": "D", "1110": "E", "1111": "F"
  )

  let res = ""
  let i = 0
  let has-x = false
  let has-z = false

  while i < s.len() {
    let nibble = s.slice(i, i + 4)
    if nibble in hex-table {
      res += hex-table.at(nibble)
    } else if "x" in nibble or "X" in nibble {
      res += "X"
      has-x = true
    } else if "z" in nibble or "Z" in nibble {
      res += "Z"
      has-z = true
    } else {
      res += "?"
    }
    i += 4
  }

  // Strip leading zeros if more than 1 digit, but keep at least 1 digit
  let trimmed = res
  while trimmed.len() > 1 and trimmed.starts-with("0") {
    trimmed = trimmed.slice(1)
  }

  return prefix + trimmed
}

/// Convert a binary string to a decimal string.
#let bin-to-dec(bin-str) = {
  let s = bin-str.trim()
  if s.starts-with("b") or s.starts-with("B") {
    s = s.slice(1)
  }
  if s == "" { return "0" }
  if "x" in s or "X" in s { return "X" }
  if "z" in s or "Z" in s { return "Z" }

  let val = 0
  for ch in s {
    val = val * 2
    if ch == "1" {
      val += 1
    } else if ch != "0" {
      return "X"
    }
  }
  return str(val)
}

/// Convert an 8-bit multiple binary string to ASCII characters.
#let bin-to-ascii(bin-str) = {
  let s = bin-str.trim()
  if s.starts-with("b") or s.starts-with("B") {
    s = s.slice(1)
  }
  if "x" in s or "X" in s or "z" in s or "Z" in s {
    return "X"
  }
  let rem = calc.rem(s.len(), 8)
  if rem != 0 {
    s = "0" * (8 - rem) + s
  }
  let res = ""
  let i = 0
  while i < s.len() {
    let byte-str = s.slice(i, i + 8)
    let code = 0
    for ch in byte-str {
      code = code * 2 + (if ch == "1" { 1 } else { 0 })
    }
    if code >= 32 and code <= 126 {
      // Printable ASCII
      res += str.from-unicode(code)
    } else if code == 0 {
      res += "\\0"
    } else {
      res += "."
    }
    i += 8
  }
  return res
}

/// Format a bus value according to format string or callback.
#let format-bus-val(val, format: "hex") = {
  if type(format) == function {
    return format(val)
  }
  if val == none { return "" }
  let v = str(val).trim()
  if v in ("x", "X") { return "X" }
  if v in ("z", "Z") { return "Z" }

  if format == "hex" {
    return bin-to-hex(v)
  } else if format == "dec" or format == "decimal" {
    return bin-to-dec(v)
  } else if format == "bin" or format == "binary" {
    if not (v.starts-with("b") or v.starts-with("B")) {
      return "b" + v
    }
    return v
  } else if format == "ascii" {
    return bin-to-ascii(v)
  } else if format == "raw" {
    return v
  }
  return v
}

/// Parse a timescale string like "1ns", "10 ps", "100us" into a structured dict.
#let parse-timescale(str-val) = {
  if str-val == none or str-val == "" {
    return (number: 1, unit: "ns", factor: 1e-9)
  }
  let clean = str-val.replace(" ", "").trim()
  // Match digits and units
  let m = clean.match(regex("^([0-9]+)\\s*([a-zA-Z]+)$"))
  if m != none {
    let num = int(m.captures.at(0))
    let unit = m.captures.at(1)
    let factor = 1e-9
    if unit == "s" { factor = 1.0 }
    else if unit == "ms" { factor = 1e-3 }
    else if unit == "us" { factor = 1e-6 }
    else if unit == "ns" { factor = 1e-9 }
    else if unit == "ps" { factor = 1e-12 }
    else if unit == "fs" { factor = 1e-15 }
    return (number: num, unit: unit, factor: factor)
  }
  return (number: 1, unit: "ns", factor: 1e-9)
}

#let time-unit-factors = (
  "fs": 1e-15,
  "ps": 1e-12,
  "ns": 1e-9,
  "us": 1e-6,
  "µs": 1e-6,
  "ms": 1e-3,
  "s": 1.0,
  "sec": 1.0,
  "min": 60.0,
  "h": 3600.0,
)

/// Convert simulation timestamp t to target display unit
#let convert-time(t, timescale, target-unit) = {
  if target-unit == auto or target-unit == none {
    return (val: t * timescale.number, unit: timescale.unit)
  }
  let src-factor = time-unit-factors.at(timescale.unit, default: 1e-9) * timescale.number
  let dst-factor = time-unit-factors.at(target-unit, default: 1e-9)
  let val = (t * src-factor) / dst-factor
  return (val: val, unit: target-unit)
}

/// Format numeric time value cleanly (integers or rounded decimals)
#let format-time-val(v) = {
  let rounded = calc.round(v)
  if calc.abs(v - rounded) < 1e-9 {
    return str(int(rounded))
  }
  return str(calc.round(v, digits: 3))
}

/// Format a simulation timestamp with appropriate units.
#let format-time(time-val, timescale: (number: 1, unit: "ns")) = {
  let val = time-val * timescale.number
  return str(val) + " " + timescale.unit
}

/// Parse signal name to separate base name and bit range (e.g. data[7:0]).
#let parse-signal-name(name) = {
  let m = name.match(regex("^(.*?)\\[([0-9]+):([0-9]+)\\]$"))
  if m != none {
    return (
      base: m.captures.at(0),
      msb: int(m.captures.at(1)),
      lsb: int(m.captures.at(2)),
      has-range: true,
      full: name
    )
  }
  let m-single = name.match(regex("^(.*?)\\[([0-9]+)\\]$"))
  if m-single != none {
    let idx = int(m-single.captures.at(1))
    return (
      base: m-single.captures.at(0),
      msb: idx,
      lsb: idx,
      has-range: true,
      full: name
    )
  }
  return (
    base: name,
    msb: 0,
    lsb: 0,
    has-range: false,
    full: name
  )
}
