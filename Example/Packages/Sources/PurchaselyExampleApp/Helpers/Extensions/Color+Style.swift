//
//  Color+Style.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 13/12/2023.
//

import Foundation
import SwiftUI

struct CustomTextFieldStyle : TextFieldStyle {
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.brandDarkGreen.opacity(0.15), lineWidth: 1))
    }
}

/// Purchasely brand swatches, mirroring the `--_swatches---*` tokens on purchasely.com.
extension Color {
    public static let brandBlackGreen = Color(hex: "#001614")
    public static let brandDarkGreen = Color(hex: "#002420")
    public static let brandDeepGreen = Color(hex: "#00352F")
    public static let brandLightGreen = Color(hex: "#CEECD0")
    public static let brandLightGrey = Color(hex: "#EEF3E9")
    public static let brandCream = Color(hex: "#FFF3D6")
    public static let brandLavender = Color(hex: "#BDBBFF")
    public static let brandCoral = Color(hex: "#FFB6B2")
}

/// Semantic roles the sample app paints with. Mapped onto the brand swatches above:
/// `main` is the dark chrome surface (`--container--primary` on dark),
/// `backgroundGrey` the light content surface (`--container--primary` on light).
extension Color {
    public static let main = Color.brandDarkGreen
    public static let mainLight = Color(hex: "#CEECD0", alpha: 0.35)
    public static let backgroundGrey = Color.brandLightGrey
}

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: alpha
        )
    }
}
