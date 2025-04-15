// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    enum GithubResponse {
        case success(String)
        case failure(String)
    }

    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @State var response: GithubResponse?
    @State private var isAuthorizing = false
    @State private var state: String = ""

    var body: some View {
        VStack {
            Text("ExampleWebAuthenticationSession")
                .font(.title)
            Text("This is a macOS application that uses WebAuthenticationSession for GitHub App authorization. All source code is available on [GitHub](https://github.com/mtgto/ExampleWebAuthenticationSession).")
                .padding()
            Text("Clicking the below button to generate GitHub User Access Token.")
            Spacer()
            if let response {
                switch response {
                case .success(let message):
                    Text(message)
                case .failure(let message):
                    Text("Failure: \(message)")
                }
            }
            Spacer()
            Button {
                guard let clientId = Bundle.main.infoDictionary?["GITHUB_CLIENT_ID"] as? String else {
                    response = .failure("GITHUB_CLIENT_ID is not found in Info.plist")
                    return
                }
                if clientId.isEmpty {
                    response = .failure("GITHUB_CLIENT_ID is not set in Config.xcconfig")
                    return
                }
                state = String(Date().timeIntervalSince1970)
                let authorizeUrl = URL(string: "https://github.com/login/oauth/authorize")?.appending(queryItems: [
                    URLQueryItem(name: "client_id", value: clientId),
                    URLQueryItem(name: "redirect_uri", value: "net.mtgto.examplewebauthenticationsession://"),
                    URLQueryItem(name: "state", value: state),
                ])
                Task {
                    do {
                        let urlWithToken = try await webAuthenticationSession.authenticate(
                            using: authorizeUrl!,
                            callbackURLScheme: "net.mtgto.gpm"
                        )
                        // Retrieve code and state params from callback url
                        guard let urlComponents = URLComponents(url: urlWithToken, resolvingAgainstBaseURL: false),
                              let queryItems = urlComponents.queryItems,
                              let code = queryItems.first(where: { $0.name == "code" })?.value,
                              let state = queryItems.first(where: { $0.name == "state" })?.value else {
                            response = .failure("Unexpected invalid response")
                            return
                        }
                        guard state == self.state else {
                            response = .failure("Unexpected invalid state")
                            return
                        }
                        guard let clientSecret = Bundle.main.infoDictionary?["GITHUB_CLIENT_SECRET"] as? String else {
                            response = .failure("GITHUB_CLIENT_SECRET is not found in Info.plist")
                            return
                        }
                        if clientSecret.isEmpty {
                            response = .failure("GITHUB_CLIENT_SECRET is not set in Config.xcconfig")
                            return
                        }
                        let client = Client()
                        let accessToken = try await client.generateAccessToken(clientId: clientId, clientSecret: clientSecret, code: code)
                        let user = try await client.getAuthenticatedUser(accessToken: accessToken.accessToken)
                        response = .success("Hello, \(user.login)!")
                    } catch {
                        debugPrint("Failed to authorize: \(error)")
                        response = .failure("Error: \(error)")
                    }
                }
            } label: {
                Text("Open github.com using WebAuthenticationSession")
            }
            .disabled(isAuthorizing)
        }
        .padding()
        .frame(width: 480, height: 270)
    }
}

#Preview {
    ContentView()
}

#Preview("Success") {
    ContentView(response: .success("token"))
}

#Preview("Failure") {
    ContentView(response: .failure("token"))
}
