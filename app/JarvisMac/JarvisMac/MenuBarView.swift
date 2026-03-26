//
//  MenuBarView.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

import SwiftUI

struct MenuBarView: View {
    @StateObject private var viewModel = ServerViewModel()

    var body: some View {
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
                Label("Server", systemImage: viewModel.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(viewModel.isHealthy ? .green : .red)
                    .font(.subheadline)

                Text(viewModel.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.primary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming")
                    .font(.subheadline)
                    .bold()

                Text("• Hold-to-talk\n• Spoken replies\n• Screenshot help")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

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
        .task {
            await viewModel.checkHealth()
        }
    }
}

#Preview {
    MenuBarView()
}
