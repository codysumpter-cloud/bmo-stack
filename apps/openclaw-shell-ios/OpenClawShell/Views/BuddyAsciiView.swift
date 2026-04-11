import SwiftUI

enum BuddyAnimationMood {
    case idle
    case happy
    case thinking
    case working
    case sleepy
    case levelUp
}

struct BuddyAsciiView: View {
    let mood: BuddyAnimationMood
    var compact = false
    @State private var tick = 0

    var body: some View {
        Text(frame)
            .font(.system(size: compact ? 12 : 19, weight: .bold, design: .monospaced))
            .foregroundColor(BMOTheme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(compact ? 12 : 18)
            .background(BMOTheme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 520_000_000)
                    tick += 1
                }
            }
            .accessibilityLabel("Buddy \(label)")
    }

    private var label: String {
        switch mood {
        case .idle: return "idle"
        case .happy: return "happy"
        case .thinking: return "thinking"
        case .working: return "working"
        case .sleepy: return "sleepy"
        case .levelUp: return "level up"
        }
    }

    private var frame: String {
        let frames = framesForMood
        return frames[tick % frames.count]
    }

    private var framesForMood: [String] {
        switch mood {
        case .idle:
            return [
                Self.make(["   /\\_/\\", "  ( o.o )", "  /| _ |\\", "   /   \\", "  _|   |_"]),
                Self.make(["   /\\_/\\", "  ( o.o )", "  /| _ |\\", "   /   \\", "   |___|"])
            ]
        case .happy:
            return [
                Self.make(["   /\\_/\\", "  ( ^.^ )", "  /| * |\\", "   / \\ \\", "  _| |_|"]),
                Self.make(["  \\/\\_/\\/", "  ( ^o^ )", "  /| * |\\", "   / \\ \\", "  _| |_|"])
            ]
        case .thinking:
            return [
                Self.make(["   /\\_/\\", "  ( o.o )  ?", "  /| _ |\\", "   /   \\", "   |___|"]),
                Self.make(["   /\\_/\\", "  ( o_o )  ..", "  /| _ |\\", "   /   \\", "   |___|"])
            ]
        case .working:
            return [
                Self.make(["    .-.", "  <(o o)> *", "   /| # |\\", "  /_|___|_\\", "    \\ /"]),
                Self.make(["    .-.", "  <(o o)> **", "   /| # |\\", "  /_|___|_\\", "    / \\"])
            ]
        case .sleepy:
            return [
                Self.make(["   /\\_/\\", "  ( -.- ) z", "  /| _ |\\", "   /   \\", "   |___|"]),
                Self.make(["   /\\_/\\", "  ( -.- ) zz", "  /| _ |\\", "   /   \\", "  _|___|_"])
            ]
        case .levelUp:
            return [
                Self.make(["  * /\\_/\\ *", "   ( ^.^ )", "  /|[*]|\\", "   / \\ \\", "  _| |_|"]),
                Self.make([" **/\\_/\\**", "   ( ^o^ )", "  /|[*]|\\", "   / \\ \\", "  _| |_|"])
            ]
        }
    }

    private static func make(_ lines: [String]) -> String {
        lines.joined(separator: "\n")
    }
}
