//
//  SettingsPanes.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2025-07-10.
//

import SwiftUI
import Combine
import Charts
import CoreBluetooth
import UniformTypeIdentifiers

struct SettingsDetailView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    var selectedSection: SettingsSection?

    private var isSelectedSectionLocked: Bool {
        selectedSection?.isPremiumLocked ?? false
    }

    var body: some View {
        VStack {
            if let selectedSection, isSelectedSectionLocked {
                LockedSettingsSectionView(section: selectedSection)
            } else {
                settingsPane(for: selectedSection)
            }
        }
        .animation(.easeOut(duration: 0.15), value: selectedSection)
        .animation(.easeOut(duration: 0.15), value: subscriptionManager.activeTier)
    }

    @ViewBuilder
    private func settingsPane(for selectedSection: SettingsSection?) -> some View {
        switch selectedSection {
        case .overview: OverviewSettingsView()
        case .general: GeneralSettingsView()
        case .systemEnhance: SystemEnhanceSettingsView()
        case .apps: AppsSettingsView()
        case .storage: StorageSettingsView()
        case .widgets: WidgetsSettingsView()
        case .liveActivities: LiveActivitiesSettingsView()
        case .appActivities: AppActivitiesSettingsView()
        case .fileProgress: FileProgressSettingsView()
        case .appearance: AppearanceSettingsView()
        case .lockScreen: LockScreenSettingsView()
        case .bluetoothUnlock: ProximityUnlockSettingsView()
        case .shortcuts: ShortcutsSettingsView()
        case .keyboardShortcuts: KeyboardShortcutsSettingsView()
        case .snapZones: SnapZonesSettingsView()
        case .audio: AudioSettingsView()
        case .battery: BatterySettingsView()
        case .bluetooth: BluetoothSettingsView()
        case .hud: HUDSettingsView()
        case .notifications: NotificationsSettingsView()
        case .nearbyShare: NearbyShareSettingsView()
        case .continuity: ContinuitySettingsView()
        case .fileShelf: FileShelfSettingsView()
        case .notes: NotesSettingsView()
        case .clipboard: ClipboardSettingsView()
        case .emoji: EmojiSettingsView()
        case .mouse: MouseSettingsView()
        case .monitoring: MonitoringSettingsView()
        case .archives: ArchivesAndDMGInstallerSettingsView()
        case .mirror: MirrorSettingsView()
        case .caffeine: CaffeineSettingsView()
        case .devActivity: DevActivitySettingsView()
        case .music: MusicSettingsView()
        case .weather: WeatherSettingsView()
        case .calendar: CalendarSettingsView()
        case .eyeBreak: EyeBreakSettingsView()
        case .focusSession: FocusSessionSettingsView()
        case .appLock: AppLockSettingsView()
        case .intelligence: IntelligenceSettingsView()
        case .sports: SportsSettingsView()
        case .finance: FinanceSettingsView()
        case .dockLayouts: DockLayoutsSettingsView()
        case .mediaOptimizer: MediaOptimizerSettingsView()
        case .about: AboutSettingsView()
        case nil:
            VStack {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 50))
                        .foregroundStyle(.tertiary)
                    Text("选择一个类别")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct LockedSettingsSectionView: View {
    let section: SettingsSection

    private var requiredTierName: String {
        guard let tier = section.minimumRequiredTier else { return "Premium" }
        return SubscriptionFeatureCatalog.tierDisplayName(tier)
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("\(section.label) requires Sapphire \(requiredTierName)")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("从帐户升级以解锁此部分。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            Button("Open Account Settings") {
                NotificationCenter.default.post(name: .sapphireOpenAccountPane, object: nil)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RequiredPermissionsView: View {
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    let section: SettingsSection
    private var requiredPermissions: [PermissionItem] { permissionsManager.allPermissions.filter { section.requiredPermissions.contains($0.type) } }
    private var missingPermissions: [PermissionItem] { requiredPermissions.filter { permissionsManager.status(for: $0.type) != .granted } }
    var body: some View {
        if !requiredPermissions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                if !missingPermissions.isEmpty {
                    missingPermissionsWarning
                }
                Text("所需权限").font(.headline).padding([.horizontal, .top])
                ForEach(requiredPermissions) { permission in
                    PermissionStatusRowView(permission: permission)
                    if permission.id != requiredPermissions.last?.id { Divider().padding(.leading, 60) }
                }
            }.modifier(SettingsContainerModifier()).onAppear(perform: permissionsManager.checkAllPermissions)
        }
    }

    private var missingPermissionsWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(missingPermissionsMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
            .background(Color.orange.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.5), lineWidth: 1)
            )
        }
        .padding([.horizontal, .top])
    }

    private var missingPermissionsMessage: String {
        let names = missingPermissions.map(\.title)
        if names.isEmpty { return "" }
        if names.count == 1 {
            return "\(names[0]) permission has not been granted. Some features may not work until it is enabled."
        }
        let list = names.dropLast().joined(separator: ", ") + " and " + names.last!
        return "\(list) permissions have not been granted. Some features may not work until they are enabled."
    }
}

struct PermissionStatusRowView: View {
    let permission: PermissionItem
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: permission.iconName).font(.system(size: 18, weight: .medium)).foregroundColor(permission.iconColor).frame(width: 36, height: 36).background(permission.iconColor.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(permission.title).font(.system(size: 14, weight: .medium))
                Text(permission.description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            let status = permissionsManager.status(for: permission.type)
            switch status {
            case .granted: Image(systemName: "checkmark.circle.fill").font(.title2).foregroundColor(.green)
            case .denied: Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.red)
            case .notRequested: Button("请求") { permissionsManager.requestPermission(permission.type) }.buttonStyle(.bordered).tint(.accentColor)
            }
            PermissionFeatureInfoButton(permission: permission)
                .padding(.trailing, 4)
        }.padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
    }
}

struct PermissionFeatureInfoButton: View {
    let permission: PermissionItem
    @State private var isShowingInfo = false

    var body: some View {
        Button {
            isShowingInfo.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("查看哪些功能需要此权限")
        .popover(isPresented: $isShowingInfo, arrowEdge: .trailing) {
            PermissionFeatureInfoPopover(permission: permission)
        }
    }
}

struct PermissionFeatureInfoPopover: View {
    let permission: PermissionItem

    private var features: [SettingsSection] { SettingsSection.features(requiring: permission.type) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(permission.title)
            } icon: {
                Image(systemName: permission.iconName)
                    .foregroundStyle(permission.iconColor)
            }
            .font(.headline)

            Divider()

            if features.isEmpty {
                Text(permission.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("需要用于")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(features, id: \.self) { section in
                    HStack(spacing: 8) {
                        Image(systemName: section.systemImage)
                            .font(.system(size: 12))
                            .foregroundStyle(section.iconBackgroundColor)
                            .frame(width: 16)
                        Text(section.label)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 240)
    }
}

struct NotchAppearanceEditorView: View {
    @Binding var appearance: NotchAppearanceSettings
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !title.isEmpty {
                Text(title).font(.headline).padding([.top, .horizontal])
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Text("风格")
                Spacer()
                Picker("", selection: $appearance.mode) {
                    ForEach(NotchAppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .fixedSize()
            }
            .padding()

            if appearance.mode == .liquidGlass || (appearance.mode == .custom && appearance.liquidGlassLook) {
                Divider().padding(.leading, 20)
                LiquidGlassOptionsEditor(
                    options: $appearance.liquidGlassOptions,
                    defaults: .notchDefault,
                    showsCornerRadius: false
                )
            }

            if appearance.mode == .default {
                Divider().padding(.leading, 20)
                ToggleRow(
                    title: "淡化底边",
                    description: "将凹口的下边缘从黑色淡化为透明。",
                    isOn: $appearance.bottomFadeEnabled
                )
            }

            if appearance.mode == .custom {
                Divider().padding(.leading, 20)
                ToggleRow(
                    title: "Liquid Glass",
                    description: "使用液体玻璃材料作为自定义凹口背景。",
                    isOn: $appearance.liquidGlassLook
                )

                Divider().padding(.leading, 20)
                HStack {
                    Text("背景风格")
                    Spacer()
                    Picker("", selection: $appearance.backgroundStyle) {
                        ForEach(NotchBackgroundStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }.labelsHidden().frame(width: 150)
                }.padding()

                if appearance.backgroundStyle == .solid {
                    solidColorPicker
                } else {
                    gradientColorEditor
                }

                Divider().padding(.leading, 20)
                let opacityBinding = Binding<Double>(
                    get: { appearance.opacity * 100 },
                    set: { appearance.opacity = min(max($0 / 100, 0), 1) }
                )
                CustomSliderRowView(label: "主控不透明度", value: opacityBinding, range: 0...100, specifier: "%.0f%%")
            }

            if appearance.mode == .blur || (appearance.mode == .custom && !appearance.liquidGlassLook) {
                Divider().padding(.leading, 20)
                ToggleRow(title: "启用透明度模糊", description: "对凹口背景应用磨砂玻璃效果。", isOn: $appearance.enableTransparencyBlur)
            }
        }
        .modifier(SettingsContainerModifier())
        .animation(.default, value: appearance.backgroundStyle)
        .animation(.default, value: appearance.mode)
        .animation(.default, value: appearance.enableTransparencyBlur)
    }

    @ViewBuilder
    private var solidColorPicker: some View {
        ColorPicker("Color", selection: $appearance.solidColor.color, supportsOpacity: true)
        .padding()
        .transition(.opacity)
    }

    @ViewBuilder
    private var gradientColorEditor: some View {
        VStack(alignment: .leading) {
            if appearance.backgroundStyle == .gradient {
                CustomSliderRowView(label: "角度", value: $appearance.gradientAngle, range: 0...360, specifier: "%.0f°")
                    .padding(.horizontal)
            }

            Text("渐变颜色").font(.subheadline).padding(.horizontal)

            ForEach($appearance.gradientColors) { $color in
                VStack(spacing: 8) {
                    HStack {
                        ColorPicker("Color Stop", selection: $color.color, supportsOpacity: true)
                        Spacer()
                        Button(action: {
                            guard appearance.gradientColors.count > 1 else { return }
                            let doomed = color.id
                            DispatchQueue.main.async {
                                appearance.gradientColors.removeAll { $0.id == doomed }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(appearance.gradientColors.count <= 1)
                    }
                    DeferredValueEditor(value: $color.location.asDouble) { draft, onEditingChanged in
                        Slider(
                            value: draft,
                            in: 0...1,
                            label: { Text("Location") },
                            minimumValueLabel: { Text("0%") },
                            maximumValueLabel: { Text("100%") },
                            onEditingChanged: onEditingChanged
                        )
                    }
                }.padding(.horizontal)
            }

            Button(action: {
                var updatedColors = appearance.gradientColors
                if let lastColor = updatedColors.last {
                    let newLocation = min(1.0, lastColor.location + 0.2)
                    let newColorStop = CodableColor(color: lastColor.color, location: newLocation)
                    updatedColors.append(newColorStop)
                } else {
                    let newColorStop = CodableColor(color: .black, location: 0.0)
                    updatedColors.append(newColorStop)
                }
                appearance.gradientColors = updatedColors.sorted { $0.location < $1.location }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加色标")
                }
            }
            .buttonStyle(.plain)
            .tint(.accentColor)
            .padding(.top, 5)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .transition(.opacity)
    }
}

struct SystemEnhanceSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                Text("System").font(.largeTitle.bold())
                Text("桌面运动、输入和窗口增强功能不会妨碍您。")
                    .font(.subheadline).foregroundStyle(.secondary)

                SystemEnhanceHingeAnimationSettingsCard()

                VStack(alignment: .leading, spacing: 0) {
                    PremiumFeatureView(feature: .windowsPreview) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("应用程序切换").font(.headline).padding([.top, .horizontal])
                            ToggleRow(title: "窗口切换器", description: "Replace the switcher with a keyboard-driven, window-aware overlay. Hold the shortcut and press Tab to cycle, arrows to move, Q to quit an app, W to close a window.", isOn: $settings.settings.systemEnhanceWindowSwitcherEnabled)
                            if settings.settings.systemEnhanceWindowSwitcherEnabled {
                                Divider().padding(.leading, 20)
                                HStack { Text("激活方式"); Spacer(); Picker("", selection: Binding(
                                    get: { settings.settings.systemEnhanceSwitcherActivation.rawValue },
                                    set: { settings.settings.systemEnhanceSwitcherActivation = SESwitcherActivation(rawValue: $0) ?? .both }
                                )) {
                                    Text("⌘ 选项卡").tag(SESwitcherActivation.command.rawValue)
                                    Text("⌥ 选项卡").tag(SESwitcherActivation.option.rawValue)
                                    Text("两者都").tag(SESwitcherActivation.both.rawValue)
                                }.labelsHidden().frame(width: 160) }.padding()
                                Divider().padding(.leading, 20)
                                ToggleRow(title: "包括其他空间的窗户", description: "Also list windows on other Spaces and full-screen apps. Selecting one switches to its Space.", isOn: $settings.settings.systemEnhanceSwitcherIncludeOtherSpaces)
                                Divider().padding(.leading, 20)
                                HStack { Text("窗口切换器布局"); Spacer(); Picker("", selection: Binding(
                                    get: { settings.settings.systemEnhanceWindowSwitcherLayout.rawValue },
                                    set: { settings.settings.systemEnhanceWindowSwitcherLayout = SEPreviewLayout(rawValue: $0) ?? .grid }
                                )) { Text("网格").tag(SEPreviewLayout.grid.rawValue); Text("列表").tag(SEPreviewLayout.list.rawValue); Text("轮播").tag(SEPreviewLayout.carousel.rawValue) }.labelsHidden().frame(width: 150) }.padding()
                            }
                        }
                    }
                }.modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("输入行为").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "粘贴为纯文本", description: "Paste without formatting using its own shortcut.", isOn: $settings.settings.systemEnhancePasteAsPlainTextEnabled)
                    if settings.settings.systemEnhancePasteAsPlainTextEnabled {
                        Divider().padding(.leading, 20)
                        PlainTextPasteShortcutRow()
                        Divider().padding(.leading, 20)
                        ToggleRow(title: "删除链接", description: "Strip web addresses from pasted text.", isOn: $settings.settings.systemEnhancePasteAsPlainStripLinks)
                        Divider().padding(.leading, 20)
                        ToggleRow(title: "删除表情符号", description: "Strip emoji characters from pasted text.", isOn: $settings.settings.systemEnhancePasteAsPlainStripEmojis)
                        Divider().padding(.leading, 20)
                        ToggleRow(title: "删除列表标记", description: "Remove bullets and numbered markers such as •, -, and 1. from list items.", isOn: $settings.settings.systemEnhancePasteAsPlainStripListMarkers)
                    }
                }.modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("日历整合").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "日历整合", description: "Include calendar context in enhanced window and Dock previews.", isOn: $settings.settings.systemEnhanceCalendarIntegrationEnabled)
                }.modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("关闭时退出").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "当最后一个窗口关闭时退出应用程序", description: "Apps quit themselves once they have no windows left, after a short grace period. Enabled for every app by default.", isOn: $settings.settings.systemEnhanceAutoQuitEnabled)
                    if settings.settings.systemEnhanceAutoQuitEnabled {
                        Divider().padding(.leading, 20)
                        Text("无窗口时退出的应用程序：")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        AppTogglesListView(
                            isEnabled: { app in $settings.settings.systemEnhanceAutoQuitExcludedApps.membership(of: app.id).negated },
                            showSearch: true
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }.modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("退出并关闭保护").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "保护退出和关闭快捷方式", description: "Require a hold, a double press, or an extra modifier for ⌘Q and ⌘W. Enabled for every app by default.", isOn: $settings.settings.systemEnhanceQuitProtectionEnabled)
                    if settings.settings.systemEnhanceQuitProtectionEnabled {
                        SEQuitProtectionRulesView()
                        Divider().padding(.leading, 20)
                        Text("具有受保护的 ⌘Q/⌘W 的应用程序：")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        AppTogglesListView(
                            isEnabled: { app in $settings.settings.systemEnhanceQuitProtectionExcludedApps.membership(of: app.id).negated },
                            showSearch: true
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }.modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("绿色按钮最大化").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "在当前空间最大化", description: "The green traffic-light button fills the screen without creating a new Space; clicking it again restores the window.", isOn: $settings.settings.systemEnhanceGreenMaximizeEnabled)
                    if settings.settings.systemEnhanceGreenMaximizeEnabled {
                        Divider().padding(.leading, 20)
                        Text("绿色按钮最大化的应用程序（⌥-单击始终保持系统行为）：")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        AppTogglesListView(
                            isEnabled: { app in $settings.settings.systemEnhanceGreenMaximizeExcludedApps.membership(of: app.id).negated },
                            showSearch: true
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }.modifier(SettingsContainerModifier())
            }.padding(25)
        }
    }
}

private struct SystemEnhanceHingeAnimationSettingsCard: View {
    @EditingSettings private var settings: SettingsEditingSession
    @ObservedObject private var lidAngleSensor = LidAngleSensor.shared
    @ObservedObject private var permissionsManager = PermissionsManager.shared

    private var currentLidAngleText: String {
        guard lidAngleSensor.isAvailable else { return "Unavailable" }
        guard lidAngleSensor.isReporting else { return "Connecting…" }
        return "\(Int(lidAngleSensor.angle.rounded()))°"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("盖子铰链动画").font(.headline).padding([.top, .horizontal])
            ToggleRow(
                title: "关闭盖子时动画",
                description: "Dim and blur the display as the lid closes past the activation angle, following the hinge.",
                isOn: $settings.settings.systemEnhanceHingeAnimationEnabled
            )
            if settings.settings.systemEnhanceHingeAnimationEnabled {
                Divider().padding(.leading, 20)
                SettingsDetailRow(title: "当前盖子角度") {
                    Text(currentLidAngleText).monospacedDigit()
                }
                Divider().padding(.leading, 20)
                CustomSliderRowView(
                    label: "激活角",
                    value: $settings.settings.systemEnhanceHingeAnimationActivationAngle,
                    range: 45...140,
                    specifier: "%.0f°"
                )
                Divider().padding(.leading, 20)
                CustomSliderRowView(
                    label: "强度",
                    value: $settings.settings.systemEnhanceHingeAnimationIntensity,
                    range: 0.5...1.5,
                    specifier: "%.2f×"
                )
                Divider().padding(.leading, 20)
                CustomSliderRowView(
                    label: "最大模糊",
                    value: $settings.settings.systemEnhanceHingeAnimationBlur,
                    range: 0...180,
                    specifier: "%.0f pt"
                )
            }
        }
        .modifier(SettingsContainerModifier())
        .onAppear {
            lidAngleSensor.acquire(.systemEnhanceSettingsPreview)
        }
        .onDisappear {
            lidAngleSensor.release(.systemEnhanceSettingsPreview)
        }
    }
}

struct AppsSettingsView: View {
    @EditingSettings private var settingsModel: SettingsEditingSession
    @ObservedObject private var installedUpdates = InstalledAppUpdatesChecker.shared
    @StateObject private var appModel = InstalledAppsViewModel()
    @State private var selectedTab: AppsTab = .updates
    @State private var updatesQuery = ""
    @State private var uninstallQuery = ""
    @State private var updateFilter: AppUpdateFilter = .updates
    @State private var showSystemApps = false
    @State private var reviewApp: InstalledApp?

    private enum AppsTab: String, CaseIterable, Identifiable {
        case updates = "Updates"
        case uninstall = "Uninstall"
        var id: String { rawValue }
        var icon: String { self == .updates ? "arrow.triangle.2.circlepath" : "trash" }
    }

    private enum AppUpdateFilter: String, CaseIterable, Identifiable {
        case updates = "Updates"
        case current = "Current"
        case attention = "Needs attention"
        case ignored = "Ignored"
        case all = "All"
        var id: String { rawValue }
    }

    private struct UpdateSnapshot {
        var filteredEntries: [InstalledAppUpdateEntry] = []
        var availableCount = 0
        var currentCount = 0
        var unsupportedCount = 0
        var checkingCount = 0
    }

    private var updateSnapshot: UpdateSnapshot {
        let query = updatesQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let ignoredIDs = installedUpdates.ignoredBundleIDs
        var snapshot = UpdateSnapshot()

        for entry in installedUpdates.entries {
            let isIgnored = ignoredIDs.contains(entry.id)
            if entry.status.isUpdateAvailable && !isIgnored { snapshot.availableCount += 1 }
            if entry.status.isUpToDate && !isIgnored { snapshot.currentCount += 1 }
            if entry.status.isUnsupported && !isIgnored { snapshot.unsupportedCount += 1 }
            if entry.status == .checking { snapshot.checkingCount += 1 }

            let matchesQuery = query.isEmpty
                || entry.name.localizedCaseInsensitiveContains(query)
                || entry.bundleIdentifier.localizedCaseInsensitiveContains(query)
            guard matchesQuery else { continue }

            let matchesFilter: Bool
            switch updateFilter {
            case .updates: matchesFilter = entry.status.isUpdateAvailable && !isIgnored
            case .current: matchesFilter = entry.status.isUpToDate && !isIgnored
            case .attention: matchesFilter = (entry.status.isUnsupported || entry.status.isError) && !isIgnored
            case .ignored: matchesFilter = isIgnored
            case .all: matchesFilter = true
            }
            if matchesFilter {
                snapshot.filteredEntries.append(entry)
            }
        }
        return snapshot
    }

    var body: some View {
        let snapshot = updateSnapshot

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header(availableCount: snapshot.availableCount)

                switch selectedTab {
                case .updates:
                    updatesPane(snapshot: snapshot)
                case .uninstall:
                    uninstallPane
                }
            }
            .padding(25)
        }
        .onAppear {
            if settingsModel.settings.installedAppUpdatesEnabled,
               installedUpdates.entries.isEmpty {
                installedUpdates.checkInBackgroundIfNeeded(force: true, announce: false)
            }
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == .uninstall { loadInstalledAppInventoryIfNeeded() }
        }
        .onChange(of: settingsModel.settings.installedAppUpdatesEnabled) { _, _ in syncInstalledUpdateSettings() }
        .onChange(of: settingsModel.settings.installedAppUpdateNotificationsEnabled) { _, enabled in
            syncInstalledUpdateSettings()
            if enabled { installedUpdates.requestNotificationAuthorization() }
        }
        .sheet(item: $reviewApp) { app in
            AppUninstallReviewSheet(app: app, model: appModel)
        }
        .sheet(item: $installedUpdates.releaseNotesEntry) { item in
            InstalledAppReleaseNotesSheet(entry: item)
        }
        .onDisappear {
            appModel.cancelScan()
            appModel.cancelArtifactScan()
        }
    }

    private func header(availableCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apps")
                        .font(.largeTitle.bold())
                    Text("使已安装的应用程序保持最新状态，并在清理之前检查应用程序链接的数据。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if availableCount > 0 {
                    Label("\(availableCount) available", systemImage: "arrow.down.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.13), in: Capsule())
                }
            }

            Picker("应用程序部分", selection: $selectedTab) {
                ForEach(AppsTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
    }

    private func updatesPane(snapshot: UpdateSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    updateMetricCards(snapshot: snapshot)
                        .frame(minWidth: 170)
                }
                VStack(spacing: 10) {
                    updateMetricCards(snapshot: snapshot)
                }
            }

            installedAppsUpdateCard(snapshot: snapshot)
        }
    }

    @ViewBuilder
    private func updateMetricCards(snapshot: UpdateSnapshot) -> some View {
        AppsMetricCard(
            title: "Updates",
            value: "\(snapshot.availableCount)",
            detail: snapshot.availableCount == 1 ? "app available" : "apps available",
            systemImage: "arrow.down.circle.fill",
            tint: .blue
        )
        AppsMetricCard(
            title: "Current",
            value: "\(snapshot.currentCount)",
            detail: snapshot.currentCount == 1 ? "app up to date" : "apps up to date",
            systemImage: "checkmark.circle.fill",
            tint: .green
        )
        AppsMetricCard(
            title: "Needs attention",
            value: "\(snapshot.unsupportedCount)",
            detail: snapshot.unsupportedCount == 1 ? "app unsupported" : "apps unsupported",
            systemImage: "exclamationmark.triangle.fill",
            tint: .orange
        )
    }

    private func installedAppsUpdateCard(snapshot: UpdateSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("已安装的应用程序更新", systemImage: "square.stack.3d.up.fill")
                    .font(.headline)
                Spacer()
                Text("Last checked \(installedUpdates.lastCheckedDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    installedUpdates.checkNow()
                } label: {
                    Label("立即查看", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(
                    installedUpdates.isChecking
                        || !settingsModel.settings.installedAppUpdatesEnabled
                )
            }

            VStack(spacing: 0) {
                ToggleRow(
                    title: "监控已安装的应用程序",
                    description: "使用每个应用程序的 App Store、Homebrew、Sparkle、Electron、Google 或 Mozilla 渠道。",
                    isOn: $settingsModel.settings.installedAppUpdatesEnabled
                )
                Divider().padding(.leading)
                ToggleRow(
                    title: "已安装的应用程序通知",
                    description: "当后台扫描发现新更新时通知您。",
                    isOn: $settingsModel.settings.installedAppUpdateNotificationsEnabled
                )
                .disabled(!settingsModel.settings.installedAppUpdatesEnabled)
                .opacity(settingsModel.settings.installedAppUpdatesEnabled ? 1 : 0.5)
            }
            .modifier(SettingsContainerModifier())

            AppsSearchField(placeholder: "搜索更新结果", text: $updatesQuery)

            Picker("更新过滤器", selection: $updateFilter) {
                ForEach(AppUpdateFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            if installedUpdates.isChecking {
                HStack(spacing: 10) {
                    ProgressView(value: installedUpdates.checkProgress)
                        .progressViewStyle(.linear)
                    Text("\(snapshot.checkingCount) remaining")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            InstalledAppUpdatesBatchBar(checker: installedUpdates)

            LazyVStack(spacing: 0) {
                if snapshot.filteredEntries.isEmpty {
                    ContentUnavailableView(
                        "No matching apps",
                        systemImage: updateFilter == .updates ? "checkmark.circle" : "magnifyingglass",
                        description: Text(updateFilter == .updates ? "No installed app updates are currently available." : "Try a different filter or search.")
                    )
                    .frame(minHeight: 150)
                } else {
                    let lastEntryID = snapshot.filteredEntries.last?.id
                    ForEach(snapshot.filteredEntries) { entry in
                        InstalledAppUpdateRowView(entry: entry, checker: installedUpdates)
                        if entry.id != lastEntryID { Divider().padding(.leading, 60) }
                    }
                }
            }
            .modifier(SettingsContainerModifier())
        }
    }

    private var uninstallPane: some View {
        let query = uninstallQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let apps = appModel.apps.filter { app in
            (showSystemApps || !app.isSystem)
                && (query.isEmpty
                    || app.name.localizedCaseInsensitiveContains(query)
                    || app.bundleIdentifier.localizedCaseInsensitiveContains(query))
        }

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "trash.slash.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("审查了应用程序清理")
                        .font(.headline)
                    Text("该应用程序会自动选择。当无法证明独占所有权时，相关文件将保持不受检查状态。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    appModel.rescan()
                } label: {
                    Label("重新扫描", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(appModel.isLoading)
            }
            .padding(14)
            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.orange.opacity(0.2)))

            HStack(spacing: 12) {
                AppsSearchField(placeholder: "搜索已安装的应用程序", text: $uninstallQuery)
                Toggle("系统应用程序", isOn: $showSystemApps)
                    .toggleStyle(.checkbox)
                    .fixedSize()
            }

            if appModel.isLoading {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("扫描应用程序...")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("取消扫描") { appModel.cancelScan() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(.vertical, 12)
            }

            if let scanError = appModel.scanError, !scanError.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("部分应用程序无法扫描")
                            .font(.subheadline.weight(.semibold))
                        Text(scanError)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .help(scanError)
                    }
                    Spacer()
                    Button("重新扫描") { appModel.rescan() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(appModel.isLoading)
                }
                .padding(12)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            LazyVStack(spacing: 0) {
                if !appModel.isLoading && apps.isEmpty {
                    ContentUnavailableView.search(text: uninstallQuery)
                        .frame(minHeight: 180)
                } else {
                    let lastAppID = apps.last?.id
                    ForEach(apps) { app in
                        HStack(spacing: 12) {
                            CachedAppIconView(url: app.url, size: 40, cornerRadius: 9)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(app.name).font(.headline)
                                Text(app.isSystem
                                    ? "Version \(app.version) · protected app"
                                    : "Version \(app.version) · \(app.formattedSize)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(app.bundleIdentifier)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if installedUpdates.isBusy(app.bundleIdentifier) {
                                HStack(spacing: 6) {
                                    ProgressView().controlSize(.small)
                                    Text("正在更新…")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            } else if app.isSystem {
                                Label("受保护", systemImage: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Button("查看卸载...") {
                                    appModel.select(app)
                                    reviewApp = app
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        if app.id != lastAppID { Divider().padding(.leading, 66) }
                    }
                }
            }
            .modifier(SettingsContainerModifier())
        }
    }

    private func syncInstalledUpdateSettings() {
        installedUpdates.applySettings(
            installedAppUpdatesEnabled: settingsModel.settings.installedAppUpdatesEnabled,
            notificationsEnabled: settingsModel.settings.installedAppUpdateNotificationsEnabled
        )
    }

    private func loadInstalledAppInventoryIfNeeded() {
        guard appModel.apps.isEmpty, !appModel.isLoading else { return }
        appModel.scan()
    }

}

private struct AppsMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(detail).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.1)))
    }
}

private struct AppsSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ClearableSearchField(placeholder: LocalizedStringKey(placeholder), text: $text)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct AppUninstallReviewSheet: View {
    let app: InstalledApp
    @ObservedObject var model: InstalledAppsViewModel
    @Environment(\.dismiss) private var dismiss

    private var groupedArtifacts: [(AppArtifactCategory, [AppUninstallArtifact])] {
        Dictionary(grouping: model.artifacts, by: \.category)
            .map { ($0.key, $0.value) }
            .sorted { $0.0.rawValue < $1.0.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                CachedAppIconView(url: app.url, size: 48, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Uninstall \(app.name)").font(.title2.bold())
                    Text("该应用程序已选择。除非所有权得到验证，否则与标识符相关的、共享的和基于名称的数据需要审查。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .disabled(model.isRemoving)
            }
            .padding(20)

            Divider()

            if model.isScanningArtifacts {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("查找相关文件...").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let result = model.uninstallResult, result.appName == app.name {
                uninstallResultView(result)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if model.artifacts.contains(where: { $0.confidence != .exact }) {
                            Label("未经验证、共享、嵌套组件、重复标识符和应用程序名称匹配在您查看之前保持未选中状态。", systemImage: "exclamationmark.shield.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }

                        ForEach(groupedArtifacts, id: \.0.id) { category, artifacts in
                            VStack(alignment: .leading, spacing: 0) {
                                Label(category.rawValue, systemImage: category.systemImage)
                                    .font(.headline)
                                    .padding(.bottom, 7)
                                ForEach(artifacts) { artifact in
                                    Toggle(isOn: Binding(
                                        get: { model.selectedArtifactIDs.contains(artifact.id) },
                                        set: { model.setArtifact(artifact, selected: $0) }
                                    )) {
                                        HStack(spacing: 10) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(artifact.url.lastPathComponent)
                                                    .font(.subheadline.weight(.medium))
                                                    .lineLimit(1)
                                                Text(artifact.url.path)
                                                    .font(.caption2.monospaced())
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                                if artifact.requiresAuthorization, !artifact.isApplication {
                                                    Text("需要管理员权限；手动删除")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                } else if artifact.confidence != .exact {
                                                    Text(artifact.confidence.explanation)
                                                        .font(.caption2)
                                                        .foregroundStyle(.orange)
                                                }
                                            }
                                            Spacer()
                                            if artifact.requiresAuthorization {
                                                Image(systemName: "lock.fill")
                                                    .foregroundStyle(.secondary)
                                                    .help("需要管理员权限；蓝宝石无法移除该物品")
                                            }
                                            Text(artifact.formattedSize)
                                                .font(.caption.monospacedDigit())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .toggleStyle(.checkbox)
                                    .disabled(
                                        artifact.isApplication
                                            || model.isRemoving
                                            || artifact.requiresAuthorization
                                    )
                                    .padding(.vertical, 7)
                                    if artifact.id != artifacts.last?.id { Divider().padding(.leading, 24) }
                                }
                            }
                            .padding(14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1)))
                        }
                    }
                    .padding(20)
                }

                Divider()
                HStack {
                    Menu("选择") {
                        Button("Recommended") { model.selectRecommendedArtifacts() }
                        Button("选择所有相关文件") { model.selectAllArtifacts() }
                    }
                    .disabled(model.isRemoving)
                    Text("\(model.selectedArtifacts.count) items · \(model.selectedSize.formatted(.byteCount(style: .file)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .destructive) {
                        model.requestRemoval(app)
                    } label: {
                        if model.isRemoving {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Uninstall \(app.name)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(model.isRemoving || model.selectedArtifacts.isEmpty)
                }
                .padding(16)
            }
        }
        .frame(minWidth: 680, idealWidth: 760, minHeight: 560, idealHeight: 700)
        .interactiveDismissDisabled(model.isRemoving)
        .onDisappear {
            if !model.isRemoving { model.cancelArtifactScan() }
        }
        .alert("将应用程序和选定的相关文件移至垃圾箱？", isPresented: $model.confirmingRemoval) {
            Button("Uninstall", role: .destructive) { model.removeConfirmed() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(model.removalMessage)
        }
    }

    @ViewBuilder
    private func uninstallResultView(_ result: AppUninstallResult) -> some View {
        VStack(spacing: 14) {
            Image(systemName: result.succeeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(result.succeeded ? .green : .orange)
            Text(result.applicationRemoved
                ? (result.succeeded ? "App and selected data removed" : "App removed with some leftovers")
                : "App could not be removed")
                .font(.title3.bold())
            Text("\(result.removed.count) item\(result.removed.count == 1 ? "" : "s") moved to Trash.")
                .foregroundStyle(.secondary)
            if !result.failures.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(result.failures) { failure in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(failure.url.path).font(.caption.monospaced()).lineLimit(1)
                            Text(failure.message).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
        }
        .padding(30)
    }
}

private struct InstalledAppUpdateRowView: View {
    let entry: InstalledAppUpdateEntry
    let checker: InstalledAppUpdatesChecker

    var body: some View {
        HStack(spacing: 12) {
            InstalledAppUpdateSelectionToggle(checker: checker, entry: entry)

            CachedAppIconView(url: entry.url, size: 36, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                switch entry.status {
                case .checking:
                    Text("正在检查...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .upToDate(let latest):
                    Text("Version \(entry.currentVersion) · Up to date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if AppVersionOrdering.isNewer(latest, than: entry.currentVersion) {
                        Text("Latest available: \(latest)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                case .updateAvailable(let latest, _, _, let releaseNotes, _):
                    HStack(spacing: 6) {
                        Text("\(entry.currentVersion) → \(latest)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                        if let releaseNotes, !releaseNotes.isEmpty {
                            Button("发行说明") {
                                checker.releaseNotesEntry = InstalledAppUpdatesChecker.ReleaseNotesEntry(entry: entry)
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    }
                    if checker.buttonLabel(for: entry) == "Open App" {
                        Text("使用自己签名的更新程序 - Sapphire 将打开该应用程序。")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                case .unsupported:
                    Text(checker.canOpenManagedUpdater(for: entry)
                        ? "Updates are managed inside this app"
                        : "No update source found")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                case .ignored:
                    Text("Ignored")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                case .error(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }

            Spacer()

            statusActions
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var statusActions: some View {
        switch entry.status {
        case .updateAvailable:
            HStack(spacing: 8) {
                if checker.isBusy(entry.id) {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在升级…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button(checker.buttonLabel(for: entry)) {
                        checker.updateAction(for: entry.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                Menu {
                    InstalledAppUpdateSkipMenuItems(checker: checker, entry: entry)
                    Button("Ignore this app") { checker.setIgnored(true, for: entry.id) }
                    if case .updateAvailable(_, _, let pageURL, _, _) = entry.status, let pageURL {
                        Button(checker.isAppStoreEntry(entry) ? "Open in App Store" : "Open update page") {
                            checker.openUpdatePage(for: entry, pageURL: pageURL)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        case .checking, .upToDate:
            Menu {
                InstalledAppUpdateSkipMenuItems(checker: checker, entry: entry)
                Button("再次检查") { checker.checkAgain(entryID: entry.id) }
                Button("Ignore this app") { checker.setIgnored(true, for: entry.id) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        case .ignored, .unsupported, .error:
            Menu {
                if checker.canOpenManagedUpdater(for: entry) {
                    Button("打开应用程序更新程序") { checker.openManagedUpdater(entryID: entry.id) }
                }
                Button("再次检查") { checker.checkAgain(entryID: entry.id) }
                Button(checker.isIgnored(entry) ? "Stop ignoring" : "Ignore this app") {
                    checker.setIgnored(!checker.isIgnored(entry), for: entry.id)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

private struct InstalledAppReleaseNotesSheet: View {
    let entry: InstalledAppUpdatesChecker.ReleaseNotesEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CachedAppIconView(url: entry.url, size: 40, cornerRadius: 9)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.name) \(entry.latestVersion)")
                        .font(.headline)
                    Text("发行说明")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            Divider()
            ScrollView {
                if let notes = entry.releaseNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let url = entry.releaseNotesURL {
                    VStack(spacing: 12) {
                        Text("笔记在线发布。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("在浏览器中打开") {
                            NSWorkspace.shared.open(url)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    Text("没有发布此更新的发行说明。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
            }
        }
        .padding(20)
        .frame(width: 460, height: 380)
    }
}

struct StorageSettingsView: View {
    @StateObject private var model = StorageViewModel()

    var body: some View {
        ScrollView {
            PremiumFeatureView(feature: .basicStorageFeatures) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Storage")
                            .font(.largeTitle.bold())
                        Text("准确查看空间的使用情况、跟踪发生的变化并安全地回收空间。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if model.currentURL.path != "/" {
                        StorageBreadcrumbBar(model: model)
                    }

                    StorageWorkspaceView(model: model)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(MaterialChartPalette.tertiary)
                        Text("受保护的系统位置仅供检查。在回收空间之前，每次清理都会经过审核并移至垃圾箱。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(25)
            }
        }
        .onAppear { model.refreshFromCache() }
        .onDisappear { model.cancelScan() }
        .alert("将项目移至垃圾箱？", isPresented: $model.confirmingRemoval) {
            Button("移至垃圾箱", role: .destructive) { model.removeConfirmed() }
            Button("Cancel", role: .cancel) { model.cancelRemovalRequest() }
        } message: { Text(model.removalMessage) }
    }
}

private struct StorageBreadcrumbBar: View {
    @ObservedObject var model: StorageViewModel

    private var pathComponents: [(String, URL)] {
        let path = model.currentURL.standardizedFileURL.path
        let parts = path.split(separator: "/").map(String.init)
        var result: [(String, URL)] = [("Macintosh HD", URL(fileURLWithPath: "/"))]
        var url = URL(fileURLWithPath: "/")
        for part in parts where part != "" {
            url.appendPathComponent(part)
            result.append((part, url))
        }
        return result
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: model.goUp) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.12)))
            .disabled(model.currentURL.path == "/")
            .help("转到父文件夹")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                        Button {
                            model.open(StorageEntry(url: component.1, size: 0, isDirectory: true))
                        } label: {
                            Label(component.0, systemImage: index == 0 ? "internaldrive.fill" : "folder.fill")
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(index == pathComponents.count - 1 ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.07), in: Capsule())
                        .overlay(Capsule().stroke(index == pathComponents.count - 1 ? Color.accentColor.opacity(0.55) : Color.white.opacity(0.10)))
                    }
                }
                .padding(.vertical, 2)
            }

            Button("刷新", systemImage: "arrow.clockwise") { model.refresh() }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.12)))
                .help("刷新文件夹内容")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.14)))
    }
}

private struct IndexingPill: View {
    let progress: Double
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 130)
            Text(label).font(.caption.weight(.medium)).lineLimit(1)
            Text("\(Int(progress * 100))%")
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12)))
    }
}

private struct StoragePieSlice: View {
    let start: Double
    let end: Double
    let color: Color
    let label: String
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PieSlicePath(start: start, end: end)
                    .fill(color)
                    .overlay(PieSlicePath(start: start, end: end).stroke(Color.black.opacity(0.35), lineWidth: 1))
                let angle = (start + end) / 2 * 2 * .pi - .pi / 2
                let radius = min(geometry.size.width, geometry.size.height) * 0.36
                if fraction >= 0.035 {
                    Text(label)
                        .font(.system(size: fraction < 0.06 ? 8 : 10, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: fraction < 0.06 ? 48 : 82)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .clipped()
                        .rotationEffect(.radians(angle + .pi / 2))
                        .position(x: geometry.size.width / 2 + cos(angle) * radius, y: geometry.size.height / 2 + sin(angle) * radius)
                }
            }
        }
    }
}

private struct PieSlicePath: Shape {
    let start: Double
    let end: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: .degrees(start * 360 - 90), endAngle: .degrees(end * 360 - 90), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct GeneralSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @State private var showingCustomConfig = false
    @ObservedObject private var appFetcher = SystemAppFetcher.shared

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("General")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    SettingsSectionHeader(title: "行为")
                ForEach(GeneralSettingType.allCases) { setting in
                    IconToggleRow(systemImage: setting.systemImage, color: setting.iconColor, title: setting.displayName, isOn: binding(for: setting))
                    if setting == .expandOnHover, settings.settings.expandOnHover {
                        CustomSliderRowView(
                            label: "悬停延迟",
                            value: $settings.settings.expandOnHoverDelay,
                            range: 0.0...1.0,
                            specifier: "%.2fs"
                        )
                        .padding(.horizontal, 60)
                        .padding(.bottom, 8)
                    }
                    if setting != GeneralSettingType.allCases.last {
                        Divider().padding(.leading, 60)
                    }
                }
                if settings.settings.capsLockHorizontalLockEnabled {
                    Divider().padding(.leading, 60)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("允许在应用程序中使用")
                            .font(.headline)
                            .padding([.horizontal])
                        AppTogglesListView(
                            isEnabled: { app in capsLockAppBinding(for: app, isBrowser: app.isBrowser) },
                            maxHeight: 360,
                            browsersSectionTitle: "Browsers (Disabled by Default)",
                            onSelectAll: setAllApps
                        )
                    }
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }.modifier(SettingsContainerModifier())

                SettingsCard(title: "System") {

                    ToggleRow(title: "登录时启动", description: "Start Sapphire automatically when you log in to your Mac.", isOn: $settings.settings.launchAtLogin)
                    Divider().padding(.leading, 20)

                    ToggleRow(title: "启用触觉反馈", description: "Provide tactile feedback for certain interactions.", isOn: $settings.settings.hapticFeedbackEnabled)
                    Divider().padding(.leading, 20)

                    ToggleRow(title: "隐藏屏幕共享", description: "Never include Sapphire in screen sharing, screenshots, or screen recordings.", isOn: $settings.settings.hideFromScreenSharing)
                    Divider().padding(.leading, 20)

                    ToggleRow(title: "谷歌分析", description: "Send anonymous usage events to Google to help improve Sapphire. Disable this to opt out of analytics collection.", isOn: $settings.settings.googleAnalyticsEnabled)
                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "滑动隐藏缺口",
                        description: "When the notch is collapsed, swipe up over it to hide it completely. Swipe down near the notch area to bring it back.",
                        isOn: $settings.settings.swipeToHideNotch
                    )
                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "锁定时请勿展开",
                        description: "Prevent hover, click, and swipe from expanding the notch while the Mac is locked.",
                        isOn: $settings.settings.preventNotchExpandWhenLocked
                    )
                }

                SettingsCard(title: "小部件转换", description: "控制扩展凹口内的小部件之间切换时的视觉效果。") {

                    Toggle("启用淡入淡出效果", isOn: $settings.settings.enableWidgetSwitchFade)
                        .padding()
                    Divider().padding(.leading, 20)
                    Toggle("启用幻灯片效果", isOn: $settings.settings.enableWidgetSwitchSlide)
                        .padding()
                    Divider().padding(.leading, 20)
                    Toggle("启用弹跳效果", isOn: $settings.settings.enableWidgetSwitchBounce)
                        .padding()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("动画简介")
                        .font(.headline)
                        .padding([.horizontal, .top])

                    Text(descriptionForCurrentProfile())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 5)

                    Picker("动画简介", selection: $settings.settings.animationProfile) {
                        ForEach(AnimationProfile.allCases) { profile in
                            Text(profile.displayName).tag(profile)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom)

                    if settings.settings.animationProfile == .custom {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("自定义动画值")
                                    .font(.subheadline.bold())
                                Spacer()
                                Button("重置为默认值") {
                                    withAnimation {
                                        settings.settings.customAnimationConfiguration = .init()
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.accentColor)
                                .help("将所有自定义动画值重置为“Snappy”默认值。")
                            }

                            Text("Response: How long the animation takes (lower is faster).\nDamping: How much bounce (1.0 is no bounce).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 5)

                            Group {
                                Text("主要转变").font(.caption.bold()).foregroundColor(.secondary)
                                AnimationSliderRow(title: "展开回应", description: "打开主小部件视图。", value: $settings.settings.customAnimationConfiguration.expandResponse, range: 0.1...1.0)
                                AnimationSliderRow(title: "展开阻尼", description: "", value: $settings.settings.customAnimationConfiguration.expandDamping, range: 0.4...1.0)
                                Divider()
                                AnimationSliderRow(title: "崩溃响应", description: "关闭主小部件视图。", value: $settings.settings.customAnimationConfiguration.collapseResponse, range: 0.1...1.0)
                                AnimationSliderRow(title: "塌陷阻尼", description: "", value: $settings.settings.customAnimationConfiguration.collapseDamping, range: 0.4...1.0)
                                Divider()
                                AnimationSliderRow(title: "滑动打开响应", description: "通过触控板滑动打开小部件。", value: $settings.settings.customAnimationConfiguration.swipeOpenResponse, range: 0.1...1.0)
                                AnimationSliderRow(title: "滑动打开阻尼", description: "", value: $settings.settings.customAnimationConfiguration.swipeOpenDamping, range: 0.4...1.0)
                            }

                            Group {
                                Text("动态状态").font(.caption.bold()).foregroundColor(.secondary).padding(.top)
                                AnimationSliderRow(title: "悬停响应", description: "悬停在凹口上时的小幅膨胀。", value: $settings.settings.customAnimationConfiguration.hoverResponse, range: 0.1...1.0)
                                AnimationSliderRow(title: "悬停阻尼", description: "", value: $settings.settings.customAnimationConfiguration.hoverDamping, range: 0.4...1.0)
                                Divider()
                                AnimationSliderRow(title: "自动扩展响应", description: "当实时活动自动出现时。", value: $settings.settings.customAnimationConfiguration.autoExpandResponse, range: 0.1...1.0)
                                AnimationSliderRow(title: "自动扩展阻尼", description: "", value: $settings.settings.customAnimationConfiguration.autoExpandDamping, range: 0.4...1.0)
                            }

                            Group {
                                Text("内容与活动").font(.caption.bold()).foregroundColor(.secondary).padding(.top)
                                AnimationSliderRow(title: "内容转换响应", description: "小部件如何显示在展开视图中。", value: $settings.settings.customAnimationConfiguration.contentTransitionResponse, range: 0.1...1.0)
                                AnimationSliderRow(title: "内容过渡阻尼", description: "", value: $settings.settings.customAnimationConfiguration.contentTransitionDamping, range: 0.4...1.0)
                                Divider()
                                AnimationSliderRow(title: "活动开关响应", description: "在不同的实时活动之间转换。", value: $settings.settings.customAnimationConfiguration.activityToActivityResponse, range: 0.1...1.0)
                                AnimationSliderRow(title: "活动开关阻尼", description: "", value: $settings.settings.customAnimationConfiguration.activityToActivityDamping, range: 0.4...1.0)
                                Divider()
                                AnimationSliderRow(title: "活动变形反应", description: "平滑地改变实时活动的形状。", value: $settings.settings.customAnimationConfiguration.activityMorphResponse, range: 0.1...1.0)
                                AnimationSliderRow(title: "活动变形阻尼", description: "", value: $settings.settings.customAnimationConfiguration.activityMorphDamping, range: 0.4...1.0)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.animationProfile)

                VStack(alignment: .leading, spacing: 0) {
                    Text("高级定制").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "启用自定义缺口配置", description: "Override default appearance and animation values. This may lead to unexpected behavior.", isOn: $settings.settings.useCustomNotchConfiguration)

                    if settings.settings.useCustomNotchConfiguration {
                        Button("编辑自定义配置") {
                            showingCustomConfig = true
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.useCustomNotchConfiguration)

                VStack(alignment: .leading, spacing: 10) {
                    Text("缺口栏项目").font(.headline).padding([.horizontal, .top])
                    Text("启用、禁用和重新排序展开凹口时出现的图标。").font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 5)
                    ReorderableVStack(items: $settings.settings.notchButtonOrder) { buttonType in
                        NotchButtonRowView(buttonType: buttonType)
                    }

                    if settings.settings.notchButtonOrder.contains(.spacer) {
                        Divider().padding(.horizontal)
                        NotchBarSpacerWidthRow()
                    }
                }
                .modifier(SettingsContainerModifier())

            }
        .padding(25)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .onAppear {
        if settings.settings.capsLockHorizontalLockEnabled {
            appFetcher.fetchApps()
        }
    }
    .onChange(of: settings.settings.capsLockHorizontalLockEnabled) { _, enabled in
        if enabled {
            appFetcher.fetchApps()
        } else {
            SystemAppFetcher.shared.releaseCachedApps()
            AppIconLoader.releaseCache()
        }
    }
    .sheet(isPresented: $showingCustomConfig) {
            CustomNotchConfigView(config: $settings.settings.customNotchConfiguration)
        }
    }

    private func binding(for setting: GeneralSettingType) -> Binding<Bool> {
        switch setting {
        case .expandOnHover: return $settings.settings.expandOnHover
        case .swipeToSwitchWidgets: return $settings.settings.swipeToSwitchWidgets
        case .enableOpeningBounce: return $settings.settings.enableOpeningBounce
        case .capsLockHorizontalLock: return $settings.settings.capsLockHorizontalLockEnabled
        }
    }

    private func capsLockAppBinding(for app: SystemApp, isBrowser: Bool) -> Binding<Bool> {
        Binding(
            get: { settings.settings.capsLockHorizontalLockAppStates[app.id, default: true] },
            set: { settings.settings.capsLockHorizontalLockAppStates[app.id] = $0 }
        )
    }

    private func setAllApps(to enabled: Bool) {
        var appStates = settings.settings.capsLockHorizontalLockAppStates
        appStates.reserveCapacity(appFetcher.apps.count)
        for app in appFetcher.apps {
            appStates[app.id] = enabled
        }
        settings.settings.capsLockHorizontalLockAppStates = appStates
    }

    private func descriptionForCurrentProfile() -> String {
        switch settings.settings.animationProfile {
        case .snappy:
            return "A quick and responsive feel with minimal bounce."
        case .fluid:
            return "The default. Content grows out of the notch with the shape, blurring into focus as it lands."
        case .bouncy:
            return "A playful and energetic animation with noticeable bounce."
        case .calm:
            return "A slower, more graceful animation with a very gentle ease."
        case .custom:
            return "Fine-tune every animation parameter to your exact liking."
        }
    }
}

fileprivate struct AnimationSliderRow: View {
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        DeferredValueEditor(value: $value) { draft, onEditingChanged in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                        if !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text(String(format: "%.2f", draft.wrappedValue))
                        .font(.body.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: draft, in: range, onEditingChanged: onEditingChanged)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CustomNotchConfigView: View {
    @Binding var config: CustomizableNotchConfiguration
    @Environment(\.dismiss) var dismiss

    @State private var initialCornerRadius: Double
    @State private var topBuffer: Double
    @State private var scaleFactor: Double
    @State private var hoverExpandedCornerRadius: Double
    @State private var autoExpandedCornerRadius: Double
    @State private var autoExpandedTallHeight: Double
    @State private var autoExpandedContentVerticalPadding: Double
    @State private var clickExpandedCornerRadius: Double
    @State private var liveActivityBottomCornerRadius: Double
    @State private var collapseAnimationDelay: Double
    @State private var dragActivationCollapseDelay: Double
    @State private var expandAnimationResponse: Double
    @State private var expandAnimationDamping: Double
    @State private var swipeOpenAnimationResponse: Double
    @State private var swipeOpenAnimationDamping: Double
    @State private var collapseAnimationResponse: Double
    @State private var collapseAnimationDamping: Double
    @State private var widgetBlurRadiusMax: Double
    @State private var activityBlurRadiusMax: Double
    @State private var expandedShadowRadius: Double
    @State private var expandedShadowOffsetY: Double
    @State private var contentTopPadding: Double
    @State private var contentBottomPadding: Double
    @State private var contentHorizontalPadding: Double

    init(config: Binding<CustomizableNotchConfiguration>) {
        self._config = config
        let wrapped = config.wrappedValue

        _initialCornerRadius = State(initialValue: Double(wrapped.initialCornerRadius))
        _topBuffer = State(initialValue: Double(wrapped.topBuffer))
        _scaleFactor = State(initialValue: Double(wrapped.scaleFactor))
        _hoverExpandedCornerRadius = State(initialValue: Double(wrapped.hoverExpandedCornerRadius))
        _autoExpandedCornerRadius = State(initialValue: Double(wrapped.autoExpandedCornerRadius))
        _autoExpandedTallHeight = State(initialValue: Double(wrapped.autoExpandedTallHeight))
        _autoExpandedContentVerticalPadding = State(initialValue: Double(wrapped.autoExpandedContentVerticalPadding))
        _clickExpandedCornerRadius = State(initialValue: Double(wrapped.clickExpandedCornerRadius))
        _liveActivityBottomCornerRadius = State(initialValue: Double(wrapped.liveActivityBottomCornerRadius))
        _collapseAnimationDelay = State(initialValue: wrapped.collapseAnimationDelay)
        _dragActivationCollapseDelay = State(initialValue: wrapped.dragActivationCollapseDelay)
        _expandAnimationResponse = State(initialValue: wrapped.expandAnimationResponse)
        _expandAnimationDamping = State(initialValue: wrapped.expandAnimationDamping)
        _swipeOpenAnimationResponse = State(initialValue: wrapped.swipeOpenAnimationResponse)
        _swipeOpenAnimationDamping = State(initialValue: wrapped.swipeOpenAnimationDamping)
        _collapseAnimationResponse = State(initialValue: wrapped.collapseAnimationResponse)
        _collapseAnimationDamping = State(initialValue: wrapped.collapseAnimationDamping)
        _widgetBlurRadiusMax = State(initialValue: Double(wrapped.widgetBlurRadiusMax))
        _activityBlurRadiusMax = State(initialValue: Double(wrapped.activityBlurRadiusMax))
        _expandedShadowRadius = State(initialValue: Double(wrapped.expandedShadowRadius))
        _expandedShadowOffsetY = State(initialValue: Double(wrapped.expandedShadowOffsetY))
        _contentTopPadding = State(initialValue: Double(wrapped.contentTopPadding))
        _contentBottomPadding = State(initialValue: Double(wrapped.contentBottomPadding))
        _contentHorizontalPadding = State(initialValue: Double(wrapped.contentHorizontalPadding))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("自定义凹口配置")
                    .font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                LazyVStack(spacing: 25) {
                    Section(header: Text("尺寸和位置").font(.headline)) {
                        CustomSliderRowView(label: "自动扩展高度", value: $autoExpandedTallHeight, range: 50...150, specifier: "%.1f")
                        CustomSliderRowView(label: "顶部缓冲器", value: $topBuffer, range: 0...20, specifier: "%.1f")
                    }

                    Section(header: Text("悬停状态").font(.headline)) {
                        CustomSliderRowView(label: "悬停比例因子", value: $scaleFactor, range: 1.0...1.5, specifier: "%.2f x")
                    }

                    Section(header: Text("拐角半径").font(.headline)) {
                        CustomSliderRowView(label: "初始", value: $initialCornerRadius, range: 5...50, specifier: "%.1f")
                        CustomSliderRowView(label: "悬停展开", value: $hoverExpandedCornerRadius, range: 10...60, specifier: "%.1f")
                        CustomSliderRowView(label: "自动扩展", value: $autoExpandedCornerRadius, range: 10...60, specifier: "%.1f")
                        CustomSliderRowView(label: "单击展开", value: $clickExpandedCornerRadius, range: 10...60, specifier: "%.1f")
                        CustomSliderRowView(label: "直播活动底部", value: $liveActivityBottomCornerRadius, range: 10...60, specifier: "%.1f")
                    }

                    Section(header: Text("动画（弹簧）").font(.headline)) {
                        CustomSliderRowView(label: "展开回应", value: $expandAnimationResponse, range: 0.1...1.0, specifier: "%.2f")
                        CustomSliderRowView(label: "展开阻尼", value: $expandAnimationDamping, range: 0.1...1.0, specifier: "%.2f")
                        CustomSliderRowView(label: "滑动打开响应", value: $swipeOpenAnimationResponse, range: 0.1...1.0, specifier: "%.2f")
                        CustomSliderRowView(label: "滑动打开阻尼", value: $swipeOpenAnimationDamping, range: 0.1...1.0, specifier: "%.2f")
                        CustomSliderRowView(label: "崩溃响应", value: $collapseAnimationResponse, range: 0.1...1.0, specifier: "%.2f")
                        CustomSliderRowView(label: "塌陷阻尼", value: $collapseAnimationDamping, range: 0.1...1.0, specifier: "%.2f")
                    }

                    Section(header: Text("延误").font(.headline)) {
                        CustomSliderRowView(label: "折叠动画延迟", value: $collapseAnimationDelay, range: 0.0...1.0, specifier: "%.2f s")
                        CustomSliderRowView(label: "拖动激活折叠延迟", value: $dragActivationCollapseDelay, range: 0.0...1.0, specifier: "%.2f s")
                    }

                    Section(header: Text("填充").font(.headline)) {
                        CustomSliderRowView(label: "内容顶部填充", value: $contentTopPadding, range: 0...50, specifier: "%.1f")
                        CustomSliderRowView(label: "内容底部填充", value: $contentBottomPadding, range: 0...50, specifier: "%.1f")
                        CustomSliderRowView(label: "内容水平填充", value: $contentHorizontalPadding, range: 0...100, specifier: "%.1f")
                        CustomSliderRowView(label: "自动扩展垂直内边距", value: $autoExpandedContentVerticalPadding, range: 0...50, specifier: "%.1f")
                    }

                    Section(header: Text("模糊和阴影").font(.headline)) {
                        CustomSliderRowView(label: "小部件模糊半径最大", value: $widgetBlurRadiusMax, range: 0...100, specifier: "%.1f")
                        CustomSliderRowView(label: "活动模糊半径最大", value: $activityBlurRadiusMax, range: 0...100, specifier: "%.1f")
                        CustomSliderRowView(label: "扩大阴影半径", value: $expandedShadowRadius, range: 0...50, specifier: "%.1f")
                        CustomSliderRowView(label: "扩展阴影偏移 Y", value: $expandedShadowOffsetY, range: 0...30, specifier: "%.1f")
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Button("重置为默认值") {
                    let defaultConfig = CustomizableNotchConfiguration()
                    syncState(from: defaultConfig)
                }
                Spacer()
                Button("Done") {
                    syncConfig()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 550, idealWidth: 600, minHeight: 400, idealHeight: 750)
    }

    private func syncState(from sourceConfig: CustomizableNotchConfiguration) {
        initialCornerRadius = Double(sourceConfig.initialCornerRadius)
        topBuffer = Double(sourceConfig.topBuffer)
        scaleFactor = Double(sourceConfig.scaleFactor)
        hoverExpandedCornerRadius = Double(sourceConfig.hoverExpandedCornerRadius)
        autoExpandedCornerRadius = Double(sourceConfig.autoExpandedCornerRadius)
        autoExpandedTallHeight = Double(sourceConfig.autoExpandedTallHeight)
        autoExpandedContentVerticalPadding = Double(sourceConfig.autoExpandedContentVerticalPadding)
        clickExpandedCornerRadius = Double(sourceConfig.clickExpandedCornerRadius)
        liveActivityBottomCornerRadius = Double(sourceConfig.liveActivityBottomCornerRadius)
        collapseAnimationDelay = sourceConfig.collapseAnimationDelay
        dragActivationCollapseDelay = sourceConfig.dragActivationCollapseDelay
        expandAnimationResponse = sourceConfig.expandAnimationResponse
        expandAnimationDamping = sourceConfig.expandAnimationDamping
        swipeOpenAnimationResponse = sourceConfig.swipeOpenAnimationResponse
        swipeOpenAnimationDamping = sourceConfig.swipeOpenAnimationDamping
        collapseAnimationResponse = sourceConfig.collapseAnimationResponse
        collapseAnimationDamping = sourceConfig.collapseAnimationDamping
        widgetBlurRadiusMax = Double(sourceConfig.widgetBlurRadiusMax)
        activityBlurRadiusMax = Double(sourceConfig.activityBlurRadiusMax)
        expandedShadowRadius = Double(sourceConfig.expandedShadowRadius)
        expandedShadowOffsetY = Double(sourceConfig.expandedShadowOffsetY)
        contentTopPadding = Double(sourceConfig.contentTopPadding)
        contentBottomPadding = Double(sourceConfig.contentBottomPadding)
        contentHorizontalPadding = Double(sourceConfig.contentHorizontalPadding)
    }

    private func syncConfig() {
        config.initialCornerRadius = CGFloat(initialCornerRadius)
        config.topBuffer = CGFloat(topBuffer)
        config.scaleFactor = CGFloat(scaleFactor)
        config.hoverExpandedCornerRadius = CGFloat(hoverExpandedCornerRadius)
        config.autoExpandedCornerRadius = CGFloat(autoExpandedCornerRadius)
        config.autoExpandedTallHeight = CGFloat(autoExpandedTallHeight)
        config.autoExpandedContentVerticalPadding = CGFloat(autoExpandedContentVerticalPadding)
        config.clickExpandedCornerRadius = CGFloat(clickExpandedCornerRadius)
        config.liveActivityBottomCornerRadius = CGFloat(liveActivityBottomCornerRadius)
        config.collapseAnimationDelay = collapseAnimationDelay
        config.dragActivationCollapseDelay = dragActivationCollapseDelay
        config.expandAnimationResponse = expandAnimationResponse
        config.expandAnimationDamping = expandAnimationDamping
        config.swipeOpenAnimationResponse = swipeOpenAnimationResponse
        config.swipeOpenAnimationDamping = swipeOpenAnimationDamping
        config.collapseAnimationResponse = collapseAnimationResponse
        config.collapseAnimationDamping = collapseAnimationDamping
        config.widgetBlurRadiusMax = CGFloat(widgetBlurRadiusMax)
        config.activityBlurRadiusMax = CGFloat(activityBlurRadiusMax)
        config.expandedShadowRadius = CGFloat(expandedShadowRadius)
        config.expandedShadowOffsetY = CGFloat(expandedShadowOffsetY)
        config.contentTopPadding = CGFloat(contentTopPadding)
        config.contentBottomPadding = CGFloat(contentBottomPadding)
        config.contentHorizontalPadding = CGFloat(contentHorizontalPadding)
    }
}

struct FileShelfSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    private var continuity: ContinuityManager { .shared }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("File Shelf")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "悬停时展开架子",
                        description: "Automatically expand the full File Shelf by hovering over its live activity.",
                        isOn: $settings.settings.hoverToOpenFileShelf
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "点击实时活动即可打开书架",
                        description: "Clicking the File Shelf live activity opens the shelf instead of the default widgets.",
                        isOn: $settings.settings.clickToOpenFileShelf
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "拖出后删除文件",
                        description: "When you drag a file out of the shelf, remove it from the shelf automatically.",
                        isOn: $settings.settings.removeFileFromShelfAfterDrag
                    )
                }
                .modifier(SettingsContainerModifier())

                SettingsCard(
                    title: "放置目的地",
                    description: "选择将文件拖入凹口时显示的目标位置。"
                ) {
                    ToggleRow(
                        title: "AirDrop",
                        description: "Show the AirDrop box in the File Shelf landing view.",
                        isOn: $settings.settings.fileShelfAirDropDestinationEnabled
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "分享到设备",
                        description: deviceDestinationDescription,
                        isOn: $settings.settings.fileShelfDeviceDestinationsEnabled
                    )
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var deviceDestinationDescription: String {
        let count = continuity.peers.count
        if count == 0 {
            return "Drop files onto your paired Continuity phone from the File Shelf. Pair a device in Continuity settings first."
        }
        return "Drop files onto any of your \(count) paired Continuity \(count == 1 ? "device" : "devices") from the File Shelf. Offline devices stay visible."
    }
}

struct NotesSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Notes")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "启用笔记小部件",
                        description: "Show the quick notes widget in the notch widget strip.",
                        isOn: $settings.settings.notesWidgetEnabled
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "点击打开笔记",
                        description: "Clicking the notes widget expands into the full notes editor.",
                        isOn: $settings.settings.notesOpenOnClick
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "在缺口栏中显示注释",
                        description: "Add a notes icon to the expanded notch header for quick access.",
                        isOn: $settings.settings.notesIconEnabled
                    )
                }
                .modifier(SettingsContainerModifier())

                SettingsCard(title: "滑动操作", description: "自定义在完整笔记视图中向左或向右滑动笔记行时会发生什么。") {

                    SwipeActionPickerRow(
                        title: "向右滑动",
                        description: "在注释行上引导滑动。",
                        selection: $settings.settings.swipeActionSettings.notesLeading,
                        options: NotesSwipeAction.allCases,
                        label: { $0.displayName }
                    )

                    Divider().padding(.leading, 20)

                    SwipeActionPickerRow(
                        title: "向左滑动",
                        description: "在注释行上尾随滑动。",
                        selection: $settings.settings.swipeActionSettings.notesTrailing,
                        options: NotesSwipeAction.allCases,
                        label: { $0.displayName }
                    )
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct ClipboardSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @State private var historyCount = 0
    @ObservedObject private var shortcutRecorder = GlobalShortcutRecorder.shared
    @ObservedObject private var clipboardPickerManager = ClipboardPickerManager.shared

    private var isRecordingPickerShortcut: Bool {
        shortcutRecorder.isRecording && shortcutRecorder.recordingIdentifier == "clipboardPickerShortcut"
    }

    private var pickerShortcutLabel: String {
        let shortcut = settings.settings.clipboardPickerShortcut
        return "\(KeyboardShortcutHelper.description(for: shortcut.modifiers))\(shortcut.key)"
    }

    private var quickPickerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            PremiumFeatureView(feature: .clipboardPicker) {
                VStack(alignment: .leading, spacing: 0) {
                    SettingsSectionHeader(title: "快速选择器", description: "在您使用全局快捷方式输入内容的位置打开统一的蓝宝石选择器。选择剪贴板项目将其复制并粘贴到光标处；表情符号选项卡直接输入表情符号。 （表情符号快捷方式在其表情符号选项卡上打开相同的面板。）")

                    ToggleRow(
                        title: "启用快速选择器",
                        description: "Allow the global shortcut to open the clipboard panel anywhere.",
                        isOn: $settings.settings.clipboardPickerEnabled
                    )

                    Divider().padding(.leading, 20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("选择器快捷方式")
                                .font(.system(size: 14, weight: .medium))
                            Text("替换默认的粘贴匹配样式快捷方式。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        if !isRecordingPickerShortcut {
                            Text(pickerShortcutLabel)
                                .font(.caption.monospaced())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.07))
                                .clipShape(Capsule())
                        }

                        Button(isRecordingPickerShortcut ? "Cancel" : "Record…") {
                            if isRecordingPickerShortcut {
                                shortcutRecorder.stopRecording()
                            } else {
                                shortcutRecorder.startRecording(identifier: "clipboardPickerShortcut") { key, modifiers in
                                    settings.settings.clipboardPickerShortcut = KeyboardShortcut(key: key, modifiers: modifiers)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!settings.settings.clipboardPickerEnabled)
                    }
                    .padding()

                    Divider().padding(.leading, 20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("打开选择器")
                                .font(.system(size: 14, weight: .medium))
                            Text("立即尝试选择器 - 它会在“剪贴板”选项卡上打开。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            clipboardPickerManager.presentPicker()
                        } label: {
                            Label("打开选择器", systemImage: "list.clipboard")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.mint)
                        .disabled(!settings.settings.clipboardPickerEnabled)
                    }
                    .padding()
                }
            }
        }
        .modifier(SettingsContainerModifier())
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Clipboard")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                RequiredPermissionsView(section: .clipboard)

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "启用剪贴板小部件",
                        description: "Show recent clipboard items in the notch widget strip.",
                        isOn: $settings.settings.clipboardWidgetEnabled
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "单击打开剪贴板",
                        description: "Clicking the clipboard widget expands into the full clipboard history.",
                        isOn: $settings.settings.clipboardOpenOnClick
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "在缺口栏中显示剪贴板",
                        description: "Add a clipboard icon to the expanded notch header for quick access.",
                        isOn: $settings.settings.clipboardIconEnabled
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "监控剪贴板",
                        description: "Continuously capture newly copied text and images into Sapphire history.",
                        isOn: $settings.settings.clipboardMonitoringEnabled
                    )
                    .onChange(of: settings.settings.clipboardMonitoringEnabled) { _, enabled in
                        settings.commitNow()
                        if enabled {
                            ClipboardManager.shared.startMonitoring()
                        } else {
                            ClipboardManager.shared.stopMonitoring()
                        }
                    }
                }
                .modifier(SettingsContainerModifier())

                quickPickerSection

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "无限历史",
                        description: "Keep every item, with no item or storage limit.",
                        isOn: $settings.settings.clipboardHistoryUnlimited
                    )
                    .onChange(of: settings.settings.clipboardHistoryUnlimited) { _, unlimited in
                        if unlimited {
                            settings.settings.clipboardHistoryLimit = 0
                        } else if settings.settings.clipboardHistoryLimit <= 0 {
                            settings.settings.clipboardHistoryLimit = ClipboardHistoryBudget.defaultItemLimit
                        }
                    }

                    if !settings.settings.clipboardHistoryUnlimited {
                        Divider().padding(.leading, 20)

                        CustomSliderRowView(
                            label: "历史限制",
                            value: Binding(
                                get: { Double(max(4, settings.settings.clipboardHistoryLimit)) },
                                set: { settings.settings.clipboardHistoryLimit = Int($0.rounded()) }
                            ),
                            range: 4...Double(ClipboardHistoryBudget.itemLimitRange.upperBound),
                            specifier: "%.0f items"
                        )

                        Divider().padding(.leading, 20)

                        ClipboardStorageLimitRow()
                    }

                    Divider().padding(.leading, 20)

                    ClipboardIgnoredAppsRow()

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "忽略隐藏的物品",
                        description: "Skip passwords and other concealed clipboard content (e.g., from 1Password, Bitwarden).",
                        isOn: $settings.settings.clipboardIgnoreConcealedItems
                    )

                    Divider().padding(.leading, 20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("清除历史记录")
                            Text("Remove \(historyCount) stored clipboard items.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear") {
                            ClipboardManager.shared.clearHistory()
                            historyCount = 0
                        }
                        .buttonStyle(.bordered)
                        .disabled(historyCount == 0)
                    }
                    .padding()
                }
                .modifier(SettingsContainerModifier())

                SettingsCard(title: "滑动操作", description: "自定义在完整剪贴板视图中向左或向右滑动剪贴板行时会发生的情况。") {

                    SwipeActionPickerRow(
                        title: "向右滑动",
                        description: "在剪贴板行上引导滑动。",
                        selection: $settings.settings.swipeActionSettings.clipboardLeading,
                        options: ClipboardSwipeAction.allCases,
                        label: { $0.displayName }
                    )

                    Divider().padding(.leading, 20)

                    SwipeActionPickerRow(
                        title: "向左滑动",
                        description: "在剪贴板行上尾随滑动。",
                        selection: $settings.settings.swipeActionSettings.clipboardTrailing,
                        options: ClipboardSwipeAction.allCases,
                        label: { $0.displayName }
                    )
                }

                VStack(alignment: .leading, spacing: 0) {
                    PremiumFeatureView(feature: .clipboardAdvancedTools) {
                        VStack(alignment: .leading, spacing: 0) {
                            SettingsSectionHeader(title: "自动清除剪贴板", description: "复制后指定时间、或者 Mac 睡眠或屏幕锁定时清空系统剪贴板。保存的历史记录项目永远不会被触及。")

                            ToggleRow(
                                title: "启用自动清除",
                                description: "Work with or without clipboard history enabled.",
                                isOn: $settings.settings.clipboardAutoClearEnabled
                            )

                            if settings.settings.clipboardAutoClearEnabled {
                                Divider().padding(.leading, 20)

                                ToggleRow(
                                    title: "延迟后清除",
                                    description: "复制某些内容后这么长时间内清空剪贴板。",
                                    isOn: Binding(
                                        get: { settings.settings.clipboardAutoClearInterval > 0 },
                                        set: { on in
                                            if on, settings.settings.clipboardAutoClearInterval <= 0 {
                                                settings.settings.clipboardAutoClearInterval = 30
                                            } else if !on {
                                                settings.settings.clipboardAutoClearInterval = 0
                                            }
                                        }
                                    )
                                )

                                if settings.settings.clipboardAutoClearInterval > 0 {
                                    Divider().padding(.leading, 20)
                                    CustomSliderRowView(
                                        label: "之后清除",
                                        value: $settings.settings.clipboardAutoClearInterval,
                                        range: 5...300,
                                        specifier: "%.0f s"
                                    )
                                    .padding(.horizontal)
                                }

                                Divider().padding(.leading, 20)
                                ToggleRow(
                                    title: "Mac 睡眠时清除",
                                    description: "Empty the clipboard when the Mac (or its display) sleeps.",
                                    isOn: $settings.settings.clipboardAutoClearOnSleep
                                )

                                Divider().padding(.leading, 20)
                                ToggleRow(
                                    title: "屏幕锁定时清除",
                                    description: "Empty the clipboard when the screen locks.",
                                    isOn: $settings.settings.clipboardAutoClearOnLock
                                )
                            }
                        }
                    }
                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    PremiumFeatureView(feature: .clipboardAdvancedTools) {
                        VStack(alignment: .leading, spacing: 0) {
                            SettingsSectionHeader(title: "干净的网址", description: "自动从复制的链接中去除跟踪参数（utm_*、fbclid、gclid...）。图像、文件和富文本不受影响地通过。")

                            ToggleRow(
                                title: "清理复制的链接",
                                description: "Rewrite copied URLs without their tracking parameters.",
                                isOn: $settings.settings.clipboardCleanURLEnabled
                            )

                            if settings.settings.clipboardCleanURLEnabled {
                                Divider().padding(.leading, 20)
                                ToggleRow(
                                    title: "复印时自动清洁",
                                    description: "Clean as soon as a link is copied. Turn off to only clean from the picker.",
                                    isOn: $settings.settings.clipboardCleanURLAutoClean
                                )

                                Divider().padding(.leading, 20)
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("清除剪贴板上的链接")
                                        Text("现在，从您上次复制的链接中删除跟踪参数。")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button("立即清洁") { CleanURLManager.shared.cleanClipboardLinkNow() }
                                        .buttonStyle(.bordered)
                                }
                                .padding()
                            }
                        }
                    }
                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    PremiumFeatureView(feature: .clipboardAdvancedTools) {
                        VStack(alignment: .leading, spacing: 0) {
                            SettingsSectionHeader(title: "Finder 剪切和粘贴", description: "⌘X 然后 ⌘V 移动复制的文件而不是复制它们，⌘V 将复制的图像作为 PNG 文件粘贴到前面的 Finder 文件夹中，F2 重命名所选项目。")

                            ToggleRow(
                                title: "启用查找器快捷方式",
                                description: "Active only while Finder is the app in front.",
                                isOn: $settings.settings.clipboardFinderCutPasteEnabled
                            )

                            if settings.settings.clipboardFinderCutPasteEnabled {
                                Divider().padding(.leading, 20)
                                ToggleRow(
                                    title: "将图像粘贴为 PNG 文件",
                                    description: "⌘V in Finder turns a copied image into a PNG file in the front folder.",
                                    isOn: $settings.settings.clipboardFinderPasteImagesAsPNG
                                )

                                Divider().padding(.leading, 20)
                                ToggleRow(
                                    title: "F2 重命名所选内容",
                                    description: "Press F2 in Finder to start an inline rename.",
                                    isOn: $settings.settings.clipboardFinderF2RenameEnabled
                                )
                            }
                        }
                    }
                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    PremiumFeatureView(feature: .clipboardAdvancedTools) {
                        VStack(alignment: .leading, spacing: 0) {
                            SettingsSectionHeader(title: "文本片段", description: "Type a short trigger anywhere and it becomes your text. Use \"{{date}}\", \"{{time}}\", \"{{date:MMMM d}}\" or \"{{clipboard}}\" in the replacement. Sapphire never expands while you type inside Sapphire itself.")

                            ToggleRow(
                                title: "启用文本片段",
                                description: "Expand triggers as you type in any app.",
                                isOn: $settings.settings.snippetsEnabled
                            )

                            if settings.settings.snippetsEnabled {
                                Divider().padding(.leading, 20)
                                ToggleRow(
                                    title: "在空格或标点符号后展开",
                                    description: "Off expands the moment the trigger completes.",
                                    isOn: $settings.settings.snippetsExpandAfterSpace
                                )

                                Divider().padding(.leading, 20)
                                HStack {
                                    Text("片段").font(.subheadline).foregroundStyle(.secondary)
                                    Spacer()
                                    Button {
                                        settings.settings.snippetsList.append(SnippetEntry())
                                    } label: {
                                        Label("添加片段", systemImage: "plus.circle")
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.horizontal)

                                ForEach($settings.settings.snippetsList) { $snippet in
                                    Divider().padding(.leading, 20)
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            Toggle("", isOn: $snippet.isEnabled)
                                                .toggleStyle(.switch)
                                                .controlSize(.small)
                                            TextField("触发", text: $snippet.trigger)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 150)
                                            Spacer()
                                            Button {
                                                let doomed = snippet.id
                                                DispatchQueue.main.async {
                                                    settings.settings.snippetsList.removeAll { $0.id == doomed }
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                                            }
                                            .buttonStyle(.borderless)
                                        }
                                        TextField("替换文本...", text: $snippet.replacement, axis: .vertical)
                                            .textFieldStyle(.roundedBorder)
                                            .lineLimit(1...4)
                                    }
                                    .padding(.horizontal)
                                }

                                if settings.settings.snippetsList.isEmpty {
                                    Text("还没有片段 - 添加一个片段，然后在任何应用程序中键入其触发器。")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .padding(.horizontal)
                                        .padding(.bottom, 6)
                                }
                            }
                        }
                    }
                }
                .modifier(SettingsContainerModifier())
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear { historyCount = ClipboardManager.shared.recentItems.count }
    }
}

struct MirrorSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Mirror")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "启用镜像小工具",
                        description: "Show the live camera feed widget in the notch widget strip.",
                        isOn: $settings.settings.mirrorWidgetEnabled
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "点击打开镜像",
                        description: "Clicking the mirror widget expands into the full camera view.",
                        isOn: $settings.settings.mirrorOpenOnClick
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "水平翻转",
                        description: "Mirror the camera feed horizontally for a natural selfie view.",
                        isOn: $settings.settings.mirrorFlipHorizontally
                    )

                    Divider().padding(.leading, 20)

                    HStack {
                        Text("相机旋转")
                        Spacer()
                        Picker("", selection: $settings.settings.mirrorRotationMode) {
                            ForEach(MirrorRotationMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 130)
                    }
                    .padding()

                    Text("自动匹配相机报告的方向。如果外部摄像头画面显示为旋转，请选择固定角度以使其直立显示。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                }
                .modifier(SettingsContainerModifier())
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct CaffeineSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Caffeinate")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "在 Notch Bar 中显示咖啡因",
                        description: "Add a caffeinate toggle to the expanded notch header. Turning this off also stops caffeinate from turning on by itself for tasks, apps, power or displays.",
                        isOn: $settings.settings.caffeinateEnabled
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "防止翻盖模式下的睡眠",
                        description: "Keep your Mac awake while Sapphire's caffeinate mode is active, even with the lid closed.",
                        isOn: $settings.settings.sleepInClamshell
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "翻盖后保持启用咖啡因",
                        description: "Continue preventing sleep after leaving clamshell mode instead of turning caffeinate off automatically.",
                        isOn: $settings.settings.persistentCaffeinateAfterClamshell
                    )

                    Divider().padding(.leading, 20)

                    HStack {
                        Text("自动关闭超时")
                        Spacer()
                        Picker("", selection: $settings.settings.caffeinateTimeoutMinutes) {
                            Text("Never").tag(0.0)
                            Text("15分钟").tag(15.0)
                            Text("30分钟").tag(30.0)
                            Text("1小时").tag(60.0)
                            Text("2小时").tag(120.0)
                            Text("4小时").tag(240.0)
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                    .padding()

                    Text("在选定的持续时间后自动关闭咖啡因。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
                .modifier(SettingsContainerModifier())

                CaffeineAutoTaskSettingsView()

                KeepAwakeTriggerSettingsView()

                LidAngleCaffeineSettingsView()
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct WidgetsSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    private var enabledWidgetCount: Int {
        settings.settings.enabledWidgetTypes.count
    }

    var body: some View {
        let lockedWidgetTypes = Set(WidgetType.allCases.filter { type in
            type.requiredPremiumFeature
                .map { !subscriptionManager.hasAccess(to: $0) } ?? false
        })

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Widgets").font(.largeTitle.bold()).padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    Text("行为").font(.headline).padding([.top, .horizontal])
                    ToggleRow(
                        title: "记住上次打开的菜单",
                        description: "When re-opening the notch, it will return to the last menu you had open.",
                        isOn: $settings.settings.rememberLastMenu
                    )
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "隐藏音乐小部件", description: "Hide music widget if no media is playing", isOn: $settings.settings.hideMusicWidgetWhenNotPlaying)
                    ToggleRow(title: "隐藏暂停的 Spotify 歌曲", description: "Hide the music widget when Spotify is paused and no other system media is playing", isOn: $settings.settings.hideMusicWidgetWhenSpotifyPausedAndIdle)
                    ToggleRow(title: "应用程序关闭时隐藏 Spotify", description: "For logged-in Spotify accounts, hide the music widget when Spotify is not running on this Mac and Spotify is the only media source.", isOn: $settings.settings.hideSpotifyWidgetWhenAppClosed)
                    ToggleRow(title: "坚持音乐小部件", description: "Keep the music widget visible with the last track even when playback is paused or stopped", isOn: $settings.settings.persistMusicWidgetWhenPaused)
                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("Appearance").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "显示小部件之间的分隔线", description: "Display a subtle line separating each widget.", isOn: $settings.settings.showDividersBetweenWidgets)
                    ToggleRow(
                        title: "忽略小部件空间限制",
                        description: "Allow any widget to be enabled even when Sapphire estimates there is not enough notch space.",
                        isOn: $settings.settings.bypassWidgetSpaceLimit
                    )
                }
                .modifier(SettingsContainerModifier())

                if settings.settings.shopifyWidgetEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Shopify Orders").font(.headline).padding([.horizontal, .top])
                        Text("连接具有 read_orders 访问权限的 Shopify 自定义应用。管理 API 令牌存储在 macOS 钥匙串中。").font(.caption).foregroundColor(.secondary).padding(.horizontal)
                        TextField("商店域名 (example.myshopify.com)", text: Binding(get: { APIKeyManager.shared.shopifyStoreDomain }, set: { APIKeyManager.shared.shopifyStoreDomain = $0 })).textFieldStyle(.roundedBorder).padding(.horizontal)
                        SecureField("管理 API 访问令牌", text: Binding(get: { APIKeyManager.shared.shopifyAdminToken }, set: { APIKeyManager.shared.shopifyAdminToken = $0 })).textFieldStyle(.roundedBorder).padding(.horizontal)
                        Text("在 Shopify 管理员 → 设置 → 应用程序和销售渠道 → 开发应用程序中创建它，并具有 read_orders 权限。").font(.caption2).foregroundColor(.secondary).padding(.horizontal).padding(.bottom)
                    }
                    .modifier(SettingsContainerModifier())
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("小部件可见性和顺序").font(.headline).padding([.horizontal, .top])
                    Text("启用、禁用和重新排序出现在凹口中的小部件。空间受到显示宽度的限制。")
                        .font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 5)
                    ReorderableVStack(items: $settings.settings.widgetOrder) { widget in
                        if widget != .agent {
                            WidgetRowView(
                                widgetType: widget,
                                enabledWidgetCount: enabledWidgetCount,
                                isPremiumLocked: lockedWidgetTypes.contains(widget)
                            )
                        }
                    }
                    .modifier(SettingsContainerModifier())
                }
            }
            .padding(25)
        }
    }
}

struct LiveActivitiesSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var availableSensors: [any Sensor_p] = []

    private enum PersistentActivitySelection: String, CaseIterable, Identifiable {
        case none = "None"
        case stats = "Stats"
        case battery = "Battery"
        case weather = "Weather"
        var id: String { self.rawValue }
    }

    private var currentPersistentActivity: PersistentActivitySelection {
        if settings.settings.showPersistentStatsLiveActivity {
            return .stats
        } else if settings.settings.showPersistentBatteryLiveActivity {
            return .battery
        } else if settings.settings.showPersistentWeatherLiveActivity {
            return .weather
        } else {
            return .none
        }
    }

    private var persistentActivityBinding: Binding<PersistentActivitySelection> {
        Binding(
            get: { currentPersistentActivity },
            set: { newValue in
                guard currentPersistentActivity != newValue else { return }
                var updated = settings.settings.value
                updated.showPersistentStatsLiveActivity = (newValue == .stats)
                updated.showPersistentBatteryLiveActivity = (newValue == .battery)
                updated.showPersistentWeatherLiveActivity = (newValue == .weather)
                settings.settings.value = updated
            }
        )
    }

    private func binding(for statType: StatType) -> Binding<StatThreshold> {
        return Binding(
            get: { settings.settings.statThresholds[statType, default: StatThreshold()] },
            set: { settings.settings.statThresholds[statType] = $0 }
        )
    }

    var body: some View {
        let lockedActivityTypes = Set(LiveActivityType.allCases.filter { type in
            type.requiredPremiumFeature
                .map { !subscriptionManager.hasAccess(to: $0) } ?? false
        })

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Live Activities").font(.largeTitle.bold()).padding(.bottom)
                VStack(alignment: .leading, spacing: 0) {
                    Text("一般行为").font(.headline).padding([.top, .horizontal])
                    ToggleRow(
                          title: "显示紧凑焦点实时活动文本",
                          description: "Instead of showing the full focus name, only on/off.",
                          isOn: Binding(
                              get: { settings.settings.focusDisplayMode == .compact },
                              set: { settings.settings.focusDisplayMode = $0 ? .compact : .full }
                          )
                      )

                    ToggleRow(
                          title: "显示紧凑型电池实时活动",
                          description: "Instead of showing the full state, only show icon.",
                          isOn: Binding(
                            get: { settings.settings.batteryNotificationStyle == .compact },
                            set: { settings.settings.batteryNotificationStyle = $0 ? .compact : .default }
                          )
                      )
                    ToggleRow(title: "滑动即可关闭", description: "Swipe down on a live activity to dismiss it.", isOn: $settings.settings.swipeToDismissLiveActivity)
                    Divider().padding(.leading, 20)
                    ToggleRow(
                        title: "当源应用程序处于活动状态时隐藏",
                        description: "Automatically hide the music live activity when Spotify or Music is the frontmost app.",
                        isOn: $settings.settings.hideLiveActivityWhenSourceActive
                    )
                    Divider().padding(.leading, 20)
                    ToggleRow(
                        title: "保持悬停时的短暂活动紧凑",
                        description: "Do not expand the notch from hover while a transient live activity is showing. Persistent activities, Music, Weather, Stats, and Developer Activity are exempt.",
                        isOn: $settings.settings.suppressHoverExpansionForTransientLiveActivities
                    )
                    Divider().padding(.leading, 20)
                    ToggleRow(
                        title: "显示缺口旁边的其他活动",
                        description: "When more than one live activity is running, the ones after the first appear as small bubbles next to the notch, like the Dynamic Island. Click a bubble to open it.",
                        isOn: $settings.settings.showLiveActivitySatellites
                    )
                    if settings.settings.showLiveActivitySatellites {
                        Divider().padding(.leading, 20)
                        HStack {
                            SettingsRowLabel(
                                title: "缺口旁边的活动",
                                description: "The most bubbles that show at once. The first two sit on either side of the notch; more line up further out."
                            )
                            Spacer()
                            Stepper(value: $settings.settings.liveActivitySatelliteLimit, in: 1...5) {
                                Text("\(settings.settings.liveActivitySatelliteLimit)")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            }
                        }
                        .padding()
                    }

                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("持续活动").font(.headline).padding([.top, .horizontal])

                    InfoContainer(
                        text: "Choose one activity to be displayed persistently when no other higher-priority activity is active.",
                        iconName: "pin.circle.fill",
                        color: .blue
                    ).padding()

                    HStack {
                        Text("持续活动")
                        Spacer()
                        Picker("持续活动", selection: persistentActivityBinding) {
                            ForEach(PersistentActivitySelection.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .labelsHidden()
                    }
                    .padding()

                    if currentPersistentActivity == .stats && !settings.settings.statsLiveActivityEnabled {
                        InfoContainer(text: "Enable the 'Stats' live activity below to select it as persistent.", iconName: "info.circle", color: .yellow)
                            .padding([.horizontal, .bottom])
                    } else if currentPersistentActivity == .weather && !settings.settings.weatherLiveActivityEnabled {
                        InfoContainer(text: "Enable the 'Weather' live activity below to select it as persistent.", iconName: "info.circle", color: .yellow)
                            .padding([.horizontal, .bottom])
                    } else if currentPersistentActivity == .battery && !settings.settings.batteryLiveActivityEnabled {
                        InfoContainer(text: "Enable the 'Weather' live activity below to select it as persistent.", iconName: "info.circle", color: .yellow)
                            .padding([.horizontal, .bottom])
                    }

                    Divider().padding(.leading, 20)

                    HStack {
                        Text("天气实时活动弹出间隔")
                        Spacer()
                        Picker("", selection: $settings.settings.weatherLiveActivityInterval) {
                            Text("5分钟").tag(5); Text("10分钟").tag(10); Text("15分钟").tag(15); Text("30分钟").tag(30)
                        }.labelsHidden()
                    }
                    .padding()
                    .disabled(currentPersistentActivity == .weather)
                    .opacity(currentPersistentActivity == .weather ? 0.5 : 1.0)
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: currentPersistentActivity)

                if settings.settings.statsLiveActivityEnabled {
                    SensorSelectionView(
                        selectedStats: $settings.settings.selectedStats,
                        selectedSensorKeys: $settings.settings.selectedSensorKeys,
                        allSensors: availableSensors
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $settings.settings.statsLiveActivityThresholdEnabled) {
                            Text("仅在使用率较高时显示")
                                .font(.headline)
                        }
                        .padding()
                        .toggleStyle(.switch)

                        if settings.settings.statsLiveActivityThresholdEnabled {
                            VStack(alignment: .leading, spacing: 15) {
                                StatThresholdRow(label: "CPU", threshold: binding(for: .cpu))
                                StatThresholdRow(label: "RAM", threshold: binding(for: .ram))
                                StatThresholdRow(label: "GPU", threshold: binding(for: .gpu))
                            }
                            .padding()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .modifier(SettingsContainerModifier())
                    .animation(.easeInOut, value: settings.settings.statsLiveActivityThresholdEnabled)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("活动可见性和顺序").font(.headline).padding([.horizontal, .top])
                    Text("Enable, disable, and reorder all available Live Activities.").font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 5)
                    if settings.settings.statsLiveActivityEnabled {
                        InfoContainer(text: "Enabling stats will increase the app's cpu and power consumption.", iconName: "info.circle", color: .yellow)
                    }
                    ReorderableVStack(items: $settings.settings.liveActivityOrder) { activity in
                        LiveActivityRowView(
                            activityType: activity,
                            isPremiumLocked: lockedActivityTypes.contains(activity)
                        )
                    }
                    .modifier(SettingsContainerModifier())
                }
                .onChange(of: settings.settings.eyeBreakLiveActivityEnabled) {
                    EyeBreakManager.shared.dismissBreak()
                }

                RequiredPermissionsView(section: .liveActivities)
            }
            .padding(25)
            .animation(.default, value: settings.settings.statsLiveActivityEnabled)
        }
        .onAppear {
            availableSensors = StatsManager.shared.allSensors
            StatsManager.shared.requestSensorCatalog()
        }
        .onReceive(StatsManager.shared.$allSensors.dropFirst()) { catalog in
            availableSensors = catalog
        }
        .onDisappear {
            availableSensors = []
        }
    }
}

struct StatThresholdRow: View {
    let label: String
    @Binding var threshold: StatThreshold

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $threshold.isEnabled) {
                Text(label)
            }
            .toggleStyle(.switch)

            if threshold.isEnabled {
                HStack {
                    Text("阈值")
                        .foregroundColor(.secondary)
                    Spacer()
                    Stepper(
                        "\(threshold.value)%",
                        value: $threshold.value,
                        in: 1...100,
                        step: 5
                    )
                }
                .padding(.leading, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: threshold.isEnabled)
    }
}

fileprivate struct SensorSelectionView: View {
    @Binding var selectedStats: [StatType]
    @Binding var selectedSensorKeys: [String]
    let allSensors: [any Sensor_p]

    private var groupedSensors: [SensorGroup: [any Sensor_p]] {
        Dictionary(grouping: allSensors, by: { $0.group })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("统计配置").font(.headline).padding([.top, .horizontal])

            DisclosureGroup("Select high-level stats") {
                VStack(spacing: 0) {
                    ForEach(StatType.allCases) { statType in
                        Toggle(statType.displayName, isOn: Binding<Bool>(
                            get: { selectedStats.contains(statType) },
                            set: { isSelected in
                                if isSelected {
                                    if !selectedStats.contains(statType) {
                                        selectedStats.append(statType)
                                    }
                                } else {
                                    selectedStats.removeAll { $0 == statType }
                                }
                            }
                        ))
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 10)
            }
            .padding()

            Divider().padding(.horizontal)

            DisclosureGroup("Select individual sensors") {
                if allSensors.isEmpty {
                    VStack {
                        ProgressView()
                        Text("正在加载传感器...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(SensorGroup.allCases, id: \.self) { group in
                            if let groupSensors = groupedSensors[group], !groupSensors.isEmpty {
                                Section(header: Text(group.rawValue).font(.headline)) {
                                    ForEach(groupSensors, id: \.key) { sensor in
                                        Toggle(sensor.name, isOn: Binding<Bool>(
                                            get: { selectedSensorKeys.contains(sensor.key) },
                                            set: { isSelected in
                                                if isSelected {
                                                    if !selectedSensorKeys.contains(sensor.key) {
                                                        selectedSensorKeys.append(sensor.key)
                                                    }
                                                } else {
                                                    selectedSensorKeys.removeAll { $0 == sensor.key }
                                                }
                                            }
                                        ))
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .frame(height: 300)
                }
            }
            .padding()
        }
        .modifier(SettingsContainerModifier())
    }
}

struct ShortcutsSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @StateObject private var fetcher = ShortcutsFetcher()
    @State private var searchText: String = ""

    private var filteredAvailableShortcuts: [ShortcutInfo] {
        let selectedIDs = Set(settings.settings.selectedShortcuts.map { $0.id })
        let available = fetcher.allShortcuts.filter { !selectedIDs.contains($0.id) }

        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return available
        }

        return available.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("快捷方式小部件")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 10) {
                    Text("添加到小部件")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack {
                        if settings.settings.selectedShortcuts.isEmpty {
                            Text("没有添加快捷方式。")
                                .font(.caption).foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                        } else {
                            let rowHeight: CGFloat = 44
                            List {
                                ForEach($settings.settings.selectedShortcuts) { $shortcut in
                                    AddedShortcutRow(shortcut: $shortcut, onRemove: {
                                        removeShortcut(shortcut)
                                    })
                                }
                                .listRowBackground(Color.clear)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .frame(height: CGFloat(settings.settings.selectedShortcuts.count) * rowHeight)
                        }
                    }
                }
                .padding(.vertical)
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 10) {
                    Text("可用的快捷键")
                        .font(.headline).padding(.horizontal)

                    TextField("搜索快捷方式", text: $searchText)
                        .textFieldStyle(.plain).padding(8)
                        .background(Color.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)

                    if fetcher.isLoading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = fetcher.accessError {
                         InfoContainer(text: error, iconName: "exclamationmark.triangle.fill", color: .yellow)
                            .padding(.horizontal)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if filteredAvailableShortcuts.isEmpty {
                                    Text(searchText.isEmpty ? "No shortcuts found." : "No shortcuts match your search.")
                                        .font(.caption).foregroundColor(.secondary).padding()
                                } else {
                                    ForEach(filteredAvailableShortcuts) { shortcut in
                                        AvailableShortcutRow(shortcut: shortcut, onAdd: { addShortcut(shortcut) })
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 350)
                    }
                }
                .padding(.vertical)
                .modifier(SettingsContainerModifier())
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear(perform: fetcher.fetchAllShortcuts)
            .onDisappear {
                fetcher.releaseLoadedShortcuts()
            }
        }
    }

    private func addShortcut(_ shortcut: ShortcutInfo) {
        if !settings.settings.selectedShortcuts.contains(where: { $0.id == shortcut.id }) {
            settings.settings.selectedShortcuts.append(shortcut)
        }
    }

    private func removeShortcut(_ shortcutToRemove: ShortcutInfo) {
        settings.settings.selectedShortcuts.removeAll { $0.id == shortcutToRemove.id }
    }
}

fileprivate struct AddedShortcutRow: View {
    @Binding var shortcut: ShortcutInfo
    let onRemove: () -> Void
    @State private var isShowingEditor = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { isShowingEditor = true }) {
                Image(nsImage: ShortcutsManager.shared.getIcon(for: shortcut))
                    .resizable().frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .id(shortcut)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isShowingEditor, arrowEdge: .leading) {
                ShortcutEditorView(shortcut: $shortcut)
            }

            Text(shortcut.name)
            Spacer()

            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}

fileprivate struct AvailableShortcutRow: View {
    let shortcut: ShortcutInfo
    let onAdd: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                Image(nsImage: ShortcutsManager.shared.getIcon(for: shortcut))
                    .resizable().frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text(shortcut.name)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isEnabled ? .green.opacity(0.8) : .secondary)
            }
        }
        .buttonStyle(.plain)
        .padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}

fileprivate struct ShortcutEditorView: View {
    @Binding var shortcut: ShortcutInfo
    @State private var isShowingIconPicker = false

    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: { shortcut.backgroundColor?.color ?? .gray },
            set: { shortcut.backgroundColor = CodableColor(color: $0) }
        )
    }

    private var iconColorBinding: Binding<Color> {
        Binding(
            get: { shortcut.iconColor?.color ?? .white },
            set: { shortcut.iconColor = CodableColor(color: $0) }
        )
    }

    var body: some View {
        VStack(spacing: 15) {
            Text("编辑快捷方式")
                .font(.headline)

            Image(nsImage: ShortcutsManager.shared.getIcon(for: shortcut))
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(spacing: 10) {
                ColorPicker("Background Color", selection: backgroundColorBinding, supportsOpacity: false)
                ColorPicker("Icon Color", selection: iconColorBinding, supportsOpacity: false)

                Button("更改图标") {
                    isShowingIconPicker = true
                }
            }
        }
        .padding()
        .frame(width: 250)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $isShowingIconPicker) {
            IconPickerView { selectedSymbol in
                shortcut.systemImageName = selectedSymbol
            }
        }
    }
}

fileprivate struct IconPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var isSearchVisible = false

    struct IconSection: Identifiable {
        let id = UUID()
        let title: String
        let symbols: [String]
    }

    static let iconSections: [IconSection] = [
        IconSection(title: "接口与通用", symbols: [
            "house.fill", "house", "gearshape.fill", "gearshape", "gearshape.2.fill", "gearshape.2",
            "slider.horizontal.3", "slider.vertical.3", "ellipsis", "ellipsis.circle.fill", "ellipsis.circle",
            "plus", "plus.circle.fill", "plus.circle", "minus", "minus.circle.fill", "minus.circle",
            "xmark", "xmark.circle.fill", "xmark.circle", "checkmark", "checkmark.circle.fill", "checkmark.circle",
            "questionmark.circle.fill", "questionmark.circle", "info.circle.fill", "info.circle",
            "magnifyingglass", "link", "link.circle.fill", "link.circle", "lock.fill", "lock.open.fill",
            "key.fill", "key", "bell.fill", "bell", "bell.slash.fill", "bell.slash",
            "lightbulb.fill", "lightbulb", "flag.fill", "flag", "bookmark.fill", "bookmark",
            "tag.fill", "tag", "pin.fill", "pin", "archivebox.fill", "archivebox",
            "square.and.arrow.up", "square.and.arrow.down", "arrow.clockwise", "arrow.counterclockwise",
            "gobackward", "goforward", "eject.fill", "eject", "power", "power.circle.fill", "power.circle",
            "app.fill", "app", "window.vertical.closed", "macwindow", "sidebar.left", "sidebar.right",
            "dock.rectangle", "ruler.fill", "ruler", "screwdriver.fill", "screwdriver", "hammer.fill", "hammer",
            "wrench.and.screwdriver.fill", "wrench.and.screwdriver", "eyedropper", "eyedropper.halffull",
            "paintpalette.fill", "paintpalette", "crop", "rotate.right.fill", "rotate.left.fill",
            "sparkle", "sparkles", "star.fill", "star", "heart.fill", "heart",
            "eye.fill", "eye", "eye.slash.fill", "eye.slash", "viewfinder",
            "camera.macro.circle.fill", "camera.macro.circle", "camera.macro",
            "trash.fill", "trash", "square.grid.2x2.fill", "square.grid.2x2", "list.bullet", "list.number",
            "list.dash", "list.clipboard.fill", "list.clipboard"
        ]),

        IconSection(title: "文件和文件", symbols: [
            "folder.fill", "folder", "folder.circle.fill", "folder.circle", "folder.badge.plus",
            "folder.badge.minus", "folder.badge.person.crop", "folder.badge.questionmark",
            "doc.fill", "doc", "doc.text.fill", "doc.text", "doc.plaintext.fill", "doc.plaintext",
            "doc.richtext.fill", "doc.richtext", "doc.on.doc.fill", "doc.on.doc",
            "doc.on.clipboard.fill", "doc.on.clipboard", "doc.badge.plus", "doc.badge.gearshape.fill",
            "doc.badge.gearshape", "doc.badge.clock.fill", "doc.badge.clock",
            "doc.badge.ellipsis",
            "archivebox.fill", "archivebox", "paperclip", "note.text",
            "note.text.badge.plus", "newspaper.fill", "newspaper", "book.fill", "book", "books.vertical.fill",
            "books.vertical", "scroll.fill", "scroll", "receipt.fill", "receipt",
            "list.bullet.rectangle.portrait.fill", "list.bullet.rectangle.portrait", "text.magnifyingglass",
            "signature", "square.and.pencil", "square.and.pencil.circle.fill", "square.and.pencil.circle",
            "photo.stack.fill", "photo.stack", "square.stack.3d.up.fill", "square.stack.3d.up",
            "square.stack.3d.down.right.fill", "square.stack.3d.down.right",
            "square.stack.3d.up.slash.fill", "square.stack.3d.up.slash",
            "doc.questionmark", "doc.questionmark.fill", "doc.append", "doc.fill.badge.plus",
            "doc.text.image.fill", "doc.text.image", "doc.badge.arrow.up.fill", "doc.badge.arrow.up"
        ]),

        IconSection(title: "文本与编辑", symbols: [
            "pencil", "pencil.circle", "pencil.circle.fill", "eraser.fill", "eraser", "highlighter", "scissors",
            "textformat", "textformat.size", "textformat.abc", "textformat.123",
            "bold", "italic", "underline", "strikethrough", "paragraphsign",
            "text.alignleft", "text.aligncenter", "text.alignright", "text.justify",
            "increase.indent", "decrease.indent", "list.bullet.indent", "quotelevel", "text.bubble.fill",
            "text.bubble", "return", "line.diagonal", "curlybraces",
            "point.topleft.down.curvedto.point.bottomright.up.fill",
            "a.circle.fill", "a.circle", "b.circle.fill", "b.circle", "c.circle.fill", "c.circle",
            "d.circle.fill", "d.circle", "e.circle.fill", "e.circle", "f.circle.fill", "f.circle",
            "g.circle.fill", "g.circle", "h.circle.fill", "h.circle", "i.circle.fill", "i.circle",
            "j.circle.fill", "j.circle", "k.circle.fill", "k.circle", "l.circle.fill", "l.circle",
            "m.circle.fill", "m.circle", "n.circle.fill", "n.circle", "o.circle.fill", "o.circle",
            "p.circle.fill", "p.circle", "q.circle.fill", "q.circle", "r.circle.fill", "r.circle",
            "s.circle.fill", "s.circle", "t.circle.fill", "t.circle", "u.circle.fill", "u.circle",
            "v.circle.fill", "v.circle", "w.circle.fill", "w.circle", "x.circle.fill", "x.circle",
            "y.circle.fill", "y.circle", "z.circle.fill", "z.circle",
            "0.circle.fill", "0.circle", "1.circle.fill", "1.circle", "2.circle.fill", "2.circle",
            "3.circle.fill", "3.circle", "4.circle.fill", "4.circle", "5.circle.fill", "5.circle",
            "6.circle.fill", "6.circle", "7.circle.fill", "7.circle", "8.circle.fill", "8.circle",
            "9.circle.fill", "9.circle",
            "number", "at", "textformat.alt",
            "asterisk", "questionmark", "exclamationmark", "percent",
            "plusminus", "divide", "equal", "dollarsign", "eurosign", "yensign", "coloncurrencysign",
            "bitcoinsign", "point.3.connected.trianglepath.dotted"
        ]),

        IconSection(title: "媒体与音频", symbols: [
            "play.fill", "play", "pause.fill", "pause", "stop.fill", "stop", "record.circle.fill", "record.circle",
            "forward.fill", "forward", "backward.fill", "backward",
            "gobackward.10", "goforward.10", "gobackward.15", "goforward.15", "gobackward.30", "goforward.30",
            "gobackward.45", "goforward.45", "gobackward.60", "goforward.60", "gobackward.75", "goforward.75",
            "gobackward.90", "goforward.90",
            "shuffle", "repeat", "repeat.1", "music.note", "music.note.list", "mic.fill", "mic",
            "mic.slash.fill", "mic.slash", "speaker.wave.3.fill", "speaker.wave.3", "speaker.slash.fill",
            "speaker.slash", "hifispeaker.fill", "hifispeaker", "waveform", "waveform.path", "waveform.path.ecg",
            "waveform.path.ecg.rectangle.fill", "waveform.path.ecg.rectangle", "earpods", "headphones",
            "airpods.chargingcase",
            "airpods", "airpodsmax", "hifispeaker.and.homepodmini.fill",
            "photo.fill", "photo", "camera.fill", "camera", "video.fill", "video", "film.fill", "film",
            "photo.on.rectangle.angled.fill", "photo.on.rectangle.angled",
            "video.badge.plus", "video.badge.waveform.fill", "video.badge.waveform", "airplayvideo", "airplayaudio",
            "captions.bubble.fill", "captions.bubble", "tv.fill", "tv", "tv.and.hifispeaker.fill",
            "opticaldisc.fill", "opticaldisc", "amplifier",
            "metronome.fill", "metronome", "guitars.fill", "guitars", "tuningfork", "square.and.arrow.up.trianglebadge.exclamationmark",
            "music.mic",
            "play.rectangle.fill", "play.rectangle"
        ]),

        IconSection(title: "时间和日期", symbols: [
            "clock.fill", "clock", "alarm.fill", "alarm", "timer", "stopwatch.fill", "stopwatch",
            "calendar", "calendar.circle.fill", "calendar.circle", "calendar.badge.plus",
            "calendar.badge.clock", "hourglass", "hourglass.tophalf.fill", "hourglass.bottomhalf.fill",
            "sunrise.fill", "sunrise", "sunset.fill", "sunset", "moon.stars.fill", "moon.stars",
            "moon.fill", "moon", "timelapse", "rays", "deskclock.fill", "deskclock"
        ]),

        IconSection(title: "连接与设备", symbols: [
            "wifi", "wifi.slash", "dot.radiowaves.left.and.right", "network", "globe", "globe.americas.fill",
            "globe.europe.africa.fill", "personalhotspot", "antenna.radiowaves.left.and.right",
            "wave.3.right.circle.fill",
            "bolt.fill", "bolt", "bolt.slash.fill", "bolt.slash", "battery.100",
            "battery.25", "battery.0", "battery.100.bolt",
            "bolt.batteryblock.fill", "bolt.batteryblock",
            "iphone", "iphone.landscape", "ipad", "ipad.landscape",
            "applewatch", "applewatch.radiowaves.left.and.right", "applewatch.slash",
            "applewatch.side.right", "macbook", "macbook.gen1", "desktopcomputer",
            "display", "tv.fill", "tv", "keyboard.fill", "keyboard", "magicmouse.fill", "computermouse.fill",
            "computermouse", "printer.fill", "printer", "externaldrive.fill", "externaldrive",
            "externaldrive.fill.badge.plus", "externaldrive.fill.badge.minus",
            "externaldrive.fill.badge.checkmark", "externaldrive.connected.to.line.below",
            "airtag.fill", "airtag", "ipodtouch.landscape", "ipodtouch", "ipod",
            "applepencil", "homepod.fill", "homepod", "homepodmini.fill", "homepodmini", "appletv.fill",
            "airpods.chargingcase.fill", "airpods.chargingcase", "airpods.chargingcase.wireless.fill",
            "airpods.chargingcase.wireless", "bonjour",
            "apple.terminal.fill", "apple.terminal", "laptopcomputer.and.arrow.down",
            "laptopcomputer"
        ]),

        IconSection(title: "通讯", symbols: [
            "envelope.fill", "envelope", "envelope.open.fill", "envelope.open", "tray.fill", "tray",
            "tray.and.arrow.up.fill", "tray.and.arrow.up", "tray.and.arrow.down.fill", "tray.and.arrow.down",
            "paperplane.fill", "paperplane", "message.fill", "message", "bubble.left.fill", "bubble.left",
            "bubble.right.fill", "bubble.right", "bubble.left.and.bubble.right.fill",
            "bubble.left.and.bubble.right", "phone.fill", "phone", "phone.fill.badge.plus", "phone.badge.plus",
            "phone.down.fill", "phone.down.circle.fill",
            "video.fill", "video", "video.badge.plus", "video.badge.waveform.fill", "video.badge.waveform",
            "airplayvideo", "airplayaudio", "mic.circle.fill", "mic.circle",
            "arrowshape.turn.up.left.fill", "arrowshape.turn.up.left",
            "arrowshape.turn.up.left.2.fill", "arrowshape.turn.up.left.2",
            "arrowshape.turn.up.right.fill", "arrowshape.turn.up.right",
            "bell.badge.fill", "bell.badge", "hand.raised.square.fill", "hand.raised.square",
            "phone.arrow.up.right.fill", "phone.arrow.up.right", "phone.arrow.down.left.fill", "phone.arrow.down.left"
        ]),

        IconSection(title: "人员与账户", symbols: [
            "person.fill", "person", "person.circle.fill", "person.circle", "person.badge.plus.fill",
            "person.badge.plus", "person.badge.minus.fill", "person.badge.minus",
            "person.crop.circle.fill", "person.crop.circle", "person.crop.circle.badge.plus.fill",
            "person.crop.circle.badge.plus", "person.crop.circle.badge.minus.fill",
            "person.crop.circle.badge.minus", "person.2.fill", "person.2", "person.3.fill", "person.3",
            "figure.walk", "figure.run", "figure.dance", "hand.raised.fill", "hand.raised",
            "hand.thumbsup.fill", "hand.thumbsup", "hand.thumbsdown.fill", "hand.thumbsdown",
            "face.smiling.fill", "face.smiling", "face.dashed.fill", "face.dashed",
            "person.fill.checkmark", "person.crop.circle.badge.checkmark",
            "person.fill.xmark", "person.crop.circle.badge.xmark",
            "person.text.rectangle.fill", "person.text.rectangle", "person.badge.key.fill", "person.badge.key",
            "person.crop.square.fill", "person.crop.square", "person.crop.rectangle.fill", "person.crop.rectangle",
            "figure.seated.side", "figure.stairs", "figure.disc.sports", "figure.baseball", "figure.tennis",
            "figure.basketball", "figure.soccer", "figure.pool.swim", "figure.golf", "figure.climbing",
            "person.and.background.dotted", "person.wave.2.fill", "person.wave.2"
        ]),

        IconSection(title: "健康与保健", symbols: [
            "heart.fill", "heart", "heart.circle.fill", "heart.circle", "heart.text.square.fill",
            "staroflife.fill", "staroflife", "cross.case.fill", "cross.case", "pills.fill", "pills",
            "bandage.fill", "bandage", "lungs.fill", "lungs", "brain.head.profile", "brain",
            "waveform.path.ecg.rectangle.fill", "waveform.path.ecg.rectangle", "drop.fill", "drop",
            "thermometer",
            "stethoscope",
            "bed.double.fill", "bed.double", "figure.walk.circle.fill", "figure.walk.circle",
            "figure.strengthtraining.traditional", "figure.yoga", "figure.cooldown",
            "figure.highintensity.intervaltraining", "figure.socialdance",
            "figure.flexibility", "figure.mind.and.body", "figure.cross.training", "figure.barre",
            "figure.stairs", "allergens.fill", "allergens", "thermometer.snowflake",
            "syringe.fill", "syringe", "medical.thermometer.fill", "medical.thermometer"
        ]),

        IconSection(title: "天气与环境", symbols: [
            "sun.max.fill", "sun.max", "moon.fill", "moon", "cloud.fill", "cloud", "cloud.sun.fill",
            "cloud.sun", "cloud.rain.fill", "cloud.rain", "cloud.bolt.fill", "cloud.bolt",
            "cloud.bolt.rain.fill", "cloud.bolt.rain", "cloud.snow.fill", "cloud.snow", "cloud.fog.fill",
            "cloud.fog", "tornado", "hurricane", "wind", "wind.circle.fill", "wind.circle",
            "snowflake", "thermometer.sun.fill", "thermometer.sun", "thermometer.snowflake",
            "tree.fill", "tree", "leaf.fill", "leaf", "flame.fill", "flame",
            "drop.fill", "drop", "water.waves",
            "mountain.2.fill", "mountain.2", "sun.haze.fill", "sun.haze", "moon.haze.fill", "moon.haze",
            "smoke.fill", "smoke", "sparkle", "star.leadinghalf.filled"
        ]),

        IconSection(title: "位置与导航", symbols: [
            "map.fill", "map", "mappin", "mappin.and.ellipse",
            "location.fill", "location", "location.circle.fill", "location.circle", "location.north.fill",
            "location.north", "location.north.line.fill", "location.north.line", "road.lanes",
            "road.lanes.curved.right", "road.lanes.curved.left", "car.fill", "car", "car.side",
            "bus.fill", "bus", "tram.fill", "tram", "train.side.front.car", "train.side.middle.car",
            "train.side.rear.car", "airplane", "airplane.departure", "airplane.arrival", "bicycle",
            "figure.walk", "ferry.fill", "ferry", "scooter", "truck.box.fill", "truck.box",
            "shippingbox.fill", "shippingbox", "fuelpump.fill", "fuelpump", "bus.doubledecker.fill",
            "bicycle.circle.fill", "bicycle.circle", "figure.walk.circle.fill", "figure.walk.circle",
            "car.front.waves.up.fill", "car.rear.waves.up.fill", "bolt.car.fill", "bus.doubledecker",
            "point.fill.topleft.down.curvedto.point.fill.bottomright.up",
            "compass.drawing", "parkingsign"
        ]),

        IconSection(title: "体育与游戏", symbols: [
            "gamecontroller.fill", "gamecontroller", "dpad.fill", "dpad", "dice.fill", "dice",
            "sportscourt.fill", "sportscourt", "trophy.fill", "trophy", "medal.fill", "medal",
            "figure.tennis", "figure.baseball", "figure.basketball", "figure.soccer", "figure.pool.swim",
            "figure.disc.sports", "figure.golf", "flag.checkered.2.crossed", "target", "scope",
            "circles.hexagongrid.fill", "circles.hexagongrid", "bell.badge.fill", "bell.badge"
        ]),

        IconSection(title: "无障碍", symbols: [
            "figure.walk.circle.fill", "figure.walk.circle", "figure.roll", "ear.and.waveform", "ear.fill",
            "hand.raised.fingers.spread.fill", "hand.raised.fingers.spread",
            "character.cursor.ibeam",
            "eye.fill", "eye.slash.fill", "mic.fill", "speaker.wave.3.fill", "square.text.square.fill",
            "square.text.square", "waveform.and.magnifyingglass", "questionmark.bubble.fill",
            "accessibility", "accessibility.fill"
        ]),

        IconSection(title: "形状与几何", symbols: [
            "circle.fill", "circle", "square.fill", "square", "triangle.fill", "triangle",
            "diamond.fill", "diamond", "octagon.fill", "octagon", "hexagon.fill", "hexagon",
            "capsule.fill", "capsule", "oval.fill", "oval", "cube.fill", "cube", "cylinder.fill", "cylinder",
            "cone.fill", "cone", "pyramid.fill", "pyramid", "gearshape.fill", "gearshape",
            "bell.fill", "bell", "lightbulb.fill", "lightbulb", "star.fill", "star", "heart.fill", "heart",
            "bolt.fill", "bolt", "drop.fill", "drop", "water.waves", "sparkle", "sparkles",
            "circle.grid.2x2.fill", "circle.grid.2x2", "rectangle.grid.2x2.fill", "rectangle.grid.2x2",
            "rectangle.grid.3x2.fill", "rectangle.grid.3x2", "square.on.square.dashed",
            "flowchart.fill", "flowchart", "circle.square.fill", "circle.square"
        ])
    ]

    private var filteredIconSections: [IconSection] {
        if searchText.isEmpty {
            return Self.iconSections
        }
        var filteredSections: [IconSection] = []
        let lowercasedSearchText = searchText.lowercased()
        for section in Self.iconSections {
            let matchingSymbols = section.symbols.filter { $0.lowercased().contains(lowercasedSearchText) }
            if !matchingSymbols.isEmpty {
                filteredSections.append(IconSection(title: section.title, symbols: matchingSymbols))
            }
        }
        return filteredSections
    }

    private let columns = [GridItem(.adaptive(minimum: 50))]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选择图标")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()

                Button(action: {
                    withAnimation(.spring()) {
                        isSearchVisible.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(isSearchVisible ? .accentColor : .white)
                        .padding(5)
                }
                .buttonStyle(.plain)

                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding(5)
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)

            if isSearchVisible {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("搜索图标...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                    if filteredIconSections.isEmpty {
                        Text("No icons found for \"\(searchText)\"")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(filteredIconSections) { section in
                            Text(section.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 5)

                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(section.symbols, id: \.self) { symbolName in
                                    Button(action: {
                                        onSelect(symbolName)
                                        dismiss()
                                    }) {
                                        Image(systemName: symbolName)
                                            .font(.system(size: 24, weight: .bold))
                                            .frame(width: 50, height: 50)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding()
            }

        }
        .frame(width: 350, height: 700)
        .background(Color(red: 0.18, green: 0.18, blue: 0.28))
    }
}

struct WeatherInfoSettingsView: View {
    @Binding var selectedInfo: [WeatherInfoType]

    var body: some View {
        SettingsMultiSelectList(
            title: "可见的天气信息",
            options: WeatherInfoType.selectableCases,
            selection: $selectedInfo,
            label: \.displayName
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

struct BatteryInfoSettingsView: View {
    @Binding var selectedInfo: [BatteryInfoType]

    var body: some View {
        SettingsMultiSelectList(
            title: "可见的电池信息",
            options: BatteryInfoType.allCases,
            selection: $selectedInfo,
            label: \.displayName
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

struct LockScreenSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @State private var notchsettingsHaveChanged: Bool = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Lock Screen")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    Text("壁纸").font(.headline).padding([.top, .horizontal])

                    ToggleRow(
                        title: "自定义锁屏壁纸",
                        description: "Show your own image or video behind the clock, sign-in controls, and Sapphire widgets on the lock screen.",
                        isOn: $settings.settings.lockScreenCustomWallpaperEnabled
                    )

                    if settings.settings.lockScreenCustomWallpaperEnabled {
                        Divider().padding(.leading, 20)

                        WallpaperFileRow(
                            path: $settings.settings.lockScreenCustomWallpaperPath,
                            panelTitle: "Choose Lock Screen Wallpaper",
                            panelMessage: "Select an image or video to show on your lock screen."
                        )

                        Divider().padding(.leading, 20)

                        ToggleRow(
                            title: "在桌面上使用",
                            description: "Also show the lock screen wallpaper (live video included) on your desktop, unless a separate desktop wallpaper is set below.",
                            isOn: $settings.settings.lockScreenKeepWallpaperAfterUnlock
                        )
                    }

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "定制桌面壁纸",
                        description: "Use your own image or video on the desktop. A video plays behind your desktop icons and pauses whenever the desktop is covered. The lock screen shows it too unless it has its own wallpaper.",
                        isOn: $settings.settings.desktopWallpaperEnabled
                    )

                    if settings.settings.desktopWallpaperEnabled {
                        Divider().padding(.leading, 20)

                        WallpaperFileRow(
                            path: $settings.settings.desktopWallpaperPath,
                            panelTitle: "Choose Desktop Wallpaper",
                            panelMessage: "Select an image or video to use as your desktop wallpaper."
                        )
                    }

                    if wallpaperConfiguration.desktopPath != nil || wallpaperConfiguration.lockScreenPath != nil {
                        Divider().padding(.leading, 20)

                        HStack {
                            SettingsRowLabel(
                                title: "缩放",
                                description: "How the wallpaper fits screens with a different shape.",
                                titleFont: .system(size: 14, weight: .medium)
                            )
                            Spacer()
                            Picker("缩放", selection: $settings.settings.liveWallpaperScaling) {
                                ForEach(WallpaperScaling.allCases) { scaling in
                                    Text(scaling.displayName).tag(scaling)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 160)
                        }
                        .padding()
                    }

                    if hasVideoWallpaper {
                        Divider().padding(.leading, 20)

                        HStack {
                            SettingsRowLabel(
                                title: "视频播放",
                                description: settings.settings.liveWallpaperPlaybackMode.description,
                                titleFont: .system(size: 14, weight: .medium)
                            )
                            Spacer()
                            Picker("视频播放", selection: $settings.settings.liveWallpaperPlaybackMode) {
                                ForEach(LiveWallpaperPlaybackMode.allCases) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 165)
                        }
                        .padding()

                        if settings.settings.liveWallpaperPlaybackMode == .adaptive {
                            Divider().padding(.leading, 20)

                            ToggleRow(
                                title: "在低功耗模式下暂停",
                                description: "Show the first frame instead of playing the video while Low Power Mode is on.",
                                isOn: $settings.settings.liveWallpaperPauseOnLowPower
                            )

                            Divider().padding(.leading, 20)

                            ToggleRow(
                                title: "暂停电池供电",
                                description: "Only play video wallpapers while your Mac is plugged in.",
                                isOn: $settings.settings.liveWallpaperPauseOnBattery
                            )
                        }
                    }

                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.lockScreenCustomWallpaperEnabled)
                .animation(.default, value: settings.settings.desktopWallpaperEnabled)
                .animation(.default, value: hasVideoWallpaper)
                .animation(.default, value: settings.settings.liveWallpaperPlaybackMode)

                ToggleRow(
                    title: "暂停时显示音乐",
                    description: "Keep showing the current track in lock screen widgets even when playback is paused.",
                    isOn: $settings.settings.lockScreenShowMusicWhenPaused
                )
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("热门信息小部件").font(.headline).padding([.top, .horizontal])

                    ToggleRow(
                        title: "显示信息小部件",
                        description: "Display small, informational widgets below the clock.",
                        isOn: $settings.settings.lockScreenShowInfoWidget
                    )

                    if settings.settings.lockScreenShowInfoWidget {
                        Divider().padding(.leading, 20)

                        ToggleRow(
                            title: "不活动时隐藏",
                            description: "Only show widgets like Music, Calendar, or Focus when they are active.",
                            isOn: $settings.settings.lockScreenHideInactiveInfoWidgets
                        )

                        Divider().padding(.leading, 20)

                        SettingsMultiSelectList(
                            title: "可见的小部件",
                            options: LockScreenWidgetType.selectableCases,
                            selection: $settings.settings.lockScreenWidgets,
                            label: \.displayName
                        )

                        if settings.settings.lockScreenWidgets.contains(.weather) {
                            Divider().padding(.horizontal)
                            WeatherInfoSettingsView(selectedInfo: $settings.settings.lockScreenWeatherInfo)
                        }

                        if settings.settings.lockScreenWidgets.contains(.battery) {
                            Divider().padding(.horizontal)
                            BatteryInfoSettingsView(selectedInfo: $settings.settings.lockScreenBatteryInfo)
                        }
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.lockScreenShowInfoWidget)
                .animation(.default, value: settings.settings.lockScreenWidgets.contains(.weather))
                .animation(.default, value: settings.settings.lockScreenWidgets.contains(.battery))

                VStack(alignment: .leading, spacing: 0) {
                    Text("主要小部件").font(.headline).padding([.top, .horizontal])

                    ToggleRow(
                        title: "显示主要小部件",
                        description: "Display larger, interactive widgets in the middle of the screen.",
                        isOn: $settings.settings.lockScreenShowMainWidget
                    )

                    if settings.settings.lockScreenShowMainWidget {
                        Divider().padding(.leading, 20)

                        SettingsMultiSelectList(
                            title: "可见的主要小部件",
                            options: LockScreenMainWidgetType.selectableCases,
                            selection: $settings.settings.lockScreenMainWidgets,
                            label: \.displayName
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.lockScreenShowMainWidget)

                VStack(alignment: .leading, spacing: 0) {
                    Text("迷你小部件").font(.headline).padding([.top, .horizontal])

                    ToggleRow(
                        title: "显示迷你小部件",
                        description: "Display compact widgets below the main widget area.",
                        isOn: $settings.settings.lockScreenShowMiniWidgets
                    )

                    if settings.settings.lockScreenShowMiniWidgets {
                        Divider().padding(.leading, 20)

                        SettingsMultiSelectList(
                            title: "可见的迷你小部件",
                            options: LockScreenMiniWidgetType.selectableCases,
                            selection: $settings.settings.lockScreenMiniWidgets,
                            label: \.displayName
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.lockScreenShowMiniWidgets)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Appearance").font(.headline).padding([.top, .horizontal])

                    ToggleRow(
                        title: "液体玻璃效果",
                        description: "Put the lock screen's widgets on native Liquid Glass.",
                        isOn: $settings.settings.lockScreenLiquidGlassLook
                    )

                    if settings.settings.lockScreenLiquidGlassLook {
                        Divider().padding(.leading, 20)
                        LiquidGlassOptionsEditor(options: $settings.settings.lockScreenGlass)
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.lockScreenLiquidGlassLook)

                VStack(alignment: .leading, spacing: 0) {
                    Text("缺口条").font(.headline).padding([.top, .horizontal])

                    ToggleRow(
                        title: "在锁定屏幕上显示凹口",
                        description: "Keep the Sapphire notch bar visible at the top of the lock screen.",
                        isOn: $settings.settings.lockScreenShowNotch
                    )

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "显示锁屏实时活动",
                        description: "Display an authentication status activity in the notch on the lock screen.",
                        isOn: $settings.settings.lockScreenLiveActivityEnabled
                    )
                }
                .modifier(SettingsContainerModifier())
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onChange(of: settings.settings.lockScreenShowNotch) {notchsettingsHaveChanged = true}
        }
    }

    private var wallpaperConfiguration: LiveWallpaperConfiguration {
        LiveWallpaperConfiguration(settings: settings.settings.value)
    }

    private var hasVideoWallpaper: Bool {
        let configuration = wallpaperConfiguration
        return WallpaperMedia.isVideo(path: configuration.desktopPath)
            || WallpaperMedia.isVideo(path: configuration.lockScreenPath)
    }

}

private struct WallpaperFileRow: View {
    @Binding var path: String?
    let panelTitle: String
    let panelMessage: String

    @State private var thumbnail: CGImage?

    private var media: WallpaperMedia? { WallpaperMedia(path: path) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                if let thumbnail {
                    Image(decorative: thumbnail, scale: 2)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: media?.isVideo == true ? "film" : "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 64, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                if media?.isVideo == true, thumbnail != nil {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(.black.opacity(0.45), in: Circle())
                        .padding(3)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if let media {
                    Text(media.url.lastPathComponent)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Text(media.isVideo ? "Live video" : "Image")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let path, !path.isEmpty {
                    Text((path as NSString).lastPathComponent)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Text("找不到文件")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else {
                    Text("未选择壁纸")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("选择...") { choose() }
            if path != nil {
                Button("删除") { path = nil }
            }
        }
        .padding()
        .task(id: path) {
            thumbnail = nil
            guard let media else { return }
            let image = await Task.detached(priority: .utility) {
                await WallpaperAssetStore.thumbnail(for: media, maxPixelSize: 160)
            }.value
            guard !Task.isCancelled else { return }
            thumbnail = image
        }
    }

    private func choose() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = panelTitle
        panel.message = panelMessage
        panel.prompt = "Choose"
        panel.allowedContentTypes = WallpaperMedia.allowedContentTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if let path, !path.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        }
        let binding = $path
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            binding.wrappedValue = url.path
        }
    }
}

struct SnapZonesSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var appFetcher = SystemAppFetcher.shared

    @State private var layoutToEdit: SnapLayout?
    @State private var planeToEdit: Plane?
    @State private var isShowingAppPicker = false

    @State private var appToConfigureMultiLayout: String?
    @State private var multiLayoutIDsForSheet: [UUID] = []
    @State private var snapShortcutsExpanded = false

    private var allLayouts: [SnapLayout] {
        LayoutTemplate.allTemplates + settings.settings.customSnapLayouts
    }

    private var viewModeDescription: String {
        switch settings.settings.snapZoneViewMode {
        case .single:
            return "Show one layout at a time, determined by your default or app-specific settings."
        case .multi:
            return "Show a user-defined list of layouts side-by-side in the widget for quick selection."
        }
    }

    private var isShowingMultiLayoutPicker: Binding<Bool> {
        Binding(
            get: { appToConfigureMultiLayout != nil },
            set: { isShowing in
                if !isShowing {
                    appToConfigureMultiLayout = nil
                }
            }
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 25) {
                Text("捕捉区域和平面")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.bottom, 5)

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "拖动时激活",
                        description: "Show Snap Zones when dragging near the notch.",
                        isOn: $settings.settings.snapDragEnabled
                    )
                    ToggleRow(
                        title: "在窗口拖动时激活",
                        description: "Show Snap Zones when dragging a window. Hold Command to temporarily hide them.",
                        isOn: $settings.settings.snapOnWindowDragEnabled
                    )

                    Divider().padding(.leading, 20)

                    DeferredValueEditor(value: $settings.settings.snapActivationDelay) { draft, onEditingChanged in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("激活延迟")
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Text(String(format: "%.2fs", draft.wrappedValue))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: draft, in: 0.1...1.0, step: 0.05, onEditingChanged: onEditingChanged)
                            Text("在打开捕捉区域之前，请在激活区域中等待这么长时间。有助于避免意外触发。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()

                    Divider().padding(.leading, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("重新定位和调整大小")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Picker("重新定位和调整大小", selection: $settings.settings.snapWindowAnimation) {
                                ForEach(SnapWindowAnimation.allCases) { animation in
                                    Text(animation.displayName).tag(animation)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .frame(width: 150)
                        }
                        Text(settings.settings.snapWindowAnimation.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .modifier(SettingsContainerModifier())

                snapShortcutsManagementSection

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("全局小部件样式").font(.headline)
                        Spacer()
                        Picker("小部件视图样式", selection: $settings.settings.snapZoneViewMode) {
                            ForEach(SnapZoneViewMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 150)
                    }.padding()

                    Text(viewModeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom)

                }.modifier(SettingsContainerModifier())

                if settings.settings.snapZoneViewMode == .single {
                    singleLayoutsManagementSection
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    multiLayoutsManagementSection
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                appSpecificLayoutsSection
                customLayoutsSection
                planesManagementSection
                RequiredPermissionsView(section: .snapZones)
            }
            .padding(25)
            .animation(.easeInOut(duration: 0.2), value: settings.settings.snapZoneViewMode)
        }
        .onAppear(perform: appFetcher.fetchApps)
        .sheet(item: $layoutToEdit) { layout in
            LayoutEditorView(layout: Binding(
                get: { layout },
                set: { updatedLayout in layoutToEdit = updatedLayout }
            ), onSave: saveLayout)
        }
        .sheet(isPresented: isShowingMultiLayoutPicker) {
            if let bundleId = appToConfigureMultiLayout {
                MultiLayoutPickerView(
                    appName: appName(for: bundleId),
                    allLayouts: allLayouts,
                    initialLayoutIDs: multiLayoutIDsForSheet,
                    onSave: { newIDs in
                        modifySettings { $0.appSpecificLayoutConfigurations[bundleId] = .multi(layoutIDs: newIDs) }
                    }
                )
            }
        }
        .sheet(item: $planeToEdit) { plane in
            PlaneEditorView(plane: Binding(
                get: { plane },
                set: { updatedPlane in planeToEdit = updatedPlane }
            ), allLayouts: allLayouts, allApps: appFetcher.apps, onSave: savePlane)
        }
        .popover(isPresented: $isShowingAppPicker, arrowEdge: .bottom) {
            AppPickerView(apps: appFetcher.apps, onSelect: addAppSpecificLayout)
        }
    }

    @ViewBuilder
    private var snapShortcutsManagementSection: some View {
        DisclosureGroup(isExpanded: $snapShortcutsExpanded) {
            VStack(alignment: .leading, spacing: 0) {
                PremiumFeatureView(feature: .snapZonesKeyboardShortcuts) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("为区域分配快捷方式以将当前聚焦的窗口捕捉到该区域。记录另一个区域已使用的快捷方式会将其移至此区域。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        ForEach(allLayouts) { layout in
                            SnapZoneShortcutLayoutView(
                                layout: layout,
                                shortcuts: settings.settings.snapZoneShortcuts,
                                onChange: { zoneID, shortcut in
                                    modifySettings { $0.setSnapZoneShortcut(shortcut, for: layout.id, zoneID: zoneID) }
                                }
                            )
                            if layout.id != allLayouts.last?.id {
                                Divider().padding(.leading, 20)
                            }
                        }
                    }
                }
            }
        } label: {
            Label("捕捉区域快捷方式", systemImage: "keyboard")
                .font(.headline)
                .padding([.top, .horizontal])
                .padding(.bottom, 6)
        }
        .modifier(SettingsContainerModifier())
    }

    @ViewBuilder
    private var singleLayoutsManagementSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("全局默认布局").font(.headline)
                Spacer()
                ModernMenuPicker(selection: $settings.settings.defaultSnapLayout, options: allLayouts, titleKeyPath: \.name)
            }.padding(.horizontal, 20).padding(.vertical, 12)
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder
    private var multiLayoutsManagementSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("全局多视图布局").font(.headline)
                Spacer()
                Menu {
                    let alreadyAddedIDs = Set(settings.settings.snapZoneLayoutOptions)
                    let availableLayouts = allLayouts.filter { !alreadyAddedIDs.contains($0.id) }

                    if availableLayouts.isEmpty { Text("添加了所有布局") }
                    else {
                        ForEach(availableLayouts) { layout in
                            Button(layout.name) { addLayoutOption(layout.id) }
                        }
                    }
                } label: {
                    HStack { Image(systemName: "plus"); Text("添加布局") }
                }
                .buttonStyle(.borderless).tint(.accentColor)
                .disabled(allLayouts.count == settings.settings.snapZoneLayoutOptions.count)

            }.padding([.horizontal, .top]).padding(.bottom, 8)

            Text("添加默认情况下出现在多视图小部件中的布局并对其进行重新排序。").font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom)
            Divider()

            if settings.settings.snapZoneLayoutOptions.isEmpty {
                 Text("单击“添加布局”来构建全局多视图小部件。")
                     .foregroundColor(.secondary).frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            } else {
                List {
                    ForEach(settings.settings.snapZoneLayoutOptions.indices, id: \.self) { index in
                        let layoutID = settings.settings.snapZoneLayoutOptions[index]
                        if let layout = allLayouts.first(where: { $0.id == layoutID }) {
                            HStack {
                                Image(systemName: "line.3.horizontal").foregroundStyle(.secondary)
                                Text(layout.name)
                                Spacer()
                                Button {
                                    deleteLayoutOption(at: IndexSet(integer: index))
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .onMove(perform: moveLayoutOption)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
                .frame(height: CGFloat(settings.settings.snapZoneLayoutOptions.count) * 28)
            }
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder
    private var appSpecificLayoutsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("应用程序特定的覆盖").font(.headline)
                Spacer()
                Button("添加应用程序") { isShowingAppPicker = true }.buttonStyle(.borderless).tint(.accentColor)
            }.padding([.horizontal, .top]).padding(.bottom, 8)
            Text("拖动特定应用程序时强制使用特定的布局模式（单或多）。").font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom)
            Divider()
            if settings.settings.appSpecificLayoutConfigurations.isEmpty {
                 Text("没有配置特定于应用程序的覆盖。").foregroundColor(.secondary).frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            } else {
                ForEach(settings.settings.appSpecificLayoutConfigurations.keys.sorted(), id: \.self) { bundleId in
                    AppSpecificLayoutConfigRow(
                        app: app(for: bundleId),
                        appName: appName(for: bundleId),
                        allLayouts: allLayouts,
                        configuration: bindingForAppConfig(bundleId),
                        onEditMulti: {
                            if case .multi(let layoutIDs) = settings.settings.appSpecificLayoutConfigurations[bundleId] {
                                self.multiLayoutIDsForSheet = layoutIDs
                            } else {
                                self.multiLayoutIDsForSheet = []
                            }
                            self.appToConfigureMultiLayout = bundleId
                        },
                        onDelete: {
                            modifySettings { $0.appSpecificLayoutConfigurations.removeValue(forKey: bundleId) }
                        }
                    )
                    Divider().padding(.leading, 60)
                }
            }
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder
    private var customLayoutsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("我的自定义布局").font(.headline)
                Spacer()
                Button("新布局") { layoutToEdit = SnapLayout(name: "新的自定义布局", zones: []) }.buttonStyle(.borderless).tint(.accentColor)
            }.padding()
            Divider()
            if settings.settings.customSnapLayouts.isEmpty {
                Text("尚未创建自定义布局。").foregroundColor(.secondary).frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            } else {
                ForEach(settings.settings.customSnapLayouts) { layout in
                    CustomLayoutRow(layout: layout, onEdit: { layoutToEdit = layout }, onDelete: { deleteLayout(layout) })
                    Divider().padding(.leading, 20)
                }
            }
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder
    private var planesManagementSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("飞机").font(.title2.bold())
                Spacer()
                Button("新飞机") {
                    guard let firstLayout = allLayouts.first else { return }
                    planeToEdit = Plane(name: "新飞机", layoutID: firstLayout.id)
                }.buttonStyle(.borderless).tint(.accentColor)
            }.padding([.horizontal, .top]).padding(.bottom, 8)
            Text("使用键盘快捷键触发布局以立即排列窗口。").font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom)
            Divider()
            if settings.settings.planes.isEmpty {
                Text("尚未创建飞机。").foregroundColor(.secondary).frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            } else {
                ForEach($settings.settings.planes) { $plane in
                    PlaneRow(plane: $plane, onEdit: { planeToEdit = $plane.wrappedValue }, onDelete: { deletePlane(withId: $plane.id) })
                    Divider().padding(.leading, 20)
                }
            }
        }.modifier(SettingsContainerModifier())
    }

    // MARK: - Helper Functions
    private func modifySettings(_ modification: (inout Settings) -> Void) {
        var newSettings = settings.settings.value
        modification(&newSettings)
        settings.settings.value = newSettings
    }

    private func saveLayout(_ savedLayout: SnapLayout) { modifySettings { settings in if let index = settings.customSnapLayouts.firstIndex(where: { $0.id == savedLayout.id }) { settings.customSnapLayouts[index] = savedLayout } else { settings.customSnapLayouts.append(savedLayout) } } }
    private func savePlane(_ savedPlane: Plane) { modifySettings { settings in if let index = settings.planes.firstIndex(where: { $0.id == savedPlane.id }) { settings.planes[index] = savedPlane } else { settings.planes.append(savedPlane) } } }

    private func deleteLayout(_ layoutToDelete: SnapLayout) {
        modifySettings { settings in
            settings.customSnapLayouts.removeAll { $0.id == layoutToDelete.id }
            if settings.defaultSnapLayout.id == layoutToDelete.id {
                settings.defaultSnapLayout = LayoutTemplate.columns
            }
            for (bundleID, config) in settings.appSpecificLayoutConfigurations {
                switch config {
                case .single(let layoutID) where layoutID == layoutToDelete.id:
                    settings.appSpecificLayoutConfigurations.removeValue(forKey: bundleID)
                case .multi(var layoutIDs):
                    layoutIDs.removeAll { $0 == layoutToDelete.id }
                    settings.appSpecificLayoutConfigurations[bundleID] = .multi(layoutIDs: layoutIDs)
                default:
                    break
                }
            }
            settings.snapZoneShortcuts.removeAll { $0.layoutID == layoutToDelete.id }
            settings.planes.removeAll { $0.layoutID == layoutToDelete.id }
        }
    }

    private func deletePlane(withId planeId: UUID) { modifySettings { settings in settings.planes.removeAll { $0.id == planeId } } }

    private func addAppSpecificLayout(_ appBundleId: String) {
        modifySettings { settings in
            if settings.appSpecificLayoutConfigurations[appBundleId] == nil {
                let firstLayoutID = allLayouts.first?.id ?? LayoutTemplate.columns.id
                settings.appSpecificLayoutConfigurations[appBundleId] = .single(layoutID: firstLayoutID)
            }
        }
        isShowingAppPicker = false
    }

    private func app(for bundleId: String) -> SystemApp? { appFetcher.apps.first { $0.id == bundleId } }
    private func appName(for bundleId: String) -> String { app(for: bundleId)?.name ?? bundleId }

    private func bindingForAppConfig(_ bundleId: String) -> Binding<AppSnapLayoutConfiguration> {
        Binding(
            get: { settings.settings.appSpecificLayoutConfigurations[bundleId] ?? .useGlobalDefault },
            set: { newConfig in modifySettings { $0.appSpecificLayoutConfigurations[bundleId] = newConfig } }
        )
    }

    private func addLayoutOption(_ layoutID: UUID) { modifySettings { $0.snapZoneLayoutOptions.append(layoutID) } }
    private func moveLayoutOption(from source: IndexSet, to destination: Int) { modifySettings { $0.snapZoneLayoutOptions.move(fromOffsets: source, toOffset: destination) } }
    private func deleteLayoutOption(at offsets: IndexSet) { modifySettings { $0.snapZoneLayoutOptions.remove(atOffsets: offsets) } }
}

fileprivate struct SnapZoneShortcutLayoutView: View {
    let layout: SnapLayout
    let shortcuts: [SnapZoneShortcut]
    let onChange: (UUID, KeyboardShortcut?) -> Void

    @ObservedObject private var shortcutRecorder = GlobalShortcutRecorder.shared

    private func shortcut(for zoneID: UUID) -> KeyboardShortcut? {
        shortcuts.first { $0.layoutID == layout.id && $0.zoneID == zoneID }?.shortcut
    }

    private func recordingIdentifier(for zoneID: UUID) -> String {
        "snap-zone-\(layout.id.uuidString)-\(zoneID.uuidString)"
    }

    private func toggleRecording(for zoneID: UUID) {
        let identifier = recordingIdentifier(for: zoneID)
        if shortcutRecorder.isRecording {
            if shortcutRecorder.recordingIdentifier == identifier {
                shortcutRecorder.stopRecording()
            }
            return
        }

        shortcutRecorder.startRecording(identifier: identifier) { key, flags in
            onChange(zoneID, KeyboardShortcut(key: key, modifiers: flags))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "rectangle.3.group")
                    .foregroundStyle(Color.accentColor)
                Text(layout.name)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(layout.zones.count) zones")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 4)

            ForEach(Array(layout.zones.enumerated()), id: \.element.id) { index, zone in
                let zoneShortcut = shortcut(for: zone.id)
                let identifier = recordingIdentifier(for: zone.id)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Zone \(index + 1)")
                            .font(.system(size: 13, weight: .medium))
                        Text("\(Int(zone.width * 100))% x \(Int(zone.height * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    Button(action: { toggleRecording(for: zone.id) }) {
                        HStack(spacing: 6) {
                            if shortcutRecorder.isRecording && shortcutRecorder.recordingIdentifier == identifier {
                                ProgressView()
                                    .controlSize(.small)
                                Text("录音...")
                            } else if let zoneShortcut {
                                Image(systemName: "keyboard")
                                Text("\(KeyboardShortcutHelper.description(for: zoneShortcut.modifiers))\(zoneShortcut.key)")
                            } else {
                                Image(systemName: "keyboard")
                                Text("Record")
                            }
                        }
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(minWidth: 125)
                    }
                    .buttonStyle(.bordered)
                    .disabled(shortcutRecorder.isRecording && shortcutRecorder.recordingIdentifier != identifier)
                    .help(zoneShortcut == nil ? "Record a shortcut for Zone \(index + 1)" : "Change the shortcut for Zone \(index + 1)")

                    if zoneShortcut != nil {
                        Button {
                            onChange(zone.id, nil)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("清除快捷方式")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
}

fileprivate struct AppSpecificLayoutConfigRow: View {
    let app: SystemApp?
    let appName: String
    let allLayouts: [SnapLayout]
    @Binding var configuration: AppSnapLayoutConfiguration
    let onEditMulti: () -> Void
    let onDelete: () -> Void

    private enum ConfigType: Int, Identifiable {
        case useDefault = 0, single, multi
        var id: Int { self.rawValue }
    }

    private var configTypeBinding: Binding<ConfigType> {
        Binding(
            get: {
                switch configuration {
                case .useGlobalDefault: return .single
                case .single: return .single
                case .multi: return .multi
                }
            },
            set: { newType in
                switch newType {
                case .single:
                    if case .single = configuration { return }
                    let firstLayoutID = allLayouts.first?.id ?? LayoutTemplate.columns.id
                    configuration = .single(layoutID: firstLayoutID)
                case .multi:
                    if case .multi = configuration { return }
                    configuration = .multi(layoutIDs: [])
                case .useDefault:
                    break
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            if let app {
                SystemAppIconView(app: app, size: 28, cornerRadius: 6)
            } else {
                Image(systemName: "app.dashed").font(.title2).frame(width: 28)
            }

            Text(appName).lineLimit(1)
            Spacer()

            Picker("模式", selection: configTypeBinding) {
                Text("单人").tag(ConfigType.single)
                Text("多").tag(ConfigType.multi)
            }
            .labelsHidden().frame(width: 180)

            switch configuration {
            case .single(let layoutID):
                let binding = Binding(
                    get: { layoutID },
                    set: { newID in configuration = .single(layoutID: newID) }
                )
                ModernMenuPickerWithID(selection: binding, options: allLayouts, titleKeyPath: \.name)
                    .frame(width: 150)
            case .multi:
                Button("Edit", action: onEditMulti).buttonStyle(.borderless).tint(.accentColor)
            case .useGlobalDefault:
                EmptyView().frame(width: 150, height: 1)
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill").font(.body).foregroundColor(.secondary.opacity(0.7))
            }
            .buttonStyle(.plain).padding(.leading, 8)
        }
        .padding(.vertical, 8).padding(.horizontal, 20)
    }
}

fileprivate struct MultiLayoutPickerView: View {
    @Environment(\.dismiss) var dismiss
    let appName: String
    let allLayouts: [SnapLayout]
    let onSave: ([UUID]) -> Void

    @State private var editedLayoutIDs: [UUID]

    init(appName: String, allLayouts: [SnapLayout], initialLayoutIDs: [UUID], onSave: @escaping ([UUID]) -> Void) {
        self.appName = appName
        self.allLayouts = allLayouts
        self.onSave = onSave
        self._editedLayoutIDs = State(initialValue: initialLayoutIDs)
    }

    private var availableLayouts: [SnapLayout] {
        allLayouts.filter { !editedLayoutIDs.contains($0.id) }
    }

    private func layout(for id: UUID) -> SnapLayout? {
        allLayouts.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Edit Multi-View for \(appName)").font(.title2.bold()).padding()
            Divider()

            HSplitView {
                VStack(alignment: .leading) {
                    Text("可用布局").font(.headline).padding([.top, .horizontal])
                    List(availableLayouts) { layout in
                        Button(action: { editedLayoutIDs.append(layout.id) }) {
                            HStack { Text(layout.name); Spacer(); Image(systemName: "plus.circle.fill").foregroundColor(.green) }
                        }.buttonStyle(.plain)
                    }.listStyle(.sidebar)
                }
                .frame(minWidth: 220)

                VStack(alignment: .leading) {
                    Text("选定的布局（拖动以重新排序）").font(.headline).padding([.top, .horizontal])
                    List {
                        ForEach(editedLayoutIDs.indices, id: \.self) { index in
                            if let layout = layout(for: editedLayoutIDs[index]) {
                                HStack {
                                    Text(layout.name)
                                    Spacer()
                                    Button {
                                        delete(at: IndexSet(integer: index))
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .onMove(perform: move)
                    }.listStyle(.sidebar)
                }
                .frame(minWidth: 220)
            }

            Divider()
            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button("保存") {
                    onSave(editedLayoutIDs)
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }.padding()
        }
        .frame(width: 550, height: 450)
    }

    private func move(from source: IndexSet, to destination: Int) {
        editedLayoutIDs.move(fromOffsets: source, toOffset: destination)
    }

    private func delete(at offsets: IndexSet) {
        editedLayoutIDs.remove(atOffsets: offsets)
    }
}

fileprivate struct ModernMenuPicker<T: Identifiable & Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let titleKeyPath: KeyPath<T, String>

    private var selectedOptionName: String {
        return options.first { $0.id == selection.id }?[keyPath: titleKeyPath] ?? "Select"
    }

    var body: some View {
        Menu {
            ForEach(options) { option in
                Button(option[keyPath: titleKeyPath]) {
                    selection = option
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedOptionName)
                Image(systemName: "chevron.down").font(.caption.bold())
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct CustomLayoutRow: View {
    let layout: SnapLayout
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "rectangle.3.group")
                .font(.title2)
                .frame(width: 30)
                .foregroundColor(.accentColor)
            Text(layout.name).font(.headline)
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)
            .tint(.secondary)

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .tint(.red)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

fileprivate struct ModernMenuPickerWithID<T: Identifiable & Hashable>: View where T.ID == UUID {
    @Binding var selection: T.ID
    let options: [T]
    let titleKeyPath: KeyPath<T, String>
    var defaultID: T.ID? = nil
    var defaultTitle: String = "Default"

    private var selectedOptionName: String {
        if let defaultID = defaultID, selection == defaultID {
            return defaultTitle
        }
        return options.first { $0.id == selection }?[keyPath: titleKeyPath] ?? "Select"
    }

    var body: some View {
        Menu {
            if let defaultID = defaultID {
                Button(defaultTitle) { selection = defaultID }
                Divider()
            }
            ForEach(options) { option in
                Button(option[keyPath: titleKeyPath]) { selection = option.id }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedOptionName)
                Image(systemName: "chevron.down").font(.caption.bold())
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct PlaneRow: View {
    @Binding var plane: Plane
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var shortcutDescription: String {
        guard let shortcut = plane.shortcut else { return "No shortcut set" }
        return "\(KeyboardShortcutHelper.description(for: shortcut.modifiers)) \(shortcut.key)"
    }

    var body: some View {
        HStack {
            Image(systemName: "keyboard")
                .font(.title2)
                .frame(width: 30)
                .foregroundColor(.accentColor)
                .onTapGesture(perform: onEdit)

            VStack(alignment: .leading) {
                Text(plane.name).font(.headline)
                Text(shortcutDescription)
                    .font(.caption).foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .tint(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

fileprivate struct AppPickerView: View {
    let apps: [SystemApp]
    let onSelect: (String) -> Void
    @State private var searchText = ""

    private var filteredApps: [SystemApp] {
        if searchText.isEmpty {
            return apps
        }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("搜索应用程序", text: $searchText)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.black.opacity(0.1))

            List(filteredApps) { app in
                Button(action: { onSelect(app.id) }) {
                    HStack {
                        SystemAppIconView(app: app, size: 24, cornerRadius: 4)
                        Text(app.name)
                    }
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
        .frame(width: 300, height: 400)
        .background(.ultraThinMaterial)
    }
}

struct NotificationsSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Notifications")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                InfoContainer(text: "All notifications and focus features are in development.", iconName: "info.circle.fill", color: .yellow)

                VStack(spacing: 0) {
                    HStack {
                        Text("启用通知")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        SettingsSwitch(isOn: $settings.settings.masterNotificationsEnabled)
                            .animation(.default, value: settings.settings.masterNotificationsEnabled)
                    }
                    .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                }
                .modifier(SettingsContainerModifier())

                VStack(spacing: 20) {

                    VStack(alignment: .leading, spacing: 0) {
                        Text("验证码")
                            .font(.headline)
                            .padding([.top, .horizontal])

                        ToggleRow(
                            title: "仅显示带有验证码的通知",
                            description: "Filter notifications to only display when a code (OTP) is detected.",
                            isOn: $settings.settings.onlyShowVerificationCodeNotifications
                        )

                        Divider().padding(.leading, 20)

                        ToggleRow(
                            title: "显示检测到的代码的复制按钮",
                            description: "Add a quick action to copy the code from supported notifications.",
                            isOn: $settings.settings.showCopyButtonForVerificationCodes
                        )

                        Divider().padding(.leading, 20)

                        ToggleRow(
                            title: "自动复制验证码",
                            description: "Automatically copy OTP codes to the clipboard when detected.",
                            isOn: $settings.settings.autoCopyVerificationCodes
                        )

                        Divider().padding(.leading, 20)

                        ToggleRow(
                            title: "OTP 缺口弹出框",
                            description: "Show a dedicated verification-code popover in the notch.",
                            isOn: $settings.settings.otpLiveActivityEnabled
                        )

                        Divider().padding(.leading, 20)

                        ToggleRow(
                            title: "扫描邮件以获取 OTP 代码",
                            description: "Watch Mail.app unread messages for verification codes (no AI).",
                            isOn: $settings.settings.mailOTPDetectionEnabled
                        )
                    }
                    .modifier(SettingsContainerModifier())
                    .disabled(!settings.settings.masterNotificationsEnabled)
                    .opacity(settings.settings.masterNotificationsEnabled ? 1.0 : 0.5)
                    .animation(.easeInOut, value: settings.settings.masterNotificationsEnabled)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("智能收件箱")
                            .font(.headline)
                            .padding([.top, .horizontal])

                        ToggleRow(
                            title: "启用智能收件箱",
                            description: "AI-independent Mail features: OTP detection and parcel tracking.",
                            isOn: $settings.settings.smartInboxEnabled
                        )

                        Divider().padding(.leading, 20)

                        ToggleRow(
                            title: "通过电子邮件跟踪包裹",
                            description: "Detect UPS/FedEx/USPS/DHL/Amazon tracking numbers in Mail.",
                            isOn: $settings.settings.parcelTrackingEnabled
                        )

                        Divider().padding(.leading, 20)

                        ToggleRow(
                            title: "包裹缺口弹出框",
                            description: "Show live package status in the notch when a shipment is active.",
                            isOn: $settings.settings.parcelLiveActivityEnabled
                        )
                    }
                    .modifier(SettingsContainerModifier())

                    VStack(spacing: 0) {
                        ForEach(NotificationSource.allCases) { source in
                            NotificationToggleRowView(source: source)
                            if source != NotificationSource.allCases.last {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.leading, 60)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("系统通知")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            SettingsSwitch(isOn: $settings.settings.systemNotificationsEnabled)
                                .animation(.default, value: settings.settings.systemNotificationsEnabled)
                        }
                        .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))

                        Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1).padding(.leading, 60)

                        Text("允许来自以下位置的通知：")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .disabled(!settings.settings.systemNotificationsEnabled)
                            .opacity(settings.settings.systemNotificationsEnabled ? 1.0 : 0.5)

                        AppTogglesListView(isEnabled: { app in binding(for: app) }, maxHeight: 360)
                            .disabled(!settings.settings.systemNotificationsEnabled)
                            .opacity(settings.settings.systemNotificationsEnabled ? 1.0 : 0.5)
                    }
                }
                .modifier(SettingsContainerModifier())
                .disabled(!settings.settings.masterNotificationsEnabled)
                .opacity(settings.settings.masterNotificationsEnabled ? 1.0 : 0.5)
                .animation(.easeInOut, value: settings.settings.masterNotificationsEnabled)

                RequiredPermissionsView(section: .notifications)
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func binding(for app: SystemApp) -> Binding<Bool> {
        return .init(
            get: { settings.settings.appNotificationStates[app.id, default: true] },
            set: { settings.settings.appNotificationStates[app.id] = $0 }
        )
    }
}

struct ProximityUnlockSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var authManager = AuthenticationManager.shared

    @State private var showPasswordPrompt = false
    @State private var showUnnamedDevices = false
    @State private var isFindingByDistance = false
    @State private var isCalibratingRSSI = false
    @State private var pendingFaceProfileAction: FaceProfileAction?
    @State private var newFaceIDWiFiNetworkName = ""
    @ObservedObject private var wifiMonitor = WiFiStatusMonitor.shared

    private let deviceRowHeight: CGFloat = 38
    private let maxDeviceListHeight: CGFloat = 228

    private struct FaceProfileAction: Identifiable {
        enum Kind {
            case register
            case append
            case delete
        }

        let id = UUID()
        let kind: Kind
        let profileName: String

        var message: String {
            switch kind {
            case .register: return "register the '\(profileName)' face profile"
            case .append: return "add captures to the '\(profileName)' face profile"
            case .delete: return "delete the '\(profileName)' face profile"
            }
        }
    }

    private func performFaceProfileAction(_ action: FaceProfileAction) {
        switch action.kind {
        case .register, .append:
            authManager.beginFaceRegistration(profileName: action.profileName)
        case .delete:
            authManager.deleteFaceProfile(name: action.profileName)
        }
    }

    private var isBluetoothEnabled: Binding<Bool> {
        Binding<Bool>(
            get: { settings.settings.bluetoothUnlockEnabled },
            set: { newValue in
                if newValue {
                    if !authManager.isPasswordSet {
                        showPasswordPrompt = true
                    } else {
                        settings.settings.bluetoothUnlockEnabled = true
                    }
                } else {
                    settings.settings.bluetoothUnlockEnabled = false
                }
            }
        )
    }

    private var isFaceIDEnabled: Binding<Bool> {
        Binding<Bool>(
            get: { settings.settings.faceIDUnlockEnabled },
            set: { newValue in
                if newValue {
                    if !authManager.isPasswordSet {
                        showPasswordPrompt = true
                    } else {
                        settings.settings.faceIDUnlockEnabled = true
                    }
                } else {
                    settings.settings.faceIDUnlockEnabled = false
                }
            }
        )
    }

    private var selectedDevice: Device? {
        guard let selectedIDString = authManager.selectedDeviceID,
              let selectedID = UUID(uuidString: selectedIDString) else { return nil }
        return authManager.scannedDevices.first { $0.id == selectedID } ?? authManager.ble.devices[selectedID]
    }

    private var filteredScannedDevices: [Device] {
        return showUnnamedDevices ? authManager.scannedDevices : authManager.scannedDevices.filter { $0.displayName != "Unnamed Device" }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header
                InfoContainer(text: "WARNING: All these features are in development and may not work as expected. They might cause unexpected unlocks on your mac. Use at your own risk.", iconName: "exclamationmark.triangle.fill", color: .red)
                if settings.settings.faceIDUnlockEnabled {
                    InfoContainer(text: "Enabling face ID will increase the app's ram usage.", iconName: "info.circle", color: .yellow)
                }
                authenticationSection
                faceIDSection
                bluetoothUnlockSection
                actionsSection
                RequiredPermissionsView(section: .bluetoothUnlock)
            }
            .padding(25)
        }
        .sheet(isPresented: $showPasswordPrompt) {
            PasswordPromptView(
                isPresented: $showPasswordPrompt,
                validate: { authManager.verifyMacLoginPassword($0) }
            ) { password in
                if authManager.verifyAndSavePassword(password) {
                    showPasswordPrompt = false
                }
            }
        }
        .sheet(item: $pendingFaceProfileAction) { action in
            PasswordPromptView(
                isPresented: Binding(
                    get: { pendingFaceProfileAction != nil },
                    set: { if !$0 { pendingFaceProfileAction = nil } }
                ),
                validate: { authManager.verifyPassword($0) },
                title: "需要面容 ID 身份验证",
                message: "Enter your Mac's password to \(action.message)."
            ) { _ in
                pendingFaceProfileAction = nil
                performFaceProfileAction(action)
            }
        }
        .sheet(item: $authManager.faceRegistrationController, onDismiss: {
            authManager.completeFaceRegistration()
        }) { controller in
            FaceIDRegistrationView(
                cameraController: controller,
                profileName: authManager.profileNameToRegister
            )
        }
        .sheet(isPresented: $isFindingByDistance) {
            FindDeviceByDistanceWizard()
        }
        .sheet(isPresented: $isCalibratingRSSI) {
            CalibrateRSSIView().environment(settings)
        }
        .onAppear {
            authManager.fetchRegisteredFaces()
            authManager.refreshFaceIDLocation()
        }
        .onDisappear {
            if authManager.isScanning {
                authManager.stopScan()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text("近距离和人脸解锁").font(.largeTitle.bold())
            HStack {
                Button("立即锁定屏幕") { authManager.manualLock() }
                    .disabled(!settings.settings.bluetoothUnlockEnabled && !settings.settings.faceIDUnlockEnabled)
                Spacer()
                Text(authManager.status).font(.caption).foregroundColor(.secondary)
            }.padding(.top, 2)
        }
    }

    @ViewBuilder
    private var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Authentication").font(.headline).padding([.horizontal, .top])
            if authManager.isPasswordSet {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("您的 Mac 密码安全地存储在钥匙串中。")
                    Spacer()
                    Button("改变") { showPasswordPrompt = true }
                    Button("删除", role: .destructive) {
                        authManager.removePassword()
                        var updated = settings.settings.value
                        updated.bluetoothUnlockEnabled = false
                        updated.faceIDUnlockEnabled = false
                        settings.settings.value = updated
                    }
                }.padding([.horizontal, .bottom])
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                    Text("要启用面容 ID 或蓝牙解锁，您必须首先提供 Mac 的登录密码。")
                    Spacer()
                    Button("设置密码") { showPasswordPrompt = true }
                }.padding([.horizontal, .bottom])
            }
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder
    private var faceIDSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ToggleRow(title: "启用面容 ID 解锁", description: "当您唤醒屏幕时，使用面部识别解锁您的 Mac。", isOn: isFaceIDEnabled)
                .disabled(!authManager.isPasswordSet)

            if settings.settings.faceIDUnlockEnabled {
                Divider().padding(.leading, 20)

                let registeredFaces = authManager.registeredFaceProfiles
                if registeredFaces.isEmpty {
                    Text("没有注册面孔。添加脸部以开始使用 Face ID。")
                        .font(.caption).foregroundColor(.secondary).padding()
                } else {
                    ForEach(registeredFaces, id: \.self) { profileName in
                        HStack {
                            Image(systemName: "faceid").font(.title2).foregroundColor(.accentColor)
                            Text(profileName)
                            Spacer()
                            Button("重新注册") {
                                pendingFaceProfileAction = FaceProfileAction(kind: .register, profileName: profileName)
                            }
                            Button("Delete", role: .destructive) {
                                pendingFaceProfileAction = FaceProfileAction(kind: .delete, profileName: profileName)
                            }
                        }.padding()
                    }
                }

                if registeredFaces.count < 2 {
                    HStack {
                        Spacer()
                        Button(action: {
                            let profileName = registeredFaces.isEmpty ? "Primary Face" : "Secondary Face"
                            pendingFaceProfileAction = FaceProfileAction(kind: .register, profileName: profileName)
                        }) { Label("添加面孔", systemImage: "plus.circle.fill") }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }.padding(.bottom)
                }

                Divider().padding(.leading, 20)
                faceIDLocationSection
                Divider().padding(.leading, 20)
                faceIDSecuritySection

                Divider().padding(.horizontal)
            }
        }
        .modifier(SettingsContainerModifier())
        .opacity(authManager.isPasswordSet ? 1.0 : 0.6)
    }

    @ViewBuilder
    private var faceIDLocationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("地点").font(.subheadline).bold().padding([.horizontal, .top])

            Picker("面容 ID 有效", selection: $settings.settings.faceIDLocationPolicy) {
                ForEach(FaceIDLocationPolicy.allCases) { policy in
                    Text(policy.displayName).tag(policy)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if settings.settings.faceIDLocationPolicy == .selectedWiFiNetworks {
                Text("使用受信任的 Wi-Fi 网络作为位置。 Face ID 在其他网络上或网络名称不可用时不会启动。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                HStack(spacing: 8) {
                    if let currentNetwork = wifiMonitor.state.networkName {
                        Button {
                            addFaceIDWiFiNetwork(currentNetwork)
                        } label: {
                            Label("Use \(currentNetwork)", systemImage: "wifi")
                        }
                        .disabled(settings.settings.faceIDAllowedWiFiNetworks.contains(currentNetwork))
                    } else {
                        Text("未检测到 Wi-Fi 网络")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        authManager.refreshFaceIDLocation()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("刷新当前 Wi-Fi 网络")
                }
                .padding(.horizontal)

                HStack(spacing: 8) {
                    TextField("Wi-Fi 网络名称", text: $newFaceIDWiFiNetworkName)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        addFaceIDWiFiNetwork(newFaceIDWiFiNetworkName)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(newFaceIDWiFiNetworkName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("添加 Wi-Fi 网络")
                }
                .padding(.horizontal)

                if settings.settings.faceIDAllowedWiFiNetworks.isEmpty {
                    Text("尚未添加受信任位置。在添加面部识别码之前，面部识别码将一直不可用。")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal)
                } else {
                    ForEach(settings.settings.faceIDAllowedWiFiNetworks, id: \.self) { networkName in
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundStyle(.secondary)
                            Text(networkName)
                            Spacer()
                            Button {
                                settings.settings.faceIDAllowedWiFiNetworks.removeAll { $0 == networkName }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                            .help("Remove \(networkName)")
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func addFaceIDWiFiNetwork(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              !settings.settings.faceIDAllowedWiFiNetworks.contains(trimmedName) else { return }
        settings.settings.faceIDAllowedWiFiNetworks.append(trimmedName)
        newFaceIDWiFiNetworkName = ""
    }

    @ViewBuilder
    private var faceIDSecuritySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("安全性").font(.subheadline).bold().padding([.horizontal, .top])
            ToggleRow(
                title: "欺骗检测",
                description: "Block photos, videos, or screen captures from unlocking Face ID.",
                isOn: $settings.settings.faceIDAntiSpoofEnabled
            )
            Divider().padding(.leading, 20)
            CustomSliderRowView(
                label: "欺骗锁定持续时间",
                value: $settings.settings.faceIDSpoofLockDuration,
                range: 1...15,
                specifier: "%.0f sec"
            )
            Text("在持续清晰的欺骗检测（不是边界帧）后锁定面容 ID 并要求输入密码。")
                .font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 4)
            Divider().padding(.leading, 20)
            CustomSliderRowView(
                label: "不匹配超时",
                value: $settings.settings.faceIDMismatchTimeout,
                range: 5...120,
                specifier: "%.0f sec"
            )
            Text("当您的脸部长时间未被识别时，会停止 Face ID 扫描。")
                .font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 8)
            Divider().padding(.horizontal)
            Text("性能").font(.subheadline).bold().padding([.horizontal, .top])
            ToggleRow(
                title: "将模型保留在内存中",
                description: "Keep the face recognition and liveness models loaded between unlocks so Face ID recognizes you from the first camera frame.",
                isOn: $settings.settings.faceIDKeepModelsInMemory
            )
            Text(settings.settings.faceIDKeepModelsInMemory
                 ? "Uses about 150–180 MB more memory. Recognition starts about 0.3 s sooner on each unlock, and up to 2 s sooner when macOS has dropped its model cache (after a restart, update, or memory pressure). Released automatically if memory runs critically low."
                 : "Models load when Face ID starts and are freed when it ends, saving about 150–180 MB. Each unlock waits about 0.3 s for the models to load, up to 2 s when macOS has dropped its model cache.")
                .font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var bluetoothUnlockSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ToggleRow(
                title: "启用蓝牙解锁",
                description: "使用受信任的蓝牙设备自动锁定和解锁您的 Mac。",
                isOn: isBluetoothEnabled
            )
            .disabled(!authManager.isPasswordSet)

            Group {
                if settings.settings.bluetoothUnlockEnabled {
                    Divider().padding(.leading, 20)
                    deviceSelectionSection
                    Divider().padding(.horizontal)
                    sensitivitySection
                    Divider().padding(.horizontal)
                    advancedSection
                }
            }.transition(.opacity.combined(with: .move(edge: .top)))
        }
        .modifier(SettingsContainerModifier())
        .opacity(authManager.isPasswordSet ? 1.0 : 0.6)
        .animation(.default, value: settings.settings.bluetoothUnlockEnabled)
    }

    @ViewBuilder
    private var deviceSelectionSection: some View {
        let listHeight = min(maxDeviceListHeight, CGFloat(filteredScannedDevices.count) * deviceRowHeight)
        VStack(alignment: .leading, spacing: 10) {
            Text("可信设备").font(.subheadline).bold().padding(.horizontal)
            if let device = selectedDevice {
                DeviceRowView(device: device, isSelected: true) {}.padding(.horizontal)
                HStack {
                    pairingStatusView
                    Spacer()
                    Button("校准范围") { isCalibratingRSSI = true }
                    Button("忘记设备", role: .destructive) { authManager.forgetDevice() }
                }.padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Button(authManager.isScanning ? "Stop Scanning" : "Scan for Devices") {
                            if authManager.isScanning { authManager.stopScan() } else { authManager.startScan(includeUnnamed: showUnnamedDevices) }
                        }
                        if authManager.isScanning { ProgressView().scaleEffect(0.8).padding(.leading) }
                    }
                    Toggle(isOn: $showUnnamedDevices) { Text("显示未命名设备") }
                        .onChange(of: showUnnamedDevices) { _, newValue in authManager.updateScanFilter(includeUnnamed: newValue) }
                    if showUnnamedDevices && authManager.isScanning {
                        Button("按距离查找...") { isFindingByDistance = true }.font(.caption).padding(.top, 5).transition(.opacity)
                    }
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if authManager.scannedDevices.isEmpty && authManager.isScanning {
                                Text("Scanning...").font(.caption).foregroundColor(.secondary).frame(minHeight: 80)
                            } else if filteredScannedDevices.isEmpty {
                                 Text(showUnnamedDevices ? "No devices found. Ensure device is nearby and discoverable." : "No named devices found. Try enabling 'Show unnamed devices'.")
                                     .font(.caption).foregroundColor(.secondary).frame(minHeight: 80).padding(.horizontal).multilineTextAlignment(.center)
                            } else {
                                ForEach(filteredScannedDevices) { device in
                                    DeviceRowView(device: device) { authManager.selectDevice(uuid: device.id) }
                                    if device.id != filteredScannedDevices.last?.id { Divider().padding(.leading, 50) }
                                }
                            }
                        }
                    }
                    .frame(height: listHeight)
                    .background(Color.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .animation(.spring(), value: listHeight)
                }.padding(.horizontal).animation(.default, value: showUnnamedDevices)
            }
        }.padding(.vertical)
    }

    @ViewBuilder
    private var sensitivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("灵敏度").font(.subheadline).bold()
                if authManager.selectedDeviceID != nil {
                    Spacer()
                    let rssiString = authManager.lastRSSI.map { "\($0) dBm" } ?? "N/A"
                    Text("Current Signal: \(rssiString)").font(.caption).foregroundColor(.secondary)
                }
            }.padding(.horizontal)
            VStack(spacing: 0) {
                CustomSliderRowView(label: "解锁RSSI", value: Binding(get: { Double(settings.settings.bluetoothUnlockUnlockRSSI) }, set: { settings.settings.bluetoothUnlockUnlockRSSI = Int($0) }), range: -100...0, specifier: "%.0f dBm")
                Divider().padding(.leading, 20)
                CustomSliderRowView(label: "锁定RSSI", value: Binding(get: { Double(settings.settings.bluetoothUnlockLockRSSI) }, set: { settings.settings.bluetoothUnlockLockRSSI = Int($0) }), range: -100...0, specifier: "%.0f dBm")
            }.padding(.top, 5)
        }.padding(.vertical)
    }

    @ViewBuilder
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("高级").font(.subheadline).bold().padding(.horizontal)
            CustomSliderRowView(label: "延迟锁定", value: $settings.settings.bluetoothUnlockTimeout, range: 1...60, specifier: "%.0f sec")
            Divider().padding(.leading, 20)
            CustomSliderRowView(label: "无信号超时", value: $settings.settings.bluetoothUnlockNoSignalTimeout, range: 10...300, specifier: "%.0f sec")
            Divider().padding(.leading, 20)
            ToggleRow(title: "被动模式", description: "Uses less energy but may be slightly slower to react.", isOn: $settings.settings.bluetoothUnlockPassiveMode)
            Divider().padding(.leading, 20)
            CustomSliderRowView(label: "最小扫描RSSI", value: Binding(get: { Double(settings.settings.bluetoothUnlockMinScanRSSI) }, set: { settings.settings.bluetoothUnlockMinScanRSSI = Int($0) }), range: -100 ... -30, specifier: "%.0f dBm")
        }.padding(.vertical)
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("锁定和解锁操作").font(.headline).padding([.top, .horizontal])
            ToggleRow(title: "接近唤醒", description: "Wake the screen when your device comes into range.", isOn: $settings.settings.bluetoothUnlockWakeOnProximity)
            Divider().padding(.leading, 20)
            ToggleRow(title: "无需解锁即可唤醒", description: "Only wake the screen, do not enter the password.", isOn: $settings.settings.bluetoothUnlockWakeWithoutUnlocking)
            Divider().padding(.leading, 20)
            ToggleRow(title: "Pause \"Now Playing\" while Locked", description: "Automatically pauses music or videos when the screen locks.", isOn: $settings.settings.bluetoothUnlockPauseMusicOnLock)
            Divider().padding(.leading, 20)
            ToggleRow(title: "使用屏幕保护程序锁定", description: "Starts the screensaver instead of showing the lock screen.", isOn: $settings.settings.bluetoothUnlockUseScreensaver)
            Divider().padding(.leading, 20)
            ToggleRow(title: "锁定时关闭屏幕", description: "Puts the display to sleep when locking.", isOn: $settings.settings.bluetoothUnlockTurnOffScreenOnLock)
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder
    private var pairingStatusView: some View {
        HStack(spacing: 4) {
            switch authManager.monitoredPeripheralState {
            case .connected: Image(systemName: "checkmark.shield.fill").foregroundColor(.green); Text("配对和监控")
            case .connecting: ProgressView().scaleEffect(0.5); Text("正在连接...")
            case .disconnecting: Image(systemName: "xmark.shield.fill").foregroundColor(.gray); Text("正在断开连接...")
            case .disconnected: Image(systemName: "xmark.shield.fill").foregroundColor(.red); Text("超出范围")
            @unknown default: Image(systemName: "questionmark.circle.fill").foregroundColor(.gray); Text("未知状态")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

fileprivate struct DeviceRowView: View {
    let device: Device
    var isSelected: Bool = false
    let action: () -> Void

    private var truncatedUUID: String {
        let fullUUID = device.id.uuidString
        return "\(fullUUID.prefix(8))...\(fullUUID.suffix(4))"
    }

    private func iconForDevice() -> String {
        if let name = device.peripheral?.name, let icon = IconMapper.icon(forName: name) {
            return icon
        }
        return "wave.3.right.circle"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: iconForDevice())
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 1) {
                    Text(device.displayName)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundColor(isSelected ? .accentColor : .primary)
                        .lineLimit(1)

                    Text(truncatedUUID)
                        .font(.caption2.monospaced())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(device.rssi) dBm")
                    .font(.caption.monospaced())
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct FindDeviceByDistanceWizard: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authManager = AuthenticationManager.shared

    @State private var wizardStep = 1
    @State private var closeReadings: [UUID: Int] = [:]
    @State private var countdown = 30
    @State private var timer: Timer?
    @State private var results: [DetectionResult] = []

    struct DetectionResult: Identifiable {
        let id: UUID
        let device: Device
        let score: Double
        let label: String
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("按距离查找设备").font(.largeTitle.bold())

            switch wizardStep {
            case 1: step1
            case 2: step2
            case 3: step3
            default: Text("发生错误。")
            }
        }
        .frame(width: 450, height: 400)
        .padding()
        .onAppear { authManager.startScan(includeUnnamed: true) }
        .onDisappear {
            timer?.invalidate()
            authManager.stopScan()
        }
    }

    @ViewBuilder
    private var step1: some View {
        Image(systemName: "arrow.down.to.line.compact").font(.system(size: 40)).foregroundColor(.accentColor)
        Text("第 1 步：靠近设备").font(.title2)
        Text("将所需的设备尽可能靠近 Mac，然后按“下一步”。").multilineTextAlignment(.center).foregroundColor(.secondary)

        let strongestDevice = authManager.scannedDevices.max(by: { $0.rssi < $1.rssi })
        Text("Strongest Signal: \(strongestDevice?.displayName ?? "None") at \(strongestDevice?.rssi ?? -100) dBm")
            .font(.body.bold()).padding()

        Button("Next") {
            self.closeReadings = Dictionary(uniqueKeysWithValues: authManager.scannedDevices.map { ($0.id, $0.rssi) })
            self.wizardStep = 2
            startCountdown()
        }.buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private var step2: some View {
        Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle").font(.system(size: 40)).foregroundColor(.accentColor)
        Text("第 2 步：将设备移至远处").font(.title2)
        Text("现在，将设备移至约 3 米（10 英尺）远的地方。扫描将自动完成。").multilineTextAlignment(.center).foregroundColor(.secondary)

        Text("Time remaining: \(countdown)s")
            .font(.title3.bold().monospacedDigit()).padding()
        ProgressView(value: Double(30 - countdown), total: 30).frame(width: 200)
    }

    @ViewBuilder
    private var step3: some View {
        Image(systemName: "checkmark.shield.fill").font(.system(size: 40)).foregroundColor(.green)
        Text("第 3 步：选择您的设备").font(.title2)
        Text("根据信号变化，以下是最有可能的候选者。").multilineTextAlignment(.center).foregroundColor(.secondary)

        if results.isEmpty {
            Text("没有设备显示距离有显着变化。").foregroundColor(.secondary).padding()
        } else {
            List(results) { result in
                Button(action: {
                    authManager.selectDevice(uuid: result.id)
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(result.device.displayName)
                            Text(result.label)
                                .font(.caption)
                                .foregroundColor(labelColor(for: result.label))
                        }
                        Spacer()
                        Text(String(format: "%.0f", result.score))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                }.buttonStyle(.plain)
            }
        }

        Button("Done") { dismiss() }.padding(.top)
    }

    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
                calculateResults()
                wizardStep = 3
            }
        }
    }

    private func calculateResults() {
        let farReadings = Dictionary(uniqueKeysWithValues: authManager.scannedDevices.map { ($0.id, $0.rssi) })
        var calculatedResults: [DetectionResult] = []

        for (id, closeRSSI) in closeReadings {
            guard let farRSSI = farReadings[id], let device = authManager.scannedDevices.first(where: { $0.id == id }) else { continue }

            let delta = Double(closeRSSI - farRSSI)
            let closeQuality = max(0, min(1, Double(closeRSSI + 85) / 30.0))

            if delta > 5 && closeQuality > 0.2 {
                let score = (delta * 0.7) + (closeQuality * 30 * 0.3)

                let label: String
                if score > 40 { label = "Highly Likely" }
                else if score > 25 { label = "Likely" }
                else { label = "Low Chance" }

                calculatedResults.append(DetectionResult(id: id, device: device, score: score, label: label))
            }
        }

        self.results = calculatedResults.sorted { $0.score > $1.score }
    }

    private func labelColor(for label: String) -> Color {
        switch label {
        case "Highly Likely": return .green
        case "Likely": return .orange
        default: return .secondary
        }
    }
}

fileprivate struct CalibrateRSSIView: View {
    @Environment(\.dismiss) var dismiss
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var authManager = AuthenticationManager.shared

    @State private var wizardStep = 1
    @State private var countdown = 5
    @State private var timer: Timer?
    @State private var rssiReadings: [Int] = []

    @State private var nearRSSI: Int?
    @State private var farRSSI: Int?

    @State private var isMeasuring = false

    @State private var calibratingDevice: Device?

    private var currentDeviceRSSI: Int? {
        if let device = calibratingDevice,
           let updatedDevice = authManager.scannedDevices.first(where: { $0.id == device.id }) {
            return updatedDevice.rssi
        }
        return calibratingDevice?.rssi
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("校准 RSSI 范围").font(.largeTitle.bold())

            switch wizardStep {
            case 1: step1Near
            case 2: step2Far
            case 3: step3Results
            default: Text("发生错误。")
            }
        }
        .frame(width: 450, height: 400)
        .padding()
        .onAppear {
            if let selectedIDString = authManager.selectedDeviceID,
               let selectedID = UUID(uuidString: selectedIDString) {
                self.calibratingDevice = authManager.scannedDevices.first { $0.id == selectedID }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    @ViewBuilder
    private var step1Near: some View {
        Image(systemName: "arrow.down.to.line.compact").font(.system(size: 40)).foregroundColor(.accentColor)
        Text("第 1 步：校准“近距离”距离").font(.title2)
        Text("将设备放在 Mac 解锁时通常使用的位置（例如，触控板旁边）。").multilineTextAlignment(.center).foregroundColor(.secondary)

        let rssiString = currentDeviceRSSI.map { "\($0) dBm" } ?? "Waiting for signal..."

        if isMeasuring {
            VStack {
                ProgressView("Measuring...", value: Double(5 - countdown), total: 5)
                Text("Current Signal: \(rssiString)")
                    .font(.body.bold().monospacedDigit()).padding()
            }
        } else {
             Text("Current Signal: \(rssiString)")
                .font(.body.bold().monospacedDigit()).padding()
        }

        Button(isMeasuring ? "Measuring..." : "Start Near Calibration") {
            startMeasurement { avgRSSI in
                self.nearRSSI = avgRSSI
                self.wizardStep = 2
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isMeasuring || calibratingDevice == nil)
    }

    @ViewBuilder
    private var step2Far: some View {
        Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle").font(.system(size: 40)).foregroundColor(.accentColor)
        Text("第 2 步：校准“远”距离").font(.title2)
        Text("现在，将设备移至您希望 Mac 自动锁定的距离。").multilineTextAlignment(.center).foregroundColor(.secondary)

        let rssiString = currentDeviceRSSI.map { "\($0) dBm" } ?? "Waiting for signal..."

        if isMeasuring {
            VStack {
                ProgressView("Measuring...", value: Double(5 - countdown), total: 5)
                Text("Current Signal: \(rssiString)")
                    .font(.body.bold().monospacedDigit()).padding()
            }
        } else {
             Text("Current Signal: \(rssiString)")
                .font(.body.bold().monospacedDigit()).padding()
        }

        Button(isMeasuring ? "Measuring..." : "Start Far Calibration") {
            startMeasurement { avgRSSI in
                self.farRSSI = avgRSSI
                self.wizardStep = 3
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isMeasuring || calibratingDevice == nil)
    }

    @ViewBuilder
    private var step3Results: some View {
        Image(systemName: "checkmark.shield.fill").font(.system(size: 40)).foregroundColor(.green)
        Text("Calibration Complete").font(.title2)
        Text("以下是根据您的测量结果建议的设置。").multilineTextAlignment(.center).foregroundColor(.secondary)

        if let near = nearRSSI, let far = farRSSI {
            let suggestedUnlock = min(-10, near + 5)
            let suggestedLock = max(-100, far - 5)

            VStack(alignment: .leading, spacing: 15) {
                Text("Measured Average 'Near' Signal: **\(near) dBm**")
                Text("Measured Average 'Far' Signal: **\(far) dBm**")
                Divider()
                Text("Suggested Unlock RSSI: **\(suggestedUnlock) dBm**")
                    .foregroundColor(.green)
                Text("Suggested Lock RSSI: **\(suggestedLock) dBm**")
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)

            HStack {
                Button("Done") { dismiss() }

                Spacer()

                Button("应用设置") {
                    var updated = settings.settings.value
                    updated.bluetoothUnlockUnlockRSSI = suggestedUnlock
                    updated.bluetoothUnlockLockRSSI = suggestedLock
                    settings.settings.value = updated
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
            .padding(.top)

        } else {
            Text("测量数据缺失。请再试一次。")
                .foregroundColor(.red)
            Button("重新启动") {
                wizardStep = 1
            }
        }
    }

    private func startMeasurement(completion: @escaping (Int) -> Void) {
        isMeasuring = true
        rssiReadings.removeAll()
        countdown = 5

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            if let rssi = currentDeviceRSSI {
                rssiReadings.append(rssi)
            }

            if countdown > 1 {
                countdown -= 1
            } else {
                timer?.invalidate()
                isMeasuring = false

                if !rssiReadings.isEmpty {
                    let average = rssiReadings.reduce(0, +) / rssiReadings.count
                    completion(average)
                } else {
                    completion(currentDeviceRSSI ?? -75)
                }
            }
        }
    }
}

struct FanControlSectionView: View {
    @ObservedObject private var fanManager = FanManager.shared
    @State private var fanToEditID: Int?

    private var isSheetPresented: Binding<Bool> {
        Binding<Bool>(
            get: { self.fanToEditID != nil },
            set: { isShowing in
                if !isShowing {
                    self.fanToEditID = nil
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("风扇控制").font(.headline).padding([.top, .horizontal])

            InfoContainer(text: "Fan control is in beta. Idle fans at 0 RPM are normal", iconName: "fanblades.fill", color: .orange)
                .padding()

            if fanManager.fans.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("该系统上未检测到风扇。")
                        .foregroundColor(.secondary)
                    Text("无风扇 Mac（某些 MacBook Air 型号）将永久显示此信息。否则，请确保安装了 Sapphire 助手并重试。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("重试检测") {
                        Task { await fanManager.refreshHardwareState(forceRediscovery: true) }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                ForEach($fanManager.fans) { $fan in
                    FanRowView(fan: $fan, onCustomize: { fanToEditID = fan.id })
                    if fan.id != fanManager.fans.last?.id {
                        Divider().padding(.leading, 20)
                    }
                }
                if fanManager.hasNonAutomaticFans {
                    HStack {
                        Text("当蓝宝石退出时，风扇恢复自动状态。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("全部重置为自动") { fanManager.resetAllFansToAutomatic() }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
        }
        .modifier(SettingsContainerModifier())
        .sheet(isPresented: isSheetPresented) {
            if let id = fanToEditID, let fanIndex = fanManager.fans.firstIndex(where: { $0.id == id }) {
                FanControlSheetView(fan: $fanManager.fans[fanIndex], availableSensors: fanManager.sensors)
                    .environmentObject(fanManager)
            }
        }
        .environmentObject(fanManager)
        .onAppear { fanManager.beginPolling() }
        .onDisappear { fanManager.endPolling() }
    }
}

struct FanRowView: View {
    @Binding var fan: FanInfo
    let onCustomize: () -> Void
    @EnvironmentObject var fanManager: FanManager

    private var modeString: String {
        switch fanManager.fanModes[fan.id] {
        case .auto: return "Auto"
        case .constant(let rpm): return "Constant \(rpm) RPM"
        case .sensor(let key, _, _):
            return "Sensor: \(SensorNameMap.name(for: key))"
        case .customCurve(let key, let points):
            return "Curve (\(points.count) pts): \(SensorNameMap.name(for: key))"
        case nil: return "Auto"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(fan.name.contains("Fan") ? "Fan \(fan.id + 1)" : fan.name)
                    .font(.headline)

                Text("Min: \(fan.minRPM) | Current: \(fan.currentRPM) | Max: \(fan.maxRPM) RPM")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)

                Text(modeString)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            Spacer()
            Button("定制...") { onCustomize() }
        }
        .padding()
    }
}

struct FanControlSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var fanManager: FanManager
    @Binding var fan: FanInfo
    let availableSensors: [TemperatureSensor]

    @State private var selectedMode: Int
    @State private var constantRPM: Double
    @State private var sensorKey: String
    @State private var minTemp: Double
    @State private var maxTemp: Double
    @State private var curvePoints: [FanCurvePoint]

    init(fan: Binding<FanInfo>, availableSensors: [TemperatureSensor]) {
        self._fan = fan
        self.availableSensors = availableSensors

        let initialMode = FanManager.shared.fanModes[fan.wrappedValue.id] ?? .auto

        switch initialMode {
        case .auto:
            _selectedMode = State(initialValue: 0)
            _constantRPM = State(initialValue: Double(fan.wrappedValue.minRPM))
            _sensorKey = State(initialValue: availableSensors.first?.key ?? "")
            _minTemp = State(initialValue: 40)
            _maxTemp = State(initialValue: 75)
            _curvePoints = State(initialValue: FanManager.defaultCurvePoints(for: fan.wrappedValue))
        case .constant(let rpm):
            _selectedMode = State(initialValue: 1)
            _constantRPM = State(initialValue: Double(rpm))
            _sensorKey = State(initialValue: availableSensors.first?.key ?? "")
            _minTemp = State(initialValue: 40)
            _maxTemp = State(initialValue: 75)
            _curvePoints = State(initialValue: FanManager.defaultCurvePoints(for: fan.wrappedValue))
        case .sensor(let key, let minT, let maxT):
            _selectedMode = State(initialValue: 2)
            _constantRPM = State(initialValue: Double(fan.wrappedValue.minRPM))
            _sensorKey = State(initialValue: key)
            _minTemp = State(initialValue: Double(minT))
            _maxTemp = State(initialValue: Double(maxT))
            _curvePoints = State(initialValue: FanManager.defaultCurvePoints(for: fan.wrappedValue))
        case .customCurve(let key, let points):
            _selectedMode = State(initialValue: 3)
            _constantRPM = State(initialValue: Double(fan.wrappedValue.minRPM))
            _sensorKey = State(initialValue: key)
            _minTemp = State(initialValue: 40)
            _maxTemp = State(initialValue: 75)
            _curvePoints = State(initialValue: points.isEmpty ? FanManager.defaultCurvePoints(for: fan.wrappedValue) : points)
        }
    }

    private var selectedSensorValueString: String {
        if let sensor = availableSensors.first(where: { $0.key == sensorKey }) {
            return String(format: "%.1f°C", sensor.value)
        }
        return "N/A"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Change Fan Control for '\(fan.name.contains("Fan") ? "Fan \(fan.id + 1)" : fan.name)'")
                .font(.title2.bold())

            Picker("控制方式", selection: $selectedMode) {
                Text("Automatic").tag(0)
                Text("恒定转速").tag(1)
                Text("基于传感器").tag(2)
                Text("自定义曲线").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.bottom)

            if selectedMode == 1 {
                VStack {
                    CustomSliderRowView(label: "风扇速度", value: $constantRPM, range: Double(fan.minRPM)...Double(fan.maxRPM), specifier: "%.0f RPM")
                }
            } else if selectedMode == 2 {
                sensorPickerSection
                CustomSliderRowView(label: "从以下位置开始增加：", value: $minTemp, range: 20...100, specifier: "%.0f °C")
                    .onChange(of: minTemp) {
                        if minTemp > maxTemp { maxTemp = minTemp }
                    }
                CustomSliderRowView(label: "最高温度：", value: $maxTemp, range: 20...100, specifier: "%.0f °C")
                    .onChange(of: maxTemp) {
                        if maxTemp < minTemp { minTemp = maxTemp }
                    }
            } else if selectedMode == 3 {
                sensorPickerSection
                FanCurveEditorView(fan: fan, points: $curvePoints)
            } else {
                Text("风扇将由 macOS 自动控制。")
                    .foregroundColor(.secondary)
                    .frame(minHeight: 150, alignment: .center)
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("OK") { saveAndDismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 580)
        .frame(minHeight: selectedMode == 3 ? 520 : 350)
    }

    @ViewBuilder
    private var sensorPickerSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("基于传感器：")
                Spacer()
                Picker("传感器", selection: $sensorKey) {
                    ForEach(availableSensors) { sensor in
                        HStack {
                            Text(sensor.name)
                            Spacer()
                            Text(String(format: "%.1f°C", sensor.value))
                                .foregroundColor(.secondary)
                        }.tag(sensor.key)
                    }
                }
                Text(selectedSensorValueString)
                    .font(.body.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }

    private func saveAndDismiss() {
        let newMode: FanControlMode
        switch selectedMode {
        case 1:
            newMode = .constant(rpm: Int(constantRPM))
        case 2:
            newMode = .sensor(sensorKey: sensorKey, minTemp: Int(minTemp), maxTemp: Int(maxTemp))
        case 3:
            let sortedPoints = curvePoints.sorted { $0.temperature < $1.temperature }
            newMode = .customCurve(sensorKey: sensorKey, points: sortedPoints)
        default:
            newMode = .auto
        }
        fanManager.setFanMode(for: fan.id, to: newMode)
        dismiss()
    }
}

private struct FanCurveEditorView: View {
    let fan: FanInfo
    @Binding var points: [FanCurvePoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("自定义风扇曲线").font(.headline)
                Spacer()
                Button("重置") {
                    points = FanManager.defaultCurvePoints(for: fan)
                }
                .buttonStyle(.borderless)
            }

            Text("设置每个温度下的 RPM。蓝宝石在点之间进行插值。")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                VStack(spacing: 8) {
                    CustomSliderRowView(
                        label: "Point \(index + 1) Temperature",
                        value: Binding(
                            get: { Double(points[index].temperature) },
                            set: { points[index].temperature = Int($0) }
                        ),
                        range: 20...100,
                        specifier: "%.0f °C"
                    )
                    CustomSliderRowView(
                        label: "Point \(index + 1) RPM",
                        value: Binding(
                            get: { Double(points[index].rpm) },
                            set: { points[index].rpm = Int($0) }
                        ),
                        range: Double(fan.minRPM)...Double(fan.maxRPM),
                        specifier: "%.0f RPM"
                    )
                    if points.count > 2 {
                        Button("删除点", role: .destructive) {
                            points.remove(at: index)
                        }
                        .font(.caption)
                    }
                }
                if index < points.count - 1 {
                    Divider()
                }
            }

            if points.count < 6 {
                Button {
                    let lastTemp = points.last?.temperature ?? 60
                    let lastRPM = points.last?.rpm ?? fan.minRPM
                    points.append(FanCurvePoint(temperature: min(lastTemp + 10, 95), rpm: min(lastRPM + 500, fan.maxRPM)))
                } label: {
                    Label("添加点", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

struct CalibrationView: View {
    @StateObject private var calibrationManager = CalibrationManager.shared
    @StateObject private var batteryMonitor = BatteryMonitor.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("电池校准").font(.headline).padding([.top, .horizontal])
            InfoContainer(
                text: "Calibrating your battery helps macOS get a more accurate reading of its health and time remaining. This process can take several hours and involves a full charge and discharge cycle. Sleeping will be disabled during calibration.",
                iconName: "gauge.high",
                color: .purple
            ).padding()

            VStack(spacing: 15) {
                if calibrationManager.isActive {
                    VStack(spacing: 8) {
                        Text(calibrationManager.state.description)
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ProgressView(value: calibrationManager.progress)
                            .progressViewStyle(.linear)

                        Text(String(format: "%.1f%% complete", calibrationManager.progress * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("取消校准", role: .destructive) {
                            calibrationManager.cancel()
                        }
                        .padding(.top, 5)
                    }

                } else {
                    VStack(spacing: 12) {
                        if calibrationManager.state == .done {
                             Text("校准成功完成。")
                                .foregroundColor(.green)
                        } else if case .error(let message) = calibrationManager.state {
                            Text(message)
                                .foregroundColor(.red)
                        }

                        Text("开始之前请确保 Mac 已插入电源。在此过程中，请勿拔下 Mac 电源插头或让 Mac 进入睡眠状态。")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: {
                            calibrationManager.start()
                        }) {
                            Text("Start Calibration")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(batteryMonitor.currentState?.isPluggedIn == false)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .modifier(SettingsContainerModifier())
    }
}

struct LidAngleCaffeineSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var lidAngleSensor = LidAngleSensor.shared

    private var caffeineTriggerAngleBinding: Binding<Double> {
        $settings.settings.caffeinateLidAngleTrigger
    }

    private var currentAngleText: String {
        guard lidAngleSensor.isAvailable else { return "Unavailable" }
        return "\(Int(lidAngleSensor.angle.rounded()))°"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ToggleRow(
                title: "使用盖子角度遮光显示",
                description: "While caffeinated, set brightness to zero when the lid reaches the trigger angle. This does not put the display to sleep.",
                isOn: $settings.settings.caffeinateTurnOffScreenUsingLidAngle
            )

            Divider().padding(.leading, 20)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前盖子角度")
                    Text(lidAngleSensor.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(currentAngleText)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(lidAngleSensor.isAvailable ? .primary : .secondary)
            }
            .padding()

            if settings.settings.caffeinateTurnOffScreenUsingLidAngle {
                Divider().padding(.leading, 20)
                CustomSliderRowView(
                    label: "触发角度",
                    value: caffeineTriggerAngleBinding,
                    range: 0...140,
                    specifier: "%.0f°"
                )
            }

            Divider().padding(.leading, 20)
            ToggleRow(
                title: "接近关闭时暂停媒体",
                description: "Automatically pause now playing media and resume when the lid opens back up.",
                isOn: $settings.settings.lidAnglePauseMediaEnabled
            )

            if settings.settings.lidAnglePauseMediaEnabled {
                Divider().padding(.leading, 20)
                CustomSliderRowView(
                    label: "暂停媒体触发",
                    value: $settings.settings.lidAnglePauseMediaTrigger,
                    range: 0...140,
                    specifier: "%.0f°"
                )
            }

            Divider().padding(.leading, 20)
            ToggleRow(
                title: "接近关闭时将系统音频静音",
                description: "Mute all system output as the lid closes, then unmute when it opens past the threshold.",
                isOn: $settings.settings.lidAngleMuteAudioEnabled
            )

            if settings.settings.lidAngleMuteAudioEnabled {
                Divider().padding(.leading, 20)
                CustomSliderRowView(
                    label: "静音音频触发",
                    value: $settings.settings.lidAngleMuteAudioTrigger,
                    range: 0...140,
                    specifier: "%.0f°"
                )
            }

            Divider().padding(.leading, 20)
            ToggleRow(
                title: "接近关闭时的睡眠显示",
                description: "Put the display into real macOS display sleep when the lid drops below the chosen angle, then wake it again when reopened. This will attempt to keep caffinate activated while the display is sleeping.",
                isOn: $settings.settings.lidAngleSleepDisplayEnabled
            )

            if settings.settings.lidAngleSleepDisplayEnabled {
                Divider().padding(.leading, 20)
                CustomSliderRowView(
                    label: "显示睡眠触发",
                    value: $settings.settings.lidAngleSleepDisplayTrigger,
                    range: 0...140,
                    specifier: "%.0f°"
                )
            }

            Divider().padding(.leading, 20)
            ToggleRow(
                title: "盖子关闭时启用低功耗模式",
                description: "Force Low Power Mode while the lid is partially closed and restore the previous state when reopened.",
                isOn: $settings.settings.lidAngleLowPowerModeEnabled
            )

            if settings.settings.lidAngleLowPowerModeEnabled {
                Divider().padding(.leading, 20)
                CustomSliderRowView(
                    label: "低功率触发",
                    value: $settings.settings.lidAngleLowPowerModeTrigger,
                    range: 0...140,
                    specifier: "%.0f°"
                )
            }

        }
        .modifier(SettingsContainerModifier())
        .onAppear {
            lidAngleSensor.acquire(.caffeineSettingsPreview)
        }
        .onDisappear {
            lidAngleSensor.release(.caffeineSettingsPreview)
        }
    }

}

struct BatterySettingsView: View {
    @State private var selectedTab: String = "Statistics"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                Text("Battery").font(.largeTitle.bold()).padding(.bottom, 10)
                ModernSegmentedPicker(
                    selection: $selectedTab,
                    options: ["Statistics", "Configuration"]
                )
                .padding(.bottom, 5)

            }
            .padding(.horizontal, 25).padding(.top, 25)

            Spacer()

            if selectedTab == "Statistics" {
                ModernBatteryStatsView()
            } else {
                BatteryConfigurationView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(NotificationCenter.default.publisher(for: .sapphireSettingsWillClose)) { _ in
            selectedTab = "Configuration"
        }
    }
}

struct DateRangePickerView: View {
    @Binding var selection: TimeRange

    @State private var showCustomPicker = false

    @State private var customStartDate: Date
    @State private var customEndDate: Date

    @Namespace private var datePickerNamespace

    init(selection: Binding<TimeRange>) {
        self._selection = selection

        if case .custom(let start, let end) = selection.wrappedValue {
            _customStartDate = State(initialValue: start)
            _customEndDate = State(initialValue: end)
        } else {
            _customStartDate = State(initialValue: Date())
            _customEndDate = State(initialValue: Date())
        }
    }

    private var isCustomSelected: Bool {
        if case .custom = selection {
            return true
        }
        return false
    }

    var body: some View {
        HStack(spacing: 8) {

            PickerButton(label: "24h", isSelected: selection == .last24Hours, namespace: datePickerNamespace) {
                updateSelection(.last24Hours)
            }
            PickerButton(label: "7d", isSelected: selection == .last7Days, namespace: datePickerNamespace) {
                updateSelection(.last7Days)
            }
            PickerButton(label: "Month", isSelected: selection == .lastMonth, namespace: datePickerNamespace) {
                updateSelection(.lastMonth)
            }
            PickerButton(label: "Year", isSelected: selection == .lastYear, namespace: datePickerNamespace) {
                updateSelection(.lastYear)
            }

            PickerButton(label: "Custom", isSelected: isCustomSelected, namespace: datePickerNamespace) {
                showCustomPicker = true
            }
            .popover(isPresented: $showCustomPicker, attachmentAnchor: .point(.bottom)) {
                customDatePickerView
            }
        }
        .padding(5)
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func updateSelection(_ newSelection: TimeRange) {
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.7)) {
            selection = newSelection
        }
    }

    private var customDatePickerView: some View {
        VStack(spacing: 15) {
            Text("选择自定义范围")
                .font(.headline)

            DatePicker("Start Date", selection: $customStartDate, in: ...customEndDate, displayedComponents: .date)
            DatePicker("End Date", selection: $customEndDate, in: ...Date(), displayedComponents: .date)

            Button("申请") {
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.7)) {
                    selection = .custom(customStartDate, customEndDate)
                }
                showCustomPicker = false
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(minWidth: 250)
    }
}

fileprivate struct PickerButton: View {
    let label: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Text(label)
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            .matchedGeometryEffect(id: "datePickerPill", in: namespace)
                    }
                }
            )
            .foregroundColor(isSelected ? .primary : .secondary)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
}

struct HeroMetricsView: View {
    @ObservedObject var viewModel: BatteryStatsViewModel
    private var statusColor: Color {
        if viewModel.isCharging { return MaterialChartPalette.tertiary }
        if viewModel.batteryLevel < 20 { return MaterialChartPalette.error }
        if viewModel.batteryLevel < 50 { return MaterialChartPalette.warning }
        return MaterialChartPalette.primary
    }

    private var metricColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    private var chargingStatusValue: String {
        if viewModel.isCharging {
            let watts = abs(viewModel.powerConsumption)
            return watts > 0 ? String(format: "%.1f W", watts) : "Active"
        }
        return viewModel.timeRemaining
    }

    private var batteryLevelLabel: Text {
        Text("\(viewModel.batteryLevel)")
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .foregroundStyle(statusColor)
        + Text("%")
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .foregroundStyle(statusColor.opacity(0.7))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Battery")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                batteryLevelLabel
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                MaterialStatChip(
                    label: viewModel.isCharging ? "Charging" : "On Battery",
                    value: chargingStatusValue,
                    color: statusColor,
                    icon: viewModel.isCharging ? "bolt.fill" : "battery.100"
                )
            }
            .fixedSize(horizontal: true, vertical: false)

            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 10) {
                MaterialStatChip(label: "Time Remaining", value: viewModel.timeRemaining, color: MaterialChartPalette.primary, icon: "clock.fill")
                MaterialStatChip(label: "健康", value: "\(viewModel.maxCapacityPercentage)%", color: Color.pink, icon: "heart.fill")
                MaterialStatChip(label: "Cycles", value: "\(viewModel.cycleCount)", color: MaterialChartPalette.secondary, icon: "arrow.triangle.2.circlepath")
                MaterialStatChip(label: "Temperature", value: String(format: "%.1f°C", viewModel.temperature), color: MaterialChartPalette.error, icon: "thermometer.medium")
                MaterialStatChip(label: "Power", value: String(format: "%.1f W", abs(viewModel.powerConsumption)), color: MaterialChartPalette.warning, icon: "bolt.fill")
                MaterialStatChip(label: "Voltage", value: String(format: "%.2f V", viewModel.voltage / 1000.0), color: MaterialChartPalette.tertiary, icon: "wave.3.right")
                MaterialStatChip(label: "Current", value: String(format: "%.2f A", Double(abs(viewModel.amperage)) / 1000.0), color: MaterialChartPalette.primary, icon: "arrow.left.arrow.right")
                MaterialStatChip(label: "条件", value: viewModel.health, color: .pink, icon: "heart.text.square")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .materialChartCard(accent: statusColor)
    }
}

struct SpecRow: View {
    let label: String, value: String, percentage: String?
    init(label: String, value: String, percentage: String? = nil) {
        self.label = label; self.value = value; self.percentage = percentage
    }
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 72, alignment: .trailing)
            Text(percentage ?? "")
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(percentage == nil ? .clear : .primary)
                .frame(width: 44, alignment: .trailing)
        }
        .font(.system(size: 12, design: .rounded))
    }
}

struct ComponentPowerBreakdownView: View {
    @ObservedObject var viewModel: BatteryStatsViewModel
    @ObservedObject private var statsManager = StatsManager.shared

    private static func finite(_ v: Double) -> Double {
        guard v.isFinite else { return 0 }
        return max(0, v)
    }

    private var systemLoad: Double { Self.finite(statsManager.currentStats?.systemPower ?? viewModel.powerConsumption) }
    private var batteryPower: Double { Self.finite(statsManager.currentStats?.batteryPower ?? viewModel.powerConsumption) }
    private var chargingPower: Double { (viewModel.isCharging && batteryPower < 0) ? abs(batteryPower) : 0 }
    private var adapterPower: Double { Self.finite(statsManager.currentStats?.sensors?.sensors.first { ["PDTR"].contains($0.key) }?.value ?? 0) }
    private var cpuPower: Double { Self.finite(statsManager.currentStats?.sensors?.sensors.first { ["PCPC", "PCTR", "PC0C"].contains($0.key) }?.value ?? 0) }
    private var gpuPower: Double { Self.finite(statsManager.currentStats?.sensors?.sensors.first { ["PGTR", "PG0C", "PCGC"].contains($0.key) }?.value ?? 0) }
    private var displayPower: Double { max(0, systemLoad - (cpuPower + gpuPower)) * 0.4 }
    private var otherPower: Double { max(0, systemLoad - (cpuPower + gpuPower + displayPower)) }
    private var isCharging: Bool { viewModel.isCharging }
    private var adapterConnected: Bool { (viewModel.powerAdapterInfo?.maxPower ?? 0) > 0 }

    private var heroWatts: Double { adapterConnected ? max(adapterPower, systemLoad) : systemLoad }

    private var statusLabel: String {
        if isCharging { return "Charging" }
        if adapterConnected { return "On AC Power" }
        return "On Battery"
    }

    private var statusColor: Color {
        if isCharging { return MaterialChartPalette.tertiary }
        if adapterConnected { return MaterialChartPalette.primary }
        return MaterialChartPalette.warning
    }

    private var components: [(id: String, icon: String, title: String, power: Double, color: Color)] {
        var rows: [(id: String, icon: String, title: String, power: Double, color: Color)] = []
        if isCharging && chargingPower > 0.15 {
            rows.append(("charging", "battery.100.bolt", "Charging", chargingPower, MaterialChartPalette.tertiary))
        }
        if cpuPower > 0.35 {
            rows.append(("cpu", "cpu", "CPU", cpuPower, Color.cyan))
        }
        if gpuPower > 0.35 {
            rows.append(("gpu", "cube.fill", "GPU", gpuPower, MaterialChartPalette.secondary))
        }
        if displayPower > 0.35 {
            rows.append(("display", "display", "Display", displayPower, MaterialChartPalette.warning))
        }
        if otherPower > 0.35 {
            rows.append(("other", "ellipsis.circle", "Other", otherPower, MaterialChartPalette.onSurfaceVariant))
        }
        return rows
    }

    private var totalComponentPower: Double {
        max(components.reduce(0) { $0 + $1.power }, 0.001)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            powerHeroHeader
            if !components.isEmpty {
                shareStrip
                componentRows
            } else {
                Text("等待功率传感器...")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .materialChartCard(accent: statusColor)
        .onAppear {
            statsManager.setPolling(for: "ComponentBreakdown", requiredStats: [.systemPower, .batteryPower, .cpu, .gpu])
        }
        .onDisappear {
            statsManager.setPolling(for: "ComponentBreakdown", requiredStats: [])
        }
    }

    private var powerHeroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("System Power")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(statusLabel)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(statusColor)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(String(format: "%.2f", heroWatts))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text("W")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                    .padding(.bottom, 4)
                Spacer(minLength: 0)
                Image(systemName: adapterConnected ? "powerplug.fill" : "battery.100")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(statusColor.opacity(0.85))
            }

            Capsule()
                .fill(statusColor)
                .frame(height: 3)
                .frame(maxWidth: 120, alignment: .leading)

            if adapterConnected || isCharging {
                HStack(spacing: 12) {
                    if adapterConnected {
                        metaChip(icon: "bolt.horizontal.fill", text: String(format: "Adapter %.0f W", adapterPower > 0 ? adapterPower : heroWatts))
                    }
                    metaChip(icon: "laptopcomputer", text: String(format: "Draw %.2f W", systemLoad))
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var shareStrip: some View {
        GeometryReader { geo in
            HStack(spacing: 3) {
                ForEach(components, id: \.id) { row in
                    Capsule()
                        .fill(row.color)
                        .frame(width: max(4, geo.size.width * CGFloat(row.power / totalComponentPower)))
                }
            }
        }
        .frame(height: 6)
    }

    private var componentRows: some View {
        VStack(spacing: 12) {
            ForEach(components, id: \.id) { row in
                PowerShareRow(
                    icon: row.icon,
                    title: row.title,
                    power: row.power,
                    fraction: row.power / totalComponentPower,
                    color: row.color
                )
            }
        }
    }
}

struct PowerShareRow: View {
    let icon: String
    let title: String
    let power: Double
    let fraction: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Text(String(format: "%.2f W", power))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                Text(String(format: "%.0f%%", fraction * 100))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                    .frame(width: 36, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MaterialChartPalette.outline.opacity(0.55))
                        .frame(height: 3)
                    Capsule()
                        .fill(color)
                        .frame(width: max(3, geo.size.width * CGFloat(fraction)), height: 3)
                }
            }
            .frame(height: 3)
        }
    }
}

struct ModernBatteryStatsView: View {
    @StateObject private var viewModel = BatteryStatsViewModel()
    @StateObject private var historyViewModel = BatteryHistoryViewModel()
    @StateObject private var energyViewModel = EnergyViewModel()
    @StateObject private var helperManager = HelperManager.shared
    @ObservedObject private var debugMode = DebugMode.shared
    @State private var selectedTimeRange: TimeRange = .last24Hours

    private let mainGridLayout = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                if debugMode.isEnabled {
                    BatteryDebugMenu()
                }
                DateRangePickerView(selection: $selectedTimeRange)
                HStack(spacing: 15) {
                    HelperStatusBanner(helperManager: helperManager)
                }
                .padding()
                .materialChartCard(accent: helperManager.status == .enabled ? MaterialChartPalette.tertiary : MaterialChartPalette.warning)

                HeroMetricsView(viewModel: viewModel)

                ComponentPowerBreakdownView(viewModel: viewModel)

                BatteryHistoryView(historyViewModel: historyViewModel)

                LazyVGrid(columns: mainGridLayout, spacing: 20) {
                    MaxCapacityGraphCard(viewModel: viewModel, historyViewModel: historyViewModel, selectedTimeRange: $selectedTimeRange)
                    CycleCountGraphCard(viewModel: viewModel, historyViewModel: historyViewModel, selectedTimeRange: $selectedTimeRange)
                    TemperatureGraphCard(viewModel: viewModel, historyViewModel: historyViewModel, selectedTimeRange: $selectedTimeRange)
                    PowerTimeHistoryGraphView(historyViewModel: historyViewModel, selectedTimeRange: $selectedTimeRange)
                    BatteryHealthCard(viewModel: viewModel)
                    BatterySpecsCard(viewModel: viewModel)
                    PowerAdapterSpecsCard(viewModel: viewModel)
                    SignificantEnergyUsersView(viewModel: energyViewModel)
                }
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 25)
        }
        .onAppear {
            viewModel.start(highFrequency: true)
            StatsManager.shared.setPolling(for: "BatterySettingsView", requiredStats: [.batteryPower], interval: .seconds(1))
            historyViewModel.fetchHistory(filtering: selectedTimeRange)
            energyViewModel.start()
        }
        .onDisappear {
            tearDownBatteryStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sapphireSettingsWillClose)) { _ in
            tearDownBatteryStats()
        }
        .onReceive(BatteryDataLogger.shared.entriesDidChange) { _ in
            historyViewModel.fetchHistory(filtering: selectedTimeRange)
        }
        .onChange(of: selectedTimeRange) { _, newRange in
            historyViewModel.filterData(for: newRange)
        }
    }

    private func tearDownBatteryStats() {
        energyViewModel.stop()
        viewModel.stop()
        historyViewModel.releaseMemory()
        StatsManager.shared.setPolling(for: "BatterySettingsView", requiredStats: [])
    }
}

struct BatterySpecsCard: View {
    @ObservedObject var viewModel: BatteryStatsViewModel
    @ObservedObject private var statsManager = StatsManager.shared
    @ObservedObject private var powerModeManager = PowerModeManager.shared

    private var systemLoad: Double {
        statsManager.currentStats?.systemPower ?? abs(viewModel.powerConsumption)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill").foregroundStyle(MaterialChartPalette.warning)
                Text("电池规格").font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            Spacer()
            SpecRow(label: "Current", value: String(format: "%.1f A", Double(abs(viewModel.amperage)) / 1000.0))
            SpecRow(label: "Voltage", value: String(format: "%.1f V", viewModel.voltage / 1000.0))
            SpecRow(label: "Power", value: String(format: "%.0f W", abs(viewModel.powerConsumption)))
            SpecRow(label: "系统负载", value: String(format: "%.2f W", systemLoad))

            HStack {
                Text("Low Power Mode").font(.system(size: 12)).foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    if powerModeManager.isLowPowerModeActive {
                        powerModeManager.disableLowPowerMode()
                    } else {
                        powerModeManager.enableLowPowerMode()
                    }
                }) {
                    Text(powerModeManager.isLowPowerModeActive ? "Enabled" : "Disabled")
                        .font(.system(size: 12)).fontWeight(.medium)
                        .foregroundColor(powerModeManager.isLowPowerModeActive ? .green : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (powerModeManager.isLowPowerModeActive ? Color.green.opacity(0.15) : Color.white.opacity(0.08)),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(16)
        .materialChartCard(height: 180, accent: MaterialChartPalette.warning)
        .onAppear {
            statsManager.setPolling(for: "BatterySettings", requiredStats: [.systemPower, .batteryPower])
            _ = powerModeManager.isLowPowerModeEnabled()
        }
        .onDisappear {
            statsManager.setPolling(for: "BatterySettings", requiredStats: [])
        }
    }
}

private extension Array where Element == BatteryLogEntry {
    func closest(to date: Date) -> BatteryLogEntry? {
        self.min {
            abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
        }
    }
}

private struct BatteryMetricGraphCard<Value: Plottable & Comparable>: View {
    let title: String
    let currentValue: String
    let color: Color
    let chartData: [BatteryLogEntry]
    @Binding var selectedTimeRange: TimeRange
    let yDomain: ClosedRange<Value>
    let yAxisMarkCount: Int
    let metricLabel: String
    let metricValue: (BatteryLogEntry) -> Value
    let annotationText: (BatteryLogEntry) -> String

    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                Text(currentValue)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.14))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            Spacer()

            if chartData.isEmpty {
                EmptyStatsView(height: 150)
                    .padding(.horizontal, 16)
            } else {
                Chart {
                    ForEach(chartData) { entry in
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value(metricLabel, metricValue(entry))
                        )
                        .foregroundStyle(MaterialChartPalette.lineGradient(for: color))
                        .interpolationMethod(.linear)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                        AreaMark(
                            x: .value("Time", entry.timestamp),
                            y: .value(metricLabel, metricValue(entry))
                        )
                        .foregroundStyle(MaterialChartPalette.tonalGradient(for: color))
                        .interpolationMethod(.linear)
                    }

                    if let selectedDate, let entry = chartData.closest(to: selectedDate) {
                        PointMark(
                            x: .value("Time", entry.timestamp),
                            y: .value(metricLabel, metricValue(entry))
                        )
                        .foregroundStyle(color)
                        .symbolSize(80)

                        RuleMark(x: .value("Selected", selectedDate))
                            .foregroundStyle(MaterialChartPalette.outline)
                            .annotation(position: .top, alignment: .center) {
                                MaterialSelectionPill(text: annotationText(entry), color: color)
                            }
                    }
                }
                .materialChartPlotStyle()
                .chartYScale(domain: yDomain)
                .dynamicXAxis(for: selectedTimeRange, isVisible: true)
                .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: yAxisMarkCount)) }
                .chartXSelection(value: $selectedDate)
                .frame(height: 150)
                .padding(.horizontal, 12)
            }

            Spacer()
        }
        .materialChartCard(height: 220)
    }
}

struct MaxCapacityGraphCard: View {
    @ObservedObject var viewModel: BatteryStatsViewModel
    @ObservedObject var historyViewModel: BatteryHistoryViewModel
    @Binding var selectedTimeRange: TimeRange

    var body: some View {
        let chartData = historyViewModel.chartData.filter { $0.maxCapacity > 0 }
        let capacities = chartData.map(\.maxCapacity)

        BatteryMetricGraphCard(
            title: "Max Capacity",
            currentValue: "\(viewModel.maxCapacityPercentage)%",
            color: MaterialChartPalette.primary,
            chartData: chartData,
            selectedTimeRange: $selectedTimeRange,
            yDomain: ((capacities.min() ?? 0) - 50)...((capacities.max() ?? 8000) + 50),
            yAxisMarkCount: 3,
            metricLabel: "Capacity",
            metricValue: { $0.maxCapacity },
            annotationText: { "\($0.maxCapacity) mAh" }
        )
    }
}

struct CycleCountGraphCard: View {
    @ObservedObject var viewModel: BatteryStatsViewModel
    @ObservedObject var historyViewModel: BatteryHistoryViewModel
    @Binding var selectedTimeRange: TimeRange

    var body: some View {
        let chartData = historyViewModel.chartData.filter { $0.cycleCount > 0 }
        let cycles = chartData.map(\.cycleCount)

        BatteryMetricGraphCard(
            title: "Cycle Count",
            currentValue: "\(viewModel.cycleCount)",
            color: MaterialChartPalette.secondary,
            chartData: chartData,
            selectedTimeRange: $selectedTimeRange,
            yDomain: ((cycles.min() ?? 0) - 10)...((cycles.max() ?? 1000) + 10),
            yAxisMarkCount: 3,
            metricLabel: "Cycles",
            metricValue: { $0.cycleCount },
            annotationText: { "\($0.cycleCount) cycles" }
        )
    }
}

struct TemperatureGraphCard: View {
    @ObservedObject var viewModel: BatteryStatsViewModel
    @ObservedObject var historyViewModel: BatteryHistoryViewModel
    @Binding var selectedTimeRange: TimeRange

    var body: some View {
        BatteryMetricGraphCard(
            title: "Temperature",
            currentValue: String(format: "%.1f °C", viewModel.temperature),
            color: MaterialChartPalette.error,
            chartData: historyViewModel.chartData.filter { $0.temperature > 0 },
            selectedTimeRange: $selectedTimeRange,
            yDomain: 20...55,
            yAxisMarkCount: 4,
            metricLabel: "Temp",
            metricValue: { $0.temperature },
            annotationText: { String(format: "%.1f °C", $0.temperature) }
        )
    }
}

struct PowerTimeHistoryGraphView: View {
    @ObservedObject var historyViewModel: BatteryHistoryViewModel
    @Binding var selectedTimeRange: TimeRange
    @State private var selectedDate: Date?

    var body: some View {
        let powerData = historyViewModel.chartData.filter { $0.powerConsumption > 0 }
        let timeData = historyViewModel.chartData.filter { $0.timeRemainingMinutes > 0 }

        VStack(alignment: .leading, spacing: 0) {
            Text("功率与时间")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .padding(.horizontal, 18)
                .padding(.top, 16)

            Spacer()

            if powerData.isEmpty && timeData.isEmpty {
                EmptyStatsView(height: 150)
                    .padding(.horizontal, 16)
            } else {
                Chart {
                    ForEach(powerData) { entry in
                        LineMark(x: .value("Time", entry.timestamp), y: .value("Power", entry.powerConsumption))
                            .foregroundStyle(by: .value("Metric", "Power (W)"))
                            .interpolationMethod(.linear)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    }
                    ForEach(timeData) { entry in
                        LineMark(x: .value("Time", entry.timestamp), y: .value("Time", Double(entry.timeRemainingMinutes) / 60.0))
                            .foregroundStyle(by: .value("Metric", "Time (h)"))
                            .interpolationMethod(.linear)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    }

                    if let selectedDate {
                        if let powerEntry = powerData.closest(to: selectedDate) {
                            PointMark(x: .value("Time", powerEntry.timestamp), y: .value("Power", powerEntry.powerConsumption))
                                .foregroundStyle(MaterialChartPalette.primary)
                                .symbolSize(80)
                        }
                        if let timeEntry = timeData.closest(to: selectedDate) {
                            PointMark(x: .value("Time", timeEntry.timestamp), y: .value("Time", Double(timeEntry.timeRemainingMinutes) / 60.0))
                                .foregroundStyle(MaterialChartPalette.tertiary)
                                .symbolSize(80)
                        }

                        RuleMark(x: .value("Selected", selectedDate))
                            .foregroundStyle(MaterialChartPalette.outline)
                            .annotation(position: .top, alignment: .center) {
                                annotationView(for: selectedDate, powerData: powerData, timeData: timeData)
                            }
                    }
                }
                .materialChartPlotStyle()
                .chartForegroundStyleScale([
                    "Power (W)": MaterialChartPalette.primary,
                    "Time (h)": MaterialChartPalette.tertiary
                ])
                .dynamicXAxis(for: selectedTimeRange, isVisible: true)
                .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) }
                .chartXSelection(value: $selectedDate)
                .frame(height: 150)
                .padding(.horizontal, 12)
            }

            Spacer()
        }
        .materialChartCard(height: 220)
    }

    @ViewBuilder
    private func annotationView(for date: Date, powerData: [BatteryLogEntry], timeData: [BatteryLogEntry]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let powerEntry = powerData.closest(to: date) {
                Text(String(format: "%.2f W", powerEntry.powerConsumption))
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            if let timeEntry = timeData.closest(to: date) {
                Text(String(format: "%.1f h", Double(timeEntry.timeRemainingMinutes) / 60.0))
                    .font(.caption)
                    .foregroundColor(.mint)
            }
        }
        .padding(4)
        .background(.background)
        .cornerRadius(4)
    }

}

struct BatteryHistoryView: View {
    @ObservedObject var historyViewModel: BatteryHistoryViewModel
    @State private var selectedEntry: BatteryLogEntry?
    @State private var hoveredDate: Date?

    private var hoveredEntry: BatteryLogEntry? {
        guard let hoveredDate else { return nil }
        return historyViewModel.chartData.closest(to: hoveredDate)
    }

    private var summaryStats: (min: Int, max: Int, avg: Int, avgTemp: Double, avgPower: Double)? {
        let data = historyViewModel.chartData
        guard !data.isEmpty else { return nil }
        let charges = data.map(\.charge)
        let temps = data.map(\.temperature).filter { $0 > 0 }
        let powers = data.map(\.powerConsumption).filter { $0 > 0 }
        return (
            min: charges.min() ?? 0,
            max: charges.max() ?? 0,
            avg: Int((Double(charges.reduce(0, +)) / Double(charges.count)).rounded()),
            avgTemp: temps.isEmpty ? 0 : temps.reduce(0, +) / Double(temps.count),
            avgPower: powers.isEmpty ? 0 : powers.reduce(0, +) / Double(powers.count)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("电池使用历史记录")
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    if !historyViewModel.chartData.isEmpty {
                        Text("\(historyViewModel.chartData.count) data points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let stats = summaryStats {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            StatPill(label: "Min", value: "\(stats.min)%", color: MaterialChartPalette.warning)
                            StatPill(label: "Avg", value: "\(stats.avg)%", color: MaterialChartPalette.primary)
                            StatPill(label: "Max", value: "\(stats.max)%", color: MaterialChartPalette.tertiary)
                            if stats.avgTemp > 0 {
                                StatPill(label: "Temp", value: String(format: "%.0f°", stats.avgTemp), color: MaterialChartPalette.error)
                            }
                            if stats.avgPower > 0 {
                                StatPill(label: "抽奖", value: String(format: "%.1fW", stats.avgPower), color: MaterialChartPalette.warning)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)

            historyLegend
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            if historyViewModel.isLoading {
                ProgressView()
                    .frame(height: 320, alignment: .center)
                    .frame(maxWidth: .infinity)
            } else if historyViewModel.chartData.isEmpty {
                EmptyHistoryView()
            } else {
                chartView
                    .frame(height: 320)
                    .padding(.horizontal, 20)

                if let entry = selectedEntry {
                    BatteryDataPointCard(entry: entry, onDismiss: {
                        withAnimation(.easeOut(duration: 0.18)) {
                            selectedEntry = nil
                        }
                    })
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(.bottom, 20)
        .materialChartCard()
        .animation(.easeOut(duration: 0.2), value: selectedEntry?.id)
    }

    private var historyLegend: some View {
        HStack(spacing: 10) {
            legendChip(label: "Charging", color: MaterialChartPalette.tertiary)
            legendChip(label: "Paused", color: MaterialChartPalette.primary)
            legendChip(label: "On Battery", color: MaterialChartPalette.warning)
            legendChip(label: "Low", color: MaterialChartPalette.error)
            Spacer(minLength: 0)
            Text("线条颜色=状态")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(MaterialChartPalette.onSurfaceVariant.opacity(0.75))
        }
    }

    private func legendChip(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(color)
                .frame(width: 14, height: 3)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                .lineLimit(1)
        }
        .frame(width: 100)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(MaterialChartPalette.surfaceContainer, in: Capsule())
    }

    private var chargeLineSegments: [(id: String, color: Color, a: BatteryLogEntry, b: BatteryLogEntry)] {
        let data = historyViewModel.chartData
        guard data.count >= 2 else { return [] }

        var segments: [(id: String, color: Color, a: BatteryLogEntry, b: BatteryLogEntry)] = []
        segments.reserveCapacity(data.count - 1)
        for i in 0..<(data.count - 1) {
            let a = data[i]
            let b = data[i + 1]
            segments.append((
                id: "\(a.id.uuidString)-\(b.id.uuidString)",
                color: statusColor(for: a),
                a: a,
                b: b
            ))
        }
        return segments
    }

    private var chartView: some View {
        Chart {
            ForEach(historyViewModel.chartData) { entry in
                AreaMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Charge", entry.charge)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white.opacity(0.10), Color.white.opacity(0.02), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.linear)
            }

            ForEach(chargeLineSegments, id: \.id) { segment in
                LineMark(
                    x: .value("Time", segment.a.timestamp),
                    y: .value("Charge", segment.a.charge),
                    series: .value("Segment", segment.id)
                )
                .foregroundStyle(segment.color)
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2.75, lineCap: .round, lineJoin: .round))

                LineMark(
                    x: .value("Time", segment.b.timestamp),
                    y: .value("Charge", segment.b.charge),
                    series: .value("Segment", segment.id)
                )
                .foregroundStyle(segment.color)
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2.75, lineCap: .round, lineJoin: .round))
            }

            if let entry = hoveredEntry ?? selectedEntry {
                RuleMark(x: .value("Selected", entry.timestamp))
                    .foregroundStyle(MaterialChartPalette.outlineStrong)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                PointMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Charge", entry.charge)
                )
                .foregroundStyle(statusColor(for: entry))
                .symbolSize(selectedEntry?.id == entry.id ? 120 : 90)
                .annotation(position: .top, spacing: 6) {
                    if selectedEntry == nil {
                        MaterialSelectionPill(
                            text: "\(entry.charge)% · \(entry.timestamp.formatted(date: .omitted, time: .shortened))",
                            color: statusColor(for: entry)
                        )
                    }
                }
            }
        }
        .materialChartPlotStyle()
        .chartYScale(domain: 0...108)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(MaterialChartPalette.outline.opacity(0.7))
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic(desiredCount: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(MaterialChartPalette.outline)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, style: .time)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                    }
                }
            }
        }
        .chartXSelection(value: $hoveredDate)
        .simultaneousGesture(TapGesture().onEnded {
            if let entry = hoveredEntry {
                withAnimation(.easeOut(duration: 0.18)) {
                    if selectedEntry?.id == entry.id {
                        selectedEntry = nil
                    } else {
                        selectedEntry = entry
                    }
                }
            }
        })
        .padding(.bottom, 8)
    }

    private func statusColor(for entry: BatteryLogEntry) -> Color {
        if entry.isCharging && entry.isPluggedIn { return MaterialChartPalette.tertiary }
        if entry.isPluggedIn && !entry.isCharging { return MaterialChartPalette.primary }
        if entry.charge <= 20 && !entry.isPluggedIn { return MaterialChartPalette.error }
        if !entry.isPluggedIn { return MaterialChartPalette.warning }
        return MaterialChartPalette.primary
    }
}
struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(12)
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("无历史数据")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("电池使用数据收集后将显示在此处")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
    }
}

struct BatteryDataPointCard: View {
    let entry: BatteryLogEntry
    let onDismiss: () -> Void

    private var statusLabel: String {
        if entry.isCharging && entry.isPluggedIn { return "Charging" }
        if entry.isPluggedIn && !entry.isCharging { return "Charge Paused" }
        if entry.charge <= 20 { return "Low Battery" }
        if !entry.isPluggedIn { return "On Battery" }
        return "Normal"
    }

    private var statusColor: Color {
        if entry.isCharging && entry.isPluggedIn { return MaterialChartPalette.tertiary }
        if entry.isPluggedIn && !entry.isCharging { return MaterialChartPalette.primary }
        if entry.charge <= 20 { return MaterialChartPalette.error }
        if !entry.isPluggedIn { return MaterialChartPalette.warning }
        return MaterialChartPalette.onSurfaceVariant
    }

    private var timeRemainingText: String {
        guard entry.timeRemainingMinutes > 0 else { return "—" }
        let hours = entry.timeRemainingMinutes / 60
        let minutes = entry.timeRemainingMinutes % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private var ledLabel: String {
        switch entry.ledColor {
        case 1: return "Green"
        case 2: return "Amber"
        case 3: return "Red"
        case 0: return "Off"
        default: return "\(entry.ledColor)"
        }
    }

    private var detailRows: [(section: String, rows: [(icon: String, label: String, value: String, color: Color)])] {
        [
            ("Charge", [
                ("battery.100", "Charge", "\(entry.charge)%", statusColor),
                ("cpu", "Hardware Charge", "\(entry.hardwareCharge)%", MaterialChartPalette.primary),
                ("heart.fill", "Max Capacity", "\(entry.maxCapacity) mAh", .pink),
                ("arrow.clockwise", "Cycle Count", "\(entry.cycleCount)", MaterialChartPalette.secondary),
            ]),
            ("Power", [
                ("bolt.fill", "Power Draw", entry.powerConsumption > 0 ? String(format: "%.2f W", entry.powerConsumption) : "—", MaterialChartPalette.warning),
                ("clock.fill", entry.isCharging ? "Time to Full" : "Time Remaining", timeRemainingText, MaterialChartPalette.primary),
                ("thermometer.medium", "Temperature", String(format: "%.1f °C", entry.temperature), entry.temperature > 40 ? MaterialChartPalette.error : MaterialChartPalette.tertiary),
            ]),
            ("State", [
                ("powerplug.fill", "Adapter", entry.isPluggedIn ? "Connected" : "Unplugged", entry.isPluggedIn ? MaterialChartPalette.tertiary : .gray),
                ("bolt.circle", "Charging", entry.isCharging ? "Yes" : "No", entry.isCharging ? MaterialChartPalette.tertiary : .gray),
                ("slider.horizontal.3", "Management", entry.managementState.rawValue, MaterialChartPalette.secondary),
                ("leaf.fill", "Low Power Mode", entry.isLowPowerMode ? "On" : "Off", entry.isLowPowerMode ? MaterialChartPalette.warning : .gray),
            ]),
            ("System", [
                ("display", "Screen", entry.isScreenOn ? "On" : "Off", entry.isScreenOn ? MaterialChartPalette.primary : .gray),
                ("moon.fill", "Sleeping", entry.isSleeping ? "Yes" : "No", entry.isSleeping ? MaterialChartPalette.secondary : .gray),
                ("light.max", "LED", ledLabel, MaterialChartPalette.onSurfaceVariant),
                ("calendar", "Logged", entry.timestamp.formatted(date: .abbreviated, time: .standard), MaterialChartPalette.onSurfaceVariant),
            ]),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.charge)%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                        .monospacedDigit()
                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                }

                Spacer()

                Text(statusLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.16), in: Capsule())

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                        .frame(width: 28, height: 28)
                        .background(MaterialChartPalette.surfaceContainer, in: Circle())
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                alignment: .leading,
                spacing: 16
            ) {
                ForEach(detailRows, id: \.section) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.section.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                            .tracking(0.6)

                        VStack(spacing: 0) {
                            ForEach(Array(section.rows.enumerated()), id: \.offset) { index, row in
                                BatteryAlignedDetailRow(
                                    icon: row.icon,
                                    label: row.label,
                                    value: row.value,
                                    color: row.color
                                )
                                if index < section.rows.count - 1 {
                                    Divider().opacity(0.35)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            MaterialChartPalette.surfaceContainer,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(MaterialChartPalette.surfaceContainer.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(MaterialChartPalette.outline, lineWidth: 1)
        )
    }
}

private struct BatteryAlignedDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18, alignment: .center)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .frame(minWidth: 84, alignment: .trailing)
        }
        .padding(.vertical, 7)
    }
}

struct BatteryHealthCard: View {
    @ObservedObject var viewModel: BatteryStatsViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill").foregroundStyle(.pink)
                Text("电池健康状况").font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            Spacer()
            SpecRow(label: "设计能力", value: "\(viewModel.designCapacity) mAh", percentage: "100%")
            SpecRow(label: "最大容量", value: "\(viewModel.maxCapacity) mAh", percentage: "\(viewModel.maxCapacityPercentage)%")
            SpecRow(label: "macOS 容量", value: "\(viewModel.appleMaxCapacity) mAh", percentage: "\(viewModel.appleMaxCapacityPercentage)%")
            SpecRow(label: "macOS 条件", value: viewModel.health)
            SpecRow(label: "Cycle Count", value: "\(viewModel.cycleCount)")
            Spacer()
        }
        .padding(16)
        .materialChartCard(height: 180, accent: .pink)
    }
}

struct PowerAdapterSpecsCard: View {
    @ObservedObject var viewModel: BatteryStatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "powerplug.fill")
                    .foregroundStyle(MaterialChartPalette.onSurfaceVariant)
                Text("电源适配器规格")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }

            if let info = viewModel.powerAdapterInfo, info.maxPower > 0 {
                if info.current > 0 || info.maxCurrent > 0 {
                    PowerAdapterSpecRow(
                        label: "Current",
                        currentValue: info.current > 0 ? "\(Double(info.current) / 1000.0, default: "%.2f") A" : "0.0 A",
                        maxValue: info.maxCurrent > 0 ? "\(Double(info.maxCurrent) / 1000.0, default: "%.1f") A" : "N/A"
                    )
                }

                if info.voltage > 0 || info.maxVoltage > 0 {
                    PowerAdapterSpecRow(
                        label: "Voltage",
                        currentValue: info.voltage > 0 ? "\(Double(info.voltage) / 1000.0, default: "%.1f") V" : "0.0 V",
                        maxValue: info.maxVoltage > 0 ? "\(Double(info.maxVoltage) / 1000.0, default: "%.1f") V" : "N/A"
                    )
                }

                PowerAdapterSpecRow(
                    label: "Power",
                    currentValue: "\(Double(info.power), default: "%.1f") W",
                    maxValue: "\(info.maxPower) W"
                )

                if !info.name.isEmpty && info.name != "N/A" {
                    SpecRow(label: "Name", value: info.name)
                }

                if !info.manufacturer.isEmpty && info.manufacturer != "N/A" {
                    SpecRow(label: "Manufacturer", value: info.manufacturer)
                }

                if !info.serialNumber.isEmpty && info.serialNumber != "N/A" {
                    SpecRow(label: "序列号", value: info.serialNumber)
                }
            } else {
                Text("未连接")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .materialChartCard(minHeight: 180, accent: .gray)
    }
}

fileprivate struct PowerAdapterSpecRow: View {
    let label: String
    let currentValue: String
    let maxValue: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(currentValue)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 56, alignment: .trailing)
            Text("of")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.secondary)
            Text(maxValue)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 48, alignment: .trailing)
        }
    }
}

struct SignificantEnergyUsersView: View {
    @ObservedObject var viewModel: EnergyViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("重要能源用户")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Spacer()
            if viewModel.topProcesses.isEmpty {
                Text("没有应用程序消耗大量能源")
                    .font(.caption).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ForEach(viewModel.topProcesses) { process in
                    HStack {
                        Text(process.name).font(.caption)
                        Spacer()
                        Text(String(format: "%.2f%%", process.usage))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MaterialChartPalette.primary.opacity(0.14), in: Capsule())
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .materialChartCard(height: 180, accent: MaterialChartPalette.primary)
    }
}
struct EmptyStatsView: View {
    var height: CGFloat
    var body: some View {
        VStack {
            Image(systemName: "chart.bar.xaxis").font(.largeTitle).foregroundColor(.secondary.opacity(0.3))
            Text("还没有历史记录").font(.caption).foregroundColor(.secondary)
        }
        .frame(height: height).frame(maxWidth: .infinity)
    }
}

struct HealthStatRow: View {
    let label: String, value: String, percentage: Int
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).multilineTextAlignment(.trailing)
            Text("\(percentage)%").font(.caption.weight(.semibold)).frame(width: 35, alignment: .trailing)
        }
    }
}
struct SimpleHealthStatRow: View {
    let label: String, value: String
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold))
        }
    }
}

struct PowerRow: View {
    let label: String, value: String, color: Color?
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).foregroundColor(color ?? .primary)
        }
    }
}

struct BatteryConfigurationView: View {
    @EditingSettings var settings: SettingsEditingSession
    @EnvironmentObject var powerStateController: PowerStateController
    @StateObject private var helperManager = HelperManager.shared
    @ObservedObject private var calibrationManager = CalibrationManager.shared
    @State private var showingScheduleSheet = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 15) {
                    HelperStatusBanner(helperManager: helperManager)
                }
                .padding()
                .roundedCard(fill: Color.black.opacity(0.15), cornerRadius: 20, stroke: Color.white.opacity(0.1))
                .onAppear { helperManager.checkIfRunning() }

                notificationsSection
                coreFeaturesSection
                chargingAndSleepSection
                automaticDischargeSection
                OneTimeDischargeView()
                schedulingSection
                CalibrationView()
                advancedSection
                FanControlSectionView()
            }
            .padding(.horizontal, 25).padding(.bottom, 25)
        }
        .sheet(isPresented: $showingScheduleSheet) {
            ScheduleView().environment(settings)
        }
    }

    @ViewBuilder private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("通知和实时活动").font(.headline).padding([.top, .horizontal])
            CustomSliderRowView(label: "当电池电量低于时发出通知", value: Binding(get: { Double(settings.settings.lowBatteryNotificationPercentage) }, set: { settings.settings.lowBatteryNotificationPercentage = Int($0) }), range: 10...50, specifier: "%.0f %%")
            Divider().padding(.leading, 20)
            ToggleRow(title: "播放低电量警报声音", description: "Get an audible alert when your battery is running low.", isOn: $settings.settings.lowBatteryNotificationSoundEnabled)
            Divider().padding(.leading, 20)
            ToggleRow(title: "提示开启低功耗模式", description: "Show a convenient button to enable Low Power Mode when your battery gets low.", isOn: $settings.settings.promptForLowPowerMode)
            Divider().padding(.leading, 20)
            ToggleRow(title: "显示预计剩余时间", description: "Display the estimated time to full (when charging) or time to empty (when on battery) in the live activity.", isOn: $settings.settings.showEstimatedBatteryTime)
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder private var coreFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("电池管理功能").font(.headline).padding([.top, .horizontal])
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 {
                InfoContainer(
                    text: "Due to changes on macOS 27 charge limiting may not work for some users. If a limit is set, Sapphire will fallback to adapter mode (which cuts power from the adapter) when the limit is reach in order to enforce it. This method is under beta and may not always work, especially when the device is asleep.",
                    iconName: "exclamationmark.triangle.fill",
                    color: .orange
                )
                .padding([.horizontal, .top])
            }
            CustomSliderRowView(label: "Charge Limit", value: Binding(get: { Double(settings.settings.batteryChargeLimit) }, set: { settings.settings.batteryChargeLimit = Int($0) }), range: 50...100, specifier: "%.0f %%")
            Divider().padding(.leading, 20)
            ToggleRow(
                title: "暂停充电",
                description: "Manually stop charging while plugged in. Turn off to resume normal charging rules (limit, sailing mode, etc.).",
                isOn: Binding(
                    get: { settings.settings.manualChargePaused },
                    set: { paused in
                        settings.settings.manualChargePaused = paused
                        BatteryManager.shared.enableCharging(!paused)
                    }
                )
            )
            Divider().padding(.leading, 20)
            ToggleRow(title: "航行模式", description: "Prevents battery wear from constant micro-charging cycles when plugged in for long periods. Charging will pause at the limit and only resume when the battery drops by a set amount.", isOn: $settings.settings.sailingModeEnabled)
            if settings.settings.sailingModeEnabled {
                 CustomSliderRowView(label: "下面继续充电", value: Binding(get: { Double(settings.settings.sailingModeLowerLimit) }, set: { settings.settings.sailingModeLowerLimit = Int($0) }), range: 5...20, specifier: "%.0f%% below limit")
            }
            Divider().padding(.leading, 20)
            ToggleRow(title: "Heat Protection", description: "Automatically pauses charging if the battery temperature gets too high to prevent heat-related damage and extend its lifespan.", isOn: $settings.settings.heatProtectionEnabled)
            if settings.settings.heatProtectionEnabled {
                 CustomSliderRowView(label: "上面暂停充电", value: $settings.settings.heatProtectionThreshold, range: 35...50, specifier: "%.0f °C")
            }
        }
        .modifier(SettingsContainerModifier()).animation(.default, value: settings.settings.sailingModeEnabled || settings.settings.heatProtectionEnabled)
    }

    @ViewBuilder private var automaticDischargeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("自动放电").font(.headline).padding([.top, .horizontal])
            ToggleRow(
                title: "启用自动放电",
                description: "When enabled, your Mac will stop using AC power and run from its battery until the battery limit is reached.",
                isOn: $settings.settings.dischargeToLimitEnabled
            )
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder private var chargingAndSleepSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("充电与睡眠").font(.headline).padding([.top, .horizontal])
            InfoContainer(text: "Although functionality is in place to keep the battery management functinal even when the device is sleeping it may not always work. Use these settings if you want to be certain of the behaviour when the device is sleeping.", iconName: "info.circle", color: .yellow).padding()
            ToggleRow(title: "睡觉时停止充电", description: "Prevents your Mac from sitting at 100% charge overnight, which can degrade the battery over time. Charging resumes on wake.", isOn: $settings.settings.stopChargingWhenSleeping)
            Divider().padding(.leading, 20)
            ToggleRow(title: "睡眠期间记录电池电量", description: "Wakes the Mac briefly (display stays off) at a set interval to record battery state and re-assert your charge limit overnight. Sleep is never disabled.", isOn: $settings.settings.logBatteryDuringSleep)
            if settings.settings.logBatteryDuringSleep {
                CustomSliderRowView(label: "记录每个", value: Binding(get: { Double(settings.settings.sleepLoggingIntervalMinutes) }, set: { settings.settings.sleepLoggingIntervalMinutes = Int($0) }), range: 15...120, specifier: "%.0f min")
            }
            Divider().padding(.leading, 20)
            ToggleRow(title: "应用程序关闭时停止充电", description: "即使 Sapphire 应用程序未运行，辅助工具也可确保您的收费规则仍然适用。", isOn: .constant(true)).disabled(true)
            Divider().padding(.leading, 20)
            ToggleRow(title: "禁用睡眠直至充电限制", description: "Keeps your Mac awake to ensure it reaches the charge limit, useful for 'top-up' schedules before you need to leave.", isOn: $settings.settings.disableSleepUntilChargeLimit)
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Scheduling").font(.headline).padding([.top, .horizontal])
            InfoContainer(text: "Automate charging behaviors and perform manual or scheduled calibrations to keep your battery's readings accurate.", iconName: "calendar.badge.clock", color: .cyan).padding()
            Divider().padding(.horizontal)
            HStack {
                Text("管理日程").font(.subheadline.bold())
                Spacer()
                Button("打开调度程序") { showingScheduleSheet = true }.buttonStyle(.bordered)
            }.padding()
        }.modifier(SettingsContainerModifier())
    }

    @ViewBuilder private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("高级").font(.headline).padding([.top, .horizontal])
            ToggleRow(title: "使用硬件电池百分比", description: "Reads the 'true' charge from the battery controller, which can be more accurate but may differ from what macOS shows.", isOn: $settings.settings.useHardwareBatteryPercentage)
        }.modifier(SettingsContainerModifier())
    }
}

struct OneTimeDischargeView: View {
    @EditingSettings private var settings: SettingsEditingSession
    @StateObject private var batteryMonitor = BatteryMonitor.shared

    private var dischargeProgress: Double {
        guard let currentCharge = batteryMonitor.currentState?.level else { return 0 }

        let targetCharge = Double(settings.settings.oneTimeDischargeTarget)
        let initialCharge = 100.0

        let totalRange = initialCharge - targetCharge
        guard totalRange > 0 else { return 1.0 }

        let dischargedAmount = initialCharge - Double(currentCharge)
        let progress = dischargedAmount / totalRange

        return max(0.0, min(1.0, progress))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("一次性放电").font(.headline).padding([.top, .horizontal])
            InfoContainer(
                text: "Temporarily discharge to a specific percentage. This will not affect your main charge limit or automatic discharge settings.",
                iconName: "target",
                color: .blue
            ).padding()

            if settings.settings.oneTimeDischargeEnabled {
                VStack(spacing: 12) {
                    Text("Discharging to \(settings.settings.oneTimeDischargeTarget)%...")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ProgressView(value: dischargeProgress)
                        .progressViewStyle(.linear)
                        .tint(.blue)

                    if let currentCharge = batteryMonitor.currentState?.level {
                        Text("Current: \(currentCharge)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button("Stop", role: .destructive) {
                        settings.settings.oneTimeDischargeEnabled = false
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 5)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .frame(minHeight: 120)

            } else {
                VStack(spacing: 15) {
                    Stepper(
                        "Discharge Target: \(settings.settings.oneTimeDischargeTarget)%",
                        value: $settings.settings.oneTimeDischargeTarget,
                        in: 1...95,
                        step: 5
                    )

                    Button(action: {
                        settings.settings.oneTimeDischargeEnabled = true
                    }) {
                        Text("开始一次性放电")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .frame(minHeight: 120)
            }
        }
        .modifier(SettingsContainerModifier())
    }
}

fileprivate extension TimeInterval {
    func formatted() -> String {
        SettingsDurationFormatter.hourMinute.string(from: self) ?? "0m"
    }
}

private enum SettingsDurationFormatter {
    static let hourMinute: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

struct ScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    @State private var showingAddTask = false

    var body: some View {
        VStack(spacing: 20) {
            Text("日程自动化").font(.largeTitle.bold())

            VStack {
                HStack {
                    Text("计划任务").font(.headline)
                    Spacer()
                    Button(action: { showingAddTask = true }) { Image(systemName: "plus") }
                }.padding([.horizontal, .top])

                if settings.settings.scheduledTasks.isEmpty {
                    Text("没有安排任务。").foregroundColor(.secondary).padding()
                } else {
                    List {
                        ForEach($settings.settings.scheduledTasks) { $task in
                            TaskRowView(task: $task).listRowBackground(Color.clear)
                        }.onDelete { indexSet in settings.settings.scheduledTasks.remove(atOffsets: indexSet) }
                    }.listStyle(.plain).background(Color.clear)
                }
            }.modifier(SettingsContainerModifier())

            VStack(alignment: .leading) {
                 Text("任务历史记录").font(.headline).padding([.horizontal, .top])
                 List(scheduleManager.taskHistory) { event in
                     HStack {
                         Text(event.taskDescription); Spacer(); Text(event.timestamp, style: .time)
                     }.listRowBackground(Color.clear)
                 }.listStyle(.plain).background(Color.clear)
            }.modifier(SettingsContainerModifier())

            Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
        }
        .padding(30).frame(minWidth: 500, minHeight: 600)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView().environment(settings)
        }
    }
}

struct TaskRowView: View {
    @Binding var task: ScheduledTask

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.action.displayName).font(.headline)

                switch task.action {
                case .setChargeLimit, .dischargeTo:
                    Text("Target: \(task.chargeLimit)% | Repeats: \(task.repeatInterval.displayName) at \(task.startTime, style: .time)")
                        .font(.caption).foregroundColor(.secondary)
                case .setFanConstant:
                    Text("Speed: \(task.fanSpeed) RPM | Repeats: \(task.repeatInterval.displayName) at \(task.startTime, style: .time)")
                        .font(.caption).foregroundColor(.secondary)
                case .setFanSensorBased:
                    Text("Sensor: \(SensorNameMap.name(for: task.sensorKey)) (\(task.minTemp)°C-\(task.maxTemp)°C) | Repeats: \(task.repeatInterval.displayName) at \(task.startTime, style: .time)")
                        .font(.caption).foregroundColor(.secondary)
                default:
                    Text("Repeats: \(task.repeatInterval.displayName) at \(task.startTime, style: .time)")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: $task.isActive).labelsHidden()
        }
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var fanManager = FanManager.shared
    @State private var newTask = ScheduledTask()

    private var firstFan: FanInfo? { fanManager.fans.first }

    var body: some View {
        VStack(spacing: 20) {
            Text("新计划任务").font(.title.bold())

            VStack(spacing: 15) {
                Picker("行动：", selection: $newTask.action) {
                    ForEach(TaskAction.allCases) { Text($0.displayName).tag($0) }
                }
                .onChange(of: newTask.action) {
                    if newTask.action == .setFanSensorBased, newTask.sensorKey.isEmpty {
                        newTask.sensorKey = fanManager.sensors.first?.key ?? ""
                    }
                }

                if [.setChargeLimit, .dischargeTo].contains(newTask.action) {
                    CustomSliderRowView(label: "目标费用", value: Binding(get: { Double(newTask.chargeLimit) }, set: { newTask.chargeLimit = Int($0) }), range: 20...100, specifier: "%.0f%%")
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                }

                if newTask.action == .setFanConstant {
                    if let fan = firstFan {
                        CustomSliderRowView(label: "目标速度", value: Binding(get: { Double(newTask.fanSpeed) }, set: { newTask.fanSpeed = Int($0) }), range: Double(fan.minRPM)...Double(fan.maxRPM), specifier: "%.0f RPM")
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                    }
                }

                if newTask.action == .setFanSensorBased {
                    VStack(spacing: 15) {
                        Picker("基于传感器：", selection: $newTask.sensorKey) {
                            ForEach(fanManager.sensors) { sensor in
                                Text(sensor.name).tag(sensor.key)
                            }
                        }

                        CustomSliderRowView(label: "从以下位置开始增加：", value: Binding(get: { Double(newTask.minTemp) }, set: { newTask.minTemp = Int($0) }), range: 20...90, specifier: "%.0f °C")

                        CustomSliderRowView(label: "最高温度：", value: Binding(get: { Double(newTask.maxTemp) }, set: { newTask.maxTemp = Int($0) }), range: Double(newTask.minTemp)...100, specifier: "%.0f °C")
                    }
                    .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                }

                Picker("重复：", selection: $newTask.repeatInterval) {
                    ForEach(RepeatInterval.allCases) { Text($0.displayName).tag($0) }
                }

                DatePicker("Time:", selection: $newTask.startTime, displayedComponents: .hourAndMinute)
            }
            .padding().modifier(SettingsContainerModifier())
            .animation(.default, value: newTask.action)

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button("添加任务") {
                    settings.settings.scheduledTasks.append(newTask)
                    dismiss()
                }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(30).frame(width: 450)
    }
}

struct HUDSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    private var hudCustomColorBinding: Binding<Color> {
        Binding(
            get: { settings.settings.hudCustomColor?.color ?? .accentColor },
            set: { settings.settings.hudCustomColor = CodableColor(color: $0) }
        )
    }

    private var pillStyleEnabled: Bool {
        settings.settings.effectiveVolumeHUDStyle == .pill || settings.settings.effectiveBrightnessHUDStyle == .pill
    }

    private var xdrBrightnessLevelBinding: Binding<Double> {
        Binding(
            get: { Double(settings.settings.xdrBrightnessLevel * 100) },
            set: { settings.settings.xdrBrightnessLevel = Float($0 / 100) }
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("HUD")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                // MARK: HUD Appearance
                VStack(alignment: .leading, spacing: 0) {
                    Text("平视显示器外观")
                        .font(.headline)
                        .padding([.horizontal, .top])

                    Divider().padding(.top, 10).padding(.leading, 20)

                    HStack {
                        Text("风格")
                        Spacer()
                        Picker("", selection: $settings.settings.hudVisualStyle) {
                            ForEach(HUDVisualStyle.allCases) { style in
                                Text(style.id).tag(style)
                            }
                        }
                        .labelsHidden().frame(width: 150)
                    }.padding()

                    if settings.settings.hudVisualStyle == .color {
                        ColorPicker("Custom HUD Color", selection: hudCustomColorBinding)
                            .padding()
                            .transition(.opacity)
                    }

                    Divider().padding(.leading, 20)

                    CustomSliderRowView(label: "平视显示器持续时间", value: $settings.settings.hudDuration, range: 1...10, specifier: "%.1f s")
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "显示百分比", description: "", isOn: $settings.settings.hudShowPercentage)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "显示函数名称", description: "Display the HUD name (e.g. Volume, Brightness, Spotify) when the thin style is enabled.", isOn: $settings.settings.hudShowFunctionName)

                    if pillStyleEnabled {
                        Divider().padding(.leading, 20)
                        HStack {
                            Text("药丸位置")
                            Spacer()
                            Picker("", selection: $settings.settings.hudPillPosition) {
                                ForEach(PillHUDPosition.allCases) { position in
                                    Text(position.id).tag(position)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }
                        .padding()
                        HStack {
                            Text("药丸款式")
                            Spacer()
                            Picker("", selection: $settings.settings.hudPillStyle) {
                                ForEach(PillHUDStyle.allCases) { style in
                                    Text(style.id).tag(style)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }
                        .padding()
                        Divider().padding(.leading, 20)
                        CustomSliderRowView(label: "药丸长度", value: $settings.settings.hudPillLength, range: 160...460, specifier: "%.0f pt")
                        Divider().padding(.leading, 20)
                        CustomSliderRowView(label: "药丸厚度", value: $settings.settings.hudPillThickness, range: 44...92, specifier: "%.0f pt")
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: pillStyleEnabled)
                .animation(.default, value: settings.settings.hudVisualStyle)

                // MARK: Spotify, App & Device Icons (essential)
                VStack(alignment: .leading, spacing: 0) {
                    Text("显示 Spotify、应用程序和设备图标")
                        .font(.headline)
                        .padding([.horizontal, .top])

                    Divider().padding(.top, 10).padding(.leading, 20)

                    ToggleRow(
                        title: "在 HUD 中显示 Spotify 设备",
                        description: "Display a special HUD with the active device name when changing volume while Spotify is active.",
                        isOn: $settings.settings.showSpotifyVolumeHUD
                    )
                    Divider().padding(.leading, 20)
                    ToggleRow(
                        title: "在 HUD 中显示应用程序音量",
                        description: "Press Option + Volume keys to adjust volume for the active app (excludes Spotify and Apple Music).",
                        isOn: $settings.settings.showAppVolumeHUD
                    )

                    if settings.settings.showAppVolumeHUD {
                        ToggleRow(
                            title: "在正常音量 HUD 中显示",
                            description: "Display app volume in the normal volume HUD (like Spotify). When disabled, only shows with Option + Volume keys.",
                            isOn: $settings.settings.showAppVolumeInNormalHUD
                        )
                        .padding(.leading, 20)
                    }

                    Divider().padding(.leading, 20)
                    ToggleRow(
                        title: "显示设备图标而不是扬声器",
                        description: "For devices like HomePods, show a device-specific icon in the volume HUD.",
                        isOn: $settings.settings.volumeHUDShowDeviceIcon
                    )

                    if settings.settings.volumeHUDShowDeviceIcon {
                        ToggleRow(
                            title: "排除内置扬声器",
                            description: "Only show device icons for external audio devices like AirPods or HomePods.",
                            isOn: $settings.settings.excludeBuiltInSpeakersFromHUDIcon
                        )
                        .padding(.leading, 20)
                        .transition(.opacity)
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.volumeHUDShowDeviceIcon)

                // MARK: Volume HUD
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("音量平视显示器")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $settings.settings.enableVolumeHUD)
                            .labelsHidden().toggleStyle(.switch)
                    }
                    .padding()

                    Divider().padding(.leading, 20)

                    HStack {
                        Text("查看样式")
                        Spacer()
                        Picker("", selection: $settings.settings.volumeHUDStyle) {
                            ForEach(HUDStyle.allCases.filter { $0 != .dots }) { style in
                                Text(style.id).tag(style)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)
                    }
                    .padding()
                    .disabled(!settings.settings.enableVolumeHUD || settings.settings.volumeHUDShowDots)
                    .opacity(settings.settings.enableVolumeHUD && !settings.settings.volumeHUDShowDots ? 1.0 : 0.5)

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "显示点",
                        description: "Display volume as a row of dots instead of a bar.",
                        isOn: $settings.settings.volumeHUDShowDots
                    )
                    .disabled(!settings.settings.enableVolumeHUD)
                    .opacity(settings.settings.enableVolumeHUD ? 1.0 : 0.5)

                    Divider().padding(.leading, 20)

                    HStack {
                        Text("变革之声")
                        Spacer()
                        Toggle("", isOn: $settings.settings.volumeHUDSoundEnabled)
                            .labelsHidden().toggleStyle(.switch)
                    }
                    .padding()
                    .disabled(!settings.settings.enableVolumeHUD)
                    .opacity(settings.settings.enableVolumeHUD ? 1.0 : 0.5)

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "每个应用程序卷使用系统卷上限",
                        description: "When enabled, 100% app volume is capped by current system output volume.",
                        isOn: $settings.settings.perAppVolumeSystemDependent
                    )
                    .disabled(!settings.settings.enableVolumeHUD)
                    .opacity(settings.settings.enableVolumeHUD ? 1.0 : 0.5)

                    Divider().padding(.leading, 20)

                    CustomSliderRowView(label: "滑块步长", value: Binding(get: { Double(settings.settings.volumesliderstep) }, set: { settings.settings.volumesliderstep = Int($0) }), range: 1...20, specifier: "%.0f")
                        .disabled(!settings.settings.enableVolumeHUD)
                        .opacity(settings.settings.enableVolumeHUD ? 1.0 : 0.5)

                    Divider().padding(.leading, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("每个设备的滑块步骤")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(MultiAudioManager.shared.availableOutputDevices, id: \.uid) { device in
                            HStack {
                                Text(device.name)
                                    .font(.system(size: 13))
                                Spacer()

                                Picker("", selection: Binding(get: {
                                    Double(settings.settings.volumesliderstepByDevice[device.uid] ?? settings.settings.volumesliderstep)
                                }, set: { newVal in
                                    settings.settings.volumesliderstepByDevice[device.uid] = Int(newVal)
                                })) {
                                    ForEach(1...20, id: \.self) { val in
                                        Text("\(val)").tag(Double(val))
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 120)

                                Button(action: {
                                    settings.settings.volumesliderstepByDevice.removeValue(forKey: device.uid)
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("重置为全局滑块步长")
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 10)
                    .disabled(!settings.settings.enableVolumeHUD)
                    .opacity(settings.settings.enableVolumeHUD ? 1.0 : 0.5)
                }
                .modifier(SettingsContainerModifier())

                // MARK: Brightness HUD
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("亮度平视显示器")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $settings.settings.enableBrightnessHUD)
                            .labelsHidden().toggleStyle(.switch)
                    }
                    .padding()

                    Divider().padding(.leading, 20)

                    HStack {
                        Text("查看样式")
                        Spacer()
                        Picker("", selection: $settings.settings.brightnessHUDStyle) {
                            ForEach(HUDStyle.allCases.filter { $0 != .dots }) { style in
                                Text(style.id).tag(style)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)
                    }
                    .padding()
                    .disabled(!settings.settings.enableBrightnessHUD || settings.settings.brightnessHUDShowDots)
                    .opacity(settings.settings.enableBrightnessHUD && !settings.settings.brightnessHUDShowDots ? 1.0 : 0.5)

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "显示点",
                        description: "Display brightness as a row of dots instead of a bar.",
                        isOn: $settings.settings.brightnessHUDShowDots
                    )
                    .disabled(!settings.settings.enableBrightnessHUD)
                    .opacity(settings.settings.enableBrightnessHUD ? 1.0 : 0.5)

                    Divider().padding(.leading, 20)

                    CustomSliderRowView(label: "滑块步长", value: Binding(get: { Double(settings.settings.brightnessliderstep) }, set: { settings.settings.brightnessliderstep = Int($0) }), range: 1...10, specifier: "%.0f")
                        .disabled(!settings.settings.enableBrightnessHUD)
                        .opacity(settings.settings.enableBrightnessHUD ? 1.0 : 0.5)

                    Divider().padding(.leading, 20)

                    HStack(spacing: 12) {
                        SettingsRowLabel(
                            title: "亮度关键步骤",
                            description: "How far each brightness key press moves. Smaller steps give finer control."
                        )
                        Spacer(minLength: 8)
                        Picker("亮度关键步骤", selection: $settings.settings.brightnessKeyStep) {
                            ForEach(BrightnessKeyStep.allCases) { step in
                                Text(step.displayName).tag(step)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                    }
                    .padding()

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "额外调光",
                        description: "Let external monitors go darker than their lowest backlight setting. The bottom quarter of the range dims the picture in software.",
                        isOn: $settings.settings.displayExtraDimming
                    )

                    SoftwareDimmingRows()
                }
                .modifier(SettingsContainerModifier())

                // MARK: XDR Brightness (essential)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("XDR 亮度")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $settings.settings.enableXDRBrightness)
                            .labelsHidden().toggleStyle(.switch)
                    }

                    Divider()

                    VStack {
                        ToggleRow(
                            title: "XDR 亮度锁定",
                            description: "Require holding the Command (⌘) key to increase the brightness in the XDR range.",
                            isOn: $settings.settings.xdrBrightnessLock
                        )

                        Divider()

                        CustomSliderRowView(
                            label: "最大 XDR 亮度",
                            value: xdrBrightnessLevelBinding,
                            range: 100...Double(getDeviceMaxBrightness() * 100),
                            specifier: "%.0f%%"
                        )

                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                                .padding(.top, 4)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("苹果限制亮度以延长电池寿命。虽然此功能是由系统控制的，并且没有已知的副作用，但您应自行承担使用此功能的风险。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("此功能在配备 XDR 显示器的设备（14 英寸和 16 英寸 Macbook Pro 以及 Pro Display XDR）上效果最佳。 M4 Macbook Pro 已经在明亮的环境中（例如直射阳光下）显示了此行为，此功能将允许您在任何类型的环境中执行此操作。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 5)
                    }
                    .disabled(!settings.settings.enableXDRBrightness)
                    .opacity(settings.settings.enableXDRBrightness ? 1.0 : 0.5)

                }
                .padding()
                .modifier(SettingsContainerModifier())
                .disabled(!settings.settings.enableBrightnessHUD)
                .opacity(settings.settings.enableBrightnessHUD ? 1.0 : 0.5)
                .animation(.easeInOut, value: settings.settings.enableBrightnessHUD)
                .animation(.easeInOut, value: settings.settings.enableXDRBrightness)

                RequiredPermissionsView(section: .hud)
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct MusicSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    @State private var isPrivateApiLoading = false
    @State private var privateApiError: String?
    @State private var isPrivateAuth = false
    @State private var isOfficialAuth = false
    @State private var officialDisplayName: String?
    @State private var isTidalAuth = false
    @State private var tidalDisplayName: String?
    @State private var tidalLoginError: String?
    @State private var isShowingTidalLogin = false
    @State private var loginChallenge: LoginChallengeDetails?
    @AppStorage("musicSettingsSelectedTab") private var selectedTab: MusicSettingsTab = .general

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Music").font(.largeTitle.bold())

                Picker("音乐部分", selection: $selectedTab) {
                    ForEach(MusicSettingsTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .padding(.bottom, 4)

                switch selectedTab {
                case .general:
                VStack(spacing: 0) {
                    HStack {
                        Text("媒体来源")
                        Spacer()
                        Picker("", selection: $settings.settings.mediaSource) {
                            ForEach(MediaSource.allCases) { source in Text(source.displayName).tag(source) }
                        }
                        .labelsHidden().frame(width: 180)
                    }.padding()
                    if settings.settings.mediaSource != .system {
                        Divider().padding(.leading, 20)
                        ToggleRow(title: "确定所选来源的优先级", description: "Only show media from your selected source, ignoring browsers and other apps.", isOn: $settings.settings.prioritizeMediaSource)
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.mediaSource)

                if settings.settings.mediaSource == .system {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("显示现在播放").font(.headline).padding([.horizontal, .top])
                        Text("选择哪些应用程序可以出现在音乐小部件和媒体切换器中。默认情况下，所有应用程序（包括浏览器）均处于打开状态。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        AppTogglesListView(isEnabled: { app in mediaVisibilityBinding(for: app, isBrowser: app.isBrowser) })
                    }
                    .modifier(SettingsContainerModifier())
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("默认音乐应用程序")
                        Spacer()
                        Picker("", selection: $settings.settings.defaultMusicPlayer) {
                            ForEach(DefaultMusicPlayer.allCases) { player in
                                Text(player.displayName)
                                    .tag(player)
                                    .disabled(!player.isAppInstalled && player.webURL == nil)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }
                    .padding()
                    Divider().padding(.leading, 20)
                    HStack { Text("单击实时活动打开详细的音乐小部件"); Spacer(); SettingsSwitch(isOn: $settings.settings.musicOpenOnClick) }.padding()
                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("手势").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "向左滑动可跳过", description: "In the music live activity, swipe left on the album art to go to the next track.", isOn: $settings.settings.swipeToSkipMusic)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "向右滑动即可快退", description: "Swipe right on the album art to go to the previous track.", isOn: $settings.settings.swipeToRewindMusic)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "反转滑动手势", description: "Swipe right to skip and left to go back.", isOn: $settings.settings.invertMusicGestures)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "两指点击即可播放/暂停", description: "Tap the album art with two fingers to toggle playback.", isOn: $settings.settings.twoFingerTapToPauseMusic)
                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("暂停行动").font(.headline).padding([.top, .horizontal])
                    ToggleRow(
                        title: "启用保留操作",
                        description: "Press and hold secondary player buttons (Queue, Devices, Like, Shuffle, Repeat) for an alternate action. Previous / Next / Play are tap-only unless you assign a hold action below. When this is off, Previous/Next still seek while held.",
                        isOn: $settings.settings.musicLongPressActionsEnabled
                    )
                    if settings.settings.musicLongPressActionsEnabled {
                        Divider().padding(.leading, 20)
                        Text("辅助按钮")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        ForEach(settings.settings.musicPlayerButtonOrder.compactMap { MusicLongPressTarget.from(buttonType: $0) }) { target in
                            MusicLongPressActionPickerRow(target: target)
                            Divider().padding(.leading, 20)
                        }
                        Text("交通（可选）")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 4)
                        ForEach([MusicLongPressTarget.previous, .next, .playPause]) { target in
                            MusicLongPressActionPickerRow(target: target)
                            if target != .playPause {
                                Divider().padding(.leading, 20)
                            }
                        }
                    }
                }
                .modifier(SettingsContainerModifier())

                RequiredPermissionsView(section: .music)
                case .player:
                VStack(alignment: .leading, spacing: 0) {
                    HStack { Text("波形对音量敏感"); Spacer(); SettingsSwitch(isOn: $settings.settings.musicWaveformIsVolumeSensitive) }.padding()
                    Divider().padding(.leading, 20)
                    Text("波形图").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "启用渐变", description: "Apply a gradient based on the album art to the waveform.", isOn: $settings.settings.waveformUseGradient)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "使用静态波形", description: "Show a non-animating waveform when music is playing.", isOn: $settings.settings.useStaticWaveform)
                    Divider().padding(.leading, 20)
                    CustomSliderRowView(label: "条数", value: Binding(get: { Double(settings.settings.waveformBarCount) }, set: { settings.settings.waveformBarCount = Int($0) }), range: 3...6, specifier: "%.0f")
                    Divider().padding(.leading, 20)
                    CustomSliderRowView(label: "棒材厚度", value: $settings.settings.waveformBarThickness, range: 1...5, specifier: "%.0f pt")
                    Divider().padding(.leading, 20)
                    Text("Live Activity").font(.headline).padding([.top, .horizontal])
                    VStack(alignment: .leading, spacing: 6) {
                        Text("右侧曲目信息")
                        Text("Show title and artist next to the album art. Phone only is the default — Mac music keeps the compact waveform.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $settings.settings.musicLiveActivityRightTextMode) {
                            ForEach(MusicLiveActivityRightTextMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .onAppear {
                        if settings.settings.musicLiveActivityRightTextMode != .always,
                           settings.settings.musicLiveActivityWaveformMode == .off {
                            settings.settings.musicLiveActivityWaveformMode = .continuityOff
                        }
                    }
                    .onChange(of: settings.settings.musicLiveActivityRightTextMode) { _, mode in
                        if mode != .always, settings.settings.musicLiveActivityWaveformMode == .off {
                            settings.settings.musicLiveActivityWaveformMode = .continuityOff
                        }
                    }
                    Divider().padding(.leading, 20)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("波形")
                        Text("默认情况下隐藏在手机上。当右侧轨道信息为“始终”时，可以完全关闭波形。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker(
                            "",
                            selection: Binding(
                                get: { settings.settings.musicLiveActivityWaveformMode },
                                set: { newValue in
                                    if newValue == .off && settings.settings.musicLiveActivityRightTextMode != .always {
                                        settings.settings.musicLiveActivityWaveformMode = .continuityOff
                                    } else {
                                        settings.settings.musicLiveActivityWaveformMode = newValue
                                    }
                                }
                            )
                        ) {
                            ForEach(
                                MusicLiveActivityWaveformMode.allCases.filter {
                                    $0 != .off || settings.settings.musicLiveActivityRightTextMode == .always
                                }
                            ) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    Divider().padding(.leading, 20)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("波形样式")
                            Text("经典的是条形波形。连续性是旧电话媒体活动使用的 SF 符号。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $settings.settings.musicLiveActivityWaveformStyle) {
                            ForEach(MusicLiveActivityWaveformStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                    .padding()
                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 10) {
                    Text("自定义播放器按钮").font(.headline).padding([.horizontal, .top])
                    Text("启用并重新排序音乐播放器中显示的按钮。前两个启用的按钮将出现在主控制栏中。").font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 5)
                    ReorderableVStack(items: $settings.settings.musicPlayerButtonOrder) { buttonType in PlayerButtonSettingsRow(buttonType: buttonType) }
                }
                .modifier(SettingsContainerModifier())

                VStack(spacing: 0) {
                    ToggleRow(title: "在 Hover 上启用曲目信息", description: "Hover over the album art in the live activity to see the song title.", isOn: $settings.settings.enableQuickPeekOnHover)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "在曲目更改上显示曲目信息", description: "Briefly show the song title when a new track begins.", isOn: $settings.settings.showQuickPeekOnTrackChange)
                }.modifier(SettingsContainerModifier())
                case .features:
                MusicPlayerFeaturesCard(isSpotifyAvailable: isPrivateAuth)
                case .accounts:
                AppleMusicAccountCard()

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Spotify").font(.headline)
                        Spacer()
                        Picker("", selection: $settings.settings.spotifyAPIMode) {
                            ForEach(SpotifyAPIMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                    .padding([.horizontal, .top])

                    switch settings.settings.spotifyAPIMode {
                    case .privateAPI:
                        InfoContainer(text: "WARNING: This method uses Spotify’s internal APIs to unlock standard and additional features for both Premium and non-Premium users. Use at your own risk, usage may be subject to Spotify’s Terms of Service.", iconName: "exclamationmark.triangle.fill", color: .yellow).padding(.horizontal)
                        InfoContainer(text: "Sapphire is a Connect controller only, audio always plays on the Spotify desktop app or another speaker.", iconName: "hifispeaker", color: .blue).padding(.horizontal)
                        if isOfficialAuth {
                            Text("您还使用官方 API 登录。").font(.caption).foregroundColor(.secondary).padding(.horizontal)
                        }
                        Divider().padding(.horizontal, 20)
                        if isPrivateAuth {
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                    Text("通过私有API登录")
                                    Spacer()
                                    Button("退出", role: .destructive) { MusicManager.shared.spotifyPrivateAPI.logout() }
                                }.padding()
                                Divider().padding(.leading, 20)
                                ToggleRow(title: "跳过广告", description: "When Spotify desktop on this Mac plays an ad, relaunch it in the background, then resume via Spotify Connect.", isOn: $settings.settings.skipSpotifyAd)
                                ToggleRow(title: "显示 Spotify 选项卡", description: "When another app is playing, show a Spotify source tab so you can switch medias. Hidden while Spotify itself is the main media source.", isOn: $settings.settings.showSpotifySourceTab)
                                    .disabled(!isPrivateAuth)
                                ToggleRow(title: "实时画布视频", description: "Show looping Spotify Canvas video behind the artwork when available. Turn off to always use the album thumbnail.", isOn: $settings.settings.spotifyCanvasLiveVideo)
                                    .disabled(!isPrivateAuth)
                            }
                        } else {
                            VStack(spacing: 12) {
                                if let error = privateApiError {
                                    Text(error).font(.caption).foregroundColor(.red)
                                }
                                if isPrivateApiLoading {
                                    ProgressView().frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    Button("通过私有API登录") { handlePrivateApiLogin() }
                                        .buttonStyle(.borderedProminent).tint(.accentColor)
                                }
                            }.padding()
                        }
                    case .officialAPI:
                        InfoContainer(text: "The Private API provides significantly more features and is better supported. The Official API only covers basic playback and device switching, and needs your own developer app.", iconName: "exclamationmark.triangle.fill", color: .yellow).padding(.horizontal)
                        if isPrivateAuth {
                            Text("您还使用 Private API 登录。").font(.caption).foregroundColor(.secondary).padding(.horizontal)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spotify API 凭证").font(.system(size: 14, weight: .medium))
                            Text("在developer.spotify.com 注册您的应用程序并在此处复制这些值。重定向 URI 为：sapphire://callback").font(.caption).foregroundColor(.secondary).padding(.bottom, 4)
                            Text("客户ID").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                            SecureField("输入您的客户 ID", text: Binding(
                                get: { APIKeyManager.shared.spotifyClientId },
                                set: { APIKeyManager.shared.spotifyClientId = $0 }
                            )).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2)))
                            Text("客户秘密").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.8)).padding(.top, 5)
                            SecureField("输入您的客户密码", text: Binding(
                                get: { APIKeyManager.shared.spotifyClientSecret },
                                set: { APIKeyManager.shared.spotifyClientSecret = $0 }
                            )).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2)))
                        }.padding().padding(.top, 5)
                        Text("登录此处可为高级用户启用设备切换等官方功能。").font(.caption).foregroundColor(.secondary).padding(.horizontal)
                        Divider().padding(.horizontal, 20)
                        HStack {
                            if isOfficialAuth {
                                HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(.green); Text(officialDisplayName.map { "Logged in as \($0)" } ?? "Logged in") }
                                Spacer()
                                Button("退出", role: .destructive) { MusicManager.shared.spotifyOfficialAPI.logout() }
                            } else {
                                Text("Not logged in.").foregroundColor(.secondary)
                                Spacer()
                                Button("登录") { MusicManager.shared.spotifyOfficialAPI.login() }
                            }
                        }.padding()
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: isPrivateAuth)
                .animation(.default, value: isOfficialAuth)
                .animation(.default, value: settings.settings.spotifyAPIMode)

                VStack(alignment: .leading, spacing: 10) {
                    Text("TIDAL").font(.headline).padding([.horizontal, .top])
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TIDAL API 凭证").font(.system(size: 14, weight: .medium))
                        Text("在developer.tidal.com上创建一个应用程序，启用user.read、search.read、collection.read/write和playlists.read/write作用域，并将重定向URI准确设置为sapphire://callback。").font(.caption).foregroundColor(.secondary).padding(.bottom, 4)
                        Text("客户ID").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                        SecureField("输入您的客户 ID", text: Binding(
                            get: { APIKeyManager.shared.tidalClientId },
                            set: { APIKeyManager.shared.tidalClientId = $0 }
                        )).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2)))
                        Text("客户秘密").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.8)).padding(.top, 5)
                        SecureField("输入您的客户密码", text: Binding(
                            get: { APIKeyManager.shared.tidalClientSecret },
                            set: { APIKeyManager.shared.tidalClientSecret = $0 }
                        )).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2)))
                    }.padding().padding(.top, 5)
                    Text("在此登录以启用 TIDAL 功能，例如目录搜索和同步喜欢的曲目和播放列表。需要 TIDAL 开发者帐户（第三方访问层）。").font(.caption).foregroundColor(.secondary).padding(.horizontal)
                    Divider().padding(.horizontal, 20)
                    HStack {
                        if isTidalAuth {
                            HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(.green); Text(tidalDisplayName.map { "Logged in as \($0)" } ?? "Logged in") }
                            Spacer()
                            Button("退出", role: .destructive) { MusicManager.shared.tidalAPI.logout() }
                        } else {
                            Text("Not logged in.").foregroundColor(.secondary)
                            Spacer()
                            Button("登录") { isShowingTidalLogin = true }
                        }
                    }.padding()
                    if !isTidalAuth, let tidalLoginError {
                        Text(tidalLoginError).font(.caption).foregroundColor(.red).padding([.horizontal, .bottom])
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: isTidalAuth)

                VStack(spacing: 0) {
                    ToggleRow(title: "相比 Spotify 设备更喜欢 Airplay", description: "Default to airplay devices when spotify isn't running and spotify is authenticated", isOn: $settings.settings.preferAirPlayOverSpotify)
                }.modifier(SettingsContainerModifier())
                case .lyrics:
                VStack(alignment: .leading, spacing: 0) {
                    Text("Lyrics").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "在现场活动中显示歌词", description: "Display synchronized lyrics when available.", isOn: $settings.settings.showLyricsInLiveActivity)
                    if settings.settings.showLyricsInLiveActivity {
                        Divider().padding(.leading, 20)
                        ToggleRow(
                            title: "全屏隐藏歌词",
                            description: "Hide the lyrics line while an app is full screen, on every display. Set it per display in Appearance → Displays.",
                            isOn: Binding(
                                get: { settings.settings.hideLyricsInFullScreen },
                                set: { settings.settings.value.setHideLyricsInFullScreenOnAllDisplays($0) }
                            )
                        )
                        Divider().padding(.leading, 20)
                        ToggleRow(title: "启用翻译", description: "Automatically translate non-English lyrics.", isOn: $settings.settings.enableLyricTranslation)
                        HStack {
                            Text("翻译为"); Spacer()
                            Picker("", selection: $settings.settings.lyricTranslationLanguage) { Text("English").tag("en"); Text("西班牙语").tag("es"); Text("法语").tag("fr") }.labelsHidden().frame(width: 150)
                        }.padding().disabled(!settings.settings.enableLyricTranslation).opacity(settings.settings.enableLyricTranslation ? 1.0 : 0.5)
                        Divider().padding(.leading, 20)
                        HStack {
                            Text("抒情延迟"); Spacer()
                            let offset = settings.settings.lyricOffset
                            let label = offset == 0 ? "On time" : String(format: "%+.1fs", offset)
                            Text(label).font(.caption).foregroundColor(.secondary)
                            Stepper("", value: $settings.settings.lyricOffset, in: -5.0...5.0, step: 0.1)
                                .labelsHidden()
                        }.padding()
                        if #available(macOS 26.0, *) {
                            Divider().padding(.leading, 20)
                            ToggleRow(
                                title: "生成逐字计时",
                                description: "When a song only has line timing, listen to the music app's audio on this Mac to time each word, and share good results. Asks for audio access and downloads Apple's speech model once.",
                                isOn: $settings.settings.generateWordTimedLyrics
                            )
                        }
                    }
                }
                .modifier(SettingsContainerModifier())
                .animation(.default, value: settings.settings.showLyricsInLiveActivity)

                if settings.settings.showLyricsInLiveActivity {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("允许歌词来自：").font(.headline).padding([.horizontal, .top])
                        AppTogglesListView(
                            isEnabled: { app in binding(for: app, isBrowser: app.isBrowser) },
                            maxHeight: 360,
                            browsersSectionTitle: "Browsers (Disabled by Default)"
                        )
                    }.modifier(SettingsContainerModifier()).transition(.opacity.combined(with: .move(edge: .top)))
                }
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                syncMusicAuthState()
            }
            .onReceive(MusicManager.shared.valuePublisher(\.isPrivateAPIAuthenticated)) { isPrivateAuth = $0 }
            .onReceive(MusicManager.shared.valuePublisher(\.isOfficialAPIAuthenticated)) { isOfficialAuth = $0 }
            .onReceive(MusicManager.shared.valuePublisher(\.isTidalAPIAuthenticated)) { isTidalAuth = $0 }
            .onReceive(MusicManager.shared.tidalAPI.valuePublisher(\.userProfile)) { profile in
                tidalDisplayName = profile?.username
            }
            .onReceive(MusicManager.shared.tidalAPI.valuePublisher(\.loginError)) { tidalLoginError = $0 }
            .onReceive(MusicManager.shared.spotifyOfficialAPI.valuePublisher(\.userProfile)) { profile in
                officialDisplayName = profile?.displayName
            }
            .onReceive(SpotifyPrivateAPIManager.shared.valuePublisher(\.loginChallenge)) { loginChallenge = $0 }
        }
        .sheet(isPresented: $isShowingTidalLogin) {
            TidalLoginWebView(
                onComplete: { isShowingTidalLogin = false },
                onCancel: { isShowingTidalLogin = false }
            )
        }
        .sheet(item: $loginChallenge) { _ in
            SpotifyLoginWebView(
                onComplete: { cookieProperties in
                    MusicManager.shared.spotifyPrivateAPI.completeLoginAfterWebViewSuccess(with: cookieProperties)
                    MusicManager.shared.spotifyPrivateAPI.loginChallenge = nil
                    isPrivateApiLoading = false
                },
                onCancel: {
                    privateApiError = "Login was cancelled."
                    MusicManager.shared.spotifyPrivateAPI.loginChallenge = nil
                    isPrivateApiLoading = false
                }
            )
        }
    }

    private func syncMusicAuthState() {
        let music = MusicManager.shared
        music.spotifyPrivateAPI.bootstrapIfNeeded(policy: .onDemand)
        isPrivateAuth = music.isPrivateAPIAuthenticated
        isOfficialAuth = music.isOfficialAPIAuthenticated
        isTidalAuth = music.isTidalAPIAuthenticated
        tidalDisplayName = music.tidalAPI.userProfile?.username
        officialDisplayName = music.spotifyOfficialAPI.userProfile?.displayName
        tidalLoginError = music.tidalAPI.loginError
        loginChallenge = music.spotifyPrivateAPI.loginChallenge
        if isOfficialAuth, !isPrivateAuth, settings.settings.spotifyAPIMode == .privateAPI {
            settings.settings.spotifyAPIMode = .officialAPI
        }
    }

    private func handlePrivateApiLogin() {
        isPrivateApiLoading = true
        privateApiError = nil
        MusicManager.shared.spotifyPrivateAPI.login()
    }

    private func binding(for app: SystemApp, isBrowser: Bool) -> Binding<Bool> {
        .init(
            get: { settings.settings.musicAppStates[app.id, default: !isBrowser] },
            set: { settings.settings.musicAppStates[app.id] = $0 }
        )
    }

    private func mediaVisibilityBinding(for app: SystemApp, isBrowser: Bool) -> Binding<Bool> {
        .init(
            get: {
                settings.settings.mediaAppVisibility[app.id]
                    ?? true
            },
            set: { settings.settings.mediaAppVisibility[app.id] = $0 }
        )
    }
}

fileprivate struct MusicLongPressActionPickerRow: View {
    let target: MusicLongPressTarget
    @EditingSettings var settings: SettingsEditingSession

    private var selection: Binding<MusicLongPressAction> {
        Binding(
            get: { target.defaultAction(in: settings.settings.value) },
            set: { settings.settings.value.setLongPressAction($0, for: target) }
        )
    }

    var body: some View {
        HStack {
            Text("Hold \(target.displayName)")
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Picker("", selection: selection) {
                ForEach(target.pickerOptions) { action in
                    Text(action.displayName).tag(action)
                }
            }
            .labelsHidden()
            .frame(width: 190)
        }
        .padding()
    }
}

fileprivate struct PlayerButtonSettingsRow: View {
    let buttonType: MusicPlayerButtonType
    @EditingSettings var settings: SettingsEditingSession

    private var isEnabledBinding: Binding<Bool> {
        switch buttonType {
        case .like: return $settings.settings.musicLikeButtonEnabled
        case .shuffle: return $settings.settings.musicShuffleButtonEnabled
        case .repeat: return $settings.settings.musicRepeatButtonEnabled
        case .playlists: return $settings.settings.musicPlaylistsButtonEnabled
        case .devices: return $settings.settings.musicDevicesButtonEnabled
        }
    }

    var body: some View {
        HStack {
            Image(systemName: buttonType.systemImage)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 30)

            Text(buttonType.displayName)
                .font(.system(size: 14, weight: .medium))

            Spacer()

            SettingsSwitch(isOn: isEnabledBinding)

            ReorderHandle()
        }
        .padding(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
    }
}

struct WeatherSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Weather")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(spacing: 0) {
                    HStack {
                        Text("使用摄氏度")
                        Spacer()
                        Toggle("", isOn: $settings.settings.weatherUseCelsius)
                            .labelsHidden().toggleStyle(.switch)
                    }
                    .padding()

                    Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1).padding(.leading, 20)

                    HStack {
                        Text("使用公制单位")
                        Spacer()
                        Toggle("", isOn: $settings.settings.weatherUseMetricSystem)
                            .labelsHidden().toggleStyle(.switch)
                    }
                    .padding()

                    Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1).padding(.leading, 20)

                    HStack {
                        Text("单击实时活动打开详细的天气小部件")
                        Spacer()
                        Toggle("", isOn: $settings.settings.weatherOpenOnClick)
                            .labelsHidden().toggleStyle(.switch)
                    }
                    .padding()
                }
                .modifier(SettingsContainerModifier())

                RequiredPermissionsView(section: .weather)
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct CalendarSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    private var isLastEnabledWidget: Bool {
        settings.settings.calendarWidgetEnabled && settings.settings.enabledWidgetTypes.count <= 1
    }

    private var isAtCapacity: Bool {
        !settings.settings.calendarWidgetEnabled && !WidgetLayoutPolicy.canFit(
            .calendar,
            in: settings.settings.enabledWidgetTypes,
            availableWidth: WidgetLayoutPolicy.availableBarWidthForSettings(settings: settings.settings.value),
            showDividers: settings.settings.showDividersBetweenWidgets,
            bypassSpaceLimit: settings.settings.bypassWidgetSpaceLimit
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("日历和提醒")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "启用日历小部件",
                        description: isAtCapacity
                            ? "Not enough notch space on this display."
                            : "Show the calendar widget in the notch widget strip.",
                        isOn: $settings.settings.calendarWidgetEnabled
                    )
                    .disabled(isLastEnabledWidget || isAtCapacity)

                    Divider().padding(.leading, 20)

                    ToggleRow(
                        title: "启用日历实时活动",
                        description: "Show upcoming events as a live activity in the notch.",
                        isOn: $settings.settings.calendarLiveActivityEnabled
                    )
                }
                .modifier(SettingsContainerModifier())

                VStack(spacing: 0) {
                    HStack {
                        Text("显示全天活动")
                        Spacer()
                        Toggle("", isOn: $settings.settings.calendarShowAllDayEvents)
                            .labelsHidden().toggleStyle(.switch)
                    }
                    .padding()

                    Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1).padding(.leading, 20)

                    HStack {
                        Text("开始一周")
                        Spacer()
                        Picker("", selection: $settings.settings.calendarStartOfWeek) {
                            ForEach(Day.allCases) { day in
                                Text(day.id).tag(day)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)
                    }
                    .padding()

                    Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1).padding(.leading, 20)

                    ToggleRow(
                        title: "单击打开日历",
                        description: "Clicking the Calendar live activity will open the expanded calendar view.",
                        isOn: $settings.settings.calendarOpenOnClick
                    )
                }
                .modifier(SettingsContainerModifier())

                RequiredPermissionsView(section: .calendar)
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
struct EyeBreakRecommendationsView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("眼睛健康建议")
                    .font(.title2.bold())
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                LazyVStack(alignment: .center, spacing: 20) {
                    recommendationCard(
                        title: "20-20-20 规则",
                        description: "每 20 分钟休息 20 秒，看看 20 英尺外的东西。这有助于减轻眼睛疲劳，让眼部肌肉得到休息。",
                        icon: "eyes",
                        color: .blue
                    )

                    recommendationCard(
                        title: "调整你的屏幕",
                        description: "将显示器放置在距眼睛一臂远的位置，并调整屏幕角度，使其顶部处于或略低于视线水平。这可以减轻颈部和眼睛的压力。",
                        icon: "display",
                        color: .green
                    )

                    recommendationCard(
                        title: "减少蓝光",
                        description: "使用 Mac 上的 Night Shift 可以减少蓝光照射，尤其是在黑暗环境中或在深夜，蓝光会干扰睡眠。",
                        icon: "moon.stars.fill",
                        color: .orange
                    )

                    recommendationCard(
                        title: "优化照明",
                        description: "确保您的工作空间拥有充足的照明，不会在屏幕上造成眩光。避免在只有屏幕灯的黑暗房间里工作。",
                        icon: "lightbulb.fill",
                        color: .yellow
                    )

                    recommendationCard(
                        title: "保持水分",
                        description: "全天喝大量的水。脱水会导致眼睛干涩和眼睛疲劳。",
                        icon: "drop.fill",
                        color: .cyan
                    )
                }
            }

            Button("明白了") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(width: 500, height: 600)
    }

    private func recommendationCard(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .frame(minWidth: 400)
        .cornerRadius(12)
    }
}

struct EyeBreakSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var eyeBreakManager = EyeBreakManager.shared
    @State private var showingRecommendationsSheet = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Eye Break")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(
                        title: "启用眼睛休息提醒",
                        description: "Receive live activities reminding you to take breaks.",
                        isOn: $settings.settings.eyeBreakLiveActivityEnabled
                    )
                    .onChange(of: settings.settings.eyeBreakLiveActivityEnabled) {
                        eyeBreakManager.dismissBreak()
                    }
                }
                .modifier(SettingsContainerModifier())

                Group {
                    currentStatusSection
                    configurationSection
                    statisticsSection
                    resetSection
                }
                .disabled(!settings.settings.eyeBreakLiveActivityEnabled)
                .opacity(settings.settings.eyeBreakLiveActivityEnabled ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.2), value: settings.settings.eyeBreakLiveActivityEnabled)
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .sheet(isPresented: $showingRecommendationsSheet) {
                EyeBreakRecommendationsView()
            }
        }
    }

    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("眼裂状态")
                    .font(.headline)
                Spacer()

                if eyeBreakManager.isPausedForGameMode {
                    Text("游戏模式暂停")
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                } else if eyeBreakManager.isBreakTime {
                    Text("进展中的突破")
                        .foregroundColor(.blue)
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text("\(eyeBreakManager.secondsUntilNextBreak.asMinuteSecondClock) until next break")
                            .foregroundColor(.secondary)
                    }
                }
            }.padding(15)

            if eyeBreakManager.isBreakTime {
                VStack(alignment: .leading, spacing: 4) {
                    Text("将视线从屏幕上移开")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("聚焦于至少 20 英尺外的物体")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ProgressView(value: 1 - (eyeBreakManager.timeRemainingInBreak / TimeInterval(settings.settings.eyeBreakBreakDuration)))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.vertical, 4)

                    HStack {
                        Spacer()

                        Button("跳过") {
                            eyeBreakManager.dismissBreak()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)

                        Button("完全休息") {
                            eyeBreakManager.completeBreak()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
            } else {
                HStack(spacing: 20) {
                    VStack(alignment: .center) {
                        Text("\(eyeBreakManager.breaksTakenToday)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.blue)
                        Text("休息时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    VStack(alignment: .center) {
                        Text("\(eyeBreakManager.currentStreak)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                        Text("连续日数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    VStack(alignment: .center) {
                        Text("\(eyeBreakManager.eyeStrainScore)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(healthColor)
                        Text("眼睛健康")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .modifier(SettingsContainerModifier())
    }

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Configuration").font(.headline).padding([.top, .horizontal])

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("20-20-20 规则")
                        .font(.subheadline)
                    Text("每 20 分钟休息 20 秒，看看 20 英尺外的东西。")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("了解更多") {
                        showingRecommendationsSheet = true
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
                Spacer()
                Image(systemName: "eyes")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding([.horizontal, .top])

            Divider()
                .padding(.horizontal)
                .padding(.vertical, 10)

            CustomSliderRowView(
                label: "工作间隔",
                value: $settings.settings.eyeBreakWorkInterval,
                range: 5...60,
                specifier: "%.0f min",
                onEditingChanged: { isEditing in
                    if !isEditing {
                        eyeBreakManager.dismissBreak()
                    }
                }
            )

            Divider().padding(.leading, 20)

            CustomSliderRowView(
                label: "休息时间",
                value: $settings.settings.eyeBreakBreakDuration,
                range: 10...60,
                specifier: "%.0f sec",
                onEditingChanged: { isEditing in
                    if !isEditing {
                        eyeBreakManager.dismissBreak()
                    }
                }
            )

            Divider().padding(.leading, 20)

            ToggleRow(
                title: "播放声音警报",
                description: "Play sounds when breaks begin and end.",
                isOn: $settings.settings.eyeBreakSoundAlerts
            )

            Divider().padding(.leading, 20)

            ToggleRow(
                title: "游戏模式期间暂停",
                description: "Pause reminders and sounds while macOS Game Mode is active.",
                isOn: $settings.settings.eyeBreakPauseDuringGameMode
            )

            Divider().padding(.leading, 20)

            ToggleRow(
                title: "显示活动图",
                description: "Display a visual graph of your work and break intervals.",
                isOn: $settings.settings.showEyeBreakGraph
            )
        }
        .modifier(SettingsContainerModifier())
        .animation(.default, value: settings.settings.showEyeBreakGraph)
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("活动统计").font(.headline).padding([.top, .horizontal])
            if settings.settings.showEyeBreakGraph {
                EyeBreakGraphView(summaries: eyeBreakManager.dailySummaries)
                    .environment(settings)
                    .padding([.horizontal, .bottom])
                    .transition(.opacity)
            } else {
                Text("启用上面的活动图表以查看您的眼睛疲劳统计数据。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .modifier(SettingsContainerModifier())
        .animation(.default, value: settings.settings.showEyeBreakGraph)
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("重置和数据").font(.headline).padding([.top, .horizontal])
            Button(action: {
                eyeBreakManager.dismissBreak()
            }) {
                HStack {
                    Text("重置定时器")
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                }
                .padding()
            }
            .buttonStyle(.plain)

            Divider().padding(.horizontal)

            Button(action: {
                UserDefaults.standard.removeObject(forKey: "EyeBreakHistory")
                eyeBreakManager.dismissBreak()
            }) {
                HStack {
                    Text("清除所有历史记录")
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .padding()
            }
            .buttonStyle(.plain)
        }
        .modifier(SettingsContainerModifier())
    }

    private var healthColor: Color {
        let score = eyeBreakManager.eyeStrainScore
        if score > 75 { return .green }
        if score > 50 { return .yellow }
        return .red
    }

}

struct EyeBreakGraphView: View {
    let summaries: [EyeBreakDailySummary]
    @EditingSettings var settings: SettingsEditingSession
    @State private var selectedDayName: String?

    private var selectedSummary: EyeBreakDailySummary? {
        chartData.first { $0.dayName == selectedDayName }?.originalSummary
    }

    private struct ChartableBreakData: Identifiable {
        var id: String { dayName }
        let dayName: String
        let completedBreaks: Int
        let missedBreaks: Int
        let originalSummary: EyeBreakDailySummary
    }

    private var chartData: [ChartableBreakData] {
        summaries.map { summary in
            let workIntervalInSeconds = settings.settings.eyeBreakWorkInterval * 60
            let totalIntervals = workIntervalInSeconds > 0 ? Int(summary.workDuration / workIntervalInSeconds) : 0
            let missed = max(0, totalIntervals - summary.completedBreaks)

            return ChartableBreakData(
                dayName: summary.dayName,
                completedBreaks: summary.completedBreaks,
                missedBreaks: missed,
                originalSummary: summary
            )
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            keyMetricsView

            HStack {
                Text("每周眼睛休息活动")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 5)

            barChart
                .frame(height: 180)

            dailySummariesView
        }
    }

    private var keyMetricsView: some View {
        HStack(spacing: 12) {
            MetricCardView(
                title: "今天的休息时间",
                value: "\(summaries.first?.completedBreaks ?? 0)",
                icon: "eyes",
                color: .blue,
                trend: "+\(summaries.first?.completedBreaks ?? 0) today"
            )

            MetricCardView(
                title: "合规性",
                value: "\(Int((summaries.first?.complianceRate ?? 0) * 100))%",
                icon: "checkmark.circle",
                color: complianceColor,
                trend: complianceTrend
            )

            MetricCardView(
                title: "当前连胜",
                value: "\(EyeBreakManager.shared.currentStreak)",
                icon: "bolt",
                color: .orange,
                trend: "days in a row"
            )

            MetricCardView(
                title: "眼睛健康",
                value: "\(summaries.first?.eyeStrainScore ?? 100)",
                icon: "heart.text.square",
                color: eyeHealthColor,
                trend: "/100"
            )
        }
    }

    private var barChart: some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Day", dataPoint.dayName),
                y: .value("Breaks", dataPoint.completedBreaks)
            )
            .foregroundStyle(by: .value("Type", "Completed"))
            .cornerRadius(6)

            BarMark(
                x: .value("Day", dataPoint.dayName),
                y: .value("Breaks", dataPoint.missedBreaks)
            )
            .foregroundStyle(by: .value("Type", "Missed"))
            .cornerRadius(6)
        }
        .materialChartPlotStyle()
        .chartForegroundStyleScale([
            "Completed": MaterialChartPalette.primary,
            "Missed": MaterialChartPalette.error.opacity(0.65)
        ])
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(MaterialChartPalette.outline)
                AxisValueLabel("\(value.as(Int.self) ?? 0)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
        }
        .chartXAxis {
            AxisMarks {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(MaterialChartPalette.outline)
                AxisValueLabel()
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
        }
        .chartLegend(position: .top, alignment: .trailing)
        .chartXSelection(value: $selectedDayName)
    }

    private var dailySummariesView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("日常活动")
                .font(.headline)
                .padding(.horizontal, 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(summaries) { summary in
                        DailySummaryCard(summary: summary, isSelected: selectedSummary?.id == summary.id)
                            .onTapGesture {
                                selectedDayName = summary.dayName
                            }
                    }
                }
                .padding(10)
                .padding(.horizontal, 0)
            }
        }
    }

    private var complianceColor: Color {
        let rate = summaries.first?.complianceRate ?? 0
        if rate > 0.8 { return .green }
        if rate > 0.5 { return .yellow }
        return .red
    }

    private var complianceTrend: String {
        let current = summaries.first?.complianceRate ?? 0
        let previous = summaries.dropFirst().first?.complianceRate ?? 0

        if current > previous {
            return "↑ Improving"
        } else if current < previous {
            return "↓ Declining"
        }
        return "→ Steady"
    }

    private var eyeHealthColor: Color {
        let score = summaries.first?.eyeStrainScore ?? 100
        if score > 75 { return .green }
        if score > 50 { return .yellow }
        return .red
    }
}

struct MetricCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(trend)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct DailySummaryCard: View {
    let summary: EyeBreakDailySummary
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.dayName)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(healthStatusColor)
                    .frame(width: 10, height: 10)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("工作")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(summary.formattedWorkTime)
                        .font(.system(size: 12, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Breaks")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(summary.completedBreaks)")
                        .font(.system(size: 12, weight: .medium))
                }
            }

            HStack {
                Text("合规性：")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                ProgressView(value: summary.complianceRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: healthStatusColor))
                    .frame(width: 60)

                Text("\(Int(summary.complianceRate * 100))%")
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .padding(10)
        .frame(width: 200)
        .background(isSelected ? Color.secondary.opacity(0.2) : Color.secondary.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private var healthStatusColor: Color {
        let score = summary.eyeStrainScore
        if score > 75 { return .green }
        if score > 50 { return .yellow }
        return .red
    }
}

struct BluetoothSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Bluetooth")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                VStack(spacing: 0) {
                    Text("Notifications").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "电池电量低时通知", description: "Show an alert when a connected device's battery is low.", isOn: $settings.settings.bluetoothNotifyLowBattery)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "播放连接声音", description: "Play a sound when devices connect or disconnect.", isOn: $settings.settings.bluetoothNotifySound)
                }
                .modifier(SettingsContainerModifier())

                VStack(spacing: 0) {
                    Text("Live Activity").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "显示蓝牙实时活动", description: "Show connection, disconnection, and battery events for Bluetooth devices.", isOn: $settings.settings.bluetoothLiveActivityEnabled)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "显示连续性设备", description: "Show live activity events for Apple devices like iPhone, iPad, Mac, and Apple Watch.", isOn: $settings.settings.showBluetoothContinuityDevices)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "显示设备名称", description: "Display the device name in the live activity for connection and battery events.", isOn: $settings.settings.showBluetoothDeviceName)
                }
                .modifier(SettingsContainerModifier())

                RequiredPermissionsView(section: .bluetooth)
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct NearbyShareSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    @State private var downloadPath: String = ""
    @State private var isPathValid: Bool = true
    @State private var settingsHaveChanged: Bool = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 40) {
                // MARK: - Nearby Share Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Nearby Share")
                        .font(.largeTitle.bold())
                        .padding(.bottom)

                    VStack(spacing: 0) {
                        HStack {
                            Text("启用附近共享")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            SettingsSwitch(isOn: $settings.settings.nearbyShareEnabled)
                        }
                        .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))

                        Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1).padding(.horizontal, 20)

                        InfoContainer(
                            text: "Nearby Share allows you to share files from Android phones to your Mac using Android's native file sharing (Nearby Share / Quick Share). It's recommended to keep this feature enabled for convenient sharing from family and friends.",
                            iconName: "info.circle.fill",
                            color: .blue
                        )
                        .padding()

                        VStack(alignment: .leading, spacing: 15) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("设备显示名称")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)

                                TextField("My Mac", text: $settings.settings.nearbyShareDeviceDisplayName)
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    .foregroundStyle(.white)
                                    .font(.system(size: 13))
                                    .disabled(!settings.settings.nearbyShareEnabled)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("下载位置")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)

                                HStack {
                                    TextField("路径", text: $downloadPath, onCommit: validateAndSavePath)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(.white)
                                        .font(.system(size: 13))
                                        .disabled(!settings.settings.nearbyShareEnabled)

                                    Image(systemName: isPathValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isPathValid ? .green : .red)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isPathValid ? Color.white.opacity(0.2) : Color.red, lineWidth: 1))

                                if !isPathValid {
                                    Text("需要一个有效的目录。")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding([.horizontal, .bottom], 20)
                        .opacity(settings.settings.nearbyShareEnabled ? 1.0 : 0.5)

                        Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1).padding(.horizontal, 20)

                        HStack {
                            Text("单击实时活动即可打开详细的 AirDrop 小部件")
                            Spacer()
                            Toggle("", isOn: $settings.settings.nearbyShareOpenOnClick)
                                .labelsHidden().toggleStyle(.switch)
                        }
                        .padding()
                        .disabled(!settings.settings.nearbyShareEnabled)
                        .opacity(settings.settings.nearbyShareEnabled ? 1.0 : 0.5)

                    }
                    .modifier(SettingsContainerModifier())
                    .animation(.easeInOut, value: settings.settings.nearbyShareEnabled)

                    SettingsCard(title: "滑动操作", description: "自定义向左或向右滑动文件拖放行时会发生什么。共享仅适用于文件架项目。") {

                        SwipeActionPickerRow(
                            title: "向右滑动",
                            description: "在文件放置行上引导滑动。",
                            selection: $settings.settings.swipeActionSettings.fileDropLeading,
                            options: FileDropSwipeAction.allCases,
                            label: { $0.displayName }
                        )

                        Divider().padding(.leading, 20)

                        SwipeActionPickerRow(
                            title: "向左滑动",
                            description: "在文件拖放行上尾随滑动。",
                            selection: $settings.settings.swipeActionSettings.fileDropTrailing,
                            options: FileDropSwipeAction.allCases,
                            label: { $0.displayName }
                        )
                    }
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                self.downloadPath = settings.settings.nearbyShareDownloadLocationPath
            }
            .onChange(of: downloadPath) { _, newValue in
                self.isPathValid = validate(path: newValue)
            }
            .onChange(of: settings.settings.nearbyShareEnabled) {
                settingsHaveChanged = true
            }
            .onChange(of: settings.settings.nearbyShareDeviceDisplayName) {
                settingsHaveChanged = true
            }
            .animation(.spring(), value: settingsHaveChanged)

            RequiredPermissionsView(section: .nearbyShare)
        }
    }

    private func validateAndSavePath() {
        if validate(path: downloadPath) {
            settings.settings.nearbyShareDownloadLocationPath = downloadPath
        }
    }

    private func validate(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

struct AboutSettingsView: View {
    private static let backupDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter
    }()

    @EditingSettings var settingsModel: SettingsEditingSession
    @ObservedObject private var updateChecker = UpdateChecker.shared
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    @ObservedObject private var debugMode = DebugMode.shared
    @State private var isExportingSettings = false
    @State private var isImportingSettings = false
    @State private var backupDocument = SettingsBackupDocument(settings: Settings())
    @State private var backupStatusMessage: BackupStatusMessage?
    @State private var showingResetConfirmation = false
    @State private var debugTapCount = 0
    @State private var debugTapResetTask: Task<Void, Never>?

    private var displayedReleaseChannel: ReleaseChannel {
        ReleaseChannelPolicy.displayedChannel(for: settingsModel.settings.value)
    }

    private var releaseChannelBinding: Binding<ReleaseChannel> {
        Binding(
            get: { displayedReleaseChannel },
            set: { newValue in
                guard SubscriptionAccess.hasAccess(to: .betaSoftwareUpdates) || newValue == .stable else { return }
                settingsModel.settings.releaseChannel = newValue
            }
        )
    }

    private var versionLabel: String {
        if BetaEntitlementRuntime.isBetaBuild {
            return "Version \(currentAppVersion) Beta"
        }
        return "Version \(currentAppVersion)"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("About").font(.largeTitle.bold()).padding(.bottom)

                HStack {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            if debugMode.isEnabled {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(Circle().fill(Color.orange))
                                    .offset(x: 6, y: 6)
                            }
                        }
                        .padding(.trailing, 10)
                        .contentShape(Rectangle())
                        .onTapGesture { handleDebugIconTap() }
                        .help(debugMode.isEnabled ? "Debug mode is ON — tap 5× quickly to disable" : "Tap 5× quickly to enable debug mode")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sapphire").font(.largeTitle.weight(.bold))
                        Text(versionLabel).foregroundStyle(.secondary).textSelection(.enabled)

                        if debugMode.isEnabled {
                            Label("调试模式启用", systemImage: "hammer.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }

                        HStack(spacing: 10) {
                            Link(destination: URL(string: "https://sapphire-app.tech/")!) {
                                Image(systemName: "link")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Link(destination: URL(string: "https://github.com/cshariq/Sapphire")!) {
                                Image("github_logo")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Link(destination: URL(string: "https://discord.gg/TdRjC2kNnU")!) {
                                Image("discord_logo")
                                    .resizable()
                                        .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .padding(6)
                                    .background(Color(red: 0.35, green: 0.40, blue: 0.95))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 6)
                    }
                    Spacer()
                }

                sapphireUpdatesPane

                settingsBackupPane

                VStack(alignment: .leading, spacing: 0) {
                    Text("权限概述").font(.headline).padding([.horizontal, .top])
                    ForEach(permissionsManager.allPermissions) { permission in
                        PermissionStatusRowView(permission: permission)
                        if permission.id != permissionsManager.allPermissions.last?.id { Divider().padding(.leading, 60) }
                    }
                }.modifier(SettingsContainerModifier()).onAppear(perform: permissionsManager.checkAllPermissions)

                Text("© 2025 沙里克·查罗利亚。版权所有。").font(.caption).foregroundStyle(.tertiary).frame(maxWidth: .infinity, alignment: .center).padding(.top, 20)
            }.padding(25).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                ReleaseChannelPolicy.reconcileStoredPreference(&settingsModel.settings.value)
                settingsModel.commitNow()
                updateChecker.checkForUpdatesMatchingCurrentChannel()
            }
        }
        .onChange(of: settingsModel.settings.releaseChannel) { _, _ in
            settingsModel.commitNow()
            updateChecker.checkForUpdatesMatchingCurrentChannel()
        }
        .onChange(of: settingsModel.settings.automaticUpdateChecksEnabled) { _, enabled in
            settingsModel.commitNow()
            updateChecker.setAutomaticChecksEnabled(enabled)
        }
        .onChange(of: settingsModel.settings.updateAvailableNotificationsEnabled) { _, enabled in
            if enabled { updateChecker.requestNotificationAuthorization() }
        }
        .onChange(of: settingsModel.settings.automaticallyDownloadSapphireUpdates) { _, enabled in
            guard enabled,
                  settingsModel.settings.automaticUpdateChecksEnabled,
                  case .available(_, let asset) = updateChecker.status else { return }
            updateChecker.downloadUpdate(asset: asset)
        }
        .fileExporter(
            isPresented: $isExportingSettings,
            document: backupDocument,
            contentType: .sapphireSettingsBackup,
            defaultFilename: backupFilename
        ) { result in
            switch result {
            case .success:
                backupStatusMessage = BackupStatusMessage(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    message: "设置备份导出成功。"
                )
            case .failure(let error):
                backupStatusMessage = BackupStatusMessage(
                    icon: "xmark.octagon.fill",
                    color: .red,
                    message: "Export failed: \(error.localizedDescription)"
                )
            }
        }
        .fileImporter(
            isPresented: $isImportingSettings,
            allowedContentTypes: [.sapphireSettingsBackup, .json]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    try settingsModel.importSettings(from: url)
                    backupStatusMessage = BackupStatusMessage(
                        icon: "arrow.down.doc.fill",
                        color: .green,
                        message: "Imported settings from \(url.lastPathComponent)."
                    )
                } catch {
                    backupStatusMessage = BackupStatusMessage(
                        icon: "xmark.octagon.fill",
                        color: .red,
                        message: "Import failed: \(error.localizedDescription)"
                    )
                }
            case .failure(let error):
                backupStatusMessage = BackupStatusMessage(
                    icon: "xmark.octagon.fill",
                    color: .red,
                    message: "Import failed: \(error.localizedDescription)"
                )
            }
        }
        .confirmationDialog(
            "重置所有设置？",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("重置设置", role: .destructive) {
                settingsModel.resetAllSettings()
                backupStatusMessage = BackupStatusMessage(
                    icon: "arrow.counterclockwise.circle.fill",
                    color: .orange,
                    message: "所有蓝宝石设置均重置为默认值。"
                )
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("这将取代您当前在应用程序中的偏好设置。")
        }
    }

    private var settingsBackupPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                SettingsIconBadge(systemImage: "externaldrive.badge.timemachine", color: .blue)

                VStack(alignment: .leading, spacing: 3) {
                    Text("设置备份")
                        .font(.headline)
                    Text("保存 Sapphire 首选项的便携式副本或恢复您之前导出的副本。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding()

            HStack(spacing: 10) {
                Button {
                    backupDocument = settingsModel.makeBackupDocument()
                    isExportingSettings = true
                } label: {
                    Label("导出备份", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    isImportingSettings = true
                } label: {
                    Label("恢复备份", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal)
            .padding(.bottom)

            if let backupStatusMessage {
                HStack(spacing: 8) {
                    Image(systemName: backupStatusMessage.icon)
                        .foregroundStyle(backupStatusMessage.color)
                    Text(backupStatusMessage.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(backupStatusMessage.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal)
                .padding(.bottom)
            }

            Divider()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("重新开始")
                        .font(.subheadline.weight(.medium))
                    Text("将所有 Sapphire 首选项恢复为默认值。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("重置设置", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
        }
        .modifier(SettingsContainerModifier())
    }

    private var sapphireUpdatesPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            ModernUpdateStatusView(updateChecker: updateChecker)

            if let error = updateChecker.lastCheckError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("发布渠道")
                    .font(.headline)
                    .padding([.horizontal, .top])
                Text("选择从中接收版本的更新渠道。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                ModernChannelSwitcher(
                    selection: releaseChannelBinding,
                    hasBetaAccess: SubscriptionAccess.hasAccess(to: .betaSoftwareUpdates),
                    isLockedToRunningBuild: false
                )
                .padding(.horizontal)
                .padding(.bottom)

                if BetaEntitlementRuntime.isBetaBuild && settingsModel.settings.releaseChannel == .stable {
                    Text("您正在使用测试版本。切换到稳定版可让您安装最新的稳定版本。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                } else if !SubscriptionAccess.hasAccess(to: .betaSoftwareUpdates) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill").font(.caption2)
                        Text("Beta 访问需要 Plus 订阅或更高版本。")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .modifier(SettingsContainerModifier())

            VStack(alignment: .leading, spacing: 0) {
                Text("更新偏好设置")
                    .font(.headline)
                    .padding([.horizontal, .top])
                ToggleRow(
                    title: "自动更新检查",
                    description: "在启动、唤醒、网络恢复后定期检查。",
                    isOn: $settingsModel.settings.automaticUpdateChecksEnabled
                )
                Divider().padding(.leading)
                ToggleRow(
                    title: "自动下载经过验证的更新",
                    description: "在后台下载。安装始终等待着您。",
                    isOn: $settingsModel.settings.automaticallyDownloadSapphireUpdates
                )
                .disabled(!settingsModel.settings.automaticUpdateChecksEnabled)
                .opacity(settingsModel.settings.automaticUpdateChecksEnabled ? 1 : 0.5)
                Divider().padding(.leading)
                ToggleRow(
                    title: "更新通知",
                    description: "当经过验证的蓝宝石版本准备就绪时通知您。",
                    isOn: $settingsModel.settings.updateAvailableNotificationsEnabled
                )
                .disabled(!settingsModel.settings.automaticUpdateChecksEnabled)
                .opacity(settingsModel.settings.automaticUpdateChecksEnabled ? 1 : 0.5)
                Divider().padding(.leading)
                ToggleRow(
                    title: "显示更新实时活动",
                    description: "当有新的蓝宝石版本可用时，在凹口中显示警报。",
                    isOn: $settingsModel.settings.showUpdateAvailableLiveActivity
                )
            }
            .modifier(SettingsContainerModifier())
        }
    }

    var currentAppVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }

    private func handleDebugIconTap() {
        debugTapCount += 1
        debugTapResetTask?.cancel()
        debugTapResetTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if !Task.isCancelled {
                await MainActor.run { debugTapCount = 0 }
            }
        }

        if debugTapCount >= DebugMode.requiredTapCount {
            debugTapCount = 0
            debugTapResetTask?.cancel()
            debugTapResetTask = nil
            debugMode.isEnabled.toggle()
        }
    }

    private var backupFilename: String {
        "Sapphire-Settings-\(Self.backupDateFormatter.string(from: .now))"
    }
}

private struct BackupStatusMessage: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let message: String
}

struct ModernUpdateStatusView: View {
    @ObservedObject var updateChecker: UpdateChecker
    @State private var upToDateAnimationTrigger = false
    @State private var showingReleaseNotes = false

    private var canShowReleaseNotes: Bool {
        switch updateChecker.status {
        case .upToDate, .available, .downloading, .downloaded:
            return updateChecker.releaseNotes != nil || updateChecker.releaseNotesURL != nil
        default:
            return false
        }
    }

    var body: some View {
        ZStack {
            switch updateChecker.status {
            case .checking:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("正在检查更新...").foregroundStyle(.secondary)
                }
            case .upToDate:
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: upToDateAnimationTrigger)
                    Text("你是最新的！")
                        .foregroundStyle(.secondary)
                    if canShowReleaseNotes {
                        releaseNotesButton
                    }
                    checkForUpdatesButton
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .onAppear {
                    upToDateAnimationTrigger.toggle()
                }
            case .available(let version, let asset):
                VStack(spacing: 12) {
                    Text("Version \(version) is available!")
                        .font(.system(size: 16, weight: .bold))

                    Button(action: { updateChecker.downloadUpdate(asset: asset) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("下载更新")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor.gradient)
                        .clipShape(Capsule())
                        .shadow(color: .accentColor.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)

                    if canShowReleaseNotes {
                        releaseNotesButton
                    }
                    Button("再次检查") {
                        updateChecker.checkForUpdatesMatchingCurrentChannel()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            case .downloading(let progress):
                VStack(spacing: 12) {
                    DownloadingView(progress: progress, onCancel: {
                        updateChecker.cancelDownload()
                    })
                    if canShowReleaseNotes {
                        releaseNotesButton
                    }
                }
                .transition(.opacity)
            case .downloaded:
                VStack(spacing: 12) {
                    Text("下载完成！")
                        .font(.system(size: 16, weight: .bold))
                    Button(action: { updateChecker.installAndRelaunch() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("安装并重新启动")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green.gradient)
                        .clipShape(Capsule())
                        .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)

                    if canShowReleaseNotes {
                        releaseNotesButton
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            case .installing:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("正在安装...应用程序将重新启动。").foregroundStyle(.secondary)
                }
            case .error(let message):
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                        Text(message).foregroundStyle(.secondary).lineLimit(1)
                    }
                    checkForUpdatesButton
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .modifier(SettingsContainerModifier())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: updateChecker.status)
        .sheet(isPresented: $showingReleaseNotes) {
            ReleaseNotesSheet(
                version: updateChecker.releaseNotesVersion ?? currentAppVersion,
                notes: updateChecker.releaseNotes,
                url: updateChecker.releaseNotesURL
            )
        }
    }

    private var checkForUpdatesButton: some View {
        Button("检查更新") {
            updateChecker.checkForUpdatesMatchingCurrentChannel()
        }
    }

    private var releaseNotesButton: some View {
        Button {
            showingReleaseNotes = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                Text("发行说明")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

private struct ReleaseNotesSheet: View {
    let version: String
    let notes: String?
    let url: URL?
    @Environment(\.dismiss) private var dismiss

    private var attributedNotes: AttributedString? {
        guard let notes else { return nil }
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return try? AttributedString(markdown: notes, options: options)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("发行说明")
                        .font(.headline)
                    Text("Version \(version)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let url {
                    Link(destination: url) {
                        Label("GitHub", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.medium))
                    }
                }
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            ScrollView {
                Group {
                    if let attributedNotes {
                        Text(attributedNotes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    } else if let notes, !notes.isEmpty {
                        Text(notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    } else {
                        VStack(spacing: 10) {
                            Text("此版本没有包含发行说明。")
                                .foregroundStyle(.secondary)
                            if let url {
                                Link("在 GitHub 上查看", destination: url)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 480, idealWidth: 560, minHeight: 360, idealHeight: 480)
    }
}

struct DownloadingView: View {
    let progress: Double
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("正在下载更新...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
            }

            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.1)).frame(height: 12)
                Capsule()
                    .fill(Color.accentColor.gradient)
                    .frame(width: (300 * progress), height: 12)
                    .animation(.easeOut, value: progress)
            }
            .frame(width: 300)

            Button("Cancel", action: onCancel)
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ModernChannelSwitcher: View {
    @Binding var selection: ReleaseChannel
    let hasBetaAccess: Bool
    var isLockedToRunningBuild: Bool = false
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ReleaseChannel.allCases, id: \.self) { channel in
                Text(channel == .stable ? "Stable" : "Beta")
                    .font(.subheadline.weight(selection == channel ? .semibold : .regular))
                    .foregroundStyle(selection == channel ? .white : .secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if selection == channel {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .matchedGeometryEffect(id: "channelPill", in: namespace)
                            }
                        }
                    )
                    .contentShape(Capsule())
                    .onTapGesture {
                        guard !isLockedToRunningBuild else { return }
                        guard hasBetaAccess || channel == .stable else { return }
                        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.85)) {
                            selection = channel
                        }
                    }
                    .opacity(isLockedToRunningBuild && channel != selection ? 0.35 : ((channel == .beta && !hasBetaAccess) ? 0.4 : 1))
            }
        }
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .opacity(isLockedToRunningBuild ? 0.85 : 1)
    }
}

fileprivate struct NotchButtonRowView: View {
    let buttonType: NotchButtonType

    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var permissionsManager = PermissionsManager.shared

    private var isEnabledBinding: Binding<Bool> {
        switch buttonType {
        case .settings, .spacer:
            return .constant(true)
        case .fileShelf: return $settings.settings.fileShelfIconEnabled
        case .notes: return $settings.settings.notesIconEnabled
        case .clipboard: return $settings.settings.clipboardIconEnabled
        case .intelligenceLive, .intelligence:
            return Binding(
                get: {
                    settings.settings.intelligenceEnabled
                        && permissionsManager.areIntelligencePermissionsGranted
                },
                set: { newValue in
                    guard permissionsManager.areIntelligencePermissionsGranted else {
                        settings.settings.intelligenceEnabled = false
                        return
                    }
                    settings.settings.intelligenceEnabled = newValue
                }
            )
        case .focusSession: return $settings.settings.focusSessionIconEnabled
        case .caffeine: return $settings.settings.caffeinateEnabled
        case .battery: return $settings.settings.batteryEstimatorEnabled
        case .continuity: return $settings.settings.continuityShowPhoneBattery
        case .multiAudio: return $settings.settings.showMultiAudioIcon
        case .pin: return $settings.settings.pinEnabled
        }
    }

    private var isToggleDisabled: Bool {
        switch buttonType {
        case .settings, .spacer:
            return true
        case .intelligenceLive, .intelligence:
            return !permissionsManager.areIntelligencePermissionsGranted
        case .focusSession:
            return false
        default:
            return false
        }
    }

    var body: some View {
        HStack {
            if buttonType == .spacer {
                HStack {
                    Rectangle().fill(.secondary).frame(height: 1)
                    Text("中心垫片")
                        .font(.caption.bold()).foregroundStyle(.secondary)
                    Rectangle().fill(.secondary).frame(height: 1)
                }
            } else {
                Image(systemName: buttonType.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 30)

                Text(buttonType.displayName)
                    .font(.system(size: 14, weight: .medium))
            }

            Spacer()

            SettingsSwitch(isOn: isEnabledBinding)
                .disabled(isToggleDisabled)
                .opacity(isToggleDisabled ? 0 : 1)

            ReorderHandle()
        }
        .padding(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
    }
}

fileprivate struct NotchBarSpacerWidthRow: View {
    @EditingSettings var settings: SettingsEditingSession

    private var widthBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(settings.settings.notchBarSpacerWidth) },
            set: { newValue in
                settings.settings.notchBarSpacerWidth = NotchBarSpacerPolicy.sanitizedWidth(CGFloat(newValue))
            }
        )
    }

    private var isAutomatic: Bool {
        !NotchBarSpacerPolicy.hasFixedWidth(settings.settings.notchBarSpacerWidth)
    }

    var body: some View {
        HStack(spacing: 18) {
            HStack {
                Image(systemName: "space")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 30)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("中心垫片宽度")
                        .font(.system(size: 14, weight: .medium))
                    Text(isAutomatic
                         ? "Automatic: the spacer grows with the bar but is never narrower than the notch."
                         : "Fixed gap between the left and right notch bar items, never narrower than the notch.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 6) {
                Slider(value: widthBinding, in: Double(NotchBarSpacerPolicy.widthRange.lowerBound)...Double(NotchBarSpacerPolicy.widthRange.upperBound))
                    .frame(width: 180)

                TextField("Width", value: widthBinding, format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 62)
                    .multilineTextAlignment(.trailing)

                Text("pt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button {
                settings.settings.notchBarSpacerWidth = NotchBarSpacerPolicy.automaticWidth
            } label: {
                Label("重置", systemImage: "arrow.counterclockwise")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            .disabled(isAutomatic)
            .help("恢复为自动间隔宽度")
        }
        .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
    }
}

struct AppearanceSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 40) {
                Text("Appearance")
                    .font(.largeTitle.bold())
                DisplaySettingsView()
                NotchAppearanceDisplaySection()
                MenuBarHidingSettingsView()
                MenuBarProfilesSettingsView()
                MenuBarAppearanceSettingsView()
                MenuBarSpacingSettingsView()
                RequiredPermissionsView(section: .appearance)
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct MenuBarHidingSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("图标隐藏").font(.title2.bold())
                Text("使用可扩展部分隐藏和显示菜单栏项目。").font(.caption).foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                ToggleRow(title: "启用菜单栏图标隐藏", description: "", isOn: $settings.settings.menuBarEnabled)
            }.modifier(SettingsContainerModifier())

            if settings.settings.menuBarEnabled {
                if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
                    HStack(alignment: .center, spacing: 12) {
                        InfoContainer(text: "Sapphire's menu bar icons need Sapphire to be allowed under System Settings → Menu Bar → Allow in the Menu Bar. If the control item never appears, check that switch.", iconName: "menubar.rectangle", color: .blue)
                        Button("打开菜单栏设置...") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                    .padding()
                    .modifier(SettingsContainerModifier())
                }

                VStack(alignment: .leading, spacing: 0) {

                    Text("控制项图标").font(.headline).padding([.top, .horizontal])
                    Text("选择主控制项的图标样式。").font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 10)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ControlItemIconStyle.allCases) { iconStyle in
                                ControlItemIconPreview(iconStyle: iconStyle, isSelected: settings.settings.controlItemIconStyle == iconStyle) {
                                    withAnimation { settings.settings.controlItemIconStyle = iconStyle }
                                }
                            }
                        }.padding(.horizontal).padding(.bottom, 12)
                    }
                }.modifier(SettingsContainerModifier())

                if MenuBarAgentHost.isActive && MenuBarVisibilityRestrictor.isUsable {
                    MenuBarLayoutEditorView()
                } else if MenuBarAgentHost.isActive && MenuBarVisibilityRestrictor.isAvailable {
                    InfoContainer(text: "Sapphire hides items with macOS's own menu bar controls only when it is installed in the Applications folder. This copy runs from elsewhere, so it falls back to stretching the divider up to the app menus.", iconName: "exclamationmark.triangle", color: .orange)
                        .padding()
                        .modifier(SettingsContainerModifier())
                }

                VStack(alignment: .leading, spacing: 0) {
                    if !(MenuBarAgentHost.isActive && MenuBarVisibilityRestrictor.isUsable) {
                        InfoContainer(text: "To customize the shown icons, right click on the menu bar and select 'Edit Menu Bar Items'. The icons placed in between the dot and expansion icon will always be shown, the icons placed in between the two dots will be hidden when the menu is collapsed, and the icons after the dot will always be hidden.", iconName: "info.circle", color: Color.mint).padding()

                        Image("MenubarDemo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 480)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    Text("显示隐藏项目").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "单击时显示", description: "Show hidden items when clicking empty menu bar space", isOn: $settings.settings.showOnClick)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "悬停时显示", description: "Show hidden items after hovering over the menu bar", isOn: $settings.settings.showOnHover)
                    if settings.settings.showOnHover {
                        CustomSliderRowView(
                            label: "悬停延迟",
                            value: $settings.settings.showOnHoverDelay,
                            range: 0.1...1.0,
                            specifier: "%.2fs"
                        )
                        .padding(.horizontal, 60)
                        .padding(.bottom, 8)
                    }
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "滚动或滑动显示", description: "Scroll up or swipe in an empty part of the menu bar to show hidden items; scroll down to hide them", isOn: $settings.settings.showOnScroll)
                    if settings.settings.showOnClick && settings.settings.enableAlwaysHiddenSection {
                        Divider().padding(.leading, 20)
                        ToggleRow(title: "双击始终隐藏的项目", description: "A second click on empty menu bar space also shows the always-hidden section. The first click still shows hidden items right away", isOn: $settings.settings.showAlwaysHiddenOnDoubleClick)
                    }
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "拥挤时隐藏应用程序菜单", description: "When shown items would run into the app's menus or the notch, temporarily swap the menus out until the items hide again", isOn: $settings.settings.hideAppMenusWhenShowingItems)
                }.modifier(SettingsContainerModifier())

                MenuBarHotkeysSettingsSection()

                VStack(alignment: .leading, spacing: 0) {
                    Text("自动重新隐藏").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "自动重新隐藏项目", description: "Automatically hide items after they're shown", isOn: $settings.settings.autoRehide)
                    if settings.settings.autoRehide {
                        Divider().padding(.leading, 20)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("重新隐藏策略").font(.subheadline).foregroundColor(.secondary)
                            Picker("", selection: $settings.settings.rehideStrategy) {
                                Text("智能（当鼠标离开时）").tag("smart"); Text("定时").tag("timed"); Text("应用程序变更").tag("focusedApp")
                            }.pickerStyle(.segmented).padding(.horizontal)
                        }.padding()
                        if settings.settings.rehideStrategy == "timed" {
                            CustomSliderRowView(label: "之后隐藏", value: $settings.settings.tempShowInterval, range: 1.0...30.0, specifier: "%.1fs")
                        }
                        if settings.settings.rehideStrategy != "focusedApp" {
                            Divider().padding(.leading, 20)
                            CustomSliderRowView(label: "保留打开的物品", value: $settings.settings.menuBarKeepOpenedItemsDelay, range: 0...30, specifier: "%.0fs")
                            Text("显示项目的菜单关闭后，在重新隐藏之前将项目显示这么长时间，这样误点击就不会将该项目送走。 0立即重新隐藏。")
                                .font(.caption).foregroundColor(.secondary)
                                .padding(.horizontal).padding(.bottom, 10)
                        }
                    }
                }.modifier(SettingsContainerModifier()).animation(.default, value: settings.settings.autoRehide || settings.settings.rehideStrategy == "timed")

                VStack(alignment: .leading, spacing: 0) {
                    Text("隐藏外观").font(.headline).padding([.top, .horizontal])
                    ToggleRow(title: "显示部分分隔线", description: "", isOn: $settings.settings.showSectionDividers)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "启用始终隐藏部分", description: "", isOn: $settings.settings.enableAlwaysHiddenSection)
                    Divider().padding(.leading, 20)
                    ToggleRow(title: "隐藏主控图标", description: "", isOn: $settings.settings.hideMenuBarIcon)
                }.modifier(SettingsContainerModifier())
            }
        }
        .animation(.easeInOut, value: settings.settings.menuBarEnabled)
    }
}

// MARK: - Menu Bar Hotkeys

private struct MenuBarHotkeysSettingsSection: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var shortcutRecorder = GlobalShortcutRecorder.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("热键和禅宗模式").font(.headline).padding([.top, .horizontal])
            Text("Zen 模式隐藏每个部分并暂停悬停、单击、滚动和配置文件显示，直到您将其关闭。单击控制项也会结束它。")
                .font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 8)
            recorderRow(title: "Toggle Hidden Items", identifier: "menuBarToggleHiddenShortcut", shortcut: $settings.settings.menuBarToggleHiddenShortcut)
            Divider().padding(.leading, 20)
            recorderRow(title: "切换始终隐藏的项目", identifier: "menuBarToggleAlwaysHiddenShortcut", shortcut: $settings.settings.menuBarToggleAlwaysHiddenShortcut)
            Divider().padding(.leading, 20)
            recorderRow(title: "搜索菜单栏项目", identifier: "menuBarSearchShortcut", shortcut: $settings.settings.menuBarSearchShortcut)
            Divider().padding(.leading, 20)
            recorderRow(title: "切换禅宗模式", identifier: "menuBarZenModeShortcut", shortcut: $settings.settings.menuBarZenModeShortcut)
            Divider().padding(.leading, 20)
            ToggleRow(title: "演示时的禅宗模式", description: "Turn Zen mode on while a display is mirrored or the screen is shared with Screen Sharing, and off again after. A Zen mode you turned on yourself is left alone", isOn: $settings.settings.menuBarAutoZenWhilePresenting)
            Divider().padding(.leading, 20)
            ToggleRow(title: "相机开启时的禅宗模式", description: "Turn Zen mode on during video calls, while any app uses a camera", isOn: $settings.settings.menuBarAutoZenWhileCameraInUse)
            Divider().padding(.leading, 20)
            HStack {
                Text("搜索并打开任何项目，包括隐藏的项目")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Button("搜索项目...") { MenuBarSearchPanelController.shared.open() }
                    .buttonStyle(.bordered).controlSize(.small)
            }
            .padding()
        }
        .modifier(SettingsContainerModifier())
    }

    private func recorderRow(title: String, identifier: String, shortcut: Binding<KeyboardShortcut>) -> some View {
        let isRecording = shortcutRecorder.isRecording && shortcutRecorder.recordingIdentifier == identifier
        let label = shortcut.wrappedValue.key.isEmpty
            ? "Not Set"
            : "\(KeyboardShortcutHelper.description(for: shortcut.wrappedValue.modifiers))\(shortcut.wrappedValue.key)"
        return HStack {
            Text(title).font(.system(size: 14, weight: .medium))
            Spacer()
            if !isRecording {
                Text(label)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Capsule())
            }
            Button(isRecording ? "Cancel" : "Record…") {
                if isRecording {
                    shortcutRecorder.stopRecording()
                } else {
                    shortcutRecorder.startRecording(identifier: identifier) { key, flags in
                        shortcut.wrappedValue = KeyboardShortcut(key: key, modifiers: flags)
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            if !shortcut.wrappedValue.key.isEmpty && !isRecording {
                Button {
                    shortcut.wrappedValue = KeyboardShortcut(key: "", modifiers: [])
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("清除快捷方式")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Menu Bar Profiles (Conditional Reveal + Display/Space/Focus Bindings)

struct MenuBarProfilesSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("菜单栏配置文件").font(.title2.bold())
                Text("当满足条件（电池电量、活动焦点、Wi-Fi 网络或脚本的退出代码）时显示隐藏的菜单栏项目，并将配置文件绑定到显示、空间或焦点过滤器。").font(.caption).foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                PremiumFeatureView(feature: .menuBarProfiles) {
                    ToggleRow(
                        title: "启用菜单栏配置文件",
                        description: "Evaluate profile conditions in the background to reveal hidden items automatically",
                        isOn: $settings.settings.menuBarProfilesEnabled
                    )
                }
            }.modifier(SettingsContainerModifier())

            if settings.settings.menuBarProfilesEnabled {
                MenuBarProfileEditorView()
                    .premiumFeature(.menuBarProfiles)
            }
        }
        .animation(.easeInOut, value: settings.settings.menuBarProfilesEnabled)
    }
}

private struct MenuBarProfileEditorView: View {
    @EditingSettings var settings: SettingsEditingSession
    @State private var expandedProfileIDs: Set<UUID> = []

    private var profilesBinding: Binding<[MenuBarProfile]> {
        $settings.settings.menuBarProfiles
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Profiles").font(.headline)
                Spacer()
                Button {
                    let newProfile = MenuBarProfile(name: "Profile \(settings.settings.menuBarProfiles.count + 1)")
                    _ = withAnimation(.easeInOut(duration: 0.2)) { expandedProfileIDs.insert(newProfile.id) }
                    settings.settings.menuBarProfiles.append(newProfile)
                } label: {
                    Label("添加个人资料", systemImage: "plus")
                        .font(.callout)
                }
                .buttonStyle(.plain)
            }

            if settings.settings.menuBarProfiles.isEmpty {
                InfoContainer(
                    text: "Create a profile, add reveal conditions, and optionally bind it to a display, a Space, or a Focus filter. When a bound context is active and any condition is met, hidden items are revealed.",
                    iconName: "info.circle",
                    color: .mint
                ).padding()
                .modifier(SettingsContainerModifier())
            } else {
                VStack(spacing: 12) {
                    ForEach(profilesBinding) { $profile in
                        MenuBarProfileCardView(profile: $profile, isExpanded: expandedProfileIDs.contains(profile.id)) { changed in
                            if changed {
                                expandedProfileIDs.insert(profile.id)
                            } else {
                                expandedProfileIDs.remove(profile.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct MenuBarProfileCardView: View {
    @Binding var profile: MenuBarProfile
    let isExpanded: Bool
    var onExpandedChange: (Bool) -> Void = { _ in }
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: profile.symbolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                TextField("个人资料名称", text: $profile.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                Text(profile.summaryText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                SettingsSwitch(isOn: $profile.isEnabled)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { onExpandedChange(!isExpanded) }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    settings.settings.menuBarProfiles.removeAll { $0.id == profile.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                Divider()

                MenuBarRevealConditionsSection(profile: $profile)

                Divider()

                MenuBarProfileBindingsSection(profile: $profile)
            }
        }
        .padding()
        .modifier(SettingsContainerModifier())
    }
}

// MARK: - Reveal Conditions

private struct MenuBarRevealConditionsSection: View {
    @Binding var profile: MenuBarProfile
    @State private var focusOptions: [MenuBarProfileEngine.FocusModeOption] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("透露时间").font(.subheadline.weight(.semibold))
                Spacer()
                Menu {
                    ForEach(MenuBarRevealConditionKind.allCases) { kind in
                        Button {
                            profile.revealConditions.append(MenuBarRevealCondition(kind: kind))
                        } label: {
                            Label(kind.displayName, systemImage: kind.systemImage)
                        }
                    }
                } label: {
                    Label("添加条件", systemImage: "plus.circle")
                        .font(.callout)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            if profile.revealConditions.isEmpty {
                Text("无条件 — 该个人资料绝不会泄露物品。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach($profile.revealConditions) { $condition in
                    HStack(spacing: 10) {
                        Image(systemName: condition.kind.systemImage)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        MenuBarRevealConditionEditor(condition: $condition, focusOptions: focusOptions)

                        Button {
                            let doomed = condition.id
                            DispatchQueue.main.async {
                                profile.revealConditions.removeAll { $0.id == doomed }
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear { refreshFocusOptions() }
    }

    private func refreshFocusOptions() {
        Task.detached(priority: .utility) {
            let options = MenuBarProfileEngine.fetchAvailableFocusModes()
            await MainActor.run { self.focusOptions = options }
        }
    }
}

private struct MenuBarRevealConditionEditor: View {
    @Binding var condition: MenuBarRevealCondition
    let focusOptions: [MenuBarProfileEngine.FocusModeOption]

    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: $condition.kind) {
                ForEach(MenuBarRevealConditionKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 210)

            switch condition.kind {
            case .batteryBelow, .batteryAbove:
                HStack(spacing: 4) {
                    TextField("Level", value: $condition.batteryThreshold, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                    Text("%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

            case .charging:
                Text("插入时")
                    .font(.caption)
                    .foregroundColor(.secondary)

            case .onBatteryPower:
                Text("拔掉插头时")
                    .font(.caption)
                    .foregroundColor(.secondary)

            case .focusActive:
                Text("任何对焦模式")
                    .font(.caption)
                    .foregroundColor(.secondary)

            case .focusIdentifier:
                Picker("", selection: $condition.focusIdentifier) {
                    Text("选择焦点...").tag("")
                    ForEach(focusOptions) { option in
                        Label(option.name, systemImage: option.symbolName).tag(option.identifier)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 190)

            case .wifiEquals:
                TextField("Wi-Fi 网络名称", text: $condition.wifiNetworkName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 170)

            case .wifiConnected:
                Text("任何网络")
                    .font(.caption)
                    .foregroundColor(.secondary)

            case .scriptSucceeds, .scriptFails, .scriptExitCode:
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        TextField("/path/to/script.sh", text: $condition.scriptPath)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                        if condition.kind == .scriptExitCode {
                            Text("退出=")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0", value: $condition.scriptExitCode, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 44)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("可选参数", text: $condition.scriptArgument)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                        Text("重新检查了每个")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("30", value: $condition.scriptPollInterval, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 44)
                        Text("sec")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Profile Bindings

private struct MenuBarProfileBindingsSection: View {
    @Binding var profile: MenuBarProfile
    @EditingSettings var settings: SettingsEditingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("绑定到").font(.subheadline.weight(.semibold))

            ToggleRow(
                title: "Displays",
                description: "仅在选定的显示器上应用此配置文件",
                isOn: $profile.bindsToDisplays
            )
            if profile.bindsToDisplays {
                MenuBarDisplayBindingsEditor(profile: $profile)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            ToggleRow(
                title: "Spaces",
                description: "仅在选定的桌面空间（编号与空间切换器类似）上应用此配置文件",
                isOn: $profile.bindsToSpaces
            )
            if profile.bindsToSpaces {
                MenuBarSpaceBindingsEditor(profile: $profile)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            ToggleRow(
                title: "Focus",
                description: "仅当选定的焦点过滤器处于活动状态时应用此配置文件",
                isOn: $profile.bindsToFocus
            )
            if profile.bindsToFocus {
                MenuBarFocusBindingsEditor(profile: $profile)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }
}

private struct MenuBarDisplayBindingsEditor: View {
    @Binding var profile: MenuBarProfile

    private var connectedScreens: [NSScreen] { NSScreen.screens }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $profile.displayScope) {
                Text("所有显示").tag(MenuBarProfileDisplayScope.allDisplays)
                Text("选定的显示器").tag(MenuBarProfileDisplayScope.selectedDisplays)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if profile.displayScope == .selectedDisplays {
                if connectedScreens.isEmpty {
                    Text("未检测到显示器。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 4) {
                        ForEach(connectedScreens, id: \.displayIdentifier) { screen in
                            let id = screen.displayIdentifier
                            let ids = screen.displayIdentifierCandidates
                            let isBound = profile.displayBindings.contains { ids.contains($0.displayIdentifier) }
                            Button {
                                if isBound {
                                    profile.displayBindings.removeAll { ids.contains($0.displayIdentifier) }
                                } else {
                                    profile.displayBindings.append(MenuBarDisplayBinding(displayIdentifier: id, displayLabel: screen.displayLabel))
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isBound ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isBound ? Color.accentColor : Color.secondary)
                                    Image(systemName: CGDisplayIsBuiltin(screen.displayID) != 0 ? "laptopcomputer" : "display")
                                    Text(screen.displayLabel)
                                        .font(.callout)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct MenuBarSpaceBindingsEditor: View {
    @Binding var profile: MenuBarProfile
    @State private var availableSpaces: Int = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("激活此配置文件的空间：")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...max(1, availableSpaces), id: \.self) { number in
                        let isBound = profile.spaceNumbers.contains(number)
                        Button {
                            if isBound {
                                profile.spaceNumbers.removeAll { $0 == number }
                            } else {
                                profile.spaceNumbers.append(number)
                                profile.spaceNumbers.sort()
                            }
                        } label: {
                            Text("\(number)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .frame(width: 32, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(isBound ? Color.accentColor.opacity(0.25) : Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(isBound ? Color.accentColor : Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            HStack {
                Text("Detected Spaces: \(availableSpaces)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Stepper("添加空间", onIncrement: { availableSpaces += 1 }, onDecrement: { availableSpaces = max(1, availableSpaces - 1) })
                    .font(.caption)
            }
        }
    }
}

private struct MenuBarFocusBindingsEditor: View {
    @Binding var profile: MenuBarProfile
    @State private var focusOptions: [MenuBarProfileEngine.FocusModeOption] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if focusOptions.isEmpty {
                Text("未找到焦点模式（或未经焦点许可不可用）。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 4) {
                    ForEach(focusOptions) { option in
                        let isBound = profile.focusIdentifiers.contains(option.identifier)
                        Button {
                            if isBound {
                                profile.focusIdentifiers.removeAll { $0 == option.identifier }
                            } else {
                                profile.focusIdentifiers.append(option.identifier)
                            }
                        } label: {
                            HStack {
                                Image(systemName: isBound ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isBound ? Color.accentColor : Color.secondary)
                                Image(systemName: option.symbolName)
                                    .font(.callout)
                                Text(option.name)
                                    .font(.callout)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("Leave empty selections unchecked to bind to any Focus filter by enabling \"Focus\" alone.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .onAppear { refreshFocusOptions() }
    }

    private func refreshFocusOptions() {
        Task.detached(priority: .utility) {
            let options = MenuBarProfileEngine.fetchAvailableFocusModes()
            await MainActor.run { self.focusOptions = options }
        }
    }
}

struct MenuBarAppearanceEditor: View {
    @EditingSettings var settings: SettingsEditingSession

    private var opacityBinding: Binding<Double> {
        Binding(
            get: { settings.settings.menuBarOpacity * 100 },
            set: { settings.settings.menuBarOpacity = $0 / 100 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("菜单栏色调").font(.headline)
                Spacer()
                Button("重置", action: resetTintSettings)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding([.top, .horizontal])

            ToggleRow(title: "液体玻璃外观", description: "Apply a shiny, glass-like effect to the menu bar's background.", isOn: $settings.settings.menuBarLiquidGlass)

            if settings.settings.menuBarLiquidGlass {
                Divider().padding(.leading, 20)
                LiquidGlassStylePickerRow(selection: $settings.settings.menuBarLiquidGlassStyle)

                Divider().padding(.leading, 20)
                ToggleRow(
                    title: "磨砂覆盖层",
                    description: "Layer frosted liquid glass on top of the base glass, matching the lock screen treatment.",
                    isOn: $settings.settings.menuBarBlur
                )
            }

            Divider().padding(.leading, 20)

            HStack {
                Text("背景风格")
                Spacer()
                Picker("", selection: $settings.settings.menuBarTintStyle) {
                    Text("None").tag("none"); Text("固体").tag("solid"); Text("渐变").tag("gradient"); Text("Adaptive").tag("adaptive")
                }.labelsHidden().frame(width: 200)
            }.padding()

            if settings.settings.menuBarTintStyle == "solid" {
                solidColorPicker
            } else if settings.settings.menuBarTintStyle == "gradient" {
                gradientColorEditor
            } else if settings.settings.menuBarTintStyle == "adaptive" {
                Divider().padding(.leading, 20)
                ToggleRow(
                    title: "双色调渐变",
                    description: "Adaptive tint follows the colours of your wallpaper behind the menu bar. Turn this on to blend its left and right sides instead of using one average colour.",
                    isOn: $settings.settings.menuBarAdaptiveTintGradient
                )
            }

            Divider().padding(.leading, 20)

                    CustomSliderRowView(label: "主控不透明度", value: opacityBinding, range: 0...100, specifier: "%.0f%%")

            if !settings.settings.menuBarLiquidGlass {
                Divider().padding(.leading, 20)
                ToggleRow(title: "启用透明度模糊", description: "将毛玻璃效果应用于菜单栏背景。", isOn: $settings.settings.menuBarBlur)
            }
        }
        .modifier(SettingsContainerModifier())
        .animation(.default, value: settings.settings.menuBarLiquidGlass)
        .animation(.default, value: settings.settings.menuBarBlur)
        .animation(.default, value: settings.settings.menuBarTintStyle)
    }

    @ViewBuilder
    private var solidColorPicker: some View {
        ColorPicker("Color", selection: $settings.settings.menuBarSolidColor.color, supportsOpacity: true)
            .padding()
            .transition(.opacity)
    }

    @ViewBuilder
    private var gradientColorEditor: some View {
        VStack(alignment: .leading) {
            CustomSliderRowView(label: "角度", value: $settings.settings.menuBarGradientAngle, range: 0...360, specifier: "%.0f°")
                .padding(.horizontal)

            Text("渐变颜色").font(.subheadline).padding(.horizontal)

            ForEach($settings.settings.menuBarGradientColors) { $color in
                VStack(spacing: 8) {
                    HStack {
                        ColorPicker("Color Stop", selection: $color.color, supportsOpacity: true)
                        Spacer()
                        Button(action: {
                            guard settings.settings.menuBarGradientColors.count > 1 else { return }
                            let doomed = color.id
                            DispatchQueue.main.async {
                                settings.settings.menuBarGradientColors.removeAll { $0.id == doomed }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }.buttonStyle(.plain).disabled(settings.settings.menuBarGradientColors.count <= 1)
                    }
                    DeferredValueEditor(value: $color.location.asDouble) { draft, onEditingChanged in
                        Slider(
                            value: draft,
                            in: 0...1,
                            label: { Text("Location") },
                            onEditingChanged: onEditingChanged
                        )
                    }
                }.padding(.horizontal)
            }

            Button(action: {
                var colors = settings.settings.menuBarGradientColors
                let newStop = CodableColor(color: colors.last?.color ?? .black, location: 1.0)
                colors.append(newStop)
                settings.settings.menuBarGradientColors = colors
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加色标")
                }
            }.buttonStyle(.plain).tint(.accentColor).padding([.top, .horizontal])
        }
        .padding(.vertical)
        .transition(.opacity)
    }

    private func resetTintSettings() {
        var updated = settings.settings.value
        updated.menuBarLiquidGlass = false
        updated.menuBarLiquidGlassStyle = .frosted
        updated.menuBarTintStyle = "none"
        updated.menuBarSolidColor = CodableColor(color: .clear)
        updated.menuBarGradientAngle = 0.0
        updated.menuBarGradientColors = [
            CodableColor(color: .white, location: 0),
            CodableColor(color: .black, location: 1)
        ]
        updated.menuBarOpacity = 1.0
        updated.menuBarBlur = false
        settings.settings.value = updated
    }
}

struct MenuBarAppearanceSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession

    private var verticalPaddingBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(settings.settings.menuBarVerticalPadding) },
            set: { settings.settings.menuBarVerticalPadding = CGFloat($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("菜单栏样式（测试版）").font(.title2.bold())
                    Text("自定义 Mac 菜单栏的外观和风格。").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button("全部重置", action: resetAllAppearanceSettings)
                    .buttonStyle(.plain)
            }

            MenuBarAppearanceEditor()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("边框厚度"); Spacer()
                    Picker("边框", selection: $settings.settings.menuBarBorderWidth) {
                        Text("无国界").tag(CGFloat(0)); Text("1px").tag(CGFloat(1)); Text("2px").tag(CGFloat(2)); Text("3px").tag(CGFloat(3))
                    }.labelsHidden().frame(width: 120)
                }.padding()
                Divider().padding(.horizontal)
                ColorPicker("Border Color", selection: $settings.settings.menuBarBorderColor.color, supportsOpacity: true).padding()
            }.modifier(SettingsContainerModifier())

            VStack(alignment: .leading, spacing: 0) {
                Toggle(isOn: Binding(
                    get: { settings.settings.menuBarShapeStyle == "rounded" },
                    set: { if $0 { settings.settings.menuBarShapeStyle = "rounded" } else if settings.settings.menuBarShapeStyle == "rounded" { settings.settings.menuBarShapeStyle = "none" } }
                )) {
                    Text("圆形菜单栏")
                }.padding()

                Divider().padding(.horizontal)

                Toggle(isOn: Binding(
                    get: { settings.settings.menuBarShapeStyle == "roundedSplit" },
                    set: { if $0 { settings.settings.menuBarShapeStyle = "roundedSplit" } else if settings.settings.menuBarShapeStyle == "roundedSplit" { settings.settings.menuBarShapeStyle = "none" } }
                )) {
                    Text("圆形的单独侧面")
                }.padding()

                Divider().padding(.horizontal)
                CustomSliderRowView(label: "垂直内边距", value: verticalPaddingBinding, range: 0...10, specifier: "%.0fpx")

            }.modifier(SettingsContainerModifier()).animation(.default, value: settings.settings.menuBarShapeStyle)
        }
    }

    private func resetAllAppearanceSettings() {
        var updated = settings.settings.value
        updated.menuBarLiquidGlass = false
        updated.menuBarLiquidGlassStyle = .frosted
        updated.menuBarTintStyle = "none"
        updated.menuBarSolidColor = CodableColor(color: .clear)
        updated.menuBarGradientAngle = 0.0
        updated.menuBarGradientColors = [
            CodableColor(color: .white, location: 0),
            CodableColor(color: .black, location: 1)
        ]
        updated.menuBarOpacity = 1.0
        updated.menuBarBlur = false

        updated.menuBarBorderWidth = 0
        updated.menuBarBorderColor = CodableColor(color: .black)

        updated.menuBarShapeStyle = "none"
        updated.menuBarVerticalPadding = 0
        settings.settings.value = updated
    }
}

struct MenuBarSpacingSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @State private var spacingManager: MenuBarSpacingManager?

    private var spacingBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(settings.settings.menuBarSpacing) },
            set: { settings.settings.menuBarSpacing = Int($0) }
        )
    }

    private var paddingBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(settings.settings.menuBarSelectionPadding) },
            set: { settings.settings.menuBarSelectionPadding = Int($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("菜单栏间距（测试版）").font(.title2.bold())
                Text("微调所有菜单栏项目之间的间距和填充。更改需要刷新菜单栏才能应用。").font(.caption).foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 0) {
                CustomSliderRowView(label: "间距", value: spacingBinding, range: 1...50, specifier: "%.0f")
                Divider().padding(.leading, 20)
                CustomSliderRowView(label: "填充", value: paddingBinding, range: 1...50, specifier: "%.0f")

                HStack {
                    Button("重置为系统默认值") {
                        spacingManager?.restoreDefaults()
                    }
                    .disabled(spacingManager == nil)

                    Spacer()

                    Button("应用并刷新菜单栏") {
                        spacingManager?.applyChanges()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(spacingManager == nil)
                }
                .padding()

            }.modifier(SettingsContainerModifier())
        }
        .onAppear {
            if spacingManager == nil {
                spacingManager = MenuBarSpacingManager()
            }
        }
    }
}

struct ControlItemIconPreview: View {
    let iconStyle: ControlItemIconStyle
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconStyle.previewSymbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 60, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(isHovered ? 0.15 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )

            Text(iconStyle.displayName)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered && !isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

extension View {
    @ViewBuilder
    func dynamicXAxis(for range: TimeRange, isVisible: Bool) -> some View {
        if isVisible {
            switch range {
            case .last24Hours:
                self.chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.hour()) } }
            case .last7Days:
                self.chartXAxis { AxisMarks(values: .automatic(desiredCount: 7)) { _ in AxisValueLabel(format: .dateTime.weekday()) } }
            case .lastMonth, .custom:
                self.chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) { _ in AxisValueLabel(format: .dateTime.day()) } }
            case .lastYear:
                self.chartXAxis { AxisMarks(values: .automatic(desiredCount: 6)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated)) } }
            }
        } else {
            self.chartXAxis(.hidden)
        }
    }
}

extension View {
    func chartInteractionOverlay<T: Identifiable>(
        proxy: ChartProxy,
        data: [T],
        keyPath: KeyPath<T, Date>,
        selectedItem: Binding<T?>
    ) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if let date: Date = proxy.value(atX: value.location.x) {
                                let closest = data.min {
                                    abs($0[keyPath: keyPath].timeIntervalSince(date)) <
                                    abs($1[keyPath: keyPath].timeIntervalSince(date))
                                }
                                selectedItem.wrappedValue = closest
                            }
                        }
                        .onEnded { _ in
                            selectedItem.wrappedValue = nil
                        }
                )
        }
    }
}

struct ModernSegmentedPicker: View {
    @Binding var selection: String
    let options: [String]

    @Namespace private var pickerNamespace

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Text(option)
                    .font(.headline.weight(.bold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
                                    .matchedGeometryEffect(id: "pickerPill", in: pickerNamespace)
                            }
                        }
                    )
                    .foregroundColor(selection == option ? .primary : .secondary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.7)) {
                            selection = option
                        }
                    }
            }
        }
        .padding(6)
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

typealias GeminiSettingsView = IntelligenceSettingsView

// MARK: - Legacy Settings View Shims

// MARK: - Task Runner Interface

struct IntelligenceRunnerView: View {
    let apiKey: String
    var backend: LLMBackend = .auto
    var geminiSpeedMode: GeminiSpeedMode = .fast
    @ObservedObject private var vm: IntelligenceNotchViewModel
    @State private var isRunningScreenshotDebug = false

    init(
        apiKey: String,
        backend: LLMBackend = .gemini,
        geminiSpeedMode: GeminiSpeedMode = .fast,
        vm: IntelligenceNotchViewModel? = nil
    ) {
        self.apiKey = apiKey
        self.backend = backend
        self.geminiSpeedMode = geminiSpeedMode
        let resolvedVM = vm ?? (NSApp.delegate as? AppDelegate)?.intelligenceViewModel ?? IntelligenceNotchViewModel()
        self._vm = ObservedObject(wrappedValue: resolvedVM)
    }

    private var isLaunchDisabled: Bool {
        if vm.taskInput.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }
        return !backend.isKeyConfigured && backend.resolveAPIKey(fallbackGeminiKey: apiKey).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField("描述一个任务...", text: $vm.taskInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15)))
                    .onSubmit {
                        if !vm.isRunning && !isLaunchDisabled {
                            let activeKey = backend.resolveAPIKey(fallbackGeminiKey: apiKey)
                            vm.run(
                                apiKey: activeKey,
                                backend: backend,
                                geminiSpeedMode: geminiSpeedMode
                            )
                        }
                    }

                if vm.isRunning {
                    Button(action: vm.stop) {
                        Image(systemName: "stop.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Button {
                        let activeKey = backend.resolveAPIKey(fallbackGeminiKey: apiKey)
                        vm.run(
                            apiKey: activeKey,
                            backend: backend,
                            geminiSpeedMode: geminiSpeedMode
                        )
                    } label: {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                    .background(isLaunchDisabled ? Color.gray.opacity(0.3) : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(isLaunchDisabled)
                }

                Button {
                    runScreenshotDebug()
                } label: {
                    Image(systemName: isRunningScreenshotDebug ? "camera.fill" : "camera")
                        .foregroundStyle(isRunningScreenshotDebug ? .yellow : .white)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .help("以 1.5 秒的间隔捕获 10 张屏幕截图")
                .disabled(isRunningScreenshotDebug)
            }

            if backend == .hackclub {
                VStack(alignment: .leading, spacing: 6) {
                    Text("黑客俱乐部人工智能集成")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        SecureField("黑客俱乐部 API 密钥", text: Binding(
                            get: { APIKeyManager.shared.hackClubAPIKey },
                            set: { APIKeyManager.shared.hackClubAPIKey = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Color.black.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12)))

                        TextField("型号名称", text: Binding(
                            get: { UserDefaults.standard.string(forKey: "hackClubModel") ?? "qwen/qwen3-32b" },
                            set: { UserDefaults.standard.set($0, forKey: "hackClubModel") }
                        ))
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Color.black.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12)))
                    }
                }
                .padding(.top, 4)
            }

            if vm.isRunning && vm.subtaskProgress.total > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Subtask \(vm.subtaskProgress.current) of \(vm.subtaskProgress.total)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProgressView().scaleEffect(0.6)
                    }
                    ProgressView(value: Double(vm.subtaskProgress.current),
                                 total: Double(vm.subtaskProgress.total))
                        .tint(.blue)
                }
            }

            if let result = vm.lastResult {
                HStack(spacing: 6) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(result.success ? .green : .orange)
                    Text(result.success ? "Completed" : "Partial")
                        .font(.caption.bold())
                    Text("· \(result.subtasksCompleted)/\(result.subtasksTotal) subtasks · \(result.actionsTaken) actions · \(String(format: "%.1fs", result.duration))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !vm.logEntries.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(vm.logEntries.reversed()) { line in
                            Text(line.text)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(
                                    line.isError ? Color.red :
                                    line.isSubtask ? Color.orange :
                                    Color.secondary
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 140)
                .background(Color.black.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func runScreenshotDebug() {
        guard !isRunningScreenshotDebug else { return }
        isRunningScreenshotDebug = true

        Task { @MainActor in
            defer { isRunningScreenshotDebug = false }

            let perception = ScreenPerception()
            vm.logEntries.append(.init(text: " Screenshot debug started (10 captures / 1.5s)", isError: false, isSubtask: true))

            for index in 1...10 {
                let (image, elements) = await perception.captureAnnotatedScreen()
                let imageNote = image == nil ? "no image" : "image ok"
                vm.logEntries.append(.init(text: " [\(index)/10] \(imageNote) · \(elements.count) elements", isError: false, isSubtask: true))
                if index < 10 {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                }
            }

            vm.logEntries.append(.init(text: " Screenshot debug finished", isError: false, isSubtask: true))
        }
    }
}

// MARK: - Focus Session Settings

struct FocusSessionSettingsView: View {
    private struct AppCandidate: Identifiable, Sendable {
        let name: String
        let bundleID: String
        var id: String { bundleID }
    }

    @EditingSettings var settings: SettingsEditingSession
    @StateObject private var shortcutRecorder = GlobalShortcutRecorder.shared
    @StateObject private var ambient = FocusAmbientSoundManager.shared
    @StateObject private var shortcutsCatalog = ShortcutsCatalog.shared
    @StateObject private var profileStore = FocusProfileStore.shared
    @State private var newBlockedApp: String = ""
    @State private var newBlockedSite: String = ""
    @State private var showingAddSchedule = false
    @State private var appCandidates: [AppCandidate] = []
    @State private var availableFocusModes: [(id: String, name: String)] = []

    nonisolated private static func loadInstalledApps() -> [AppCandidate] {
        InstalledApplications.namesAndBundleIDs().map { AppCandidate(name: $0.name, bundleID: $0.bundleID) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Focus")
                    .font(.largeTitle.bold())
                    .padding(.bottom)

                FocusInsightsPanel(manager: FocusSessionManager.shared)
                    .environmentObject(FocusSessionManager.shared)

                profilesSection
                durationSection
                blockingSection
                socialSection
                triggersSection
                schedulingSection
                liveActivityToggleSection
                environmentSection
                automationSection
            }
            .padding(25)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task {
            guard appCandidates.isEmpty else { return }
            let candidates = await Task.detached(priority: .utility) {
                Self.loadInstalledApps()
            }.value
            guard !Task.isCancelled else { return }
            appCandidates = candidates
            availableFocusModes = MenuBarProfileEngine.fetchAvailableFocusModes()
                .map { (id: $0.identifier, name: $0.name) }
        }
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Profiles")
            Text("每个配置文件都有自己的计时器、块和社交过滤器。单独同步激活和设置。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(profileStore.profiles) { profile in
                        Button {
                            profileStore.select(profile.id)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: profile.symbolName)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(profile.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .frame(width: 88, height: 72)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(profile.id == profileStore.activeProfileID
                                          ? profile.accentColor.opacity(0.28)
                                          : Color.primary.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(profile.id == profileStore.activeProfileID
                                                  ? profile.accentColor.opacity(0.8)
                                                  : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("重复") {
                                var copy = profile
                                copy.id = UUID()
                                copy.name = profile.name + " Copy"
                                profileStore.upsert(copy)
                            }
                            if profileStore.profiles.count > 1 {
                                Button("Delete", role: .destructive) {
                                    profileStore.delete(id: profile.id)
                                }
                            }
                        }
                    }
                    Button {
                        let p = FocusProfile.makeDefault(name: "New Profile", symbol: "sparkles")
                        profileStore.upsert(p)
                        profileStore.select(p.id)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 72)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider().opacity(0.3).padding(.horizontal, 16)

            HStack {
                Text("Name")
                    .font(.system(size: 13))
                Spacer()
                TextField("Name", text: Binding(
                    get: { profileStore.activeProfile.name },
                    set: { name in profileStore.updateActive { $0.name = name } }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(
                title: "与手机同步开始和停止",
                description: "当此配置文件在此处开始或结束时，请在 Android 上执行相同的操作。",
                isOn: Binding(
                    get: { profileStore.activeProfile.syncActivation },
                    set: { v in profileStore.updateActive { $0.syncActivation = v } }
                )
            )
            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(
                title: "同步此配置文件的设置",
                description: "镜像块和社交过滤器。关闭 = 自定义每个设备。",
                isOn: Binding(
                    get: { profileStore.activeProfile.syncSettings },
                    set: { v in profileStore.updateActive { $0.syncSettings = v } }
                )
            )
            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(
                title: "还同步系统 Focus / DND",
                description: "Mirror macOS Focus and Android Do Not Disturb.",
                isOn: $settings.settings.continuitySyncNotificationMode
            )
        }
        .modifier(SettingsContainerModifier())
    }

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Social filters")
            Text("默认情况下，无需阻止每个应用程序即可剪切简短的提要。")
                .font(.caption).foregroundColor(.secondary)
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                socialChip("Instagram Reels", \.blockInstagramReels)
                socialChip("Instagram Explore", \.blockInstagramExplore)
                socialChip("Following only", \.instagramFollowingOnly)
                socialChip("YouTube Shorts", \.blockYouTubeShorts)
                socialChip("Facebook Reels", \.blockFacebookReels)
                socialChip("TikTok", \.blockTikTok)
                socialChip("Snap Spotlight", \.blockSnapchatSpotlight)
                socialChip("Short-form web", \.blockShortFormWeb)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .modifier(SettingsContainerModifier())
    }

    private func socialChip(_ title: String, _ keyPath: WritableKeyPath<FocusSocialFilters, Bool>) -> some View {
        let on = profileStore.activeProfile.social[keyPath: keyPath]
        return Button {
            profileStore.updateActive { $0.social[keyPath: keyPath].toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(on ? Color.purple : Color.secondary)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(on ? Color.purple.opacity(0.12) : Color.primary.opacity(0.04))
            )
            .padding(6)
        }
        .buttonStyle(.plain)
    }

    private func socialToggle(_ title: String, _ keyPath: WritableKeyPath<FocusSocialFilters, Bool>) -> some View {
        socialChip(title, keyPath)
    }

    private var triggersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Auto-Start Triggers")
            Text("当 macOS 焦点模式打开或您的手机进入“勿扰模式”时启动此配置文件。")
                .font(.caption).foregroundColor(.secondary)
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 6)

            if availableFocusModes.isEmpty {
                Text("未找到 macOS 焦点模式。启用焦点状态权限并在系统设置中创建模式。")
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.horizontal, 16).padding(.vertical, 10)
            } else {
                ForEach(availableFocusModes, id: \.id) { mode in
                    let selected = profileStore.activeProfile.triggers.macOSFocusModeIDs.contains(mode.id)
                    ToggleRow(
                        title: mode.name,
                        description: "Start this profile when “\(mode.name)” activates",
                        isOn: Binding(
                            get: { selected },
                            set: { on in
                                profileStore.updateActive { p in
                                    if on {
                                        if !p.triggers.macOSFocusModeIDs.contains(mode.id) {
                                            p.triggers.macOSFocusModeIDs.append(mode.id)
                                        }
                                        if !p.triggers.macOSFocusModeNames.contains(mode.name) {
                                            p.triggers.macOSFocusModeNames.append(mode.name)
                                        }
                                    } else {
                                        p.triggers.macOSFocusModeIDs.removeAll { $0 == mode.id }
                                        p.triggers.macOSFocusModeNames.removeAll { $0 == mode.name }
                                    }
                                }
                            }
                        )
                    )
                    Divider().opacity(0.3).padding(.horizontal, 16)
                }
            }

            ToggleRow(
                title: "安卓勿扰模式",
                description: "当电话进入 DND（需要连续性）时启动。",
                isOn: Binding(
                    get: { profileStore.activeProfile.triggers.androidDND || profileStore.activeProfile.triggers.syncPeerSystemFocus },
                    set: { v in
                        profileStore.updateActive {
                            $0.triggers.androidDND = v
                            $0.triggers.syncPeerSystemFocus = v
                        }
                    }
                )
            )
        }
        .modifier(SettingsContainerModifier())
    }

    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Scheduling")
            Text("在一天中的设定时间自动启动焦点课程 - 每天、一周中的特定日期、每周、每月或一次。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

            if settings.settings.scheduledFocusSessions.isEmpty {
                Text("没有预定的会议。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else {
                ForEach($settings.settings.scheduledFocusSessions) { $schedule in
                    FocusScheduleRowView(schedule: $schedule)
                    Divider().opacity(0.3).padding(.horizontal, 16)
                }
            }

            Divider().opacity(0.3).padding(.horizontal, 16)
            Button {
                showingAddSchedule = true
            } label: {
                Label("添加时间表", systemImage: "plus.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .modifier(SettingsContainerModifier())
        .sheet(isPresented: $showingAddSchedule) {
            AddFocusScheduleView().environment(settings)
        }
    }

    private var liveActivityToggleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Widget & Activity")
            ToggleRow(
                title: "显示在缺口中",
                description: "Display the focus session as a live activity in the notch while it's running.",
                isOn: $settings.settings.focusSessionLiveActivityEnabled
            )
            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(
                title: "显示时间而不是响铃",
                description: "Show the remaining time on the right side instead of the completing progress ring.",
                isOn: $settings.settings.focusSessionLiveActivityShowTime
            )
            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(
                title: "休息和会议通知",
                description: "Get a notification when a focus block ends and a break starts, when a break ends, and when the session finishes.",
                isOn: $settings.settings.focusNotificationsEnabled
            )
            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(
                title: "单击以显示详细视图",
                description: "Clicking the focus session activity opens the full detail view.",
                isOn: $settings.settings.clickToShowFocusSessionView
            )
        }
        .modifier(SettingsContainerModifier())
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Session Timing")
            HStack {
                Text("聚焦持续时间：")
                    .font(.system(size: 13))
                Spacer()
                TextField("分钟", value: Binding(
                    get: { settings.settings.focusSessionDuration / 60 },
                    set: { settings.settings.focusSessionDuration = max(1, $0) * 60 }
                ), format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1)
                    .frame(width: 62)
                    .multilineTextAlignment(.trailing)
                    .help("无限制 — 输入任意分钟数")
                Text("min")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            Divider().opacity(0.3).padding(.horizontal, 16)

            ToggleRow(title: "启用中断", description: "Automatically start a break after each focus block.", isOn: $settings.settings.focusBreakEnabled)
            if settings.settings.focusBreakEnabled {
                Divider().opacity(0.3).padding(.horizontal, 16)
                HStack {
                    Text("休息时间：")
                        .font(.system(size: 13))
                    Spacer()
                    TextField("分钟", value: Binding(
                        get: { settings.settings.focusBreakDuration / 60 },
                        set: { settings.settings.focusBreakDuration = max(0, $0) * 60 }
                    ), format: .number.precision(.fractionLength(0)))
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1)
                        .frame(width: 62)
                        .multilineTextAlignment(.trailing)
                        .help("无限制 — 输入任意分钟数（0 禁用休息）")
                    Text("min")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
        .modifier(SettingsContainerModifier())
    }

    private var blockingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("App & Website Blocking")
            ToggleRow(title: "启用阻止", description: "Block distracting apps and websites during focus sessions.", isOn: $settings.settings.focusBlockingEnabled)
            if settings.settings.focusBlockingEnabled {
                Divider().opacity(0.3).padding(.horizontal, 16)
                Picker("阻塞模式", selection: $settings.settings.focusBlockingMode) {
                    ForEach(FocusBlockingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                Text(settings.settings.focusBlockingMode.blurb)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16).padding(.bottom, 8)

                Divider().opacity(0.3).padding(.horizontal, 16)
                HStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
                    Text("阻断强度")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.top, 10).padding(.horizontal, 16).padding(.bottom, 6)
                Text("在会话期间如何处理被积极阻止的应用程序（和网站）。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                if FocusSessionManager.shared.isSessionActive {
                    Label("会话运行时无法更改强度", systemImage: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                }

                ForEach(FocusIntensity.allCases) { level in
                    Button {
                        guard !FocusSessionManager.shared.isSessionActive else { return }
                        settings.settings.focusIntensity = level
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: level.systemImage)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(settings.settings.focusIntensity == level ? .green : .secondary)
                                .frame(width: 22)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(level.displayName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    if settings.settings.focusIntensity == level {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                    }
                                }
                                Text(level.blurb)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(settings.settings.focusIntensity == level ? Color.green.opacity(0.12) : Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                    .opacity(FocusSessionManager.shared.isSessionActive ? 0.45 : 1.0)
                }
                .padding(.bottom, 6)

                Divider().opacity(0.3).padding(.horizontal, 16)

                if settings.settings.focusBlockingMode == .allowlist {
                    Divider().opacity(0.3).padding(.horizontal, 16)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("允许的应用程序")
                            .font(.caption.bold()).padding(.horizontal, 16).padding(.top, 10)
                        Picker("添加应用程序", selection: $newBlockedApp) {
                            Text("选择一个应用程序...").tag("")
                            ForEach(appCandidates, id: \.bundleID) { candidate in
                                Text(candidate.name).tag(candidate.bundleID)
                            }
                        }
                        .padding(.horizontal, 16)
                        HStack {
                            Spacer()
                            Button("Add") {
                                guard !newBlockedApp.isEmpty else { return }
                                settings.settings.focusAllowedApps.insert(newBlockedApp)
                                newBlockedApp = ""
                            }
                            .disabled(newBlockedApp.isEmpty)
                            .padding(.trailing, 16)
                        }
                        if !settings.settings.focusAllowedApps.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 4) {
                                ForEach(Array(settings.settings.focusAllowedApps), id: \.self) { bundleID in
                                    let name = appCandidates.first(where: { $0.bundleID == bundleID })?.name ?? bundleID
                                    chipView(name) { settings.settings.focusAllowedApps.remove(bundleID) }
                                }
                            }
                            .padding(.horizontal, 16).padding(.bottom, 8)
                        }
                    }
                } else {
                    Divider().opacity(0.3).padding(.horizontal, 16)
                    ToggleRow(title: "休息期间阻塞", description: "Keep blocking active while on break.", isOn: $settings.settings.focusBlockingDuringBreaks)

                    Divider().opacity(0.3).padding(.horizontal, 16)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("被阻止的应用程序")
                            .font(.caption.bold()).padding(.horizontal, 16).padding(.top, 10)
                    Picker("添加应用程序", selection: $newBlockedApp) {
                        Text("选择一个应用程序...").tag("")
                        ForEach(appCandidates, id: \.bundleID) { candidate in
                            Text(candidate.name).tag(candidate.bundleID)
                        }
                    }
                    .padding(.horizontal, 16)
                    HStack {
                        Spacer()
                        Button("Add") {
                            guard !newBlockedApp.isEmpty else { return }
                            settings.settings.focusBlockedApps.insert(newBlockedApp)
                            newBlockedApp = ""
                        }
                        .disabled(newBlockedApp.isEmpty)
                        .padding(.trailing, 16)
                    }
                    if !settings.settings.focusBlockedApps.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 4) {
                            ForEach(Array(settings.settings.focusBlockedApps), id: \.self) { bundleID in
                                let name = appCandidates.first(where: { $0.bundleID == bundleID })?.name ?? bundleID
                                chipView(name) { settings.settings.focusBlockedApps.remove(bundleID) }
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 8)
                    }

                    Divider().opacity(0.3).padding(.horizontal, 16)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("被阻止的网站")
                            .font(.caption.bold()).padding(.horizontal, 16).padding(.top, 10)
                        HStack {
                            TextField("例如推特.com", text: $newBlockedSite)
                                .textFieldStyle(.roundedBorder)
                                .padding(.leading, 16)
                            Button("Add") {
                                let trimmed = newBlockedSite
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .replacingOccurrences(of: "https://", with: "")
                                    .replacingOccurrences(of: "http://", with: "")
                                    .replacingOccurrences(of: "www.", with: "")
                                guard !trimmed.isEmpty else { return }
                                settings.settings.focusBlockedWebsites.insert(trimmed)
                                newBlockedSite = ""
                            }
                            .disabled(newBlockedSite.trimmingCharacters(in: .whitespaces).isEmpty)
                            .padding(.trailing, 16)
                        }
                        if !settings.settings.focusBlockedWebsites.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], alignment: .leading, spacing: 4) {
                                ForEach(Array(settings.settings.focusBlockedWebsites), id: \.self) { site in
                                    chipView(" \(site)") { settings.settings.focusBlockedWebsites.remove(site) }
                                }
                            }
                            .padding(.horizontal, 16).padding(.bottom, 8)
                        }
                    }
                    .padding(.bottom, 8)
                    }
                }
            }
        }
        .modifier(SettingsContainerModifier())
    }

    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Environment")
            Text("在会话运行时将环境调整应用于整个 Mac。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

            ToggleRow(title: "调暗非活动应用程序", description: "Darken windows you're not using so the active app stands out and visual clutter recedes.", isOn: $settings.settings.focusDimInactiveApps)
            if settings.settings.focusDimInactiveApps {
                Divider().opacity(0.3).padding(.horizontal, 16)
                HStack {
                    Text("暗淡强度：")
                        .font(.system(size: 13))
                    Spacer()
                    DeferredSlider(value: $settings.settings.focusDimInactiveOpacity, in: 0.2...1.0)
                        .frame(width: 160)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                Divider().opacity(0.3).padding(.horizontal, 16)
                ToggleRow(title: "任务控制暂停", description: "Temporarily remove the dim layer while Mission Control is open so you can actually see the apps in the Exposé grid.", isOn: $settings.settings.focusDisableDimInMissionControl)
            }

            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(title: "隐藏壁纸", description: "Cover the desktop wallpaper and icons with black for the duration of the session.", isOn: $settings.settings.focusHideWallpaper)

            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(title: "限制可见应用程序", description: "Keep only a few apps on screen; switching to another tucks the oldest one away (restored when the session ends).", isOn: $settings.settings.focusAppLimitEnabled)
            if settings.settings.focusAppLimitEnabled {
                Divider().opacity(0.3).padding(.horizontal, 16)
                HStack {
                    Text("最大可见应用程序数：")
                        .font(.system(size: 13))
                    Spacer()
                    Stepper(value: $settings.settings.focusAppLimit, in: 1...6) {
                        Text("\(settings.settings.focusAppLimit)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            Divider().opacity(0.3).padding(.horizontal, 16)
            ToggleRow(title: "环境声音", description: "Play generated white/pink/brown noise or rain to mask noisy surroundings. Starts automatically with each session.", isOn: $settings.settings.focusAmbientSoundEnabled)
            if settings.settings.focusAmbientSoundEnabled {
                Divider().opacity(0.3).padding(.horizontal, 16)
                Picker("Sound", selection: $settings.settings.focusAmbientSoundType) {
                    ForEach(FocusAmbientSoundType.allCases) { type in
                        Label(type.displayName, systemImage: type.systemImage).tag(type)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                Divider().opacity(0.3).padding(.horizontal, 16)
                HStack(spacing: 12) {
                    Button(action: { ambient.toggle() }) {
                        Label(ambient.isPlaying ? "Stop" : "Preview", systemImage: ambient.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    Text("Volume")
                        .font(.system(size: 13))
                    DeferredSlider(
                        value: Binding(
                            get: { settings.settings.focusAmbientSoundVolume },
                            set: {
                                ambient.volume = $0
                                settings.settings.focusAmbientSoundVolume = $0
                            }
                        ),
                        in: 0...1,
                        onDraftChange: { ambient.volume = $0 }
                    )
                    .frame(width: 110)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
        .modifier(SettingsContainerModifier())
        .onChange(of: settings.settings.focusAmbientSoundType) { _, newType in
            if ambient.isPlaying { ambient.setType(newType) }
        }
        .onChange(of: settings.settings.focusAmbientSoundEnabled) { _, enabled in
            if !enabled, ambient.isPlaying { ambient.stop() }
        }
    }

    private var automationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Automation")

            Text("从任何地方按此快捷键即可开始或暂停焦点会话。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)
            Button(action: {
                if shortcutRecorder.isRecording {
                    shortcutRecorder.stopRecording()
                } else {
                    shortcutRecorder.startRecording { key, flags in
                        settings.settings.focusStartShortcut = KeyboardShortcut(key: key, modifiers: flags)
                    }
                }
            }) {
                HStack {
                    if shortcutRecorder.isRecording {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7)
                            Text("正在录制...（Esc 取消）")
                                .foregroundColor(.accentColor)
                        }
                    } else {
                        Image(systemName: "keyboard")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text("\(KeyboardShortcutHelper.description(for: settings.settings.focusStartShortcut.modifiers)) \(settings.settings.focusStartShortcut.key)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16).padding(.bottom, 12)

            Divider().opacity(0.3).padding(.horizontal, 16)

            HStack(spacing: 8) {
                Image(systemName: "link.icloud")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
                Text("系统时钟和快捷方式")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.top, 10).padding(.horizontal, 16).padding(.bottom, 6)
            Text("Sapphire automatically uses Apple's standard Clock shortcut names (\"Start Timer\", \"Start Stopwatch\", etc.). If iCloud sync is enabled and those Clock shortcuts are present on this Mac, they run automatically during sessions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16).padding(.top, 2).padding(.bottom, 8)
            ToggleRow(title: "与系统时钟同步", description: "Mirror focus sessions to the system Clock app via Shortcuts.", isOn: $settings.settings.focusShortcutsEnabled)
            if settings.settings.focusShortcutsEnabled {
                Divider().opacity(0.3).padding(.horizontal, 16)
                Picker("同步模式", selection: $settings.settings.focusShortcutSyncMode) {
                    ForEach(FocusShortcutSyncMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            Divider().opacity(0.3).padding(.horizontal, 16)
            Text("当会话开始/结束时运行快捷方式 - 例如打开请勿打扰。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 6)
            Picker("会话开始时", selection: $settings.settings.focusStartShortcutName) {
                Text("None").tag("")
                ForEach(shortcutsCatalog.installedNames, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 4)
            Picker("会话结束时", selection: $settings.settings.focusEndShortcutName) {
                Text("None").tag("")
                ForEach(shortcutsCatalog.installedNames, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 4)
            .padding(.bottom, 8)
        }
        .modifier(SettingsContainerModifier())
        .onAppear {
            FocusSessionManager.refreshInstalledShortcuts()
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .padding(.top, 12).padding(.horizontal, 16).padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func chipView(_ text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 3) {
            Text(text).font(.caption).lineLimit(1)
            Button(action: onRemove) { Image(systemName: "xmark.circle.fill").font(.caption) }.buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}

// MARK: - Scheduled Focus Sessions

private struct FocusScheduleRowView: View {
    @EditingSettings private var settings: SettingsEditingSession
    @Binding var schedule: ScheduledFocusSession

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
                .foregroundColor(schedule.isActive ? .green : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(schedule.startTime, style: .time)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(schedule.isActive ? .primary : .secondary)
                    Text(schedule.repeatDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            SettingsSwitch(isOn: $schedule.isActive)
                .controlSize(.mini)

            Button {
                settings.settings.scheduledFocusSessions.removeAll { $0.id == schedule.id }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("删除日程")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var subtitle: String {
        var text = "\(Int(schedule.duration / 60)) min session"
        if schedule.isActive,
           let next = FocusScheduleManager.shared.nextFireDate(for: schedule) {
            let day = Calendar.current.isDateInToday(next)
                ? "today" : (Calendar.current.isDateInTomorrow(next) ? "tomorrow" : next.formatted(date: .abbreviated, time: .omitted))
            text += " · next \(day) at \(next.formatted(date: .omitted, time: .shortened))"
        }
        return text
    }
}

private struct AddFocusScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @EditingSettings private var settings: SettingsEditingSession
    private struct WeekdayToken: Identifiable {
        let number: Int
        let label: String
        var id: Int { number }
    }

    private static let weekdayChoices: [WeekdayToken] = [
        WeekdayToken(number: 2, label: "Mon"),
        WeekdayToken(number: 3, label: "Tue"),
        WeekdayToken(number: 4, label: "Wed"),
        WeekdayToken(number: 5, label: "Thu"),
        WeekdayToken(number: 6, label: "Fri"),
        WeekdayToken(number: 7, label: "Sat"),
        WeekdayToken(number: 1, label: "Sun"),
    ]

    @State private var startTime = Date().addingTimeInterval(60 * 60)
    @State private var repeatInterval: FocusScheduleRepeat = .daily
    @State private var repeatWeekdays: [Int] = []
    @State private var durationMinutes: Double = 90

    var body: some View {
        VStack(spacing: 20) {
            Text("新焦点时间表")
                .font(.title.bold())

            VStack(spacing: 16) {
                DatePicker("Start Time:", selection: $startTime, displayedComponents: .hourAndMinute)

                Picker("重复：", selection: $repeatInterval) {
                    ForEach(FocusScheduleRepeat.allCases) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }

                if repeatInterval == .custom {
                    Divider().opacity(0.2)
                    weekdayPicker
                }

                HStack {
                    Text("持续时间：")
                    Spacer()
                    TextField("分钟", value: Binding(
                        get: { durationMinutes },
                        set: { durationMinutes = max(1, $0) }
                    ), format: .number.precision(.fractionLength(0)))
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1)
                        .frame(width: 62)
                        .multilineTextAlignment(.trailing)
                        .help("无限制 — 输入任意分钟数")
                    Text("min")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Text("预定的会话会尊重您的阻塞、环境和环境声音设置 - 它们的行为与您手动启动的会话完全相同。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .modifier(SettingsContainerModifier())

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button("添加时间表") {
                    var schedule = ScheduledFocusSession()
                    schedule.startTime = startTime
                    schedule.repeatInterval = repeatInterval
                    schedule.duration = durationMinutes * 60
                    if repeatInterval == .custom {
                        schedule.repeatWeekdays = repeatWeekdays
                    }
                    settings.settings.scheduledFocusSessions.append(schedule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 420)
        .onAppear {
            durationMinutes = settings.settings.focusSessionDuration / 60
        }
    }

    private var weekdayPicker: some View {
        VStack(spacing: 8) {
            HStack {
                Text("重复")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(repeatWeekdays.isEmpty ? "Every day" : "Clear all") {
                    repeatWeekdays = []
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.green)
            }

            HStack(spacing: 6) {
                ForEach(Self.weekdayChoices) { token in
                    weekdayPill(token)
                }
            }
        }
    }

    private func weekdayPill(_ token: WeekdayToken) -> some View {
        let isOn = repeatWeekdays.contains(token.number)
        return Button {
            if isOn {
                repeatWeekdays.removeAll { $0 == token.number }
            } else {
                repeatWeekdays.append(token.number)
            }
        } label: {
            Text(token.label)
                .font(.system(size: 11, weight: isOn ? .bold : .medium))
                .foregroundColor(isOn ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(
                    isOn ? Color.green : Color.white.opacity(0.08),
                    in: Capsule()
                )
        }        .buttonStyle(.plain)
        .help(token.label)
    }
}