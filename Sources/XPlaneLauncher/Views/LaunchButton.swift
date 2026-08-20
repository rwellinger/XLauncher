//
//  Copyright (c) 2026 Jeremie Corbier
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import SwiftUI

struct LaunchButton: View {
    @Environment(PluginManager.self) var pluginManager
    @Environment(SystemReadinessManager.self) var readiness

    private var isBlocked: Bool {
        pluginManager.xPlanePath == nil || readiness.blocksLaunch
    }

    var body: some View {
        VStack(spacing: 6) {
            Button(action: {
                pluginManager.launchXPlane()
            }) {
                HStack {
                    Image(systemName: "airplane")
                        .rotationEffect(.degrees(-45))
                    Text("Launch X-Plane")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.gradient)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(.plain) // Important for custom styling in SwiftUI macOS
            .disabled(isBlocked)
            .opacity(isBlocked ? 0.6 : 1.0)
            .help(readiness.blocksLaunch ? readiness.reason : "")

            if readiness.blockLaunchOnHighLoad {
                Label(readiness.reason, systemImage: readiness.isReady ? "checkmark.circle" : "hourglass")
                    .font(.caption)
                    .foregroundStyle(readiness.isReady ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Never lock the user out: the readiness check is advisory only.
                if readiness.blocksLaunch && pluginManager.xPlanePath != nil {
                    Button("Launch Anyway") {
                        pluginManager.launchXPlane()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
        }
        .task {
            readiness.startMonitoring()
        }
        .onDisappear {
            readiness.stopMonitoring()
        }
    }
}
