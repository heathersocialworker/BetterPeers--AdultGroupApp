import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// Define ResourceItem model with accurate Firestore field mappings
struct ResourceItem: Identifiable, Codable {
    @DocumentID var id: String?         // Firebase Document ID
    var title: String                   // Resource Title
    var phone_number: String?           // Optional: Resource Phone Number
    var website: String?                // Optional: Resource Website URL
    var resourceType: String?           // Optional: Resource Type (e.g., "self care", "financial")
    var state: String?                  // Optional: State (e.g., "AZ", "CA", "ALL")
    var email: String?                  // Optional: Resource Email
    var description: String?            // Optional: Resource Description

    enum CodingKeys: String, CodingKey {
        case id                         // Maps to Firestore document ID
        case title                      // Matches "title" in Firestore
        case phone_number = "phone number" // Matches "phone number" in Firestore
        case website                    // Matches "website" in Firestore
        case resourceType = "Resource Type" // Matches "Resource Type" in Firestore
        case state                      // Matches "state" in Firestore
        case email                      // Matches "email" in Firestore
        case description               // Matches "description" in Firestore
    }
}

struct ResourcesAppView: View {
    @State private var resources: [ResourceItem] = []   // State array for resources
    @State private var searchText: String = ""          // State for the search text
    @State private var selectedFilter: String = "All"   // Default filter for resources
    @State private var availableFilters: [String] = ["All"] // Filters from Firebase
    @State private var userState: String = "ALL"        // User's selected state
    @StateObject private var imageLoader = ProfileImageLoader.shared
    @EnvironmentObject private var tabViewModel: TabViewModel // Access tab view model
    private let db = Firestore.firestore()
    
    // Grid layout columns based on device
    private var gridColumns: [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ]
        } else {
            return [GridItem(.flexible())]
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Header with profile icon
                HStack {
                    NavigationLink(destination: ProfileView().navigationBarHidden(true)) {
                        if let image = imageLoader.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 35, 
                                       height: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 35)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 4)
                                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 35, 
                                       height: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 35)
                                .foregroundColor(.white)
                                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                        }
                    }
                    Spacer()
                }
                .padding(.top)
                
                // Title
                Text("Resources")
                    .font(.custom("Lobster1.4", size: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 60))
                    .foregroundColor(.white)
                    .padding(.top, -1)
                    .padding(.bottom, -10)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Search and Filter Section
                HStack {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search resources...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.black)
                            .tint(.blue)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    // Filter Menu
                    Menu {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(availableFilters, id: \.self) { filter in
                                Text(filter).tag(filter)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedFilter)
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 14))
                                .foregroundColor(.white)
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 12 : 10))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                .padding(.top, 10)

                // Display filtered resources
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16) {
                        if filteredResources.isEmpty {
                            Text("No resources found.")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .gridCellColumns(gridColumns.count)
                        } else {
                            ForEach(filteredResources) { resource in
                                ResourceCardView(resource: resource)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                    .padding(.top, 12)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )

            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Load profile image
            if let uid = Auth.auth().currentUser?.uid {
                ProfileImageLoader.shared.loadProfileImage(forUID: uid)
            }
            loadUserData()
            fetchResources()
            
            // Trigger a refresh when view appears
            tabViewModel.refreshResources()
        }
        .onChange(of: tabViewModel.shouldRefreshResources) { shouldRefresh in
            if shouldRefresh {
                print("Refreshing resources due to tab selection")
                loadUserData()
                fetchResources()
            }
        }
    }

    // Fetch resources from Firestore
    private func fetchResources() {
        db.collection("resourcesApp")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching documents: \(error)")
                } else {
                    guard let documents = querySnapshot?.documents else {
                        print("No documents found in resourcesApp.")
                        return
                    }
                    
                    print("Found \(documents.count) resources in Firestore")
                    
                    // Track successful and failed decodings
                    var successCount = 0
                    var failureCount = 0
                    
                    let fetchedResources = documents.compactMap { document in
                        do {
                            let resource = try document.data(as: ResourceItem.self)
                            successCount += 1
                            return resource
                        } catch {
                            failureCount += 1
                            print("Error decoding document \(document.documentID): \(error.localizedDescription)")
                            print("Document data: \(document.data())")
                            return nil
                        }
                    }
                    
                    print("Successfully decoded \(successCount) resources, failed to decode \(failureCount) resources")
                    
                    DispatchQueue.main.async {
                        self.resources = fetchedResources
                        
                        // Check for missing required fields
                        for (index, resource) in self.resources.enumerated() {
                            if resource.resourceType == nil {
                                print("Warning: Resource at index \(index) (title: \(resource.title)) has nil resourceType")
                            }
                            if resource.state == nil {
                                print("Warning: Resource at index \(index) (title: \(resource.title)) has nil state")
                            }
                        }
                        
                        updateAvailableFilters()
                    }
                }
            }
    }

    // Update available filters based on resources
    private func updateAvailableFilters() {
        // Create a set to hold all unique resource types
        var typeSet = Set<String>()
        
        // Process each resource
        for resource in resources {
            if let resourceTypeString = resource.resourceType {
                // Check if this is a comma-separated list of types
                if resourceTypeString.contains(",") {
                    // Split by comma and add each type individually
                    let types = resourceTypeString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    types.forEach { typeSet.insert($0) }
                } else {
                    // Add the single type
                    typeSet.insert(resourceTypeString.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        // Convert to sorted array with "All" at the beginning
        availableFilters = ["All"] + Array(typeSet).sorted()
        
        // Debug print the available filters
        print("Available filters: \(availableFilters)")
    }

    // Filter resources based on search and filters
    private var filteredResources: [ResourceItem] {
        resources.filter { resource in
            // For "All" filter, include resources regardless of resource type
            // Otherwise check if resource type contains the selected filter (case insensitive)
            let matchesFilter = selectedFilter == "All" || 
                resource.resourceType?.lowercased().contains(selectedFilter.lowercased()) == true
            
            // Check if resource title contains search text (case insensitive)
            let matchesSearch = searchText.isEmpty || 
                resource.title.lowercased().contains(searchText.lowercased())
            
            // Check if resource state is ALL, matches user state, or state is missing
            let matchesState = userState == "ALL" || resource.state == nil ||
                resource.state == "ALL" || resource.state == userState
            
            // For debugging in console
            if selectedFilter == "All" && !matchesState {
                print("Resource filtered out due to state mismatch: \(resource.title) - State: \(resource.state ?? "nil")")
            }
            
            return matchesFilter && matchesSearch && matchesState
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
                    self.userState = state == "Arizona" ? "AZ" : state == "California" ? "CA" : "ALL"
                }
            }
        }
    }
}

struct ResourcesAppView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesAppView()
    }
}
