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
