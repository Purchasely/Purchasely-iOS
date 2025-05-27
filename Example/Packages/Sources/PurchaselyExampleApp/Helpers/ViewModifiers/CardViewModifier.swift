import SwiftUI

public struct CardViewModifier: ViewModifier {
    
    fileprivate enum Constants {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 3
        static let shadowXOffset: CGFloat = 1
        static let shadowYOffset: CGFloat = 1
        
        /// Used to avoid clipping the shadow
        static var minimumPadding: CGFloat {
            shadowRadius + shadowXOffset + shadowYOffset
        }
    }

    let horizontalPadding: CGFloat
    
    init(horizontalPadding: CGFloat) {
        self.horizontalPadding = horizontalPadding
    }

    public func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(Constants.cornerRadius)
            .shadow(color: .gray.opacity(0.5),
                    radius: Constants.shadowRadius,
                    x: Constants.shadowXOffset,
                    y: Constants.shadowYOffset)
            .padding(.horizontal, horizontalPadding)
    }
}

public extension View {
    func card(horizontalPadding: CGFloat = 15) -> some View {
        modifier(CardViewModifier(horizontalPadding: horizontalPadding))
    }

    func unpaddedCard() -> some View {
        modifier(CardViewModifier(horizontalPadding: CardViewModifier.Constants.minimumPadding))
    }
}
