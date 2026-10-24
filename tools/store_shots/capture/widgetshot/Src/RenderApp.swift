import SwiftUI
import WidgetKit

struct Market { let code: String; let label: String; let cards: [(String, String, String, String)] }

let markets: [Market] = [
  Market(code: "us", label: "Up next", cards: [("Starbucks","#006241","#003D28","#FFFFFF"),("Target","#CC0000","#8A0000","#FFFFFF"),("Ulta Beauty","#F26822","#B84A12","#FFFFFF"),("Best Buy","#0046BE","#002C7A","#FFFFFF")]),
  Market(code: "de", label: "Als Nächstes", cards: [("REWE","#CC071E","#8C0414","#FFFFFF"),("dm","#002878","#00174A","#FFFFFF"),("Payback","#003EAA","#002670","#FFFFFF"),("Douglas","#2A2A2A","#0B0B0B","#FFFFFF")]),
  Market(code: "tr", label: "Sıradaki", cards: [("Migros","#FF6600","#C24A00","#FFFFFF"),("Kahve Dünyası","#5A2D0C","#341A06","#FFFFFF"),("D&R","#E30613","#9E040D","#FFFFFF"),("LC Waikiki","#0047BA","#002C78","#FFFFFF")]),
  Market(code: "fr", label: "À suivre", cards: [("Carrefour","#004E9F","#003066","#FFFFFF"),("Intermarché","#E2001A","#9C0012","#FFFFFF"),("Fnac","#E1A925","#A87A10","#FFFFFF"),("Sephora","#2A2A2A","#0B0B0B","#FFFFFF")]),
  Market(code: "es", label: "Siguiente", cards: [("El Corte Inglés","#00873D","#005426","#FFFFFF"),("Carrefour","#004E9F","#003066","#FFFFFF"),("Dia","#E30613","#9E040D","#FFFFFF"),("Repsol","#FF8200","#C25E00","#FFFFFF")]),
  Market(code: "it", label: "Prossima", cards: [("Esselunga","#1E6CB5","#114273","#FFFFFF"),("Conad","#E30613","#9E040D","#FFFFFF"),("Eni","#FFD100","#C9A200","#1A1A1A"),("Leroy Merlin","#78BE20","#4E8212","#FFFFFF")]),
  Market(code: "nl", label: "Volgende", cards: [("Albert Heijn","#00ADE6","#00739A","#FFFFFF"),("Jumbo","#FFD200","#C9A300","#1A1A1A"),("HEMA","#E2001A","#9C0012","#FFFFFF"),("IKEA","#0058A3","#003866","#FFFFFF")]),
  Market(code: "pl", label: "Następna", cards: [("Żabka","#00A651","#006B34","#FFFFFF"),("Biedronka","#E30613","#9E040D","#FFFFFF"),("Lidl","#0050AA","#00326B","#FFFFFF"),("Douglas","#2A2A2A","#0B0B0B","#FFFFFF")]),
  Market(code: "br", label: "A seguir", cards: [("Pão de Açúcar","#00843D","#005226","#FFFFFF"),("Livelo","#E5007E","#9E0057","#FFFFFF"),("Drogasil","#E30613","#9E040D","#FFFFFF"),("Smiles","#FF6600","#C24A00","#FFFFFF")]),
]

func entry(_ m: Market) -> LoyaltyEntry {
  let cards = m.cards.enumerated().map { (i, c) in
    WidgetCard(id: "c\(i)", name: c.0, barcode: "60612345678901", format: "CODE_128",
               bgHex: c.1, bg2Hex: c.2, fgHex: c.3, imagePath: nil)
  }
  return LoyaltyEntry(date: Date(), cards: cards, upNextLabel: m.label)
}

struct Tile<Content: View>: View {
  let size: CGSize; let card: WidgetCard?; let content: Content
  var body: some View {
    content
      .frame(width: size.width, height: size.height)
      .background(WidgetBackground(card: card))
      .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
      .environment(\.colorScheme, .dark)
  }
}

@MainActor func save<V: View>(_ v: V, _ name: String) {
  let r = ImageRenderer(content: v)
  r.scale = 3
  r.isOpaque = false
  guard let img = r.uiImage, let data = img.pngData() else { print("FAIL \(name)"); return }
  let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
  try? data.write(to: url)
  print("wrote \(name)")
}

@main
struct RenderApp: App {
  init() {
    Task { @MainActor in
      for m in markets {
        let e = entry(m)
        save(Tile(size: CGSize(width: 170, height: 170), card: e.upNext, content: SmallView(entry: e)), "\(m.code)_small.png")
        save(Tile(size: CGSize(width: 364, height: 170), card: e.upNext, content: MediumView(entry: e)), "\(m.code)_medium.png")
        save(AccessoryRectangularView(entry: e).foregroundStyle(.white).frame(width: 172, height: 76).environment(\.colorScheme, .dark), "\(m.code)_lock.png")
      }
      let done = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DONE")
      try? Data().write(to: done)
    }
  }
  var body: some Scene { WindowGroup { Text("rendering") } }
}
