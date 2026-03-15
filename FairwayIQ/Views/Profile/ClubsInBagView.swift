//
//  ClubsInBagView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct ClubsInBagView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile
    @State private var newClubName = ""
    @State private var showAddField = false

    private var clubs: [String] { profile.clubsList }

    var body: some View {
        NavigationStack {
            List {
                ForEach(clubs, id: \.self) { club in
                    Text(club)
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                .onDelete(perform: deleteClubs)
                if showAddField {
                    HStack {
                        TextField("Club name", text: $newClubName)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Button("Add") {
                            addClub()
                        }
                        .foregroundStyle(Theme.Color.greenPrimary)
                        .disabled(newClubName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Color.background)
            .navigationTitle("Clubs in bag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(showAddField ? "Done" : "Add club") {
                        if showAddField && !newClubName.isEmpty {
                            addClub()
                            newClubName = ""
                        }
                        showAddField.toggle()
                    }
                    .foregroundStyle(Theme.Color.greenPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addClub() {
        let name = newClubName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        var list = profile.clubsList
        if !list.contains(name) {
            list.append(name)
            profile.clubsList = list
            try? modelContext.save()
        }
        newClubName = ""
    }

    private func deleteClubs(at offsets: IndexSet) {
        var list = profile.clubsList
        list.remove(atOffsets: offsets)
        profile.clubsList = list
        try? modelContext.save()
    }
}
