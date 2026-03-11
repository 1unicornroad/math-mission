//
//  MenuView.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import SwiftUI
import SwiftData

enum ArithmeticMode: String, CaseIterable {
    case multiplication
    case division

    var title: String {
        switch self {
        case .multiplication: return "Multiplication"
        case .division: return "Division"
        }
    }

    var symbol: String {
        switch self {
        case .multiplication: return "×"
        case .division: return "÷"
        }
    }

    var tileLabel: String {
        switch self {
        case .multiplication: return "TABLE"
        case .division: return "FACTS"
        }
    }

    func tableSummary(for table: Int) -> String {
        switch self {
        case .multiplication:
            return "\(table)\(symbol)"
        case .division:
            return "÷\(table)"
        }
    }

    func practiceKey(lhs: Int, rhs: Int) -> String {
        "\(lhs)\(symbol)\(rhs)"
    }

    var selectionScreenTitle: String {
        "TABLES"
    }

    var selectionScreenSubtitle: String {
        switch self {
        case .multiplication: return "OR HIT PRACTICE BAY"
        case .division: return "OR BUILD CUSTOM QUOTIENT DRILLS"
        }
    }

    var subsectionTitle: String {
        switch self {
        case .multiplication: return "Tables"
        case .division: return "Divisors"
        }
    }

    var subsectionDetailWhenEmpty: String {
        switch self {
        case .multiplication: return "Pick Some"
        case .division: return "Pick Divisors"
        }
    }

    var readyStatusWhenEmpty: String {
        switch self {
        case .multiplication: return "PICK TABLES OR HIT PRACTICE"
        case .division: return "PICK DIVISORS OR HIT PRACTICE"
        }
    }

    var practiceBayTitle: String {
        "Custom Practice"
    }
}

private struct MenuPracticeTile: View {
    let title: String

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text(title.uppercased())
                    .font(.custom("Orbitron-Bold", size: 18))
                    .foregroundColor(.white)
                Text("CUSTOM SETUP")
                    .font(.custom("Exo 2 SemiBold", size: 10))
                    .foregroundColor(ArcadePalette.textMuted)
                    .tracking(1.2)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ArcadePalette.panelBottom.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ArcadePalette.coolLine.opacity(0.9), lineWidth: 1.0)
        )
    }
}

private struct ProfileHubView: View {
    @ObservedObject var profileStore: PlayerProfileStore
    let onChooseDifferentPilot: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""
    @State private var draftAvatar: PlayerAvatar = .rocket

    var body: some View {
        NavigationStack {
            ZStack {
                ArcadeBackground(variant: .quiet)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        hubHeader

                        if let profile = profileStore.activeProfile {
                            recordsSection(profile: profile)
                            unlockedShipsSection(profile: profile)
                            performanceSection(title: "MULTIPLICATION TABLES", mode: .multiplication, profile: profile)
                            performanceSection(title: "DIVISION TABLES", mode: .division, profile: profile)
                            editProfileSection(profile: profile)
                        } else {
                            guestSection
                        }
                    }
                    .frame(maxWidth: 820, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 34)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            syncDraftValues()
        }
        .onChange(of: profileStore.activeProfile?.id) { _, _ in
            syncDraftValues()
        }
    }

    private var hubHeader: some View {
        let rank = profileStore.activeRank
        return HStack(alignment: .center, spacing: 16) {
            AvatarBadge(avatar: profileStore.activeAvatar, isSelected: false, size: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(profileStore.activeDisplayName.uppercased())
                    .font(.custom("Orbitron-Bold", size: 30))
                    .foregroundColor(ArcadePalette.textPrimary)
                Text(profileStore.isGuestActive ? "GUEST SESSION" : rank.title)
                    .font(.custom("Exo 2 SemiBold", size: 13))
                    .foregroundColor(profileStore.isGuestActive ? ArcadePalette.warning : ArcadePalette.signalBright)
                    .tracking(1.4)
                if !profileStore.isGuestActive {
                    Text(rank.detail)
                        .font(.custom("Exo 2 SemiBold", size: 11))
                        .foregroundColor(ArcadePalette.textSecondary)
                        .tracking(0.9)
                }
            }

            Spacer(minLength: 12)
        }
    }

    private func recordsSection(profile: PlayerProfile) -> some View {
        let summary = profileStore.recordSummary(for: profile)

        return ArcadePanel(accent: ArcadePalette.coolLine) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("RECORDS")

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    statCard(title: "STARS", value: "\(summary.lifetimeStars)", accent: ArcadePalette.warning)
                    statCard(title: "BEST STREAK", value: "\(summary.bestStreak)", accent: ArcadePalette.signalBright)
                    statCard(title: "BEST RUN", value: "\(summary.bestRunCleared)", accent: ArcadePalette.success)
                    statCard(title: "MISSIONS", value: "\(summary.missionsCompleted)", accent: ArcadePalette.coolLine)
                    statCard(title: "RUNS", value: "\(summary.totalRuns)", accent: ArcadePalette.signal)
                    statCard(title: "1ST TRY", value: "\(summary.firstAttemptAccuracy)%", accent: ArcadePalette.textSecondary)
                }
            }
        }
    }

    private func unlockedShipsSection(profile: PlayerProfile) -> some View {
        let unlockedShips = profileStore.unlockedShips(for: profile)

        return ArcadePanel(accent: ArcadePalette.signal) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("UNLOCKED SHIPS")

                if unlockedShips.isEmpty {
                    Text("NO SHIPS UNLOCKED YET")
                        .font(.custom("Exo 2 SemiBold", size: 13))
                        .foregroundColor(ArcadePalette.textSecondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                        ForEach(unlockedShips, id: \.modelName) { ship in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ship.name.uppercased())
                                    .font(.custom("Orbitron-Bold", size: 13))
                                    .foregroundColor(.white)
                                Text(ShipProgression.requirementText(for: ship).uppercased())
                                    .font(.custom("Exo 2 SemiBold", size: 10))
                                    .foregroundColor(ArcadePalette.textSecondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(ArcadePalette.panelBottom.opacity(0.9))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(ArcadePalette.panelLine, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    private func performanceSection(title: String, mode: ArithmeticMode, profile: PlayerProfile) -> some View {
        let summaries = profileStore.performanceSummaries(for: mode, profile: profile)

        return ArcadePanel(accent: ArcadePalette.coolLine) {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title)

                VStack(spacing: 10) {
                    ForEach(summaries) { summary in
                        HStack(spacing: 12) {
                            Text(mode.tableSummary(for: summary.tableNumber))
                                .font(.custom("Orbitron-Bold", size: 15))
                                .foregroundColor(.white)
                                .frame(width: 62, alignment: .leading)

                            Text(summary.attempts == 0 ? "NO DATA" : "\(summary.accuracyPercentage)% FIRST TRY")
                                .font(.custom("Exo 2 SemiBold", size: 12))
                                .foregroundColor(summary.attempts == 0 ? ArcadePalette.textSecondary : ArcadePalette.signalBright)

                            Spacer(minLength: 10)

                            Text("\(summary.correctAnswers)/\(summary.attempts)")
                                .font(.custom("Exo 2 SemiBold", size: 12))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(ArcadePalette.panelBottom.opacity(0.9))
                        )
                    }
                }
            }
        }
    }

    private func editProfileSection(profile: PlayerProfile) -> some View {
        ArcadePanel(accent: ArcadePalette.signalBright) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("EDIT PROFILE")

                TextField("Pilot name", text: Binding(
                    get: { draftName },
                    set: { draftName = String($0.prefix(20)) }
                ))
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Exo 2 SemiBold", size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ArcadePalette.panelBottom.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ArcadePalette.panelLine, lineWidth: 1)
                )

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(PlayerAvatar.allCases, id: \.self) { avatar in
                        Button {
                            AudioManager.shared.playButtonTap()
                            draftAvatar = avatar
                        } label: {
                            AvatarBadge(avatar: avatar, isSelected: draftAvatar == avatar, size: 52)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(ArcadePalette.panelBottom.opacity(0.92))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(draftAvatar == avatar ? ArcadePalette.signalBright : ArcadePalette.panelLine, lineWidth: draftAvatar == avatar ? 1.4 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    AudioManager.shared.playButtonTap()
                    profileStore.updateProfile(profile, name: draftName, avatar: draftAvatar)
                    syncDraftValues()
                } label: {
                    ArcadePrimaryActionLabel(
                        title: "Save Profile",
                        enabled: !profileStore.sanitizedName(draftName).isEmpty
                    )
                }
                .disabled(profileStore.sanitizedName(draftName).isEmpty)
            }
        }
    }

    private var guestSection: some View {
        ArcadePanel(accent: ArcadePalette.warning) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("GUEST SESSION")

                Text("GUEST PROGRESS ISN'T SAVED. PICK OR CREATE A PILOT TO TRACK STARS, SHIPS, RECORDS, AND TABLE PROGRESS.")
                    .font(.custom("Exo 2 Medium", size: 13))
                    .foregroundColor(ArcadePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    AudioManager.shared.playButtonTap()
                    dismiss()
                    onChooseDifferentPilot()
                } label: {
                    ArcadePrimaryActionLabel(title: "Choose Pilot", enabled: true)
                }
            }
        }
    }

    private func syncDraftValues() {
        draftName = profileStore.activeProfile?.name ?? ""
        draftAvatar = profileStore.activeProfile?.avatar ?? .rocket
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom("Orbitron-Bold", size: 18))
            .foregroundColor(ArcadePalette.textPrimary)
    }

    private func statCard(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom("Exo 2 SemiBold", size: 11))
                .foregroundColor(ArcadePalette.textSecondary)
                .tracking(1.0)
            Text(value)
                .font(.custom("Orbitron-Bold", size: 24))
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ArcadePalette.panelBottom.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ArcadePalette.panelLine, lineWidth: 1)
        )
    }
}

private struct PilotSelectionCard: View {
    let title: String
    let avatar: PlayerAvatar
    let isSelected: Bool
    var usesAccentSelection: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            AvatarBadge(
                avatar: avatar,
                isSelected: isSelected && usesAccentSelection,
                size: 78
            )
            Text(title.uppercased())
                .font(.custom("Orbitron-Bold", size: 16))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 10)
    }
}

private struct AddPilotCard: View {
    let isExpanded: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ArcadePalette.panelBottom.opacity(0.92))
                    .frame(width: 78, height: 78)
                Circle()
                    .stroke(isExpanded ? ArcadePalette.signalBright : ArcadePalette.panelLine, lineWidth: isExpanded ? 2 : 1)
                    .frame(width: 78, height: 78)
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isExpanded ? ArcadePalette.signalBright : .white)
            }
            VStack(spacing: 4) {
                Text("NEW PILOT")
                    .font(.custom("Orbitron-Bold", size: 16))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 10)
    }
}

private struct AvatarBadge: View {
    let avatar: PlayerAvatar
    let isSelected: Bool
    let size: CGFloat

    var body: some View {
        Image(systemName: avatar.symbolName)
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isSelected ? ArcadePalette.signal.opacity(0.9) : ArcadePalette.panelBottom.opacity(0.92))
            )
            .overlay(
                Circle()
                    .stroke(isSelected ? ArcadePalette.signalBright : ArcadePalette.panelLine, lineWidth: isSelected ? 2 : 1)
            )
    }
}


struct MenuView: View {
    private enum MenuStage: Int {
        case attract
        case profile
        case createPilot
        case setup
    }

    @StateObject private var profileStore = PlayerProfileStore.shared
    @State private var selectedTables: Set<Int> = []
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var arithmeticMode: ArithmeticMode = .multiplication
    @State private var showingShipSelection = false
    @State private var showingCustomPractice = false
    @State private var showingPlayerHub = false
    @State private var currentStage: MenuStage = .attract
    @State private var startPromptPulse = false
    @State private var titlePulse = false
    @State private var signalBlink = false
    @State private var readyPulse = false
    @State private var newPlayerName = ""
    @State private var selectedAvatar: PlayerAvatar = .rocket
    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ArcadeBackground(variant: currentStage == .attract ? .standard : .quiet)
                
                VStack(spacing: 0) {
                    attractScreen(containerHeight: geometry.size.height)
                    playerSelectionScreen(containerHeight: geometry.size.height)
                    createPilotScreen(containerHeight: geometry.size.height)
                    setupRevealScreen(containerHeight: geometry.size.height)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .offset(y: -geometry.size.height * CGFloat(currentStage.rawValue))
                .clipped()
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.42), value: currentStage)
        .onAppear {
            AudioManager.shared.startMenuMusic()
            restartAnimations()
        }
        .onDisappear {
            AudioManager.shared.stopMenuMusic()
            resetAnimations()
        }
        .onChange(of: showingShipSelection) { _, isPresented in
            if isPresented {
                resetAnimations()
            } else {
                AudioManager.shared.startMenuMusic()
                restartAnimations()
            }
        }
        .onChange(of: showingCustomPractice) { _, isPresented in
            if isPresented {
                resetAnimations()
            } else {
                AudioManager.shared.startMenuMusic()
                restartAnimations()
            }
        }
        .onChange(of: currentStage) { _, _ in
            restartAnimations()
        }
        .fullScreenCover(isPresented: $showingShipSelection) {
            ShipSelectionView(
                selectedTables: selectedTables.sorted(),
                arithmeticMode: arithmeticMode,
                selectedDifficulty: $selectedDifficulty,
                isCustomMode: false,
                onReturnToMenu: {
                    showingShipSelection = false
                    showSetup()
                }
            )
        }
        .fullScreenCover(isPresented: $showingCustomPractice) {
            CustomPracticeView(
                arithmeticMode: arithmeticMode,
                selectedDifficulty: $selectedDifficulty
            )
        }
        .sheet(isPresented: $showingPlayerHub) {
            ProfileHubView(profileStore: profileStore) {
                showingPlayerHub = false
                showProfileSelection()
            }
            .modelContainer(PlayerProfileStore.shared.modelContainer)
        }
        .statusBar(hidden: true)
    }
    
    private func attractScreen(containerHeight: CGFloat) -> some View {
        VStack(spacing: 18) {
            Spacer()
            
            ArcadeSignalLights(isActive: signalBlink, accent: ArcadePalette.signalBright)
            
            Text("MATH BLAST")
                .font(.custom("Orbitron-Bold", size: 44))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .scaleEffect(titlePulse ? 1.02 : 0.985)
                .shadow(
                    color: ArcadePalette.signal.opacity(titlePulse ? 0.42 : 0.18),
                    radius: titlePulse ? 22 : 10
                )
            
            Text("1 PLAYER")
                .font(.custom("Exo 2 SemiBold", size: 13))
                .foregroundColor(ArcadePalette.signalBright)
                .tracking(2.0)
            
            Button {
                AudioManager.shared.playButtonTap()
                showProfileSelection()
            } label: {
                Text("PRESS START")
                    .font(.custom("Orbitron-Bold", size: 24))
                    .foregroundColor(.white)
                    .frame(minWidth: 220)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(ArcadePalette.signal.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(ArcadePalette.signalBright, lineWidth: 1.6)
                    )
                    .opacity(startPromptPulse ? 1.0 : 0.55)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: containerHeight)
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .onTapGesture {
            AudioManager.shared.playButtonTap()
            showProfileSelection()
        }
    }

    private func playerSelectionScreen(containerHeight: CGFloat) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            Text("SELECT PILOT")
                .font(.custom("Orbitron-Bold", size: 32))
                .foregroundColor(ArcadePalette.textPrimary)

            pilotStack

            Button {
                AudioManager.shared.playButtonTap()
                showAttract()
            } label: {
                ArcadeSecondaryActionLabel(title: "Back")
                    .frame(width: 148)
            }

            Spacer()
        }
        .frame(maxWidth: 720)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: containerHeight)
    }

    private func createPilotScreen(containerHeight: CGFloat) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("CREATE PILOT")
                    .font(.custom("Orbitron-Bold", size: 32))
                    .foregroundColor(ArcadePalette.textPrimary)
                Text("NAME YOUR PILOT AND CHOOSE AN AVATAR")
                    .font(.custom("Exo 2 SemiBold", size: 13))
                    .foregroundColor(ArcadePalette.signalBright)
                    .tracking(1.4)
            }
            .frame(maxWidth: 520, alignment: .leading)

            VStack(alignment: .leading, spacing: 18) {
                TextField("Enter pilot name", text: Binding(
                    get: { newPlayerName },
                    set: { newPlayerName = String($0.prefix(20)) }
                ))
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Exo 2 SemiBold", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .focused($isNameFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isNameFieldFocused = false
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(ArcadePalette.panelBottom.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ArcadePalette.panelLine, lineWidth: 1.0)
                )

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 3), spacing: 18) {
                    ForEach(PlayerAvatar.allCases, id: \.self) { avatar in
                        Button {
                            AudioManager.shared.playButtonTap()
                            selectedAvatar = avatar
                        } label: {
                            AvatarBadge(avatar: avatar, isSelected: selectedAvatar == avatar, size: 62)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        AudioManager.shared.playButtonTap()
                        createPilotAndContinue()
                    } label: {
                        ArcadePrimaryActionLabel(
                            title: "Create Pilot",
                            enabled: !profileStore.sanitizedName(newPlayerName).isEmpty
                        )
                    }
                    .disabled(profileStore.sanitizedName(newPlayerName).isEmpty)

                    Button {
                        AudioManager.shared.playButtonTap()
                        newPlayerName = ""
                        selectedAvatar = .rocket
                        showProfileSelection()
                    } label: {
                        ArcadeSecondaryActionLabel(title: "Back")
                    }
                }
            }
            .frame(maxWidth: 520)

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: containerHeight)
    }
    private var pilotStack: some View {
        Group {
            if horizontalSizeClass == .regular {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 28) {
                        pilotButtons(fillWidth: false)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 18) {
                    pilotButtons(fillWidth: true)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func setupRevealScreen(containerHeight: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(arithmeticMode.selectionScreenTitle)
                            .font(.custom("Orbitron-Bold", size: 32))
                            .foregroundColor(ArcadePalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }

                    Spacer(minLength: 12)
                    playerHubButton
                }
                .padding(.horizontal, 4)
                
                ArcadePanel(accent: selectedTables.isEmpty ? ArcadePalette.coolLine : ArcadePalette.signal) {
                    VStack(alignment: .leading, spacing: 18) {

                        ArithmeticModePicker(selection: $arithmeticMode)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(1...12, id: \.self) { number in
                                Button {
                                    AudioManager.shared.playButtonTap()
                                    if selectedTables.contains(number) {
                                        selectedTables.remove(number)
                                    } else {
                                        selectedTables.insert(number)
                                    }
                                } label: {
                                    MenuTableTile(
                                        number: number,
                                        arithmeticMode: arithmeticMode,
                                        isSelected: selectedTables.contains(number)
                                    )
                                }
                            }
                        }

                        Button {
                            AudioManager.shared.playButtonTap()
                            showPracticeBay()
                        } label: {
                            MenuPracticeTile(title: arithmeticMode.practiceBayTitle)
                        }
                    }
                }
                
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        Button {
                            AudioManager.shared.playButtonTap()
                            showProfileSelection()
                        } label: {
                            ArcadeSecondaryActionLabel(title: "Back")
                        }
                        .frame(width: 132)
                        
                        startButton
                    }
                    
                    VStack(spacing: 12) {
                        Button {
                            AudioManager.shared.playButtonTap()
                            showProfileSelection()
                        } label: {
                            ArcadeSecondaryActionLabel(title: "Back")
                        }
                        
                        startButton
                    }
                }
                
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 34)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
            .frame(minHeight: containerHeight, alignment: .top)
        }
        .frame(height: containerHeight)
    }
    
    private var startButton: some View {
        Button {
            AudioManager.shared.playButtonTap()
            showingShipSelection = true
        } label: {
            ArcadePrimaryActionLabel(
                title: "Open Hangar",
                enabled: !selectedTables.isEmpty
            )
            .scaleEffect(selectedTables.isEmpty ? 1.0 : (readyPulse ? 1.018 : 0.992))
            .shadow(
                color: selectedTables.isEmpty
                    ? .clear
                    : ArcadePalette.signal.opacity(readyPulse ? 0.34 : 0.16),
                radius: 18,
                y: 10
            )
        }
        .disabled(selectedTables.isEmpty)
    }

    private var playerHubButton: some View {
        let rank = profileStore.activeRank
        return Button {
            AudioManager.shared.playButtonTap()
            showingPlayerHub = true
        } label: {
            HStack(spacing: 10) {
                AvatarBadge(avatar: profileStore.activeAvatar, isSelected: false, size: 42)
                Text(profileStore.isGuestActive ? "GUEST" : rank.title)
                    .font(.custom("Exo 2 SemiBold", size: 10))
                    .foregroundColor(ArcadePalette.textSecondary)
                    .tracking(1.0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ArcadePalette.panelBottom.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ArcadePalette.panelLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func showProfileSelection() {
        currentStage = .profile
    }

    private func showCreatePilot() {
        currentStage = .createPilot
    }

    private func showSetup() {
        currentStage = .setup
    }
    
    private func showAttract() {
        currentStage = .attract
    }
    
    private func showPracticeBay() {
        showingCustomPractice = true
    }

    private func createPilotAndContinue() {
        isNameFieldFocused = false
        let cleanName = profileStore.sanitizedName(newPlayerName)
        guard !cleanName.isEmpty else { return }
        profileStore.createProfile(name: cleanName, avatar: selectedAvatar)
        newPlayerName = ""
        selectedAvatar = .rocket
        showSetup()
    }

    @ViewBuilder
    private func pilotButtons(fillWidth: Bool) -> some View {
        ForEach(profileStore.profiles) { profile in
            Button {
                AudioManager.shared.playButtonTap()
                profileStore.selectProfile(profile)
                showSetup()
            } label: {
                PilotSelectionCard(
                    title: profile.name,
                    avatar: profile.avatar,
                    isSelected: profileStore.activeProfile?.id == profile.id
                )
                .frame(maxWidth: fillWidth ? .infinity : nil)
            }
            .buttonStyle(.plain)
        }

        Button {
            AudioManager.shared.playButtonTap()
            showCreatePilot()
        } label: {
            AddPilotCard(isExpanded: currentStage == .createPilot)
                .frame(maxWidth: fillWidth ? .infinity : nil)
        }
        .buttonStyle(.plain)

        Button {
            AudioManager.shared.playButtonTap()
            profileStore.continueAsGuest()
            showSetup()
        } label: {
            PilotSelectionCard(
                title: "Guest",
                avatar: .star,
                isSelected: profileStore.isGuestActive,
                usesAccentSelection: false
            )
            .frame(maxWidth: fillWidth ? .infinity : nil)
        }
        .buttonStyle(.plain)
    }
    
    private func restartAnimations() {
        guard !showingShipSelection && !showingCustomPractice else { return }
        resetAnimations()
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                startPromptPulse = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                titlePulse = true
            }
            withAnimation(.easeInOut(duration: 0.48).repeatForever(autoreverses: true)) {
                signalBlink = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                readyPulse = true
            }
        }
    }
    
    private func resetAnimations() {
        startPromptPulse = false
        titlePulse = false
        signalBlink = false
        readyPulse = false
    }
}

private struct MenuModeButton: View {
    let title: String
    var subtitle: String? = nil
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 6) {
            Text(title.uppercased())
                .font(.custom("Orbitron-Bold", size: 20))
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle.uppercased())
                    .font(.custom("Exo 2 SemiBold", size: 11))
                    .foregroundColor(ArcadePalette.textSecondary)
                    .tracking(0.9)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .frame(height: subtitle == nil ? 74 : 82)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.85), lineWidth: 1.2)
        )
    }
}

private struct ArithmeticModePicker: View {
    @Binding var selection: ArithmeticMode

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ArithmeticMode.allCases, id: \.self) { mode in
                Button {
                    AudioManager.shared.playButtonTap()
                    selection = mode
                } label: {
                    Text(mode.title.uppercased())
                        .font(.custom("Exo 2 SemiBold", size: 12))
                        .foregroundColor(.white)
                        .tracking(1.0)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    selection == mode
                                        ? ArcadePalette.signal.opacity(0.86)
                                        : ArcadePalette.panelBottom.opacity(0.92)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    selection == mode
                                        ? ArcadePalette.signalBright
                                        : ArcadePalette.panelLine.opacity(0.85),
                                    lineWidth: selection == mode ? 1.5 : 1.0
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct MenuSubsectionHeader: View {
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title.uppercased())
                .font(.custom("Exo 2 SemiBold", size: 12))
                .foregroundColor(ArcadePalette.textPrimary)
                .tracking(1.2)
            
            Spacer(minLength: 8)
            
            Text(detail.uppercased())
                .font(.custom("Exo 2 SemiBold", size: 11))
                .foregroundColor(ArcadePalette.textSecondary)
                .tracking(0.8)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct ArcadeSignalLights: View {
    let isActive: Bool
    var accent: Color = ArcadePalette.signalBright
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accent)
                    .frame(width: index.isMultiple(of: 2) ? 18 : 10, height: 4)
                    .opacity(isActive ? activeOpacity(for: index) : restingOpacity(for: index))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(accent.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func activeOpacity(for index: Int) -> Double {
        index.isMultiple(of: 2) ? 1.0 : 0.24
    }
    
    private func restingOpacity(for index: Int) -> Double {
        index.isMultiple(of: 2) ? 0.28 : 1.0
    }
}

private struct ArcadeMarqueeLabel: View {
    let text: String
    var accent: Color = ArcadePalette.signalBright
    var isBlinking: Bool
    
    var body: some View {
        Text(text.uppercased())
            .font(.custom("Exo 2 SemiBold", size: 11))
            .foregroundColor(.white)
            .tracking(1.8)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                BeveledPanelShape(cut: 10)
                    .fill(accent.opacity(0.12))
            )
            .overlay(
                BeveledPanelShape(cut: 10)
                    .stroke(accent.opacity(0.32), lineWidth: 1.1)
            )
            .opacity(isBlinking ? 1.0 : 0.5)
    }
}
extension Difficulty {
    var title: String {
        switch self {
        case .easy: return "EASY"
        case .medium: return "MEDIUM"
        case .hard: return "HARD"
        }
    }
}

private struct MenuTableTile: View {
    let number: Int
    let arithmeticMode: ArithmeticMode
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(arithmeticMode.tableSummary(for: number))
                .font(.custom("Orbitron-Bold", size: 22))
                .foregroundColor(.white)
            Text(arithmeticMode.tileLabel)
                .font(.custom("Exo 2 SemiBold", size: 10))
                .foregroundColor(isSelected ? Color.white.opacity(0.76) : ArcadePalette.textMuted)
                .tracking(1.2)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isSelected
                        ? ArcadePalette.signal.opacity(0.20)
                        : ArcadePalette.panelBottom.opacity(0.82)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected ? ArcadePalette.signalBright : ArcadePalette.panelLine.opacity(0.85),
                    lineWidth: isSelected ? 1.5 : 1.0
                )
        )
    }
}
