// SPDX-License-Identifier: Apache-2.0

import Foundation

struct Client {
    struct AccessTokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Int
        let refreshToken: String
        let refreshTokenExpiresIn: Int
        let scope: String
        let tokenType: String
    }

    struct UserResponse: Decodable {
        let login: String
    }

    enum ClientError: Error {
        case invalidResponse
    }

    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func generateAccessToken(clientId: String, clientSecret: String, code: String) async throws -> AccessTokenResponse {
        let request: URLRequest = {
            let url = URL(string: "https://github.com/login/oauth/access_token")?.appending(
                queryItems: [
                    URLQueryItem(name: "client_id", value: clientId),
                    URLQueryItem(name: "client_secret", value: clientSecret),
                    URLQueryItem(name: "code", value: code),
                    URLQueryItem(name: "redirect_uri", value: "net.mtgto.examplewebauthenticationsession://"),
                ])
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = [
                "Accept": "application/json",
            ]
            return request
        }()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        if response.statusCode != 200 {
            debugPrint("Status Code: \(response.statusCode)")
            throw ClientError.invalidResponse
        }
        return try decoder.decode(AccessTokenResponse.self, from: data)
    }

    // https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28#get-the-authenticated-user
    func getAuthenticatedUser(accessToken: String) async throws -> UserResponse {
        let request: URLRequest = {
            var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = [
                "Accept": "application/vnd.github+json",
                "Authorization": "Bearer \(accessToken)",
                "X-GitHub-Api-Version": "2022-11-28",
            ]
            return request
        }()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        if response.statusCode != 200 {
            debugPrint("Status Code: \(response.statusCode)")
            throw ClientError.invalidResponse
        }
        return try decoder.decode(UserResponse.self, from: data)
    }
}
