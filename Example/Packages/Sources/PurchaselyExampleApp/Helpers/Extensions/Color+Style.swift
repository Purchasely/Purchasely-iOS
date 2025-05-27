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
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1))
    }
}

extension Color {
    public static let main = Color(hex: "#6668F5")
    public static let mainLight = Color(hex: "#6668F5", alpha: 0.3)
    public static let backgroundGrey = Color(hex: "#F7F7FD", alpha: 1)
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
