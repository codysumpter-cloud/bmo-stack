import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case goal
    case role
    case behavior
    case building
    case summary
}

struct OnboardingFlow: View {
    @EnvironmentObject private var appState: AppState
    @State private var step: OnboardingStep = .welcome
    @State private var config = StackConfig.default
    @State private var buildProgress: Double = 0
    @State private var buildMessages: [String] = []

    var body: some View {
        ZStack {
            BMOTheme.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                if step != .welcome && step != .building {
                    progressBar
                        .padding(.horizontal, BMOTheme.spacingLG)
                        .padding(.top, BMOTheme.spacingMD)
                }

                // Content
                Group {
                    switch step {
                    case .welcome: welcomeScreen
                    case .goal: goalScreen
                    case .role: roleScreen
                    case .behavior: behaviorScreen
                    case .building: buildingScreen
                    case .summary: summaryScreen
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Progress

    private var progressBar: some View {
        let total = OnboardingStep.allCases.count - 2 // exclude welcome + building
        let current = max(0, step.rawValue - 1)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(BMOTheme.divider)
                    .frame(height: 4)
                Capsule()
                    .fill(BMOTheme.accent)
                    .frame(width: geo.size.width * CGFloat(current) / CGFloat(max(1, total - 1)), height: 4)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Welcome

    private var welcomeScreen: some View {
        VStack(spacing: BMOTheme.spacingLG) {
            Spacer()

            Image(systemName: "cpu")
                .font(.system(size: 64))
                .foregroundColor(BMOTheme.accent)
                .shadow(color: BMOTheme.accentGlow, radius: 20)

            Text("BeMoreAgent")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)

            Text("Your on-device AI command center.\nPrivate. Autonomous. Yours.")
                .font(.body)
                .foregroundColor(BMOTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BMOTheme.spacingXL)

            Spacer()

            Button("Get Started") {
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = .goal
                }
            }
            .buttonStyle(BMOButtonStyle())

            Spacer().frame(height: BMOTheme.spacingXL)
        }
    }

    // MARK: - Goal

    private var goalScreen: some View {
        VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
            Spacer().frame(height: BMOTheme.spacingXL)

            Text("What are you\nbuilding toward?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)
                .padding(.horizontal, BMOTheme.spacingLG)

            Text("This helps your agent stack understand your intent.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
                .padding(.horizontal, BMOTheme.spacingLG)

            let goals = [
                ("rocket", "Launch a product"),
                ("brain.head.profile", "Learn & research"),
                ("hammer", "Build & create"),
                ("chart.line.uptrend.xyaxis", "Grow a business"),
                ("person.2", "Manage a team"),
                ("ellipsis.circle", "Something else"),
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(goals, id: \.1) { icon, label in
                    Button {
                        config.goal = label
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: icon)
                                .font(.title2)
                            Text(label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .foregroundColor(config.goal == label ? BMOTheme.backgroundPrimary : BMOTheme.textPrimary)
                        .background(config.goal == label ? BMOTheme.accent : BMOTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, BMOTheme.spacingLG)

            Spacer()

            navButtons(back: .welcome, next: .role, canProceed: !config.goal.isEmpty)
        }
    }

    // MARK: - Role

    private var roleScreen: some View {
        VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
            Spacer().frame(height: BMOTheme.spacingXL)

            Text("What's your role?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)
                .padding(.horizontal, BMOTheme.spacingLG)

            Text("We'll tailor agent behavior to match how you work.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
                .padding(.horizontal, BMOTheme.spacingLG)

            let roles = [
                "Founder / CEO",
                "Engineer",
                "Designer",
                "Product Manager",
                "Researcher",
                "Creator / Writer",
                "Student",
                "Other",
            ]

            VStack(spacing: 10) {
                ForEach(roles, id: \.self) { role in
                    Button {
                        config.role = role
                    } label: {
                        HStack {
                            Text(role)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            if config.role == role {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(BMOTheme.accent)
                            }
                        }
                        .padding(.horizontal, BMOTheme.spacingMD)
                        .padding(.vertical, 14)
                        .foregroundColor(config.role == role ? BMOTheme.textPrimary : BMOTheme.textSecondary)
                        .background(config.role == role ? BMOTheme.backgroundCardHover : BMOTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, BMOTheme.spacingLG)

            Spacer()

            navButtons(back: .goal, next: .behavior, canProceed: !config.role.isEmpty)
        }
    }

    // MARK: - Behavior

    private var behaviorScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)

                Text("Configure your\nagent stack")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)
                    .padding(.horizontal, BMOTheme.spacingLG)

                // Autonomy
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "gauge.open.with.lines.needle.33percent")
                            .foregroundColor(BMOTheme.accent)
                        Text("Autonomy Level")
                            .font(.headline)
                            .foregroundColor(BMOTheme.textPrimary)
                    }
                    Text("How much should agents act on their own?")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)

                    HStack {
                        Text("Ask first")
                            .font(.caption)
                            .foregroundColor(BMOTheme.textTertiary)
                        Slider(value: Binding(
                            get: { Double(config.autonomyLevel) },
                            set: { config.autonomyLevel = Int($0) }
                        ), in: 1...5, step: 1)
                        .tint(BMOTheme.accent)
                        Text("Full auto")
                            .font(.caption)
                            .foregroundColor(BMOTheme.textTertiary)
                    }
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                // Memory toggle
                toggleCard(
                    icon: "brain",
                    title: "Memory",
                    subtitle: "Remember context across sessions",
                    isOn: $config.memoryEnabled
                )
                .padding(.horizontal, BMOTheme.spacingLG)

                // Tools toggle
                toggleCard(
                    icon: "wrench.and.screwdriver",
                    title: "Tools",
                    subtitle: "Allow agents to use external tools and APIs",
                    isOn: $config.toolsEnabled
                )
                .padding(.horizontal, BMOTheme.spacingLG)

                // Optimization mode
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "dial.low")
                            .foregroundColor(BMOTheme.accent)
                        Text("Optimization")
                            .font(.headline)
                            .foregroundColor(BMOTheme.textPrimary)
                    }

                    HStack(spacing: 10) {
                        ForEach(["speed", "balanced", "quality"], id: \.self) { mode in
                            Button {
                                config.optimizationMode = mode
                            } label: {
                                Text(mode.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(config.optimizationMode == mode ? BMOTheme.backgroundPrimary : BMOTheme.textSecondary)
                                    .background(config.optimizationMode == mode ? BMOTheme.accent : BMOTheme.backgroundSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusSmall, style: .continuous))
                            }
                        }
                    }
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                navButtons(back: .role, next: .building, canProceed: true)
                    .padding(.top, BMOTheme.spacingMD)
            }
        }
    }

    // MARK: - Building

    private var buildingScreen: some View {
        VStack(spacing: BMOTheme.spacingLG) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(BMOTheme.divider, lineWidth: 4)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: buildProgress)
                    .stroke(BMOTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "bolt.fill")
                    .font(.system(size: 36))
                    .foregroundColor(BMOTheme.accent)
            }

            Text("Building your stack...")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(buildMessages, id: \.self) { msg in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(BMOTheme.success)
                        Text(msg)
                            .font(.subheadline)
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, BMOTheme.spacingXL)

            Spacer()
        }
        .onAppear { runBuildSequence() }
    }

    private func runBuildSequence() {
        let steps = [
            (0.2, "Configuring primary agent..."),
            (0.4, "Setting up memory layer..."),
            (0.6, "Preparing tool connections..."),
            (0.8, "Checking model availability..."),
            (1.0, "Stack ready."),
        ]

        for (index, (progress, message)) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.6) {
                withAnimation(.easeOut(duration: 0.4)) {
                    buildProgress = progress
                    buildMessages.append(message)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps.count) * 0.6 + 0.5) {
            withAnimation(.easeInOut(duration: 0.35)) {
                step = .summary
            }
        }
    }

    // MARK: - Summary

    private var summaryScreen: some View {
        ScrollView {
            VStack(spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(BMOTheme.success)

                Text(config.stackName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)

                Text("Your agent stack is configured and ready.")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textSecondary)

                VStack(spacing: 12) {
                    summaryRow(icon: "target", label: "Goal", value: config.goal)
                    summaryRow(icon: "person", label: "Role", value: config.role)
                    summaryRow(icon: "gauge.open.with.lines.needle.33percent", label: "Autonomy", value: "\(config.autonomyLevel)/5")
                    summaryRow(icon: "brain", label: "Memory", value: config.memoryEnabled ? "On" : "Off")
                    summaryRow(icon: "wrench.and.screwdriver", label: "Tools", value: config.toolsEnabled ? "On" : "Off")
                    summaryRow(icon: "dial.low", label: "Mode", value: config.optimizationMode.capitalized)
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                // Agent summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Agent")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                    HStack(spacing: 12) {
                        Circle()
                            .fill(BMOTheme.accent)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "cpu")
                                    .foregroundColor(BMOTheme.backgroundPrimary)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BMO Agent")
                                .font(.headline)
                                .foregroundColor(BMOTheme.textPrimary)
                            Text("On-device • gemma4-e2b-it")
                                .font(.caption)
                                .foregroundColor(BMOTheme.textSecondary)
                        }
                    }
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                Button("Launch") {
                    config.isOnboardingComplete = true
                    appState.completeOnboarding(config)
                }
                .buttonStyle(BMOButtonStyle())
                .padding(.top, BMOTheme.spacingMD)

                Spacer().frame(height: BMOTheme.spacingXL)
            }
        }
    }

    // MARK: - Helpers

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(BMOTheme.accent)
            Text(label)
                .foregroundColor(BMOTheme.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(BMOTheme.textPrimary)
        }
    }

    private func toggleCard(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(BMOTheme.accent)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(BMOTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(BMOTheme.accent)
                .labelsHidden()
        }
        .bmoCard()
    }

    private func navButtons(back: OnboardingStep?, next: OnboardingStep, canProceed: Bool) -> some View {
        HStack {
            if let back {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) { step = back }
                } label: {
                    Image(systemName: "arrow.left")
                        .foregroundColor(BMOTheme.textSecondary)
                        .frame(width: 48, height: 48)
                        .background(BMOTheme.backgroundCard)
                        .clipShape(Circle())
                }
            }

            Spacer()

            Button("Continue") {
                withAnimation(.easeInOut(duration: 0.35)) { step = next }
            }
            .buttonStyle(BMOButtonStyle())
            .disabled(!canProceed)
            .opacity(canProceed ? 1.0 : 0.4)
        }
        .padding(.horizontal, BMOTheme.spacingLG)
        .padding(.bottom, BMOTheme.spacingLG)
    }
}
