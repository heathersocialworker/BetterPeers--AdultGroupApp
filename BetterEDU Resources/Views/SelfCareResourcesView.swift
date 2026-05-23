//
//  SelfCareResourcesView.swift
//  BetterEDU Resources
//
//  Created by Nick Arana on 11/5/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SelfCareResourcesView: View {
    @State private var searchText = ""
    @State private var selfCareResources: [ResourceItem] = [] // Dynamic resources fetched from Firestore
    @State private var userState: String = "ALL"        // User's selected state
    @Environment(\.presentationMode) var presentationMode // For custom back navigation
    @EnvironmentObject var tabViewModel: TabViewModel // Add TabViewModel environment object
    private let db = Firestore.firestore()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom header with back button
            HStack {
                Button(action: {
                    // Go back to previous screen
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                // Location Dropdown
                LocationDropdown(userState: $userState)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Title
            Text("Self-Care Resources")
                .font(.custom("Impact", size: 35))
                .foregroundColor(Color(hex: "#FFFFFF"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)

            // Search Bar
            TextField("Search Resources", text: $searchText)
                .padding()
                .foregroundColor(.black)
                .background(Color.white)
                .tint(.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 16)

            // Resource List
            ScrollView {
                LazyVStack(spacing: 16) {
                    if filteredResources.isEmpty {
                        Text("No resources found.")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(filteredResources) { resource in
                            ResourceCard(resource: resource)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(.bottom)
        .background(
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
        .navigationBarHidden(true) // Hide the navigation bar
        .onAppear {
            loadUserData()
            fetchSelfCareResources()
            tabViewModel.refreshResources() // Trigger a refresh when view appears
        }
        .onChange(of: tabViewModel.shouldRefreshResources) { shouldRefresh in
            if shouldRefresh {
                print("Refreshing self-care resources due to tab selection")
                loadUserData()
                fetchSelfCareResources()
            }
        }
    }

    // Fetch self-care resources from Firestore
    private func fetchSelfCareResources() {
        db.collection("resourcesApp")
            .whereField("Resource Type", isEqualTo: "self care")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching self-care resources: \(error)")
                } else {
                    guard let documents = querySnapshot?.documents else { return }
                    self.selfCareResources = documents.compactMap { document in
                        try? document.data(as: ResourceItem.self)
                    }
                }
            }
    }

    // Filter resources based on search text and state
    private var filteredResources: [ResourceItem] {
        selfCareResources.filter { resource in
            let matchesSearch = searchText.isEmpty || resource.title.lowercased().contains(searchText.lowercased())
            let matchesState = userState == "ALL" || resource.state == "ALL" || resource.state == userState
            return matchesSearch && matchesState
        }
    }

    // Load user's profile data from Firestore
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error loading user data: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists,
               let state = document.data()?["location"] as? String {
                // Convert state name to abbreviation
                DispatchQueue.main.async {
                    // Convert state name to abbreviation
                    switch state {
                        case "Arizona": self.userState = "AZ"
                        case "California": self.userState = "CA"
                        case "Nevada": self.userState = "NV"
                        default: self.userState = "ALL"
                    }
                }
            }
        }
    }
}


struct SelfCareResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SelfCareResourcesView()
    }
}
