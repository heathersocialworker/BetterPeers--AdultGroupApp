import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HotlinesView: View {
    @State private var searchText = ""
    @State private var hotlineResources: [ResourceItem] = [] // Dynamic resources fetched from Firestore
    @State private var userState: String = "ALL"        // User's selected state
    @Environment(\.presentationMode) var presentationMode // For custom back navigation
    @EnvironmentObject var authViewModel: AuthViewModel
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
            Text("Hotlines")
                .font(.custom("Impact", size: 35))
                .foregroundColor(Color(hex: "#FFFFFF"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search Hotlines", text: $searchText)
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 16)

            // Hotline List
            ScrollView {
                LazyVStack(spacing: 16) {
                    if filteredHotlines.isEmpty {
                        Text("No hotlines found.")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(filteredHotlines) { hotline in
                            HotlineCard(hotline: hotline)
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
            // Add notification observer
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshUserLocation"),
                object: nil,
                queue: .main
            ) { _ in
                loadUserData()
            }
            
            loadUserData()
            fetchHotlineResources()
            
            // Trigger a refresh when view appears
            tabViewModel.refreshResources()
        }
        .onChange(of: tabViewModel.shouldRefreshResources) { shouldRefresh in
            if shouldRefresh {
                print("Refreshing hotlines due to tab selection")
                fetchHotlineResources()
            }
        }
    }

    // Fetch resources that have phone numbers from Firestore
    private func fetchHotlineResources() {
        db.collection("resourcesApp")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching hotline resources: \(error)")
                } else {
                    guard let documents = querySnapshot?.documents else { return }
                    
                    // Filter resources to include only those with phone numbers
                    self.hotlineResources = documents.compactMap { document in
                        if let resource = try? document.data(as: ResourceItem.self),
                           let phoneNumber = resource.phone_number,
                           !phoneNumber.isEmpty {
                            return resource
                        }
                        return nil
                    }
                }
            }
    }

    // Filter hotlines based on search text and state
    private var filteredHotlines: [ResourceItem] {
        hotlineResources.filter { hotline in
            let matchesSearch = searchText.isEmpty || hotline.title.lowercased().contains(searchText.lowercased())
            let matchesState = userState == "ALL" || hotline.state == "ALL" || hotline.state == userState
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
                        self.fetchHotlineResources() // Reload resources with new state
                    }
                } else if let location = document.data()?["location"] as? String {
                    DispatchQueue.main.async {
                        // Convert state name to code
                        switch location {
                            case "Arizona": self.userState = "AZ"
                            case "California": self.userState = "CA"
                            case "Nevada": self.userState = "NV"
                            default: self.userState = "ALL"
                        }
                        print("User state set from 'location' field: \(self.userState)")
                        self.fetchHotlineResources() // Reload resources with new state
                    }
                }
            }
        }
    }
}

// Custom view for displaying hotlines
struct HotlineCard: View {
    let hotline: ResourceItem
    @State private var isLiked: Bool = false
    @State private var showGuestAlert = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tabViewModel: TabViewModel
    private let db = Firestore.firestore()
    
    // Parse phone numbers outside of the view body
    private var parsedPhoneNumbers: [String] {
        guard let phoneNumber = hotline.phone_number, !phoneNumber.isEmpty else {
            return []
        }
        
        let lowercased = phoneNumber.lowercased()
        var numbers: [String] = []
        
        // Check if this contains multiple numbers with different separators
        if lowercased.contains("or") {
            // Split by OR/or
            let orComponents = phoneNumber.components(separatedBy: "OR")
            for component in orComponents {
                let subComponents = component.components(separatedBy: "or")
                for subComponent in subComponents {
                    numbers.append(subComponent.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        } else if phoneNumber.contains(",") {
            // Split by comma
            let commaComponents = phoneNumber.components(separatedBy: ",")
            for component in commaComponents {
                numbers.append(component.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } else {
            // Just a single number
            numbers = [phoneNumber]
        }
        
        return numbers
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Hotline Title
            Text(hotline.title)
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            // Phone Numbers with Call Buttons
            if let phoneNumber = hotline.phone_number, !phoneNumber.isEmpty {
                VStack(spacing: 12) {
                    ForEach(parsedPhoneNumbers, id: \.self) { number in
                        // Check if this is a text message number
                        let isTextNumber = number.lowercased().contains("text")
                        
                        // Get just the digits for the URL
                        let formattedPhone = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                        
                        // Only create a link if we have digits
                        if !formattedPhone.isEmpty {
                            // Choose appropriate URL scheme based on whether it's for texting or calling
                            let urlScheme = isTextNumber ? "sms:" : "tel:"
                            
                            if let phoneURL = URL(string: "\(urlScheme)\(formattedPhone)") {
                                VStack(spacing: 8) {
                                    // Display the phone number prominently
                                    Text(number)
                                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 22 : 18))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    
                                    // Call/Text Button
                                    Link(destination: phoneURL) {
                                        HStack {
                                            Image(systemName: isTextNumber ? "message.fill" : "phone.fill")
                                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16))
                                            Text(isTextNumber ? "Text Now" : "Call Now")
                                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    isTextNumber ? Color.blue : Color(hex: "#5a0ef6"),
                                                    isTextNumber ? Color.blue.opacity(0.7) : Color(hex: "#7849fd")
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            
            // Bottom row with website (if available) and save button
            HStack {
                if let website = hotline.website, !website.isEmpty, let url = URL(string: website) {
                    // Website Button
                    Link(destination: url) {
                        HStack {
                            Text("Visit Website")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14, weight: .medium))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 14 : 12))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#5a0ef6"), Color(hex: "#7849fd")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                // Save Button
                Button(action: handleSaveResource) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20))
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
            }
        }
        .padding(UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#333333"), Color(hex: "#222222")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        .onAppear(perform: checkIfResourceIsSaved)
        .onChange(of: tabViewModel.shouldRefreshResources) { _ in
            // Refresh liked status when tabViewModel.shouldRefreshResources changes
            checkIfResourceIsSaved()
        }
        .alert("Sign In Required", isPresented: $showGuestAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign In") {
                // Sign out the guest user and this will trigger navigation to LoginView
                authViewModel.signOut()
            }
        } message: {
            Text("You need to create an account or sign in to save resources.")
        }
    }
    
    private func handleSaveResource() {
        if Auth.auth().currentUser?.isAnonymous == true {
            showGuestAlert = true
        } else {
            toggleSaveResource()
        }
    }

    // Check if the resource is saved
    private func checkIfResourceIsSaved() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid).collection("savedResources").document(hotline.id ?? "")

        userRef.getDocument { document, error in
            DispatchQueue.main.async {
                isLiked = document?.exists == true
            }
        }
    }

    // Toggle resource save
    private func toggleSaveResource() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let userRef = db.collection("users").document(uid)
        let resourceRef = userRef.collection("savedResources").document(hotline.id ?? "")

        if isLiked {
            resourceRef.delete { error in
                if error == nil {
                    DispatchQueue.main.async {
                        isLiked = false
                        // Trigger a refresh when a resource is unsaved
                        tabViewModel.refreshResourcesOnSave()
                    }
                }
            }
        } else {
            let resourceData: [String: Any] = [
                "id": hotline.id ?? "",
                "title": hotline.title,
                "phone_number": hotline.phone_number ?? "",
                "website": hotline.website ?? "",
                "resourceType": hotline.resourceType ?? "",
                "state": hotline.state ?? ""
            ]
            resourceRef.setData(resourceData) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        isLiked = true
                        // Trigger a refresh when a resource is saved
                        tabViewModel.refreshResourcesOnSave()
                    }
                }
            }
        }
    }
}

struct HotlinesView_Previews: PreviewProvider {
    static var previews: some View {
        HotlinesView()
    }
} 
