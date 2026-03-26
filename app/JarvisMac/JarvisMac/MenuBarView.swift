//
//  MenuBarView.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

import SwiftUI

struct MenuBarView: View {
    @StateObject private var viewModel = ServerViewModel()
    @ObservedObject var hotkeyMonitor: HotkeyMonitor
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(hotkeyMonitor.isRightOptionPressed ? Color.green : Color.gray.opacity(0.3))
                .frame(height: 6)
                .opacity(hotkeyMonitor.isRightOptionPressed ? (pulse ? 1.0 : 0.4) : 1.0)
                .animation(
                    hotkeyMonitor.isRightOptionPressed
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: pulse
                )

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 30))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Jarvis")
                            .font(.headline)
                        Text("Menu Bar Assistant")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        "Server",
                        systemImage: viewModel.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .foregroundStyle(viewModel.isHealthy ? .green : .red)
                    .font(.subheadline)

                    Text(viewModel.statusMessage)
                        .font(.callout)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Push-to-Talk Status")
                        .font(.subheadline)
                        .bold()

                    Label(
                        hotkeyMonitor.isRightOptionPressed ? "Listening..." : "Hold Right Option to Talk",
                        systemImage: hotkeyMonitor.isRightOptionPressed ? "mic.fill" : "keyboard"
                    )
                    .foregroundStyle(hotkeyMonitor.isRightOptionPressed ? .green : .secondary)
                    .font(.callout)
                }

                Divider()

                HStack {
                    Button("Test Server") {
                        Task {
                            await viewModel.checkHealth()
                        }
                    }

                    Spacer()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding(16)
            .frame(width: 340)
        }
        .task {
            await viewModel.checkHealth()
        }
        .onAppear {
            pulse.toggle()
        }
    }
}

#Preview {
    MenuBarView(hotkeyMonitor: HotkeyMonitor.shared)
}
