//
//  TokenManager.swift
//
//
//

import Foundation

public enum TokenManagerError: Error {
    case invalidURLFromBundle
    case invalidResponse
}

public class TokenManager {
    private var token: String?
    private let tokenURL = URL(string: "https://api.cp.pt/cp-api/oauth/token")!

    public init() {}

    private func getNewToken() async throws -> String {
        var request = URLRequest(url: tokenURL)
        guard let apiAuth = Bundle.main.infoDictionary?["API_AUTH"] as? String else {
            throw TokenManagerError.invalidURLFromBundle
        }
        request.httpMethod = "POST"
        request.setValue(apiAuth, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyData = "grant_type=client_credentials"
        request.httpBody = bodyData.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TokenManagerError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? [String: Any],
              let accessToken = dictionary["access_token"] as? String else {
            throw TokenManagerError.invalidResponse
        }

        return accessToken
    }

    public func savedToken() async throws -> String {
        if let token = token {
            return token
        } else {
            return try await renewSavedToken()
        }
    }

    private func renewSavedToken() async throws -> String {
        let newToken = try await getNewToken()
        token = newToken
        return newToken
    }
}

