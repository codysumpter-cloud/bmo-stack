import SwiftUI

enum BuddyAnimationMood: String, CaseIterable {
    case idle
    case happy
    case thinking
    case working
    case sleepy
    case levelUp
    case needsAttention
}

enum BuddyVisualMode {
    case ascii
    case rich
}
