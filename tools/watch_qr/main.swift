// Round-trip check for the watch QR encoder: encodes samples with
// WatchQRCode and decodes them with CoreImage.
//   swiftc -O ios/CardWalletWatch/BarcodeRenderer.swift tools/watch_qr/main.swift -o /tmp/qrcheck && /tmp/qrcheck
// (BarcodeRenderer.swift needs SwiftUI, available on macOS.)
import Foundation
import CoreImage
import AppKit

func image(_ m: [[Bool]]) -> CIImage {
    let quiet = 4, scale = 6
    let n = m.count + 2 * quiet
    let w = n * scale
    var px = [UInt8](repeating: 255, count: w * w)
    for y in 0..<m.count { for x in 0..<m.count where m[y][x] {
        for dy in 0..<scale { for dx in 0..<scale { px[((y + quiet) * scale + dy) * w + (x + quiet) * scale + dx] = 0 } } } }
    let provider = CGDataProvider(data: Data(px) as CFData)!
    let cg = CGImage(width: w, height: w, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    return CIImage(cgImage: cg)
}
let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
var samples = ["6061234567890123", "GYM-0042-7781", "1", "https://example.com/loyalty?id=1234567890&member=ABCDEF", "Ayşe Yılmaz · Żabka · Pão de Açúcar"]
for n in [40, 80, 120, 200, 300, 500, 800, 1200] {
    samples.append(String((0..<n).map { i in Character(UnicodeScalar(33 + (i * 7919) % 90)!) }))
}
var ok = 0
for s in samples {
    guard let m = WatchQRCode.encode(s) else { print("NIL", s.count); continue }
    let found = detector.features(in: image(m)).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
    let pass = found.first == s
    if pass { ok += 1 }
    print(pass ? "OK  " : "FAIL", "len=\(s.utf8.count) version=\((m.count - 17) / 4)", pass ? "" : "got=\(found)")
}
print("\(ok)/\(samples.count)")
