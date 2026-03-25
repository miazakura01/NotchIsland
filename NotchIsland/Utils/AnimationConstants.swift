import SwiftUI

enum AnimationConstants {
    static let expandSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let contentFade = Animation.easeInOut(duration: 0.2)
    static let hoverScale = Animation.easeInOut(duration: 0.15)
    static let notificationBounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let deckReveal = Animation.easeOut(duration: 0.25)
    static let deckHide = Animation.easeIn(duration: 0.25)
    static let displaySwitch = Animation.easeInOut(duration: 0.3)

    static func customSpring(speed: AnimationSpeed) -> Animation {
        .spring(response: speed.springResponse, dampingFraction: speed.springDamping)
    }
}
