package com.volkan.wallet_app.wear

import android.graphics.Bitmap
import android.graphics.Color
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.MultiFormatWriter

private val formats = mapOf(
    "CODE_128" to BarcodeFormat.CODE_128,
    "CODE_39" to BarcodeFormat.CODE_39,
    "CODE_93" to BarcodeFormat.CODE_93,
    "CODABAR" to BarcodeFormat.CODABAR,
    "EAN_13" to BarcodeFormat.EAN_13,
    "EAN_8" to BarcodeFormat.EAN_8,
    "UPC_A" to BarcodeFormat.UPC_A,
    "UPC_E" to BarcodeFormat.UPC_E,
    "ITF" to BarcodeFormat.ITF,
    "QR_CODE" to BarcodeFormat.QR_CODE,
    "PDF417" to BarcodeFormat.PDF_417,
    "AZTEC" to BarcodeFormat.AZTEC,
    "DATA_MATRIX" to BarcodeFormat.DATA_MATRIX,
)

fun isSquare(format: String) = format in setOf("QR_CODE", "AZTEC", "DATA_MATRIX")

/** Black-on-white barcode, or null when the value doesn't fit the format. */
fun renderBarcode(value: String, format: String, width: Int, height: Int): Bitmap? = try {
    val f = formats[format] ?: BarcodeFormat.CODE_128
    val matrix = MultiFormatWriter().encode(
        value, f, width, height, mapOf(EncodeHintType.MARGIN to 1),
    )
    val pixels = IntArray(matrix.width * matrix.height)
    for (y in 0 until matrix.height) {
        val row = y * matrix.width
        for (x in 0 until matrix.width) {
            pixels[row + x] = if (matrix[x, y]) Color.BLACK else Color.WHITE
        }
    }
    Bitmap.createBitmap(pixels, matrix.width, matrix.height, Bitmap.Config.ARGB_8888)
} catch (_: Exception) {
    null
}

/** `#RRGGBB` as sent by the phone. */
fun parseHex(hex: String?, fallback: Int): Int = try {
    if (hex.isNullOrBlank()) fallback else Color.parseColor(hex)
} catch (_: IllegalArgumentException) {
    fallback
}
