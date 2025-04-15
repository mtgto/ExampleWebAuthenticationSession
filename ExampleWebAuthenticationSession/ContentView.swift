// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct ContentView: View {
    enum GithubResponse {
        case success(String)
        case failure(String)
    }

    @State private var githubResponse: GithubResponse?

    var body: some View {
        VStack {
            Text("ExampleWebAuthenticationSession")
                .font(.title)
                .padding()
            Text("This is a macOS application that uses WebAuthenticationSession for GitHub App authorization. All source code is available on [GitHub](https://github.com/mtgto/ExampleWebAuthenticationSession).")
                .padding()
            Text("Clicking the below button to generate GitHub User Access Token.")
            Spacer()
            if let githubResponse = githubResponse {
                if case .success(let token) = githubResponse {
                    Text("Successfully obtained GitHub User Access Token: \(token)")
                } else {
                    Text("Failed to obtain GitHub User Access Token.")
                }
            }
            Spacer()
            Button {

            } label: {
                Text("Generate GitHub User Access Token")
            }
        }
        .padding()
        .frame(width: 480, height: 270)
    }
}

#Preview {
    ContentView()
}
