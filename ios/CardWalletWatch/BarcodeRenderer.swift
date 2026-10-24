import SwiftUI

/// watchOS does not expose CoreImage barcode generators, so the watch
/// renderer draws the common retail 1D formats directly with SwiftUI.
enum WatchBarcodeRenderer {
    static func modules(for value: String, format: String) -> [Bool]? {
        let normalized = format.uppercased()
        let trimmed = value.filter { !$0.isWhitespace }

        switch normalized {
        case "EAN_13", "EAN13":
            return ean13Modules(trimmed)
        case "EAN_8", "EAN8":
            return ean8Modules(trimmed)
        case "UPC_A", "UPCA":
            guard trimmed.count == 12 else { return nil }
            return ean13Modules("0" + trimmed)
        case "CODE_128", "CODE128":
            return code128BModules(trimmed)
        default:
            return nil
        }
    }

    static func supports(format: String) -> Bool {
        switch format.uppercased() {
        case "EAN_13", "EAN13", "EAN_8", "EAN8", "UPC_A", "UPCA", "CODE_128", "CODE128":
            return true
        default:
            return false
        }
    }

    private static func ean13Modules(_ value: String) -> [Bool]? {
        guard value.count == 13, value.allSatisfy({ $0.isNumber }) else { return nil }
        let digits = value.compactMap { Int(String($0)) }
        guard digits.count == 13 else { return nil }

        let parity = [
            "LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
            "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL",
        ][digits[0]]

        var modules = quietZone()
        appendPattern("101", to: &modules)
        for index in 1...6 {
            appendPattern(pattern(for: digits[index], set: parity[parity.index(parity.startIndex, offsetBy: index - 1)]), to: &modules)
        }
        appendPattern("01010", to: &modules)
        for index in 7...12 {
            appendPattern(pattern(for: digits[index], set: "R"), to: &modules)
        }
        appendPattern("101", to: &modules)
        modules.append(contentsOf: quietZone())
        return modules
    }

    private static func ean8Modules(_ value: String) -> [Bool]? {
        guard value.count == 8, value.allSatisfy({ $0.isNumber }) else { return nil }
        let digits = value.compactMap { Int(String($0)) }
        guard digits.count == 8 else { return nil }

        var modules = quietZone()
        appendPattern("101", to: &modules)
        for index in 0...3 {
            appendPattern(pattern(for: digits[index], set: "L"), to: &modules)
        }
        appendPattern("01010", to: &modules)
        for index in 4...7 {
            appendPattern(pattern(for: digits[index], set: "R"), to: &modules)
        }
        appendPattern("101", to: &modules)
        modules.append(contentsOf: quietZone())
        return modules
    }

    private static func code128BModules(_ value: String) -> [Bool]? {
        guard !value.isEmpty else { return nil }
        let values = value.unicodeScalars.map { Int($0.value) - 32 }
        guard values.allSatisfy({ 0...95 ~= $0 }) else { return nil }

        var codes = [104]
        codes.append(contentsOf: values)

        var checksum = 104
        for (offset, code) in values.enumerated() {
            checksum += code * (offset + 1)
        }
        codes.append(checksum % 103)
        codes.append(106)

        var modules = quietZone(count: 10)
        for code in codes {
            guard code < code128Patterns.count else { return nil }
            appendWidths(code128Patterns[code], to: &modules)
        }
        modules.append(contentsOf: quietZone(count: 10))
        return modules
    }

    private static func quietZone(count: Int = 9) -> [Bool] {
        Array(repeating: false, count: count)
    }

    private static func appendPattern(_ pattern: String, to modules: inout [Bool]) {
        modules.append(contentsOf: pattern.map { $0 == "1" })
    }

    private static func appendWidths(_ widths: String, to modules: inout [Bool]) {
        var isBar = true
        for widthChar in widths {
            guard let width = Int(String(widthChar)) else { continue }
            modules.append(contentsOf: Array(repeating: isBar, count: width))
            isBar.toggle()
        }
    }

    private static func pattern(for digit: Int, set: Character) -> String {
        switch set {
        case "G":
            return eanG[digit]
        case "R":
            return eanR[digit]
        default:
            return eanL[digit]
        }
    }

    private static let eanL = [
        "0001101", "0011001", "0010011", "0111101", "0100011",
        "0110001", "0101111", "0111011", "0110111", "0001011",
    ]

    private static let eanG = [
        "0100111", "0110011", "0011011", "0100001", "0011101",
        "0111001", "0000101", "0010001", "0001001", "0010111",
    ]

    private static let eanR = [
        "1110010", "1100110", "1101100", "1000010", "1011100",
        "1001110", "1010000", "1000100", "1001000", "1110100",
    ]

    private static let code128Patterns = [
        "212222", "222122", "222221", "121223", "121322", "131222", "122213", "122312",
        "132212", "221213", "221312", "231212", "112232", "122132", "122231", "113222",
        "123122", "123221", "223211", "221132", "221231", "213212", "223112", "312131",
        "311222", "321122", "321221", "312212", "322112", "322211", "212123", "212321",
        "232121", "111323", "131123", "131321", "112313", "132113", "132311", "211313",
        "231113", "231311", "112133", "112331", "132131", "113123", "113321", "133121",
        "313121", "211331", "231131", "213113", "213311", "213131", "311123", "311321",
        "331121", "312113", "312311", "332111", "314111", "221411", "431111", "111224",
        "111422", "121124", "121421", "141122", "141221", "112214", "112412", "122114",
        "122411", "142112", "142211", "241211", "221114", "413111", "241112", "134111",
        "111242", "121142", "121241", "114212", "124112", "124211", "411212", "421112",
        "421211", "212141", "214121", "412121", "111143", "111341", "131141", "114113",
        "114311", "411113", "411311", "113141", "114131", "311141", "411131", "211412",
        "211214", "211232", "2331112",
    ]
}

struct WatchBarcodeModulesView: View {
    let modules: [Bool]

    var body: some View {
        GeometryReader { proxy in
            let moduleWidth = proxy.size.width / CGFloat(max(modules.count, 1))
            Path { path in
                for (index, isBar) in modules.enumerated() where isBar {
                    let x = CGFloat(index) * moduleWidth
                    path.addRect(CGRect(
                        x: x.rounded(.down),
                        y: 0,
                        width: max(1, moduleWidth.rounded(.up)),
                        height: proxy.size.height
                    ))
                }
            }
            .fill(Color.black)
        }
    }
}

/// A QR code's dark modules on a square, pixel-aligned grid.
struct WatchQRModulesView: View {
    let modules: [[Bool]]

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let count = CGFloat(max(modules.count, 1))
            // Whole points per module keep the edges crisp for scanners.
            let cell = max(1, (side / count).rounded(.down))
            let drawn = cell * count
            Path { path in
                for (y, row) in modules.enumerated() {
                    for (x, dark) in row.enumerated() where dark {
                        path.addRect(CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell))
                    }
                }
            }
            .fill(Color.black)
            .frame(width: drawn, height: drawn)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

/// QR Code encoder (ISO/IEC 18004) for the watch, which has no CoreImage
/// generator. Byte mode, error correction M, versions 1–40, best mask by
/// the standard penalty rules. Follows the structure of Project Nayuki's
/// reference implementation (MIT).
enum WatchQRCode {
    /// Dark modules, row by row; nil when the text doesn't fit (≈2300 bytes).
    static func encode(_ text: String) -> [[Bool]]? {
        let data = Array(text.utf8)
        let ecl = 0  // index of M in the tables
        var version = 1
        while true {
            let ccBits = version <= 9 ? 8 : 16
            let used = 4 + ccBits + data.count * 8
            if used <= dataCodewords(version, ecl) * 8 { break }
            version += 1
            if version > 40 { return nil }
        }
        // Bit stream: mode, count, data, terminator, padding.
        var bits: [Bool] = []
        func append(_ value: Int, _ count: Int) {
            for i in stride(from: count - 1, through: 0, by: -1) { bits.append((value >> i) & 1 == 1) }
        }
        append(0b0100, 4)
        append(data.count, version <= 9 ? 8 : 16)
        for b in data { append(Int(b), 8) }
        let capacity = dataCodewords(version, ecl) * 8
        append(0, min(4, capacity - bits.count))
        append(0, (8 - bits.count % 8) % 8)
        var pad = 0xEC
        while bits.count < capacity { append(pad, 8); pad ^= 0xEC ^ 0x11 }
        var codewords = [Int](repeating: 0, count: bits.count / 8)
        for (i, bit) in bits.enumerated() where bit { codewords[i >> 3] |= 1 << (7 - (i & 7)) }

        var qr = Matrix(version: version)
        qr.drawFunctionPatterns()
        qr.drawCodewords(addEcc(codewords, version, ecl))
        var best = 0
        var bestPenalty = Int.max
        for mask in 0..<8 {
            var trial = qr
            trial.applyMask(mask)
            trial.drawFormatBits(mask)
            let p = trial.penalty()
            if p < bestPenalty { bestPenalty = p; best = mask }
        }
        qr.applyMask(best)
        qr.drawFormatBits(best)
        return qr.modules
    }

    // MARK: Tables (index 0 unused), error correction M

    private static let eccPerBlock: [[Int]] = [
        [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],
    ]
    private static let numBlocks: [[Int]] = [
        [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],
    ]

    fileprivate static func rawDataModules(_ ver: Int) -> Int {
        var result = (16 * ver + 128) * ver + 64
        if ver >= 2 {
            let numAlign = ver / 7 + 2
            result -= (25 * numAlign - 10) * numAlign - 55
            if ver >= 7 { result -= 36 }
        }
        return result
    }

    private static func dataCodewords(_ ver: Int, _ ecl: Int) -> Int {
        rawDataModules(ver) / 8 - eccPerBlock[ecl][ver] * numBlocks[ecl][ver]
    }

    private static func addEcc(_ data: [Int], _ ver: Int, _ ecl: Int) -> [Int] {
        let blocksCount = numBlocks[ecl][ver]
        let eccLen = eccPerBlock[ecl][ver]
        let raw = rawDataModules(ver) / 8
        let numShort = blocksCount - raw % blocksCount
        let shortLen = raw / blocksCount
        let divisor = rsDivisor(eccLen)
        var blocks: [[Int]] = []
        var k = 0
        for i in 0..<blocksCount {
            let len = shortLen - eccLen + (i < numShort ? 0 : 1)
            var dat = Array(data[k..<(k + len)])
            k += len
            let ecc = rsRemainder(dat, divisor)
            if i < numShort { dat.append(0) }
            blocks.append(dat + ecc)
        }
        var result: [Int] = []
        for i in 0..<blocks[0].count {
            for j in 0..<blocks.count where i != shortLen - eccLen || j >= numShort {
                result.append(blocks[j][i])
            }
        }
        return result
    }

    private static func rsDivisor(_ degree: Int) -> [Int] {
        var result = [Int](repeating: 0, count: degree)
        result[degree - 1] = 1
        var root = 1
        for _ in 0..<degree {
            for j in 0..<degree {
                result[j] = gfMultiply(result[j], root)
                if j + 1 < degree { result[j] ^= result[j + 1] }
            }
            root = gfMultiply(root, 0x02)
        }
        return result
    }

    private static func rsRemainder(_ data: [Int], _ divisor: [Int]) -> [Int] {
        var result = [Int](repeating: 0, count: divisor.count)
        for b in data {
            let factor = b ^ result.removeFirst()
            result.append(0)
            for i in 0..<result.count { result[i] ^= gfMultiply(divisor[i], factor) }
        }
        return result
    }

    private static func gfMultiply(_ x: Int, _ y: Int) -> Int {
        var z = 0
        for i in stride(from: 7, through: 0, by: -1) {
            z = (z << 1) ^ ((z >> 7) * 0x11D)
            z ^= ((y >> i) & 1) * x
        }
        return z & 0xFF
    }

    // MARK: Module matrix

    private struct Matrix {
        let version: Int
        let size: Int
        var modules: [[Bool]]
        var isFunction: [[Bool]]

        init(version: Int) {
            self.version = version
            size = version * 4 + 17
            modules = Array(repeating: Array(repeating: false, count: size), count: size)
            isFunction = modules
        }

        mutating func set(_ x: Int, _ y: Int, _ dark: Bool) {
            modules[y][x] = dark
            isFunction[y][x] = true
        }

        mutating func drawFunctionPatterns() {
            for i in 0..<size {
                set(6, i, i % 2 == 0)
                set(i, 6, i % 2 == 0)
            }
            drawFinder(3, 3)
            drawFinder(size - 4, 3)
            drawFinder(3, size - 4)
            let align = alignmentPositions()
            let n = align.count
            for i in 0..<n {
                for j in 0..<n {
                    if (i == 0 && j == 0) || (i == 0 && j == n - 1) || (i == n - 1 && j == 0) { continue }
                    for dy in -2...2 {
                        for dx in -2...2 {
                            set(align[i] + dx, align[j] + dy, max(abs(dx), abs(dy)) != 1)
                        }
                    }
                }
            }
            drawFormatBits(0)  // reserve; overwritten after masking
            if version >= 7 {
                var rem = version
                for _ in 0..<12 { rem = (rem << 1) ^ ((rem >> 11) * 0x1F25) }
                let bits = version << 12 | rem
                for i in 0..<18 {
                    let bit = (bits >> i) & 1 == 1
                    let a = size - 11 + i % 3
                    let b = i / 3
                    set(a, b, bit)
                    set(b, a, bit)
                }
            }
        }

        mutating func drawFinder(_ x: Int, _ y: Int) {
            for dy in -4...4 {
                for dx in -4...4 {
                    let xx = x + dx, yy = y + dy
                    guard xx >= 0, xx < size, yy >= 0, yy < size else { continue }
                    let dist = max(abs(dx), abs(dy))
                    set(xx, yy, dist != 2 && dist != 4)
                }
            }
        }

        func alignmentPositions() -> [Int] {
            if version == 1 { return [] }
            let numAlign = version / 7 + 2
            let step = version == 32 ? 26 : (version * 4 + numAlign * 2 + 1) / (numAlign * 2 - 2) * 2
            var result = [Int](repeating: 6, count: numAlign)
            var pos = size - 7
            for i in stride(from: numAlign - 1, through: 1, by: -1) {
                result[i] = pos
                pos -= step
            }
            return result
        }

        mutating func drawFormatBits(_ mask: Int) {
            let data = 0 << 3 | mask  // M = 0b00
            var rem = data
            for _ in 0..<10 { rem = (rem << 1) ^ ((rem >> 9) * 0x537) }
            let bits = (data << 10 | rem) ^ 0x5412
            func bit(_ i: Int) -> Bool { (bits >> i) & 1 == 1 }
            for i in 0...5 { set(8, i, bit(i)) }
            set(8, 7, bit(6))
            set(8, 8, bit(7))
            set(7, 8, bit(8))
            for i in 9..<15 { set(14 - i, 8, bit(i)) }
            for i in 0..<8 { set(size - 1 - i, 8, bit(i)) }
            for i in 8..<15 { set(8, size - 15 + i, bit(i)) }
            set(8, size - 8, true)
        }

        mutating func drawCodewords(_ data: [Int]) {
            var i = 0
            var right = size - 1
            while right >= 1 {
                if right == 6 { right = 5 }
                for vert in 0..<size {
                    for j in 0..<2 {
                        let x = right - j
                        let upward = (right + 1) & 2 == 0
                        let y = upward ? size - 1 - vert : vert
                        if !isFunction[y][x] && i < data.count * 8 {
                            modules[y][x] = (data[i >> 3] >> (7 - (i & 7))) & 1 == 1
                            i += 1
                        }
                    }
                }
                right -= 2
            }
        }

        mutating func applyMask(_ mask: Int) {
            for y in 0..<size {
                for x in 0..<size where !isFunction[y][x] {
                    let invert: Bool
                    switch mask {
                    case 0: invert = (x + y) % 2 == 0
                    case 1: invert = y % 2 == 0
                    case 2: invert = x % 3 == 0
                    case 3: invert = (x + y) % 3 == 0
                    case 4: invert = (x / 3 + y / 2) % 2 == 0
                    case 5: invert = x * y % 2 + x * y % 3 == 0
                    case 6: invert = (x * y % 2 + x * y % 3) % 2 == 0
                    default: invert = ((x + y) % 2 + x * y % 3) % 2 == 0
                    }
                    if invert { modules[y][x].toggle() }
                }
            }
        }

        /// Standard penalty: runs, 2x2 blocks, finder-like patterns, balance.
        func penalty() -> Int {
            var result = 0
            func line(_ get: (Int) -> Bool) -> Int {
                var p = 0
                var run = 1
                var row: [Bool] = []
                for i in 0..<size { row.append(get(i)) }
                for i in 1..<size {
                    if row[i] == row[i - 1] {
                        run += 1
                        if run == 5 { p += 3 } else if run > 5 { p += 1 }
                    } else { run = 1 }
                }
                // 1:1:3:1:1 with four light modules on one side.
                let pattern: [Bool] = [true, false, true, true, true, false, true]
                for i in 0...(size - 7) where Array(row[i..<(i + 7)]) == pattern {
                    let before = i >= 4 && !row[(i - 4)..<i].contains(true)
                    let after = i + 11 <= size && !row[(i + 7)..<(i + 11)].contains(true)
                    if before || after { p += 40 }
                }
                return p
            }
            for y in 0..<size { result += line { modules[y][$0] } }
            for x in 0..<size { result += line { modules[$0][x] } }
            for y in 0..<(size - 1) {
                for x in 0..<(size - 1) {
                    let c = modules[y][x]
                    if c == modules[y][x + 1] && c == modules[y + 1][x] && c == modules[y + 1][x + 1] { result += 3 }
                }
            }
            let dark = modules.reduce(0) { $0 + $1.filter { $0 }.count }
            let total = size * size
            let k = (abs(dark * 20 - total * 10) + total - 1) / total - 1
            result += max(0, k) * 10
            return result
        }
    }
}
