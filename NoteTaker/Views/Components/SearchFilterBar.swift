//
//  SearchFilterBar.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI

/// Advanced search filter controls
/// Provides date range, scope, and pinned filtering options
struct SearchFilterBar: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var showPinnedOnly: Bool?
    @Binding var searchScope: SearchScope

    @State private var showDatePicker = false

    var body: some View {
        VStack(spacing: .spacingS) {
            // Search scope selector
            Picker("Scope", selection: $searchScope) {
                Text("All").tag(SearchScope.all)
                Text("Title").tag(SearchScope.titleOnly)
                Text("Content").tag(SearchScope.contentOnly)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Filter chips
            HStack(spacing: .spacingS) {
                // Pinned filter toggle
                Button {
                    if showPinnedOnly == nil {
                        showPinnedOnly = true
                    } else if showPinnedOnly == true {
                        showPinnedOnly = false
                    } else {
                        showPinnedOnly = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                        Text(pinnedFilterLabel)
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, .spacingS)
                    .padding(.vertical, 4)
                    .background(pinnedFilterBackground)
                    .foregroundStyle(pinnedFilterForeground)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Date filter button
                Button {
                    showDatePicker.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(dateFilterLabel)
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, .spacingS)
                    .padding(.vertical, 4)
                    .background(hasDateFilter ? Color.accentColor.opacity(0.2) : .clear)
                    .foregroundStyle(hasDateFilter ? .primary : .secondary)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Spacer()

                // Clear all filters
                if hasActiveFilters {
                    Button("Clear") {
                        clearAllFilters()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }

            // Date picker popover
            if showDatePicker {
                VStack(spacing: .spacingS) {
                    HStack {
                        Text("From:")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { startDate ?? Date() },
                                set: { startDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)

                        if startDate != nil {
                            Button {
                                startDate = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        Text("To:")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { endDate ?? Date() },
                                set: { endDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)

                        if endDate != nil {
                            Button {
                                endDate = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.spacingS)
                .background(.background.secondary)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Computed Properties

    private var pinnedFilterLabel: String {
        if showPinnedOnly == nil {
            return "Any"
        } else if showPinnedOnly == true {
            return "Pinned"
        } else {
            return "Unpinned"
        }
    }

    private var pinnedFilterBackground: Color {
        showPinnedOnly != nil ? Color.accentColor.opacity(0.2) : .clear
    }

    private var pinnedFilterForeground: Color {
        showPinnedOnly != nil ? .primary : .secondary
    }

    private var dateFilterLabel: String {
        if startDate != nil || endDate != nil {
            return "Dates"
        }
        return "Any Date"
    }

    private var hasDateFilter: Bool {
        startDate != nil || endDate != nil
    }

    private var hasActiveFilters: Bool {
        showPinnedOnly != nil || hasDateFilter || searchScope != .all
    }

    // MARK: - Actions

    private func clearAllFilters() {
        startDate = nil
        endDate = nil
        showPinnedOnly = nil
        searchScope = .all
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SearchFilterBar(
            startDate: .constant(nil),
            endDate: .constant(nil),
            showPinnedOnly: .constant(nil),
            searchScope: .constant(.all)
        )
        .padding()

        Spacer()
    }
    .frame(width: 300, height: 400)
}
