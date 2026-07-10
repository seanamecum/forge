import Foundation
import UIKit

extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(range.upperBound, Swift.max(range.lowerBound, self))
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(range.upperBound, Swift.max(range.lowerBound, self))
    }
}

extension Date {
    var shortLabel: String {
        formatted(.dateTime.month(.abbreviated).day())
    }
}

/// Time-of-day words shared by the dashboard greeting and the coach's opener —
/// pure and hour-injected so it's testable.
enum Daypart {
    static func greeting(hour: Int) -> String {
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }

    static var now: String {
        greeting(hour: Calendar.current.component(.hour, from: .now))
    }
}

/// Premium haptics — light, intentional, and used only where an action lands:
/// completing a set, logging a check-in, switching tabs, sending to the coach.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
