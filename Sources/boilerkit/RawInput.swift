import Darwin

// MARK: - Terminal Raw Mode

private func withRawMode(_ body: () -> Void) {
    var original = termios()
    tcgetattr(STDIN_FILENO, &original)

    var raw = original
    raw.c_lflag &= ~tcflag_t(ICANON | ECHO)
    raw.c_cc.16 = 1 // VMIN: return after 1 byte
    raw.c_cc.17 = 0 // VTIME: no timeout

    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    body()
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
}

// MARK: - Keys

private enum Key {
    case up, down, space, enter, other
}

private func readKey() -> Key {
    var b: UInt8 = 0
    Darwin.read(STDIN_FILENO, &b, 1)

    if b == 27 {
        var b2: UInt8 = 0
        var b3: UInt8 = 0
        Darwin.read(STDIN_FILENO, &b2, 1)
        Darwin.read(STDIN_FILENO, &b3, 1)
        if b2 == 91 {
            if b3 == 65 { return .up }   // ESC [ A  ↑
            if b3 == 66 { return .down } // ESC [ B  ↓
        }
        return .other
    }

    switch b {
    case 32:     return .space
    case 13, 10: return .enter
    default:     return .other
    }
}

// MARK: - Raw write

/// Writes directly to STDOUT_FILENO, bypassing Swift's buffered stdout.
private func rawWrite(_ s: String) {
    _ = s.withCString { Darwin.write(STDOUT_FILENO, $0, strlen($0)) }
}

// MARK: - Public API

/// Presents an interactive multi-select list.
/// Navigate with ↑↓, toggle with Space, confirm with Enter.
///
/// - Parameters:
///   - title: Header line printed above the list (e.g. "  🔧 Code quality tools:").
///   - options: Options to display, each with a name and short description.
///   - defaults: Initial selected state per option (index-aligned with `options`).
/// - Returns: Boolean array (index-aligned) with the final selection state.
func selectMultiple(
    title: String,
    options: [(name: String, description: String)],
    defaults: [Bool]
) -> [Bool] {
    var selected = defaults
    var cursor = 0
    let count = options.count

    // Flush Swift's buffered stdout so any preceding print() calls appear
    // before our raw writes to STDOUT_FILENO.
    fflush(stdout)

    // Builds the option rows + hint line as a single string.
    // Every option row ends with \r\n; the hint line has no trailing newline
    // so the cursor parks there and we know exactly where we are.
    func buildBlock() -> String {
        var s = ""
        for (i, opt) in options.enumerated() {
            let mark = selected[i] ? "x" : " "
            let ptr  = i == cursor ? "▶" : " "
            s += "\r\u{1B}[2K     \(ptr) [\(mark)]  \(opt.name)  (\(opt.description))\r\n"
        }
        s += "\r\u{1B}[2K     ↑↓ move   Space toggle   Enter confirm"
        return s
    }

    // Initial draw: blank line, title, blank line, then the option block.
    rawWrite("\n\(title)\n\n")
    rawWrite(buildBlock())

    var done = false
    withRawMode {
        while !done {
            switch readKey() {
            case .up:
                cursor = (cursor - 1 + count) % count
            case .down:
                cursor = (cursor + 1) % count
            case .space:
                selected[cursor].toggle()
            case .enter:
                done = true
                continue
            case .other:
                continue
            }
            // Move up by count lines: one per option row (each ended with \r\n).
            // The hint line has no \n so the cursor is on it — moving up by
            // count reaches option row 0.
            rawWrite("\u{1B}[\(count)A")
            rawWrite(buildBlock())
        }
    }

    // Finish: move past the hint line and leave one blank line.
    rawWrite("\n\n")
    // Sync: flush fd-level writes before Swift's buffered stdout resumes.
    fflush(stdout)

    return selected
}
