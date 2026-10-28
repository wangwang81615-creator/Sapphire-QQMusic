//
//  AudioSettingsView.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2026-08-10

import SwiftUI

struct AudioSettingsView: View {
    @EditingSettings var settings: SettingsEditingSession
    @ObservedObject private var audioManager = MultiAudioManager.shared
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    @State private var showResetAppConfirmation = false
    @State private var showResetDeviceConfirmation = false
    @State private var mixerNavigationStack: [NotchWidgetMode] = []
    @State private var selectedAdjustment: AudioSettingsAdjustment?
    @AppStorage(AudioEQ.displayedBandCountDefaultsKey) private var displayedBandCount = AudioEQBandLayout.thirtyOne.rawValue

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Audio")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 0) {
                    Text("缺口")
                        .font(.headline)
                        .padding([.top, .horizontal])

                    CompactToggleRow(
                        title: "凹口多音频",
                        description: "在扩展的凹口中显示每个应用程序的混合器。",
                        isOn: Binding(
                            get: { settings.settings.notchButtonOrder.contains(.multiAudio) },
                            set: { enabled in
                                if enabled && !settings.settings.notchButtonOrder.contains(.multiAudio) {
                                    settings.settings.notchButtonOrder.append(.multiAudio)
                                } else if !enabled {
                                    settings.settings.notchButtonOrder.removeAll { $0 == .multiAudio }
                                }
                            }
                        )
                    )
                    .disabled(permissionsManager.screenRecordingStatus != .granted)
                    Divider().padding(.leading, 20)
                    CompactToggleRow(
                        title: "触觉反馈",
                        description: "调整音频控制时出现轻微振动。",
                        isOn: $settings.settings.hapticFeedbackEnabled
                    )
                    Divider().padding(.leading, 20)
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("均衡器频段")
                            Text("选择应用程序和设备均衡器中显示的频率控制数量。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("均衡器频段", selection: $displayedBandCount) {
                            ForEach(AudioEQBandLayout.allCases) { layout in
                                Text(layout.displayName).tag(layout.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .modifier(SettingsContainerModifier())

                MicrophoneAmplifierSettingsView()
                    .modifier(SettingsContainerModifier())

                AudioSwitchingSettingsView()
                    .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("应用程序和设备混合器")
                            .font(.headline)
                        Text("凹口中提供相同的音量、路由、EQ、8D、环绕、平衡和延迟控制。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    SystemAudioPanel(navigationStack: $mixerNavigationStack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 430)
                }
                .modifier(SettingsContainerModifier())

                VStack(alignment: .leading, spacing: 0) {
                    Text("重置")
                        .font(.headline)
                        .padding([.top, .horizontal])

                    AudioResetRow(
                        title: "重置每个应用程序的调整",
                        subtitle: "清除所有应用程序的自定义音量、静音、EQ 和 8D 空间音频。",
                        buttonTitle: "Reset Apps",
                        buttonColor: .red
                    ) {
                        showResetAppConfirmation = true
                    }
                    .alert("重置每个应用程序设置？", isPresented: $showResetAppConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("重置", role: .destructive) { resetAllAppSettings() }
                    } message: {
                        Text("这将为每个应用程序恢复默认音量、平坦均衡器、环绕声和 8D 音频。")
                    }

                    Divider().padding(.leading, 20)

                    AudioResetRow(
                        title: "重置设备设置",
                        subtitle: "清除所有设备的主音量、平衡、延迟和均衡器。",
                        buttonTitle: "Reset Devices",
                        buttonColor: .red
                    ) {
                        showResetDeviceConfirmation = true
                    }
                    .alert("重置设备设置？", isPresented: $showResetDeviceConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("重置", role: .destructive) { resetAllDeviceSettings() }
                    } message: {
                        Text("这会将所有连接的输出设备恢复为其默认状态。")
                    }
                }
                .modifier(SettingsContainerModifier())

                RequiredPermissionsView(section: .audio)
            }
            .padding(25)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: permissionsManager.screenRecordingStatus) { _, newStatus in
            if newStatus == .granted, !settings.settings.notchButtonOrder.contains(.multiAudio) {
                settings.settings.notchButtonOrder.append(.multiAudio)
            }
        }
        .onChange(of: mixerNavigationStack.count) { _, _ in
            presentLatestMixerAdjustment()
        }
        .sheet(item: $selectedAdjustment) { adjustment in
            AudioSettingsAdjustmentSheet(adjustment: adjustment)
        }
    }

    private func presentLatestMixerAdjustment() {
        guard let destination = mixerNavigationStack.last else { return }
        mixerNavigationStack.removeAll()

        switch destination {
        case .multiAudioDeviceAdjust(let device):
            selectedAdjustment = .deviceAdjust(device)
        case .multiAudioEQ(let device):
            selectedAdjustment = .deviceEQ(device)
        case .earbudControls(let device):
            selectedAdjustment = .earbudControls(device)
        case .multiAudioAppEQ(let bundleID, let appName):
            selectedAdjustment = .appEQ(bundleID: bundleID, appName: appName)
        case .multiAudioApp8D(let bundleID, let appName):
            selectedAdjustment = .app8D(bundleID: bundleID, appName: appName)
        case .multiAudioAppSurround(let bundleID, let appName):
            selectedAdjustment = .appSurround(bundleID: bundleID, appName: appName)
        default:
            break
        }
    }

    private func resetAllAppSettings() {
        Task { @MainActor in
            PerAppAudioController.shared.clearAllPersistedState()
            MultiAudioManager.shared.clearAllEightDAudioSettings()
            MultiAudioManager.shared.resetAllTaps()
        }
    }

    private func resetAllDeviceSettings() {
        Task { @MainActor in
            MultiAudioManager.shared.clearAllDeviceSettings()
        }
    }
}

private enum AudioSettingsAdjustment: Identifiable {
    case deviceAdjust(AudioDevice)
    case deviceEQ(AudioDevice)
    case earbudControls(AudioDevice)
    case appEQ(bundleID: String, appName: String)
    case app8D(bundleID: String, appName: String)
    case appSurround(bundleID: String, appName: String)

    var id: String {
        switch self {
        case .deviceAdjust(let device):
            return "device-adjust-\(device.id)"
        case .deviceEQ(let device):
            return "device-eq-\(device.id)"
        case .earbudControls(let device):
            return "earbuds-\(device.id)"
        case .appEQ(let bundleID, _):
            return "app-eq-\(bundleID)"
        case .app8D(let bundleID, _):
            return "app-8d-\(bundleID)"
        case .appSurround(let bundleID, _):
            return "app-surround-\(bundleID)"
        }
    }
}

private struct AudioSettingsAdjustmentSheet: View {
    let adjustment: AudioSettingsAdjustment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("音频调整")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .frame(height: 48)

            Divider()

            adjustmentView
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var adjustmentView: some View {
        switch adjustment {
        case .deviceAdjust(let device):
            DeviceAdjustView(device: device)
        case .deviceEQ(let device):
            DeviceEQView(device: device)
        case .earbudControls(let device):
            EarbudControlsView(device: device)
        case .appEQ(let bundleID, let appName):
            AppEQView(bundleID: bundleID, appName: appName)
        case .app8D(let bundleID, let appName):
            EightDAudioView(bundleID: bundleID, appName: appName)
        case .appSurround(let bundleID, let appName):
            SurroundAudioView(bundleID: bundleID, appName: appName)
        }
    }
}

// MARK: - Microphone gain preview

private struct MicrophoneAmplifierSettingsView: View {
    @ObservedObject private var mic = MicrophoneUsageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("麦克风增益预览")
                .font(.headline)
                .padding([.top, .horizontal])

            CompactToggleRow(
                title: "预览增益",
                description: "将增益应用于 Sapphire 的实时电平表，以便您可以检查削波。其他应用程序仍然接收原始麦克风信号。",
                isOn: $mic.amplifierEnabled
            )

            Divider().padding(.leading, 20)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("预览增益")
                    Spacer()
                    Text("×\(mic.amplifierGain, specifier: "%.1f")")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $mic.amplifierGain, in: 1...4, step: 0.1)
                    .tint(.orange)
                    .disabled(!mic.amplifierEnabled)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.leading, 20)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(mic.isClipping ? "Clipping detected" : "Live input level", systemImage: mic.isClipping ? "exclamationmark.triangle.fill" : "mic.fill")
                        .foregroundStyle(mic.isClipping ? .red : .primary)
                    Spacer()
                    Text("\(Int(mic.audioLevel * 100))%")
                        .font(.caption.monospacedDigit())
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.18))
                        Capsule()
                            .fill(mic.isClipping ? Color.red : (mic.audioLevel > 0.85 ? Color.orange : Color.green))
                            .frame(width: proxy.size.width * CGFloat(mic.audioLevel))
                        Rectangle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 2)
                            .offset(x: max(0, proxy.size.width - 2))
                    }
                }
                .frame(height: 8)
                Text(mic.isMicInUse ? (mic.isClipping ? "Lower the gain or microphone input level." : "Peak: \(Int(mic.peakLevel * 100))%") : "Start using the microphone to see its level.")
                    .font(.caption)
                    .foregroundStyle(mic.isClipping ? .red : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .onAppear { mic.beginMetering() }
        .onDisappear { mic.endMetering() }
    }
}

// MARK: - Rows

private struct AudioResetRow: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonColor: Color
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button(buttonTitle, action: action)
                .buttonStyle(.bordered)
                .tint(buttonColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
// MARK: - Output switching & microphone

private struct AudioSwitchingSettingsView: View {
    @ObservedObject private var switcher = AudioOutputSwitcher.shared
    @ObservedObject private var audio = MultiAudioManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("输出切换和麦克风")
                .font(.headline)
                .padding([.top, .horizontal])

            AudioShortcutRow(
                title: "循环输出装置",
                subtitle: "使下一个输出低于系统默认值。",
                identifier: "audioOutputCycleShortcut",
                shortcut: $switcher.cycleShortcut
            )

            if !audio.availableOutputDevices.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("循环中的输出")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(audio.availableOutputDevices) { device in
                        Toggle(device.name, isOn: cycleBinding(for: device.uid))
                            .toggleStyle(.checkbox)
                            .font(.system(size: 12))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }

            Divider().padding(.leading, 20)

            CompactToggleRow(
                title: "耳机断开连接时降低音量",
                description: "当耳机消失时，将扬声器音量降至安全水平，并在耳机返回时恢复音量。",
                isOn: $switcher.lowerVolumeOnHeadphoneDisconnect
            )
            HStack {
                Text("扬声器电平")
                Slider(value: $switcher.headphoneDisconnectLevel, in: 0...0.8, step: 0.05)
                Text("\(Int(switcher.headphoneDisconnectLevel * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .disabled(!switcher.lowerVolumeOnHeadphoneDisconnect)

            Divider().padding(.leading, 20)

            AudioShortcutRow(
                title: "Mute microphone",
                subtitle: "在每个输入设备上切换静音。",
                identifier: "microphoneMuteShortcut",
                shortcut: $switcher.micMuteShortcut
            )

            Divider().padding(.leading, 20)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("首选麦克风")
                    Text("即使连接带有麦克风的耳机，仍保留为系统输入。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("首选麦克风", selection: preferredInputBinding) {
                    Text("系统选择").tag(String?.none)
                    ForEach(audio.availableInputDevices) { device in
                        Text(device.name).tag(String?.some(device.uid))
                    }
                    if let preferred = audio.preferredInputUID,
                       !audio.availableInputDevices.contains(where: { $0.uid == preferred }) {
                        Text("断开连接的设备").tag(String?.some(preferred))
                    }
                }
                .labelsHidden()
                .frame(width: 200)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func cycleBinding(for uid: String) -> Binding<Bool> {
        Binding(
            get: { switcher.cycleDeviceUIDs.isEmpty || switcher.cycleDeviceUIDs.contains(uid) },
            set: { included in
                var uids = switcher.cycleDeviceUIDs.isEmpty ? audio.availableOutputDevices.map(\.uid) : switcher.cycleDeviceUIDs
                if included {
                    if !uids.contains(uid) { uids.append(uid) }
                } else {
                    uids.removeAll { $0 == uid }
                }
                switcher.cycleDeviceUIDs = uids
            }
        )
    }

    private var preferredInputBinding: Binding<String?> {
        Binding(
            get: { audio.preferredInputUID },
            set: { uid in
                if let uid, let device = audio.availableInputDevices.first(where: { $0.uid == uid }) {
                    audio.selectInputDevice(device)
                } else if uid == nil {
                    audio.clearPreferredInput()
                }
            }
        )
    }
}

private struct AudioShortcutRow: View {
    let title: String
    let subtitle: String
    let identifier: String
    @Binding var shortcut: KeyboardShortcut?
    @ObservedObject private var recorder = GlobalShortcutRecorder.shared

    private var isRecordingThis: Bool {
        recorder.isRecording && recorder.recordingIdentifier == identifier
    }

    private var shortcutText: String {
        guard let shortcut else { return "Not set" }
        var text = ""
        if shortcut.modifiers.contains(.control) { text += "⌃" }
        if shortcut.modifiers.contains(.option) { text += "⌥" }
        if shortcut.modifiers.contains(.shift) { text += "⇧" }
        if shortcut.modifiers.contains(.command) { text += "⌘" }
        return text + shortcut.key
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(isRecordingThis ? "Press keys…" : shortcutText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(shortcut == nil && !isRecordingThis ? .secondary : .primary)
            Button(isRecordingThis ? "Cancel" : "Record") {
                if isRecordingThis {
                    recorder.stopRecording()
                } else if !recorder.isRecording {
                    recorder.startRecording(identifier: identifier) { key, flags in
                        shortcut = KeyboardShortcut(key: key, modifiers: flags)
                    }
                }
            }
            .buttonStyle(.bordered)
            if shortcut != nil {
                Button("Clear") { shortcut = nil }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}