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

/// Convert a binary string to an octal string.
#let bin-to-oct(bin-str, prefix: "0o") = {
  if bin-str == none or bin-str == "" { return "" }
  let s = str(bin-str).trim()
  if s.starts-with("b") or s.starts-with("B") { s = s.slice(1) }
  if s == "" { return prefix + "0" }
  if s.replace("z", "").replace("Z", "") == "" { return "Z" }
  if s.replace("x", "").replace("X", "") == "" { return "X" }
  let rem = calc.rem(s.len(), 3)
  if rem != 0 {
    s = "0" * (3 - rem) + s
  }
  let oct-table = (
    "000": "0", "001": "1", "010": "2", "011": "3",
    "100": "4", "101": "5", "110": "6", "111": "7"
  )
  let res = ""
  let i = 0
  while i < s.len() {
    let chunk = s.slice(i, i + 3)
    if chunk in oct-table {
      res += oct-table.at(chunk)
    } else if "x" in chunk or "X" in chunk {
      res += "X"
    } else if "z" in chunk or "Z" in chunk {
      res += "Z"
    } else {
      res += "?"
    }
    i += 3
  }
  while res.len() > 1 and res.starts-with("0") {
    res = res.slice(1)
  }
  return prefix + res
}

/// Convert binary string to signed decimal (two's complement).
#let bin-to-signed(bin-str) = {
  let s = str(bin-str).trim()
  if s.starts-with("b") or s.starts-with("B") { s = s.slice(1) }
  if s == "" { return (val: "0", ok: true, error: none) }
  if "x" in s or "X" in s { return (val: "X", ok: true, error: none) }
  if "z" in s or "Z" in s { return (val: "Z", ok: true, error: none) }

  let n = s.len()
  let msb = s.at(0)
  let unsigned-val = 0
  for ch in s {
    unsigned-val = unsigned-val * 2 + (if ch == "1" { 1 } else { 0 })
  }

  if msb == "1" {
    let mod = calc.pow(2, n)
    let diff = mod - unsigned-val
    return (val: "-" + str(diff), ok: true, error: none)
  }
  return (val: str(unsigned-val), ok: true, error: none)
}

/// Decode a one-hot binary vector to integer index.
/// Flags an error if not strictly one-hot (multiple bits or zero bits set).
#let decode-one-hot(bin-str) = {
  let s = str(bin-str).trim()
  if s.starts-with("b") or s.starts-with("B") { s = s.slice(1) }
  if "x" in s or "X" in s { return (val: "X", ok: true, error: none) }
  if "z" in s or "Z" in s { return (val: "Z", ok: true, error: none) }

  let ones-indices = ()
  let n = s.len()
  for i in range(n) {
    let ch = s.at(i)
    if ch == "1" {
      ones-indices.push(n - 1 - i)
    } else if ch != "0" {
      return (val: "X", ok: true, error: none)
    }
  }

  if ones-indices.len() == 1 {
    return (val: str(ones-indices.at(0)), ok: true, error: none)
  } else if ones-indices.len() == 0 {
    return (val: "NONE", ok: false, error: "One-hot vector has no active bits: " + s)
  } else {
    return (val: "ERR", ok: false, error: "Multiple active bits in one-hot vector: " + s)
  }
}

/// Convert Gray code to standard binary string and decimal integer value.
#let gray-to-bin(bin-str) = {
  let s = str(bin-str).trim()
  if s.starts-with("b") or s.starts-with("B") { s = s.slice(1) }
  if "x" in s or "X" in s { return (val: "X", bin: "X", ok: true, error: none) }
  if "z" in s or "Z" in s { return (val: "Z", bin: "Z", ok: true, error: none) }

  let b = ""
  let last = 0
  for i in range(s.len()) {
    let g = if s.at(i) == "1" { 1 } else { 0 }
    let bit = if i == 0 { g } else { calc.rem(last + g, 2) }
    b += str(bit)
    last = bit
  }
  let dec = bin-to-dec(b)
  return (val: dec, bin: b, ok: true, error: none)
}

// Active-high 7-segment patterns (g f e d c b a)
#let seg7-active-high-map = (
  "63": "0",   // 0x3F
  "6": "1",    // 0x06
  "91": "2",   // 0x5B
  "79": "3",   // 0x4F
  "102": "4",  // 0x66
  "109": "5",  // 0x6D
  "125": "6",  // 0x7D
  "7": "7",    // 0x07
  "39": "7",   // 0x27 (with f)
  "127": "8",  // 0x7F
  "111": "9",  // 0x6F
  "103": "9",  // 0x67 (without d)
  "119": "A",  // 0x77
  "124": "b",  // 0x7C
  "57": "C",   // 0x39
  "88": "c",   // 0x58
  "94": "d",   // 0x5E
  "121": "E",  // 0x79
  "113": "F",  // 0x71
  "64": "-",   // 0x40
  "0": " ",    // 0x00 (blank)
  "99": "°",   // 0x63
  "92": "o",   // 0x5C
  "116": "h",  // 0x74
  "118": "H",  // 0x76
  "80": "r",   // 0x50
  "28": "u",   // 0x1C
  "62": "U",   // 0x3E
)

// Active-low 7-segment patterns (0 = ON, 1 = OFF, ~val & 0x7F)
#let seg7-active-low-map = (
  "64": "0",   // 0x40
  "121": "1",  // 0x79
  "36": "2",   // 0x24
  "48": "3",   // 0x30
  "25": "4",   // 0x19
  "18": "5",   // 0x12
  "2": "6",    // 0x02
  "120": "7",  // 0x78
  "88": "7",   // 0x58 (with f)
  "0": "8",    // 0x00
  "16": "9",   // 0x10
  "24": "9",   // 0x18 (without d)
  "8": "A",    // 0x08
  "3": "b",    // 0x03
  "70": "C",   // 0x46
  "39": "c",   // 0x27
  "33": "d",   // 0x21
  "6": "E",    // 0x06
  "14": "F",   // 0x0E
  "63": "-",   // 0x3F
  "127": " ",  // 0x7F (blank)
  "28": "°",   // 0x1C
  "35": "o",   // 0x23
  "11": "h",   // 0x0B
  "9": "H",    // 0x09
  "47": "r",   // 0x2F
  "99": "u",   // 0x63
  "65": "U",   // 0x41
)

#let reverse-7bits(n) = {
  let res = 0
  let temp = n
  for i in range(7) {
    res = res * 2 + calc.rem(temp, 2)
    temp = calc.floor(temp / 2)
  }
  return res
}

/// Decode a binary or integer value representing a 7-segment display.
/// active: "low" | "high" | "auto"
/// order: "g-to-a" | "a-to-g"
#let decode-7segment(bin-val, active: "auto", order: "g-to-a") = {
  if bin-val == none or bin-val == "" {
    return (val: "", ok: true, error: none)
  }
  let s = str(bin-val).trim()
  if s.starts-with("b") or s.starts-with("B") {
    s = s.slice(1)
  }
  if "x" in s or "X" in s { return (val: "X", ok: true, error: none) }
  if "z" in s or "Z" in s { return (val: "Z", ok: true, error: none) }

  let int-val = 0
  for ch in s {
    int-val = int-val * 2 + (if ch == "1" { 1 } else { 0 })
  }

  let has-dp = false
  let seg-val = int-val
  if s.len() >= 8 {
    let dp-bit = calc.rem(calc.floor(int-val / 128), 2)
    seg-val = calc.rem(int-val, 128)
    if (active == "low" or active == "auto") and dp-bit == 0 {
      has-dp = true
    } else if (active == "high" or active == "auto") and dp-bit == 1 {
      has-dp = true
    }
  } else {
    seg-val = calc.rem(int-val, 128)
  }

  if order == "a-to-g" {
    seg-val = reverse-7bits(seg-val)
  }

  let dp-suffix = if has-dp { "." } else { "" }
  let seg-key = str(seg-val)

  if active == "low" {
    if seg-key in seg7-active-low-map {
      return (val: seg7-active-low-map.at(seg-key) + dp-suffix, ok: true, error: none)
    }
    return (
      val: "?",
      ok: false,
      error: "Invalid active-low 7-segment pattern: " + s + " (" + bin-to-hex(s) + ")"
    )
  } else if active == "high" {
    if seg-key in seg7-active-high-map {
      return (val: seg7-active-high-map.at(seg-key) + dp-suffix, ok: true, error: none)
    }
    return (
      val: "?",
      ok: false,
      error: "Invalid active-high 7-segment pattern: " + s + " (" + bin-to-hex(s) + ")"
    )
  } else {
    // Auto-detect: first try active-low (prevalent on FPGA demo boards like DE10-Lite), then active-high
    if seg-key in seg7-active-low-map {
      return (val: seg7-active-low-map.at(seg-key) + dp-suffix, ok: true, error: none)
    }
    if seg-key in seg7-active-high-map {
      return (val: seg7-active-high-map.at(seg-key) + dp-suffix, ok: true, error: none)
    }
    return (
      val: "?",
      ok: false,
      error: "Invalid 7-segment pattern: " + s + " (" + bin-to-hex(s) + ")"
    )
  }
}

/// Interpret and decode a bus value according to a format/interpreter.
/// Returns (text: str, ok: bool, error: none | str)
#let interpret-bus-val(val, format: "hex") = {
  if type(format) == function {
    let res = format(val)
    return (text: str(res), ok: true, error: none)
  }
  if val == none { return (text: "", ok: true, error: none) }
  let v = str(val).trim()
  if v in ("x", "X") { return (text: "X", ok: true, error: none) }
  if v in ("z", "Z") { return (text: "Z", ok: true, error: none) }

  // Check dictionary format: e.g. (type: "7segment", active: "low") or enum mapping
  if type(format) == dictionary {
    let fmt-type = format.at("type", default: auto)
    if fmt-type == "7segment" or fmt-type == "7seg" {
      let active = format.at("active", default: "auto")
      let order = format.at("order", default: "g-to-a")
      let dec = decode-7segment(v, active: active, order: order)
      return (text: dec.val, ok: dec.ok, error: dec.error)
    } else if fmt-type == "enum" {
      let m = format.at("map", default: (:))
      let int-v = bin-to-dec(v)
      if int-v in m {
        return (text: str(m.at(int-v)), ok: true, error: none)
      } else if int(int-v) != none and int(int-v) in m {
        return (text: str(m.at(int(int-v))), ok: true, error: none)
      } else if v in m {
        return (text: str(m.at(v)), ok: true, error: none)
      }
      return (text: "?" + v, ok: false, error: "Value " + v + " (" + int-v + ") not in enum mapping")
    } else {
      // Direct enum mapping dictionary: e.g. (0: "IDLE", 1: "ACTIVE")
      let int-v = bin-to-dec(v)
      if int-v in format {
        return (text: str(format.at(int-v)), ok: true, error: none)
      } else if int(int-v) != none and int(int-v) in format {
        return (text: str(format.at(int(int-v))), ok: true, error: none)
      } else if v in format {
        return (text: str(format.at(v)), ok: true, error: none)
      }
      return (text: "?" + v, ok: false, error: "Value " + v + " (" + int-v + ") not in dictionary mapping")
    }
  }

  let f = lower(str(format))
  if f == "hex" {
    return (text: bin-to-hex(v), ok: true, error: none)
  } else if f == "hex-raw" or f == "hex-plain" {
    return (text: bin-to-hex(v, prefix: ""), ok: true, error: none)
  } else if f in ("dec", "decimal", "unsigned") {
    return (text: bin-to-dec(v), ok: true, error: none)
  } else if f in ("bin", "binary") {
    let s = if not (v.starts-with("b") or v.starts-with("B")) { "b" + v } else { v }
    return (text: s, ok: true, error: none)
  } else if f in ("oct", "octal") {
    return (text: bin-to-oct(v), ok: true, error: none)
  } else if f == "ascii" {
    return (text: bin-to-ascii(v), ok: true, error: none)
  } else if f in ("signed", "twos-complement", "2s-complement") {
    let res = bin-to-signed(v)
    return (text: res.val, ok: res.ok, error: res.error)
  } else if f in ("one-hot", "onehot") {
    let res = decode-one-hot(v)
    return (text: res.val, ok: res.ok, error: res.error)
  } else if f in ("gray", "gray-code") {
    let res = gray-to-bin(v)
    return (text: res.val, ok: res.ok, error: res.error)
  } else if f in ("7segment", "7seg") {
    let res = decode-7segment(v, active: "auto")
    return (text: res.val, ok: res.ok, error: res.error)
  } else if f in ("7segment-low", "7seg-low", "7segment-active-low", "7seg-active-low") {
    let res = decode-7segment(v, active: "low")
    return (text: res.val, ok: res.ok, error: res.error)
  } else if f in ("7segment-high", "7seg-high", "7segment-active-high", "7seg-active-high") {
    let res = decode-7segment(v, active: "high")
    return (text: res.val, ok: res.ok, error: res.error)
  } else if f in ("bool", "boolean") {
    let clean = v.replace("b", "").replace("B", "")
    if clean == "1" { return (text: "TRUE", ok: true, error: none) }
    if clean == "0" { return (text: "FALSE", ok: true, error: none) }
    return (text: v, ok: true, error: none)
  } else if f == "raw" {
    return (text: v, ok: true, error: none)
  }

  return (text: v, ok: true, error: none)
}

/// Format a bus value according to format string or callback.
#let format-bus-val(val, format: "hex") = {
  return interpret-bus-val(val, format: format).text
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

/// Pad binary string to target-len according to Verilog/VCD zero/sign extension rules
#let pad-binary-str(s, target-len) = {
  let val = str(s).trim()
  if val.starts-with("b") or val.starts-with("B") {
    val = val.slice(1)
  }
  if val.len() >= target-len {
    return val
  }
  let first = if val.len() > 0 { val.at(0) } else { "0" }
  let pad-char = if first in ("x", "X") { "x" } else if first in ("z", "Z") { "z" } else { "0" }
  return pad-char * (target-len - val.len()) + val
}

/// Extract a bit at Verilog index target-idx from binary vector declared with msb and lsb
#let get-bit-at-index(bin-str, msb, lsb, target-idx) = {
  let min-idx = calc.min(msb, lsb)
  let max-idx = calc.max(msb, lsb)
  if target-idx < min-idx or target-idx > max-idx {
    return (val: "x", ok: false, error: "Index " + str(target-idx) + " out of bounds [" + str(msb) + ":" + str(lsb) + "]")
  }
  let total-bits = calc.abs(msb - lsb) + 1
  let padded = pad-binary-str(bin-str, total-bits)
  let char-idx = if msb >= lsb { msb - target-idx } else { target-idx - msb }
  if char-idx >= 0 and char-idx < padded.len() {
    return (val: padded.at(char-idx), ok: true, error: none)
  }
  return (val: "x", ok: false, error: "Char index out of range")
}

/// Extract sub-vector slice [hi:lo] from binary vector declared with msb and lsb
#let get-slice-range(bin-str, msb, lsb, hi, lo) = {
  let min-idx = calc.min(msb, lsb)
  let max-idx = calc.max(msb, lsb)
  if hi < min-idx or hi > max-idx or lo < min-idx or lo > max-idx {
    return (val: "x", ok: false, error: "Slice [" + str(hi) + ":" + str(lo) + "] out of bounds [" + str(msb) + ":" + str(lsb) + "]")
  }
  let total-bits = calc.abs(msb - lsb) + 1
  let padded = pad-binary-str(bin-str, total-bits)
  let res = ""
  let cur = hi
  if hi >= lo {
    while cur >= lo {
      let char-idx = if msb >= lsb { msb - cur } else { cur - msb }
      res += if char-idx < padded.len() { padded.at(char-idx) } else { "x" }
      cur -= 1
    }
  } else {
    while cur <= lo {
      let char-idx = if msb >= lsb { msb - cur } else { cur - msb }
      res += if char-idx < padded.len() { padded.at(char-idx) } else { "x" }
      cur += 1
    }
  }
  return (val: res, ok: true, error: none)
}

/// Normalize signal name by trimming and stripping whitespace around brackets and colons
#let normalize-signal-name(name) = {
  if name == none { return "" }
  let s = str(name).trim()
  return s.replace(regex("\\s*\\[\\s*"), "[").replace(regex("\\s*:\\s*"), ":").replace(regex("\\s*\\]"), "]")
}

/// Parse signal name to separate base name and bit range (e.g. data[7:0] or data [7:0]).
#let parse-signal-name(name) = {
  if name == none {
    return (base: "", msb: 0, lsb: 0, has-range: false, is-range: false, full: "")
  }
  let trimmed = str(name).trim()
  let m = trimmed.match(regex("^(.*?)\\s*\\[\\s*([0-9]+)\\s*:\\s*([0-9]+)\\s*\\]$"))
  if m != none {
    return (
      base: m.captures.at(0).trim(),
      msb: int(m.captures.at(1)),
      lsb: int(m.captures.at(2)),
      has-range: true,
      is-range: true,
      full: trimmed
    )
  }
  let m-single = trimmed.match(regex("^(.*?)\\s*\\[\\s*([0-9]+)\\s*\\]$"))
  if m-single != none {
    let idx = int(m-single.captures.at(1))
    return (
      base: m-single.captures.at(0).trim(),
      msb: idx,
      lsb: idx,
      has-range: true,
      is-range: false,
      full: trimmed
    )
  }
  return (
    base: trimmed,
    msb: 0,
    lsb: 0,
    has-range: false,
    is-range: false,
    full: trimmed
  )
}
