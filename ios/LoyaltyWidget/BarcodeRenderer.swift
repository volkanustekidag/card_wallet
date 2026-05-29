import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// CoreImage barcode rendering for the home-screen widget preview.
///
/// We only ship the two formats that cover the vast majority of loyalty
/// cards: `QR_CODE` and `CODE_128`. EAN/UPC barcodes don't have a
/// first-party CoreImage generator on iOS and aren't worth pulling in
/// a third-party Swift package for; widgets in those formats render the
/// raw number text instead, and the user can tap through to the
/// full-screen barcode in the app where the Flutter `barcode_widget`
/// package handles every format.
enum BarcodeRenderer {
    static func image(for value: String, format: String, scale: CGFloat = 5) -> UIImage? {
        let normalized = format.uppercased()
        let data = Data(value.utf8)
        let context = CIContext()

        let filter: CIFilter?
        switch normalized {
        case "QR_CODE":
            let qr = CIFilter.qrCodeGenerator()
            qr.setValue(data, forKey: "inputMessage")
            qr.setValue("M", forKey: "inputCorrectionLevel")
            filter = qr
        case "CODE_128":
            let code = CIFilter.code128BarcodeGenerator()
            code.setValue(data, forKey: "inputMessage")
            // Tighter quiet zones — widget surfaces are small.
            code.setValue(7.0, forKey: "inputQuietSpace")
            filter = code
        case "AZTEC":
            let aztec = CIFilter.aztecCodeGenerator()
            aztec.setValue(data, forKey: "inputMessage")
            filter = aztec
        default:
            return nil
        }

        guard let outputImage = filter?.outputImage else { return nil }
        let transformed = outputImage.transformed(
            by: CGAffineTransform(scaleX: scale, y: scale)
        )
        guard let cgImage = context.createCGImage(
            transformed,
            from: transformed.extent
        ) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// True if the home-screen widget can render an actual scannable
    /// preview for this format. Lock-screen widgets ignore this and
    /// always show text — the surface is too small + monochrome to be
    /// reliably scannable.
    static func supportsInlineRendering(format: String) -> Bool {
        switch format.uppercased() {
        case "QR_CODE", "CODE_128", "AZTEC":
            return true
        default:
            return false
        }
    }
}
