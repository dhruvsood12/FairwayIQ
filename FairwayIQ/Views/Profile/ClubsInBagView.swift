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
    @State private var saveErrorMessage: String?
    @State private var showingSaveError = false

    private var clubs: [String] { profile.clubsList }

    var body: some View {
        NavigationStack {
            List {
                ForEach(clubs, id: \.self) { club in
                    Text(club)
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                .onDelete(perform: deleteClubs)
                .onMove(perform: moveClubs)
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
                ToolbarItem(placement: .secondaryAction) {
                    EditButton()
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Couldn’t save clubs", isPresented: $showingSaveError) {
            Button("OK") {
                saveErrorMessage = nil
                showingSaveError = false
            }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func addClub() {
        let name = newClubName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        var list = profile.clubsList
        if !list.contains(name) {
            list.append(name)
            profile.clubsList = list
            save()
        }
        newClubName = ""
    }

    private func deleteClubs(at offsets: IndexSet) {
        var list = profile.clubsList
        list.remove(atOffsets: offsets)
        profile.clubsList = list
        save()
    }

    private func moveClubs(from source: IndexSet, to destination: Int) {
        var list = profile.clubsList
        list.move(fromOffsets: source, toOffset: destination)
        profile.clubsList = list
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = String(describing: error)
            showingSaveError = true
        }
    }
}
