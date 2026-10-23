import WidgetKit
import SwiftUI

@main
struct LoyaltyWidgetBundle: WidgetBundle {
    var body: some Widget {
        LoyaltyWidget()
        if #available(iOSApplicationExtension 17.0, *) {
            PinnedCardWidget()
        }
    }
}
