//
//  TechResourcesView.swift
//  BetterEDU Resources
//
//  Created by Connor Ott on 3/10/25.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct TechResourcesView: View {
    @State private var searchText = ""
    @State private var techResources: [ResourceItem] = [] // Dynamic resources fetched from Firestore
    @State private var userState: String = "ALL"        // User's selected state
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode // For custom back navigation
    @EnvironmentObject var tabViewModel: TabViewModel
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
                
                LocationDropdown(userState: $userState)
                    .padding(.trailing)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Title
            Text("Tech Resources")
                .font(.custom("Impact", size: 30))
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
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top,
                           50)
                        .tint(.white)
                } else {
                    LazyVStack(spacing: 16) {
                        if filteredResources.isEmpty {
                            VStack(spacing: 12) {
                                Text("No technology resources found in \(userState).")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                if userState != "ALL" {
                                    Button(action: {
                                        userState = "ALL"
                                        fetchTechResources()
                                    }) {
                                        Text("Show All States")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(Color(hex: "5a0ef6"))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(filteredResources) { resource in
                                ResourceCardView(resource: resource)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(.top, 12)
                }
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
            // Add notification observer
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshUserLocation"),
                object: nil,
                queue: .main
            ) { _ in
                loadUserData()
            }
            
            loadUserData()
            fetchTechResources()
        }
        .onChange(of: tabViewModel.shouldRefreshResources) { _ in
            fetchTechResources()
        }
    }

    // Fetch tech resources from Firestore
    private func fetchTechResources() {
        isLoading = true
        
        let query = db.collection("resourcesApp")
            .whereField("Resource Type", isEqualTo: "tech")
        
        query.getDocuments { querySnapshot, error in
            isLoading = false
            
            if let error = error {
                print("Error fetching tech resources: \(error)")
            } else {
                guard let documents = querySnapshot?.documents else { return }
                self.techResources = documents.compactMap { document in
                    try? document.data(as: ResourceItem.self)
                }
                
                print("Fetched \(self.techResources.count) tech resources")
                print("Current user state: \(self.userState)")
                
                // Print all unique states for debugging
                let states = Set(self.techResources.map { $0.state })
                print("Available states: \(states)")
            }
        }
    }

    // Filter resources based on search text and state
    private var filteredResources: [ResourceItem] {
        techResources.filter { resource in
            let matchesSearch = searchText.isEmpty || 
                                resource.title.lowercased().contains(searchText.lowercased())
                               
            let matchesState = userState == "ALL" || 
                               resource.state == "ALL" || 
                               resource.state == userState
                              
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
            
            if let document = document, document.exists {
                if let state = document.data()?["state"] as? String {
                    DispatchQueue.main.async {
                        self.userState = state
                        print("User state set from 'state' field: \(state)")
                        self.fetchTechResources() // Reload resources with new state
                    }
                } else if let location = document.data()?["location"] as? String {
                    DispatchQueue.main.async {
                        // Convert state name to code
                        switch location {
                            case "Arizona": self.userState = "AZ"
                            case "California": self.userState = "CA"
                            default: self.userState = "ALL"
                        }
                        print("User state set from 'location' field: \(self.userState)")
                        self.fetchTechResources() // Reload resources with new state
                    }
                }
            }
        }
    }
}


struct TechResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        TechResourcesView()
    }
}
