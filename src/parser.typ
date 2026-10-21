// src/parser.typ
// IEEE Std 1364-2001 VCD & EVCD Parser in pure Typst

#import "util.typ": parse-timescale, parse-signal-name

// EVCD character tables according to IEEE Std 1364-2001
#let evcd-chars = "DUNZduLHXTlh01?FAaBbCcf"
#let evcd-input-map = (
  "D": "0", "U": "1", "N": "x", "Z": "z", "d": "0", "u": "1",
  "L": "z", "H": "z", "X": "z", "T": "z", "l": "z", "h": "z",
  "0": "0", "1": "1", "?": "x", "F": "x", "A": "0", "a": "0",
  "B": "1", "b": "1", "C": "x", "c": "x", "f": "z"
)
#let evcd-output-map = (
  "D": "z", "U": "z", "N": "z", "Z": "z", "d": "z", "u": "z",
  "L": "0", "H": "1", "X": "x", "T": "z", "l": "0", "h": "1",
  "0": "0", "1": "1", "?": "x", "F": "1", "A": "x", "a": "0",
  "B": "x", "b": "0", "C": "0", "c": "1", "f": "z"
)
#let evcd-composite-map = (
  "D": "0", "U": "1", "N": "x", "Z": "z", "d": "0", "u": "1",
  "L": "0", "H": "1", "X": "x", "T": "z", "l": "0", "h": "1",
  "0": "0", "1": "1", "?": "x", "F": "x", "A": "0", "a": "0",
  "B": "1", "b": "1", "C": "x", "c": "x", "f": "z"
)
#let evcd-direction-map = (
  "D": "IN", "U": "IN", "N": "IN", "Z": "HI-Z", "d": "IN", "u": "IN",
  "L": "OUT", "H": "OUT", "X": "OUT", "T": "HI-Z", "l": "OUT", "h": "OUT",
  "0": "PORT", "1": "PORT", "?": "PORT", "F": "PORT", "A": "PORT", "a": "PORT",
  "B": "PORT", "b": "PORT", "C": "PORT", "c": "PORT", "f": "HI-Z"
)

/// Resolve EVCD multi-character string to logic value.
#let decode-evcd-char(ch, mode: "composite") = {
  if mode == "input" {
    return evcd-input-map.at(ch, default: "x")
  } else if mode == "output" {
    return evcd-output-map.at(ch, default: "x")
  } else if mode == "raw" {
    return ch
  } else {
    return evcd-composite-map.at(ch, default: "x")
  }
}

/// Decode an entire EVCD string (1-bit or multi-bit vector)
#let decode-evcd-value(val-str, mode: "composite") = {
  let res = ""
  for ch in val-str {
    res += decode-evcd-char(ch, mode: mode)
  }
  return res
}

/// Parse a standard VCD or EVCD string into a structured dictionary.
#let parse-vcd(content, evcd-mode: "composite") = {
  let lines = content.split("\n")
  let date = ""
  let version = ""
  let timescale-str = "1ns"
  let scopes = ()
  let signals = (:)
  let signals-by-id = (:)
  let id-to-is-port = (:)
  let id-to-size = (:)
  let all-signals = ()
  let is-evcd = false

  let in-definitions = true
  let cur-time = 0
  let time-min = none
  let time-max = 0

  let i = 0
  while i < lines.len() {
    let line = lines.at(i).trim()
    if line == "" {
      i += 1
      continue
    }

    if in-definitions {
      if line.starts-with("$date") {
        // Collect until $end
        let d = line.slice(5)
        while not d.contains("$end") and i + 1 < lines.len() {
          i += 1
          d += " " + lines.at(i).trim()
        }
        date = d.replace("$end", "").trim()
      } else if line.starts-with("$version") {
        let v = line.slice(8)
        while not v.contains("$end") and i + 1 < lines.len() {
          i += 1
          v += " " + lines.at(i).trim()
        }
        version = v.replace("$end", "").trim()
      } else if line.starts-with("$timescale") {
        let t = line.slice(10)
        while not t.contains("$end") and i + 1 < lines.len() {
          i += 1
          t += " " + lines.at(i).trim()
        }
        timescale-str = t.replace("$end", "").trim()
      } else if line.starts-with("$scope") {
        let parts = line.split(regex("\\s+"))
        if parts.len() >= 3 {
          scopes.push(parts.at(2))
        }
      } else if line.starts-with("$upscope") {
        if scopes.len() > 0 {
          let _ = scopes.pop()
        }
      } else if line.starts-with("$var") {
        // Format: $var <type> <size> <id> <name> [range] $end
        let parts = line.split(regex("\\s+"))
        if parts.len() >= 5 {
          let var-type = parts.at(1)
          let size-raw = parts.at(2)
          let id = parts.at(3)
          let raw-name = parts.at(4)
          let bit-size = 1

          if var-type == "port" {
            is-evcd = true
          }

          // Handle VCS extension [msb:lsb] in size field
          if size-raw.starts-with("[") {
            let inner = size-raw.replace("[", "").replace("]", "")
            let colon-parts = inner.split(":")
            if colon-parts.len() == 2 {
              let hi = int(colon-parts.at(0))
              let lo = int(colon-parts.at(1))
              bit-size = calc.abs(hi - lo) + 1
            } else {
              bit-size = int(inner)
            }
          } else {
            // Numeric size
            let parsed-size = int(size-raw)
            if parsed-size != none {
              bit-size = parsed-size
            }
          }

          // If there's an additional range part before $end, e.g. [7:0]
          if parts.len() >= 6 and parts.at(5) != "$end" {
            raw-name += " " + parts.at(5)
          }

          let scope-prefix = scopes.join(".")
          let full-name = if scope-prefix != "" { scope-prefix + "." + raw-name } else { raw-name }
          let parsed-name = parse-signal-name(raw-name)

          let is-bus = (bit-size > 1) or parsed-name.has-range
          let is-clock = (
            raw-name.starts-with("clk") or raw-name.starts-with("clock") or
            raw-name.ends-with("_clk") or raw-name.ends-with("_clock") or
            raw-name == "ck"
          ) and (bit-size == 1)

          let msb = if parsed-name.has-range { parsed-name.msb } else { bit-size - 1 }
          let lsb = if parsed-name.has-range { parsed-name.lsb } else { 0 }

          let sig-info = (
            id: id,
            name: raw-name,
            base-name: parsed-name.base,
            full-name: full-name,
            scopes: scopes,
            type: var-type,
            size: bit-size,
            msb: msb,
            lsb: lsb,
            is-bus: is-bus,
            is-clock: is-clock,
            is-port: (var-type == "port"),
            changes: ()
          )

          signals.insert(full-name, sig-info)
          signals-by-id.insert(id, full-name)
          id-to-is-port.insert(id, var-type == "port")
          id-to-size.insert(id, bit-size)
          all-signals.push(full-name)
        }
      } else if line.starts-with("$enddefinitions") {
        in-definitions = false
      }
      i += 1
      continue
    }

    // Value Change Section
    if line.starts-with("#") {
      let t-val = int(line.slice(1).trim())
      cur-time = t-val
      if time-min == none {
        time-min = cur-time
      }
      if cur-time > time-max {
        time-max = cur-time
      }
      i += 1
      continue
    }

    // Extended VCD (EVCD) line starting with 'p'
    if line.starts-with("p") {
      is-evcd = true
      let sub = line.slice(1).trim()
      let tokens = sub.split(regex("\\s+"))
      if tokens.len() >= 1 {
        let val-str = tokens.at(0)
        let id = tokens.last()
        if id in signals-by-id {
          let sig-name = signals-by-id.at(id)
          let dec-val = decode-evcd-value(val-str, mode: evcd-mode)
          let sig = signals.at(sig-name)
          let chgs = sig.changes
          chgs.push((
            time: cur-time,
            val: dec-val,
            raw-evcd: val-str,
            direction: evcd-direction-map.at(val-str.at(0), default: "PORT")
          ))
          sig.changes = chgs
          signals.insert(sig-name, sig)
        }
      }
      i += 1
      continue
    }

    // Vector change: b<bits> <id> or B<bits> <id>
    if line.starts-with("b") or line.starts-with("B") {
      let rest = line.slice(1).trim()
      let tokens = rest.split(regex("\\s+"))
      if tokens.len() >= 2 {
        let val = tokens.at(0)
        let id = tokens.at(1)
        if id in signals-by-id {
          let sig-name = signals-by-id.at(id)
          let sig = signals.at(sig-name)
          let chgs = sig.changes
          chgs.push((time: cur-time, val: val))
          sig.changes = chgs
          signals.insert(sig-name, sig)
        }
      }
      i += 1
      continue
    }

    // Real number change: r<num> <id> or R<num> <id>
    if line.starts-with("r") or line.starts-with("R") {
      let rest = line.slice(1).trim()
      let tokens = rest.split(regex("\\s+"))
      if tokens.len() >= 2 {
        let val = tokens.at(0)
        let id = tokens.at(1)
        if id in signals-by-id {
          let sig-name = signals-by-id.at(id)
          let sig = signals.at(sig-name)
          let chgs = sig.changes
          chgs.push((time: cur-time, val: val))
          sig.changes = chgs
          signals.insert(sig-name, sig)
        }
      }
      i += 1
      continue
    }

    // Standard scalar change: [01xzXZ]<id>
    if line.len() >= 2 {
      let first = line.at(0)
      if first in ("0", "1", "x", "X", "z", "Z") {
        let id = line.slice(1).trim()
        if id in signals-by-id {
          let sig-name = signals-by-id.at(id)
          let sig = signals.at(sig-name)
          let chgs = sig.changes
          chgs.push((time: cur-time, val: lower(first)))
          sig.changes = chgs
          signals.insert(sig-name, sig)
        }
      }
    }

    i += 1
  }

  if time-min == none {
    time-min = 0
  }

  return (
    type: if is-evcd { "evcd" } else { "vcd" },
    date: date,
    version: version,
    timescale: parse-timescale(timescale-str),
    signals: signals,
    signals-by-id: signals-by-id,
    all-signals: all-signals,
    time-min: time-min,
    time-max: time-max
  )
}
