import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case chooseBuddy
    case nameBuddy
    case focusBuddy
    case powerMode
    case building
    case summary
}

struct OnboardingFlow: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var buddyStore = BuddyProfileStore()
    @State private var step: OnboardingStep = .welcome
    @State private var config = StackConfig.default
    @State private var selectedTemplateID = ""
    @State private var buddyName = ""
    @State private var buddyFocus = ""
    @State private var selectedPowerMode: BuddyPowerMode = .balanced
    @State private var showAdvancedSetup = false
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
                    case .chooseBuddy: chooseBuddyScreen
                    case .nameBuddy: nameBuddyScreen
                    case .focusBuddy: focusBuddyScreen
                    case .powerMode: powerModeScreen
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
            buddyStore.load(for: appState.stackConfig)
            appState.buddyStore.load(for: appState.stackConfig)
            if selectedTemplateID.isEmpty {
                selectedTemplateID = buddyStore.templates.first?.templateID ?? ""
            }
            if buddyName.isEmpty {
                buddyName = config.onboardingBuddyName ?? "Buddy"
            }
            if buddyFocus.isEmpty {
                buddyFocus = config.onboardingBuddyFocus ?? "Help me decide what matters and finish the next useful step."
            }
            selectedPowerMode = config.onboardingPowerMode ?? .balanced
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

            BuddyAsciiView(mood: .happy)
                .padding(.horizontal, BMOTheme.spacingXL)

            Text("Welcome to BeMore")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("Start with a Buddy. Runtime pairing, models, and power mode come after your companion has an identity.")
                .font(.body)
                .foregroundColor(BMOTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BMOTheme.spacingXL)

            VStack(alignment: .leading, spacing: 10) {
                featureRow("Choose the Buddy who will be with you on Home, Chat, Skills, and Results")
                featureRow("Name them and set their first focus")
                featureRow("Add Mac power mode later when you want a stronger runtime")
            }
            .padding(.horizontal, BMOTheme.spacingXL)

            Spacer()

            Button("Create my Buddy") {
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = .chooseBuddy
                }
            }
            .buttonStyle(BMOButtonStyle())

            Spacer().frame(height: BMOTheme.spacingXL)
        }
    }

    private var chooseBuddyScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)

                onboardingTitle("Choose your first Buddy", subtitle: "Pick a starter archetype. You can own more Buddies later, but this one becomes your active companion now.")

                if buddyStore.templates.isEmpty {
                    Text("Buddy templates are still loading. Continue and BeMore will use the default Buddy when it is ready.")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                        .bmoCard()
                        .padding(.horizontal, BMOTheme.spacingLG)
                } else {
                    VStack(spacing: 12) {
                        ForEach(buddyStore.templates) { template in
                            buddyTemplateButton(template)
                        }
                    }
                    .padding(.horizontal, BMOTheme.spacingLG)
                }

                navButtons(back: .welcome, next: .nameBuddy, canProceed: !selectedTemplateID.isEmpty || buddyStore.templates.isEmpty)
                    .padding(.top, BMOTheme.spacingMD)
            }
        }
    }

    private var nameBuddyScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)
                onboardingTitle("Name your Buddy", subtitle: "Give your companion the name you want to see on Home, Chat, tasks, training, and receipts.")
                labeledField(title: "Buddy name", text: $buddyName, placeholder: selectedTemplate?.name ?? "Buddy")
                selectedBuddyPreview
                navButtons(back: .chooseBuddy, next: .focusBuddy, canProceed: !trimmed(buddyName).isEmpty)
                    .padding(.top, BMOTheme.spacingMD)
            }
        }
    }

    private var focusBuddyScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)
                onboardingTitle("Pick your Buddy's first focus", subtitle: "This sets the first use-case BeMore reinforces after onboarding. You can change it later.")
                labeledField(title: "First focus", text: $buddyFocus, placeholder: selectedTemplate?.canonicalRole ?? "Help me finish the next useful step")
                VStack(alignment: .leading, spacing: 10) {
                    Text("How this will show up")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                    Text("\(fallback(buddyName, defaultValue: selectedTemplate?.name ?? "Buddy")) will open on Home with this focus, carry it into Chat, and use it as the default for the first check-ins and receipts.")
                        .font(.subheadline)
                        .foregroundColor(BMOTheme.textSecondary)
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)
                navButtons(back: .nameBuddy, next: .powerMode, canProceed: !trimmed(buddyFocus).isEmpty)
                    .padding(.top, BMOTheme.spacingMD)
            }
        }
    }

    private var powerModeScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)
                onboardingTitle("Power mode is optional", subtitle: "BeMore can start as your Buddy on iPhone. Pairing Mac and route setup are stronger-mode choices, not the first thing you have to understand.")

                VStack(spacing: 12) {
                    ForEach(BuddyPowerMode.allCases) { mode in
                        Button {
                            selectedPowerMode = mode
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.title)
                                        .font(.headline)
                                    Text(mode.subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(BMOTheme.textSecondary)
                                }
                                Spacer()
                                if selectedPowerMode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(BMOTheme.accent)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .foregroundColor(BMOTheme.textPrimary)
                            .background(selectedPowerMode == mode ? BMOTheme.backgroundCardHover : BMOTheme.backgroundCard)
                            .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, BMOTheme.spacingLG)

                toggleCard(icon: "macbook.and.iphone", title: "Pair with Mac later", subtitle: "Keep Mac runtime pairing available after you land on Buddy Home.", isOn: $config.installDesktopNode)
                    .padding(.horizontal, BMOTheme.spacingLG)
                toggleCard(icon: "bell.badge", title: "Buddy notifications", subtitle: "Allow BeMore to remind you about Buddy tasks, results, and check-ins when enabled.", isOn: $config.enableNotifications)
                    .padding(.horizontal, BMOTheme.spacingLG)

                DisclosureGroup(isExpanded: $showAdvancedSetup) {
                    VStack(spacing: BMOTheme.spacingMD) {
                        labeledField(title: "Runtime endpoint", text: $config.gatewayURL, placeholder: "https://bemore.example.com")
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        labeledField(title: "Public domain", text: $config.adminDomain, placeholder: "example.com")
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        toggleCard(icon: "wrench.and.screwdriver", title: "Tools", subtitle: "Allow tool and API actions when the connected runtime supports them.", isOn: $config.toolsEnabled)
                        toggleCard(icon: "brain", title: "Memory", subtitle: "Persist Buddy and operator context locally on device.", isOn: $config.memoryEnabled)
                    }
                    .padding(.top, BMOTheme.spacingMD)
                } label: {
                    Text("Advanced runtime setup")
                        .font(.headline)
                        .foregroundColor(BMOTheme.textPrimary)
                }
                .padding(BMOTheme.spacingMD)
                .background(BMOTheme.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                .padding(.horizontal, BMOTheme.spacingLG)

                navButtons(back: .focusBuddy, next: .building, canProceed: true)
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
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 36))
                    .foregroundColor(BMOTheme.accent)
            }

            Text("Waking \(buddyName)")
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

    private var summaryScreen: some View {
        ScrollView {
            VStack(spacing: BMOTheme.spacingLG) {
                Spacer().frame(height: BMOTheme.spacingXL)

                BuddyAsciiView(mood: .levelUp)
                    .padding(.horizontal, BMOTheme.spacingXL)

                Text("\(buddyName) is ready")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BMOTheme.textPrimary)

                Text("You’ll land on Buddy Home. Chat, Skills, Results, and Mac power mode all point back to this active Buddy.")
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BMOTheme.spacingLG)

                VStack(spacing: 12) {
                    summaryRow(icon: "person.crop.circle.badge.checkmark", label: "Active Buddy", value: buddyName)
                    summaryRow(icon: "sparkles", label: "Starter", value: selectedTemplate?.name ?? "Default Buddy")
                    summaryRow(icon: "scope", label: "Focus", value: buddyFocus)
                    summaryRow(icon: "dial.high", label: "Power mode", value: selectedPowerMode.title)
                    summaryRow(icon: "macbook.and.iphone", label: "Mac power", value: config.installDesktopNode ? "Available later" : "Phone-first")
                    summaryRow(icon: "creditcard", label: "Plans", value: "Free now; Plus and Council previews in Pricing")
                }
                .bmoCard()
                .padding(.horizontal, BMOTheme.spacingLG)

                Button("Go to Buddy Home") {
                    finishOnboarding()
                }
                .buttonStyle(BMOButtonStyle())
                .padding(.top, BMOTheme.spacingMD)

                Spacer().frame(height: BMOTheme.spacingXL)
            }
        }
    }

    private func runBuildSequence() {
        buildProgress = 0
        buildMessages = []
        let name = fallback(buddyName, defaultValue: selectedTemplate?.name ?? "Buddy")
        let steps = [
            (0.25, "Creating \(name) as your active Buddy"),
            (0.50, "Linking Buddy to Home, Chat, Skills, and Results"),
            (0.75, config.installDesktopNode ? "Keeping Mac power mode available as an optional upgrade" : "Starting in phone-first mode"),
            (1.0, "Preparing your Buddy-first BeMore shell")
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

    private func finishOnboarding() {
        let cleanedBuddyName = fallback(buddyName, defaultValue: selectedTemplate?.name ?? "Buddy")
        let cleanedFocus = fallback(buddyFocus, defaultValue: selectedTemplate?.canonicalRole ?? "Finish the next useful step")
        let templateID = selectedTemplate?.templateID ?? selectedTemplateID

        config.stackName = fallback(config.stackName, defaultValue: "BeMore")
        config.goal = cleanedFocus
        config.role = selectedTemplate?.canonicalRole ?? "Buddy companion"
        config.operatorName = fallback(config.operatorName, defaultValue: "Builder")
        config.gatewayURL = fallback(config.gatewayURL, defaultValue: "https://prismtek.dev")
        config.adminDomain = fallback(config.adminDomain, defaultValue: "prismtek.dev")
        config.onboardingBuddyName = cleanedBuddyName
        config.onboardingBuddyTemplateID = templateID
        config.onboardingBuddyFocus = cleanedFocus
        config.onboardingPowerMode = selectedPowerMode
        config.optimizationMode = selectedPowerMode.optimizationMode
        config.setupChecklist = generatedChecklist
        config.isOnboardingComplete = true
        appState.completeOnboarding(config)
        appState.buddyStore.ensureStarterBuddy(templateID: templateID, displayName: cleanedBuddyName, focus: cleanedFocus, using: appState)
        appState.selectedTab = .missionControl
    }

    private var selectedTemplate: CouncilStarterBuddyTemplate? {
        buddyStore.templates.first(where: { $0.templateID == selectedTemplateID || $0.id == selectedTemplateID }) ?? buddyStore.templates.first
    }

    private var selectedBuddyPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your active Buddy")
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            Text(selectedTemplate?.ascii.baseSilhouette ?? "    /\\\n  < o  o >\n  /|  v |\\\n /_|____|_\\")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(BMOTheme.accent)
            Text("\(fallback(buddyName, defaultValue: selectedTemplate?.name ?? "Buddy")) will become the Buddy shown on Home and in Chat.")
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
        .bmoCard()
        .padding(.horizontal, BMOTheme.spacingLG)
    }

    private func buddyTemplateButton(_ template: CouncilStarterBuddyTemplate) -> some View {
        Button {
            selectedTemplateID = template.templateID
            if buddyName == "Buddy" || buddyName.isEmpty {
                buddyName = template.name
            }
            if buddyFocus.isEmpty {
                buddyFocus = template.canonicalRole
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                        Text(template.starterRole)
                            .font(.subheadline)
                            .foregroundColor(BMOTheme.textSecondary)
                    }
                    Spacer()
                    if selectedTemplateID == template.templateID {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(BMOTheme.accent)
                    }
                }
                Text(template.onboardingCopy)
                    .font(.subheadline)
                    .foregroundColor(BMOTheme.textSecondary)
                Text(template.ascii.baseSilhouette)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(BMOTheme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .foregroundColor(BMOTheme.textPrimary)
            .background(selectedTemplateID == template.templateID ? BMOTheme.backgroundCardHover : BMOTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
        }
    }

    private func onboardingTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(BMOTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(BMOTheme.textSecondary)
        }
        .padding(.horizontal, BMOTheme.spacingLG)
    }

    @ViewBuilder
    private func labeledField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(BMOTheme.textPrimary)
            TextField(placeholder, text: text, axis: title == "First focus" ? .vertical : .horizontal)
                .textFieldStyle(.plain)
                .padding()
                .background(BMOTheme.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: BMOTheme.radiusMedium, style: .continuous))
                .foregroundColor(BMOTheme.textPrimary)
        }
        .padding(.horizontal, BMOTheme.spacingLG)
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

            Button(next == .building ? "Start BeMore" : "Continue") {
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

    private var generatedChecklist: [String] {
        var items = ["Keep \(fallback(buddyName, defaultValue: selectedTemplate?.name ?? "Buddy")) active on Home, Chat, Skills, and Results."]
        items.append("Start in \(selectedPowerMode.title.lowercased()) so the first-run shell matches your comfort level.")
        if config.installDesktopNode {
            items.append("Pair a BeMore Mac runtime when you want workspace execution, diffs, artifacts, and receipts from your desktop.")
        }
        if config.toolsEnabled {
            items.append("Enable only the tools you want this Buddy to use through the connected runtime.")
        }
        items.append("Use Pricing to compare free Buddy slots, Plus runtime capacity, and Council/marketplace access before upgrading.")
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
