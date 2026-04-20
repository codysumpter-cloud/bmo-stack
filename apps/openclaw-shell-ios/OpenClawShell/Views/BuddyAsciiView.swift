import SwiftUI

struct BuddyAsciiView: View {
    var buddy: BuddyInstance?
    var template: CouncilStarterBuddyTemplate?
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
            .accessibilityLabel("\(buddy?.displayName ?? "Buddy") \(label)")
    }

    private var label: String {
        switch mood {
        case .idle: return "idle"
        case .happy: return "happy"
        case .thinking: return "thinking"
        case .working: return "working"
        case .sleepy: return "sleepy"
        case .levelUp: return "level up"
        case .needsAttention: return "needs attention"
        }
    }

    private var frame: String {
        let frames = framesForMood
        return frames[tick % frames.count]
    }

    private var framesForMood: [String] {
        if let template {
            let state = moodKey
            if state == "idle", template.ascii.idleFrames.isEmpty == false {
                return template.ascii.idleFrames
            }
            if let expression = template.ascii.expressions[state] {
                return [expression, template.ascii.baseSilhouette]
            }
            return activeTemplateFallbackFrames(for: template.ascii.baseSilhouette)
        }
        switch mood {
        case .idle:
            return [
                Self.make(["    /\\", "  < o  o >", "  /|  v |\\", " /_|____|_\\", "   /_  _\\"]),
                Self.make(["    /\\", "  < o  o >", "  /|  v |\\", " /_|____|_\\", "   \\_  _/"])
            ]
        case .happy:
            return [
                Self.make(["  \\ /\\ /", "  < ^  ^ >", "  /|  * |\\", " /_|____|_\\", "    /  \\"]),
                Self.make([" *  /\\  *", "  < ^  o >", "  /|  * |\\", " /_|____|_\\", "    \\  /"])
            ]
        case .thinking:
            return [
                Self.make(["    /\\   ?", "  < o  o >", "  /|  ? |\\", " /_|____|_\\", "    /  \\"]),
                Self.make(["    /\\  ..", "  < o  O >", "  /|  ? |\\", " /_|____|_\\", "    \\  /"])
            ]
        case .working:
            return [
                Self.make(["    /\\  #", "  < >  < >", "  /| [ ]|\\", " /_|____|_\\", "   /_  _\\"]),
                Self.make(["    /\\  ##", "  < >  < >", "  /| [*]|\\", " /_|____|_\\", "   \\_  _/"])
            ]
        case .sleepy:
            return [
                Self.make(["    /\\   z", "  < -  - >", "  /|  . |\\", " /_|____|_\\", "    /__\\"]),
                Self.make(["    /\\  zz", "  < -  - >", "  /|  . |\\", " /_|____|_\\", "   _/  \\_"])
            ]
        case .levelUp:
            return [
                Self.make([" ** /\\ **", "  < ^  ^ >", "  /|{*}|\\", " /_|____|_\\", "    /  \\"]),
                Self.make(["*** /\\ ***", "  < ^  o >", "  /|{*}|\\", " /_|____|_\\", "    \\  /"])
            ]
        case .needsAttention:
            return [
                Self.make([" !  /\\  !", "  < o  o >", "  /|  ! |\\", " /_|____|_\\", "    /  \\"]),
                Self.make([" !! /\\ !!", "  < O  o >", "  /|  ! |\\", " /_|____|_\\", "    \\  /"])
            ]
        }
    }

    private func activeTemplateFallbackFrames(for silhouette: String) -> [String] {
        switch mood {
        case .idle:
            return [silhouette]
        case .happy:
            return [Self.wrap(silhouette, top: "\\   /", bottom: "  YES"), Self.wrap(silhouette, top: " \\ / ", bottom: "  <3 ")]
        case .thinking:
            return [Self.wrap(silhouette, top: "  ? ", bottom: "  ..."), Self.wrap(silhouette, top: " ?  ", bottom: "  hmm")]
        case .working:
            return [Self.wrap(silhouette, top: "  ##", bottom: "[work]"), Self.wrap(silhouette, top: " ###", bottom: "[build]")]
        case .sleepy:
            return [Self.wrap(silhouette, top: "   z", bottom: " rest"), Self.wrap(silhouette, top: "  zz", bottom: " slow")]
        case .levelUp:
            return [Self.wrap(silhouette, top: "** **", bottom: "LEVEL"), Self.wrap(silhouette, top: "*****", bottom: " UP! ")]
        case .needsAttention:
            return [Self.wrap(silhouette, top: " ! !", bottom: "check"), Self.wrap(silhouette, top: "!! !!", bottom: " care")]
        }
    }

    private var moodKey: String {
        switch mood {
        case .idle: return buddy?.visual?.currentAnimationState ?? buddy?.state.mood ?? "idle"
        case .happy: return "happy"
        case .thinking: return "thinking"
        case .working: return "working"
        case .sleepy: return "sleepy"
        case .levelUp: return "levelUp"
        case .needsAttention: return "needsAttention"
        }
    }

    private static func make(_ lines: [String]) -> String {
        lines.joined(separator: "\n")
    }

    private static func wrap(_ silhouette: String, top: String, bottom: String) -> String {
        "\(top)\n\(silhouette.trimmingCharacters(in: .newlines))\n\(bottom)"
    }
}
