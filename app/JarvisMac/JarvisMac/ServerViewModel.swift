//
//  ServerViewModel.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

import Foundation
import Combine

@MainActor
final class ServerViewModel: ObservableObject {
    @Published var statusMessage: String = "Checking local server..."
    @Published var isHealthy: Bool = false

    private let healthURL = URL(string: "http://localhost:8787/health")!

    func checkHealth() async {
        statusMessage = "Checking local server..."
        isHealthy = false

        do {
            let (data, response) = try await URLSession.shared.data(from: healthURL)

            guard let httpResponse = response as? HTTPURLResponse else {
                statusMessage = "Invalid server response."
                return
            }

            guard httpResponse.statusCode == 200 else {
                statusMessage = "Server returned status \(httpResponse.statusCode)."
                return
            }

            let decoded = try JSONDecoder().decode(HealthResponse.self, from: data)

            if decoded.ok {
                statusMessage = "Connected to local token server."
                isHealthy = true
            } else {
                statusMessage = "Server responded, but health check failed."
            }
        } catch {
            statusMessage = "Could not reach local server: \(error.localizedDescription)"
        }
    }
}

struct HealthResponse: Decodable {
    let ok: Bool
}
