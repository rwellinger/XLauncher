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

struct AircraftListView: View {
    @Environment(PluginManager.self) var pluginManager
    @State private var itemToDelete: PluginManager.Aircraft? = nil

    /// Aircraft stored directly under the central Aircraft folder.
    private var ungrouped: [PluginManager.Aircraft] {
        pluginManager.aircraft.filter { $0.groupName == nil }
    }

    /// Grouping folders in the order they appear in the scanned list.
    private var groupNames: [String] {
        var seen: Set<String> = []
        return pluginManager.aircraft.compactMap { item -> String? in
            guard let group = item.groupName, seen.insert(group).inserted else { return nil }
            return group
        }
    }

    private func members(of group: String) -> [PluginManager.Aircraft] {
        pluginManager.aircraft.filter { $0.groupName == group }
    }

    var body: some View {
        List {
            ForEach(ungrouped) { item in
                AircraftRow(aircraft: item, onDelete: {
                    itemToDelete = item
                })
            }

            ForEach(groupNames, id: \.self) { group in
                let items = members(of: group)
                let isExpanded = pluginManager.isAircraftGroupExpanded(group)

                Section {
                    if isExpanded {
                        ForEach(items) { item in
                            AircraftRow(aircraft: item, onDelete: {
                                itemToDelete = item
                            })
                        }
                    }
                } header: {
                    AircraftGroupHeader(group: group, items: items, isExpanded: isExpanded)
                }
            }

            if pluginManager.aircraft.isEmpty {
                ContentUnavailableView {
                    Label("No Aircraft Found", systemImage: "airplane")
                } description: {
                    Text("Check your Central Data Folder ('Aircraft' subfolder).")
                }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .alert(
            "Delete Aircraft",
            isPresented: Binding(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            ),
            presenting: itemToDelete
        ) { item in
            Button("Delete", role: .destructive) {
                pluginManager.deleteAircraft(item)
            }
            Button("Cancel", role: .cancel) { }
        } message: { item in
            Text("Are you sure you want to delete '\(item.name)'?\n\nThis will permanently delete the files from your Central Data Folder ('Aircraft/\(item.folderName)'), unlink it from X-Plane, and remove it from all profiles.\n\nThis action cannot be undone.")
        }
    }
}

struct AircraftRow: View {
    @Environment(PluginManager.self) var pluginManager
    let aircraft: PluginManager.Aircraft
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane")
                .font(.title3)
                .foregroundStyle(aircraft.isEnabled ? .green : .secondary)
                .frame(width: 32, height: 32)
                .background(aircraft.isEnabled ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(aircraft.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(aircraft.folderName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if pluginManager.isAircraftModified(aircraft) {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 5, height: 5)
                    Text("Modified")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            }

            Text(aircraft.isEnabled ? "Enabled" : "Disabled")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(aircraft.isEnabled ? .green : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(aircraft.isEnabled ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12))
                .clipShape(Capsule())

            Toggle("", isOn: Binding(
                get: { aircraft.isEnabled },
                set: { _ in pluginManager.toggleAircraft(aircraft) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete Add-on...", systemImage: "trash")
            }
        }
    }
}

struct AircraftGroupHeader: View {
    @Environment(PluginManager.self) var pluginManager
    let group: String
    let items: [PluginManager.Aircraft]
    let isExpanded: Bool

    private var enabledCount: Int {
        items.filter(\.isEnabled).count
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    pluginManager.toggleAircraftGroup(group)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)

                    Label(group, systemImage: isExpanded ? "folder.badge.gearshape" : "folder")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isExpanded ? "Collapse this group" : "Expand this group")

            Text("\(enabledCount)/\(items.count)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(enabledCount > 0 ? .green : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(enabledCount > 0 ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12))
                .clipShape(Capsule())

            Toggle("", isOn: Binding(
                get: { enabledCount == items.count },
                set: { pluginManager.setAircraftGroupEnabled(group, isEnabled: $0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
            .help("Enable or disable every aircraft in this group")
        }
    }
}
