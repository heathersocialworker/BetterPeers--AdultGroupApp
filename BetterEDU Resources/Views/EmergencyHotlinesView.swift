import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct EmergencyHotlinesView: View {
    @State private var searchText = ""
    @State private var emergencyResources: [ResourceItem] = [] // Dynamic resources fetched from Firestore
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
            Text("Emergency Hotlines")
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
                        .padding(.top, 50)
                        .tint(.white)
                } else {
                    LazyVStack(spacing: 16) {
                        if filteredResources.isEmpty {
                            VStack(spacing: 12) {
                                Text("No emergency hotlines found in \(userState).")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                if userState != "ALL" {
                                    Button(action: {
                                        userState = "ALL"
                                        fetchEmergencyResources()
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
                                ResourceCard(resource: resource)
                                    .padding(.horizontal)
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
            loadUserData()
            fetchEmergencyResources()
        }
        .onChange(of: tabViewModel.shouldRefreshResources) { _ in
            fetchEmergencyResources()
        }
    }

    // Fetch emergency resources from Firestore
    private func fetchEmergencyResources() {
        isLoading = true
        
        let query = db.collection("resourcesApp")
            .whereField("Resource Type", isEqualTo: "emergency")
        
        query.getDocuments { querySnapshot, error in
            isLoading = false
            
            if let error = error {
                print("Error fetching emergency resources: \(error)")
            } else {
                guard let documents = querySnapshot?.documents else { return }
                self.emergencyResources = documents.compactMap { document in
                    try? document.data(as: ResourceItem.self)
                }
                
                print("Fetched \(self.emergencyResources.count) emergency resources")
                print("Current user state: \(self.userState)")
                
                // Print all unique states for debugging
                let states = Set(self.emergencyResources.map { $0.state })
                print("Available states: \(states)")
            }
        }
    }

    // Filter resources based on search text and state
    private var filteredResources: [ResourceItem] {
        emergencyResources.filter { resource in
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
                        self.fetchEmergencyResources() // Reload resources with new state
                    }
                } else if let location = document.data()?["location"] as? String {
                    // Try the location field as fallback (for backward compatibility)
                    DispatchQueue.main.async {
                        // Convert state name to abbreviation if needed
                        let stateCode = self.getStateCode(from: location)
                        self.userState = stateCode
                        print("User state set from 'location' field: \(stateCode)")
                        self.fetchEmergencyResources() // Reload resources with new state
                    }
                }
            }
        }
    }
    
    // Convert full state name to abbreviation if needed
    private func getStateCode(from stateName: String) -> String {
        let stateMap = [
            "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
            "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
            "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
            "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
            "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
            "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
            "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
            "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
            "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
            "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
            "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
            "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
            "Wisconsin": "WI", "Wyoming": "WY"
        ]
        
        return stateMap[stateName] ?? stateName
    }
}

struct EmergencyHotlinesView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyHotlinesView()
    }
}
