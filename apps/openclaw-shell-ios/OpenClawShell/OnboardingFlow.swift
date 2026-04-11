import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case intent
    case operatorProfile
    case stackSetup
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
                if step != .welcome && step != .building {
                    progressBar
                        .padding(.horizontal, BMOTheme.spacingLG)
                        .padding(.top, BMOTheme.spacingMD)
                }

                Group {
                    switch step {
                    case .welcome: welcomeScreen
                    case .intent: intentScreen
                    case .operatorProfile: operatorProfileScreen
                    case .stackSetup: stackSetupScreen
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
        .onAppear {
            config = appState.stackConfig
        }
    }

    private var progressBar: some View {
        let total = OnboardingStep.allCases.count - 2
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

    private var welcomeScreen: some View {
        VStack(spacing: BMOTheme.spacingLG) {
            Spacer()

            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 64))
                .foregroundColor(BMOTheme.accent)
                .shadow(color: BMOTheme.accentGlow, radius: 20)

            Text("BeMoreAgent")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)

            Text("Build the mobile front door for a real BeMore stack, based on the answers you give here.")
                .font(.body)
                .foregroundColor(BMOTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BMOTheme.spacingXL)

            VStack(alignment: .leading, spacing: 10) {
                featureRow("Generate a concrete stack profile instead of fake setup copy")
                featureRow("Target a real BeMore runtime and Mac pairing flow")
                featureRow("Show honest readiness for local runtime, providers, and shell surfaces")
            }
            .padding(.horizontal, BMOTheme.spacingXL)

            Spacer()

            Button("Build my stack") {
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = .intent
                }
            }
            .buttonStyle(BMOButtonStyle())

            Spacer().frame(height: BMOTheme.spacingXL)
        }
    }

    private var intentScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)

                Text("What stack are we setting up?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)
                    .padding(.horizontal, BMOTheme.spacingLG)

                Text("This should match the real BeMore deployment the app is going to represent.")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textSecondary)
                    .padding(.horizontal, BMOTheme.spacingLG)

                VStack(spacing: 12) {
                    ForEach(StackDeploymentMode.allCases) { mode in
                        Button {
                            config.deploymentMode = mode
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(mode.title)
                                        .font(.headline)
                                    Spacer()
                                    if config.deploymentMode == mode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(BMOTheme.accent)
                                    }
                                }
                                Text(mode.subtitle)
                                    .font(.caption)
                                    .foregroundColor(BMOTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .foregroundColor(BMOTheme.textPrimary)
                            .background(config.deploymentMode == mode ? BMOTheme.backgroundCardHover : BMOTheme.backgroundCard)
                            .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, BMOTheme.spacingLG)

                labeledField(title: "Stack name", text: $config.stackName, placeholder: "BeMoreAgent")
                labeledField(title: "Primary goal", text: $config.goal, placeholder: "Run my own BeMore stack")
                labeledField(title: "Runtime endpoint", text: $config.gatewayURL, placeholder: "https://bemore.example.com")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                labeledField(title: "Admin / public domain", text: $config.adminDomain, placeholder: "example.com")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                navButtons(back: .welcome, next: .operatorProfile, canProceed: canContinueFromIntent)
                    .padding(.top, BMOTheme.spacingMD)
            }
        }
    }

    private var operatorProfileScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)

                Text("Who is this stack for?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)
                    .padding(.horizontal, BMOTheme.spacingLG)

                labeledField(title: "Operator name", text: $config.operatorName, placeholder: "Cody")
                labeledField(title: "Role", text: $config.role, placeholder: "Builder, founder, operator")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Autonomy")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("How aggressively should the stack try to act on its own once connected?")
                        .font(.caption)
                        .foregroundColor(BMOTheme.textSecondary)
                    HStack {
                        Text("Guarded")
                            .font(.caption)
                            .foregroundColor(BMOTheme.textTertiary)
                        Slider(value: Binding(get: { Double(config.autonomyLevel) }, set: { config.autonomyLevel = Int($0) }), in: 1...5, step: 1)
                            .tint(BMOTheme.accent)
                        Text("Autonomous")
                            .font(.caption)
                            .foregroundColor(BMOTheme.textTertiary)
                    }
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                toggleCard(icon: "brain", title: "Memory", subtitle: "Persist operator context and stack state locally on device", isOn: $config.memoryEnabled)
                    .padding(.horizontal, BMOTheme.spacingLG)
                toggleCard(icon: "wrench.and.screwdriver", title: "Tools", subtitle: "Allow tool and API actions when the connected stack supports them", isOn: $config.toolsEnabled)
                    .padding(.horizontal, BMOTheme.spacingLG)
                toggleCard(icon: "app.badge", title: "Notifications", subtitle: "Enable push surfaces for node events and stack health", isOn: $config.enableNotifications)
                    .padding(.horizontal, BMOTheme.spacingLG)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Optimization")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
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

                navButtons(back: .intent, next: .stackSetup, canProceed: !trimmed(config.operatorName).isEmpty && !trimmed(config.role).isEmpty)
                    .padding(.top, BMOTheme.spacingMD)
            }
        }
    }

    private var stackSetupScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)

                Text("What should this app stand up?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)
                    .padding(.horizontal, BMOTheme.spacingLG)

                Text("This is the contract the shell should reflect after onboarding.")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textSecondary)
                    .padding(.horizontal, BMOTheme.spacingLG)

                toggleCard(icon: "iphone", title: "Install node on this phone", subtitle: "Treat iPhone capabilities as part of the self-hosted stack surface", isOn: $config.installNodeOnThisPhone)
                    .padding(.horizontal, BMOTheme.spacingLG)
                toggleCard(icon: "desktopcomputer", title: "Expect desktop / server node", subtitle: "Assume a host runtime or desktop companion is part of the stack", isOn: $config.installDesktopNode)
                    .padding(.horizontal, BMOTheme.spacingLG)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Generated setup checklist")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    ForEach(generatedChecklist, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checklist")
                                .foregroundColor(BMOTheme.accent)
                                .padding(.top, 2)
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(BMOTheme.textSecondary)
                        }
                    }
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                navButtons(back: .operatorProfile, next: .building, canProceed: true)
                    .padding(.top, BMOTheme.spacingMD)
            }
        }
    }

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
                Image(systemName: "server.rack")
                    .font(.system(size: 36))
                    .foregroundColor(BMOTheme.accent)
            }

            Text("Building your stack profile...")
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
        config.setupChecklist = generatedChecklist
        buildProgress = 0
        buildMessages = []

        let steps = [
            (0.2, "Saving operator profile for \(trimmed(config.operatorName).isEmpty ? "this device" : trimmed(config.operatorName))"),
            (0.4, "Targeting runtime endpoint \(trimmed(config.gatewayURL))"),
            (0.6, config.installNodeOnThisPhone ? "Marking this iPhone as a node-capable surface" : "Skipping local node install on this phone"),
            (0.8, config.installDesktopNode ? "Expecting a desktop or server runtime companion" : "Running in phone-only mode"),
            (1.0, "Stack profile ready. The shell will show actual readiness instead of pretending setup is complete.")
        ]

        for (index, (progress, message)) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                withAnimation(.easeOut(duration: 0.35)) {
                    buildProgress = progress
                    buildMessages.append(message)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps.count) * 0.5 + 0.4) {
            withAnimation(.easeInOut(duration: 0.35)) {
                step = .summary
            }
        }
    }

    private var summaryScreen: some View {
        ScrollView {
            VStack(spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(BMOTheme.success)

                Text(trimmed(config.stackName).isEmpty ? "BeMoreAgent" : trimmed(config.stackName))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)

                Text("Your iPhone shell now reflects a real BeMore setup profile.")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textSecondary)

                VStack(spacing: 12) {
                    summaryRow(icon: "person.crop.circle", label: "Operator", value: trimmed(config.operatorName))
                    summaryRow(icon: "briefcase", label: "Role", value: trimmed(config.role))
                    summaryRow(icon: "link", label: "Runtime", value: trimmed(config.gatewayURL))
                    summaryRow(icon: "switch.2", label: "Mode", value: config.deploymentMode.title)
                    summaryRow(icon: "gauge.open.with.lines.needle.33percent", label: "Autonomy", value: "\(config.autonomyLevel)/5")
                    summaryRow(icon: "brain", label: "Memory", value: config.memoryEnabled ? "On" : "Off")
                    summaryRow(icon: "wrench.and.screwdriver", label: "Tools", value: config.toolsEnabled ? "On" : "Off")
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Next steps the app expects")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    ForEach(config.setupChecklist, id: \.self) { item in
                        Text("• \(item)")
                            .font(.subheadline)
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

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
                            Text(primaryAgentSummary)
                                .font(.caption)
                                .foregroundColor(BMOTheme.textSecondary)
                        }
                    }
                    Text(primaryAgentDetail)
                        .font(.caption)
                        .foregroundColor(BMOTheme.textTertiary)
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                Button("Launch shell") {
                    config.stackName = fallback(config.stackName, defaultValue: "BeMoreAgent")
                    config.goal = fallback(config.goal, defaultValue: "Run a self-hosted BeMore stack")
                    config.role = fallback(config.role, defaultValue: "Operator")
                    config.operatorName = fallback(config.operatorName, defaultValue: "Operator")
                    config.gatewayURL = fallback(config.gatewayURL, defaultValue: "https://prismtek.dev")
                    config.adminDomain = fallback(config.adminDomain, defaultValue: "prismtek.dev")
                    config.setupChecklist = generatedChecklist
                    config.isOnboardingComplete = true
                    appState.completeOnboarding(config)
                }
                .buttonStyle(BMOButtonStyle())
                .padding(.top, BMOTheme.spacingMD)

                Spacer().frame(height: BMOTheme.spacingXL)
            }
        }
    }

    @ViewBuilder
    private func labeledField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding()
                .background(BMOTheme.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                .foregroundColor(BMOTheme.textPrimary)
        }
        .padding(.horizontal, BMOTheme.spacingLG)
    }

    private var primaryAgentSummary: String {
        appState.usesStubRuntime
            ? "Local-first shell • route setup after launch"
            : "On-device runtime available after model install"
    }

    private var primaryAgentDetail: String {
        appState.usesStubRuntime
            ? "This build still uses the stub local runtime. Launch into Mission Control, then use Models to link a cloud route or prepare a local model."
            : "Finish onboarding, then use Models to select an installed on-device route."
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(BMOTheme.accent)
            Text(label)
                .foregroundColor(BMOTheme.textSecondary)
            Spacer()
            Text(value.isEmpty ? "Not set" : value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
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

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(BMOTheme.success)
                .padding(.top, 1)
            Text(text)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
    }

    private var canContinueFromIntent: Bool {
        !trimmed(config.stackName).isEmpty && !trimmed(config.goal).isEmpty && !trimmed(config.gatewayURL).isEmpty && !trimmed(config.adminDomain).isEmpty
    }

    private var generatedChecklist: [String] {
        var items: [String] = []
        if config.deploymentMode == .bootstrapSelfHosted {
            items.append("Provision or verify a BeMore runtime endpoint at \(fallback(config.gatewayURL, defaultValue: "https://prismtek.dev")).")
            items.append("Set runtime and pairing/public URL values to match \(fallback(config.adminDomain, defaultValue: "prismtek.dev")).")
        } else {
            items.append("Pair this app to the existing BeMore runtime endpoint at \(fallback(config.gatewayURL, defaultValue: "https://prismtek.dev")).")
        }
        if config.installNodeOnThisPhone {
            items.append("Treat this iPhone as a node surface with notification, camera, and device capability permissions.")
        }
        if config.installDesktopNode {
            items.append("Keep a desktop or server node online so the shell has a real self-hosted stack to connect to.")
        }
        if config.toolsEnabled {
            items.append("Enable only the tools the operator actually wants exposed through the stack.")
        }
        items.append("Verify local runtime readiness honestly. Do not claim on-device inference is live unless the runtime bridge is actually present.")
        return items
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallback(_ value: String, defaultValue: String) -> String {
        let cleaned = trimmed(value)
        return cleaned.isEmpty ? defaultValue : cleaned
    }
}
