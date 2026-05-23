import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// HomePageView implementation starts here
struct HomePageView: View {
    @StateObject private var imageLoader = ProfileImageLoader.shared
    @State private var searchText: String = ""
    @State private var resources: [ResourceItem] = []
    @State private var discounts: [StudentDiscountItem] = [] // Add state for student discounts
    @State private var likedResources: Set<String> = [] // Tracks liked resource IDs locally
    @State private var hasScrolled = false
    @State private var userState: String = "ALL"        // User's selected state
    @State private var userName: String = ""            // Add userName state
    
    // Sheet presentation states for category pages
    @State private var showFinancialServicesSheet = false
    @State private var showEmergencyHotlinesSheet = false
    @State private var showSelfCareResourcesSheet = false
    @State private var showAcademicStressSheet = false
    @State private var showHousingResourcesSheet = false
    @State private var showFoodClothingResourcesSheet = false
    @State private var showTechResourcesSheet = false
    @State private var showHotlinesSheet = false         // New state for Hotlines sheet
    
    @EnvironmentObject var tabViewModel: TabViewModel
    private let db = Firestore.firestore()
    @State private var showGuestAlert = false
    @EnvironmentObject var authViewModel: AuthViewModel

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

    // Scroll Arrow View
    private var scrollArrow: some View {
        Button(action: {
            // Scroll to bottom
            withAnimation {
                hasScrolled = true
            }
        }) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#5a0ef6").opacity(0.8),
                                Color(hex: "#7849fd").opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                
                // Chevron icon
        Image(systemName: "chevron.down")
                    .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            }
            .opacity(hasScrolled ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: hasScrolled)
            .modifier(BounceAnimation())
        }
    }

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    VStack(spacing: 0) {  // Changed spacing to 0 for manual control
                        // Header Section
                        VStack(spacing: 16) {
                            // Header Section with profile picture
                            HStack {
                                ProfileImageView(size: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 40, showBorder: false)
                                    .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                                Spacer()
                            }
                            .padding([.horizontal, .top], UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)

                            // Title
                            Text("BetterResources")
                                .font(.custom("tan-nimbus", size: UIDevice.current.userInterfaceIdiom == .pad ? 55 : 39))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.top, -10)

                            // Welcome Message
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back, \(userName)!")
                                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 28 : 24, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Let's find the resources you need today.")
                                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 22 : 18))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                        }
                        .padding(.bottom, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        Color.black.opacity(0.4),
                                        Color.black.opacity(0.3),
                                        Color.black.opacity(0.2)
                                    ]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 30,
                                    style: .continuous
                                )
                            )
                            .edgesIgnoringSafeArea(.top)
                        )
                        
                        // Visual Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20)
                        
                        // Content Section
                        VStack(spacing: 24) {  // Increased spacing between elements
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search resources & discounts...", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.black)
                                    .tint(.blue)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                            .padding(.top, 20)  // Added top padding after divider

                            // Content Area
                            ScrollView {
                                GeometryReader { proxy in
                                    Color.clear.onChange(of: proxy.frame(in: .named("scroll")).minY) { value in
                                        withAnimation {
                                            hasScrolled = value < -10
                                        }
                                    }
                                }
                                .frame(height: 0)

                                if searchText.isEmpty {
                                    // Category Grid
                                    LazyVGrid(columns: gridColumns, spacing: 20) {
                                        Button(action: {
                                            tabViewModel.selectedTab = 3  // Switch to Student Discounts tab
                                        }) {
                                            categoryButton(icon: "tag.fill", title: "Student Discounts")
                                        }
                                        
                                        Button(action: {
                                            showHotlinesSheet = true
                                        }) {
                                            categoryButton(icon: "phone.fill", title: "Hotlines")
                                        }
                                        
                                        Button(action: {
                                            showFinancialServicesSheet = true
                                        }) {
                                            categoryButton(icon: "building.columns.fill", title: "Financial Services")
                                        }
                                        
                                        Button(action: {
                                            showEmergencyHotlinesSheet = true
                                        }) {
                                            categoryButton(icon: "phone.arrow.up.right.fill", title: "Emergency Hotlines")
                                        }
                                        
                                        Button(action: {
                                            showSelfCareResourcesSheet = true
                                        }) {
                                            categoryButton(icon: "heart.fill", title: "Self-Care Resources")
                                        }
                                        
                                        Button(action: {
                                            showAcademicStressSheet = true
                                        }) {
                                            categoryButton(icon: "book.fill", title: "Academic Support")
                                        }
                                        
                                        Button(action: {
                                            showHousingResourcesSheet = true
                                        }) {
                                            categoryButton(icon: "house.fill", title: "Housing & Shelter")
                                        }
                                        
                                        Button(action: {
                                            showFoodClothingResourcesSheet = true
                                        }) {
                                            categoryButton(icon: "fork.knife", title: "Food & Clothing")
                                        }
                                        
                                        Button(action: {
                                            showTechResourcesSheet = true
                                        }) {
                                            categoryButton(icon: "network", title: "Technology Resources")
                                        }
                                    }
                                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                                    .padding(.top, 12)
                                    .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 90 : 80)
                                } else {
                                    // Search Results
                                    LazyVGrid(columns: gridColumns, spacing: 20) {
                                        if filteredResources.isEmpty && filteredDiscounts.isEmpty {
                                            Text("No resources or discounts found.")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.top, 16)
                                                .gridCellColumns(gridColumns.count)
                                        } else {
                                            // Display resources
                                            ForEach(filteredResources) { resource in
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Text(resource.title)
                                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 17, weight: .bold))
                                                            .foregroundColor(.white)
                                                            .multilineTextAlignment(.leading)
                                                            .lineLimit(2)

                                                        if let phoneNumber = resource.phone_number {
                                                            Text("Phone: \(phoneNumber)")
                                                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 15))
                                                                .foregroundColor(.white.opacity(0.7))
                                                                .lineLimit(1)
                                                        }

                                                        if let website = resource.website, !website.isEmpty, let url = URL(string: website) {
                                                            Link("Visit Website", destination: url)
                                                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 15))
                                                                .foregroundColor(.blue)
                                                        } else {
                                                            Text("Website unavailable")
                                                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 15))
                                                                .foregroundColor(.gray)
                                                        }
                                                    }
                                                    Spacer()

                                                    Button(action: {
                                                        if Auth.auth().currentUser?.isAnonymous == true {
                                                            showGuestAlert = true
                                                        } else {
                                                            toggleSaveResource(resource: resource)
                                                        }
                                                    }) {
                                                        Image(systemName: likedResources.contains(resource.id ?? "") ? "heart.fill" : "heart")
                                                            .foregroundColor(likedResources.contains(resource.id ?? "") ? .red : .gray)
                                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20))
                                                    }
                                                }
                                                .padding(UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.black.opacity(0.4))
                                                .cornerRadius(12)
                                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                            }
                                            
                                            // Display discounts
                                            ForEach(filteredDiscounts) { discount in
                                                VStack(alignment: .leading, spacing: 12) {
                                                    HStack {
                                                        Text(discount.name)
                                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 17, weight: .bold))
                                                            .foregroundColor(.white)
                                                            .lineLimit(1)
                                                        
                                                        Spacer()
                                                        
                                                        Text(discount.category)
                                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 14 : 12))
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [Color(hex: "#5a0ef6").opacity(0.3), Color(hex: "#7849fd").opacity(0.3)]),
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                            .cornerRadius(12)
                                                    }
                                                    
                                                    HStack {
                                                        Image(systemName: "tag.fill")
                                                            .foregroundColor(.green)
                                                        Text(discount.discount)
                                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 15, weight: .semibold))
                                                            .foregroundColor(.green)
                                                    }
                                                    
                                                    Text(discount.description)
                                                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14))
                                                        .foregroundColor(.white.opacity(0.9))
                                                        .lineLimit(2)
                                                    
                                                    if let url = URL(string: discount.link) {
                                                        Link(destination: url) {
                                                            HStack {
                                                                Text("Get Discount")
                                                                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14, weight: .semibold))
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
                                                    }
                                                }
                                                .padding(UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12)
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    ZStack {
                                                        Color.black.opacity(0.4)
                                                        
                                                        // Glassmorphic effect
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(.ultraThinMaterial)
                                                            .opacity(0.3)
                                                        
                                                        // Gradient overlay
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color.black.opacity(0.6),
                                                                        Color.black.opacity(0.4)
                                                                    ]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                    }
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [
                                                                    Color.white.opacity(0.5),
                                                                    Color.white.opacity(0.2),
                                                                    Color.white.opacity(0.1)
                                                                ]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 0.5
                                                        )
                                                )
                                                .cornerRadius(12)
                                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                                    .padding(.top, 12)
                                    .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 90 : 80)
                                }
                            }
                            .coordinateSpace(name: "scroll")
                            .scrollDismissesKeyboard(.immediately)
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

                    // Scroll Arrow Overlay
                    VStack {
                        Spacer()
                        scrollArrow
                            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 120 : 100)
                    }
                }
                .onAppear {
                    if let uid = Auth.auth().currentUser?.uid {
                        ProfileImageLoader.shared.loadProfileImage(forUID: uid)
                    }
                    loadUserData()
                    fetchResources()
                    fetchDiscounts()
                    fetchLikedResources()
                    hasScrolled = false
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        // Sheet presentation for Financial Services
        .fullScreenCover(isPresented: $showFinancialServicesSheet) {
            FinancialServicesView()
        }
        // Sheet for Emergency Hotlines
        .fullScreenCover(isPresented: $showEmergencyHotlinesSheet) {
            EmergencyHotlinesView()
        }
        // Sheet for Self Care Resources
        .fullScreenCover(isPresented: $showSelfCareResourcesSheet) {
            SelfCareResourcesView()
        }
        // Sheet for Academic Stress
        .fullScreenCover(isPresented: $showAcademicStressSheet) {
            AcademicStressView()
        }
        // Sheet for Housing Resources
        .fullScreenCover(isPresented: $showHousingResourcesSheet) {
            HousingResourcesView()
        }
        // Sheet for Food & Clothing Resources
        .fullScreenCover(isPresented: $showFoodClothingResourcesSheet) {
            FoodandClothingResourcesView()
        }
        // Sheet for Tech Resources
        .fullScreenCover(isPresented: $showTechResourcesSheet) {
            TechResourcesView()
        }
        // Hotlines Sheet
        .fullScreenCover(isPresented: $showHotlinesSheet) {
            HotlinesView()
        }
        .alert("Sign In Required", isPresented: $showGuestAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign In") {
                authViewModel.signOut() // This will navigate to login screen
            }
        } message: {
            Text("You need to create an account or sign in to save resources.")
        }
    }

    private func fetchResources() {
        db.collection("resourcesApp")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching resources: \(error.localizedDescription)")
                } else {
                    guard let documents = querySnapshot?.documents else { return }
                    self.resources = documents.compactMap { document in
                        try? document.data(as: ResourceItem.self)
                    }
                }
            }
    }
    
    // Add function to fetch student discounts
    private func fetchDiscounts() {
        db.collection("studentDisc")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching student discounts: \(error.localizedDescription)")
                } else {
                    guard let documents = querySnapshot?.documents else {
                        print("No documents found in studentDisc.")
                        return
                    }
                    
                    let fetchedDiscounts = documents.compactMap { document in
                        do {
                            return try document.data(as: StudentDiscountItem.self)
                        } catch {
                            print("Error decoding document \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                    DispatchQueue.main.async {
                        self.discounts = fetchedDiscounts
                    }
                }
            }
    }

    private func fetchLikedResources() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("savedResources")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching liked resources: \(error.localizedDescription)")
                } else {
                    let likedResourceIDs = querySnapshot?.documents.compactMap { $0.documentID } ?? []
                    DispatchQueue.main.async {
                        self.likedResources = Set(likedResourceIDs)
                    }
                }
            }
    }

    private var filteredResources: [ResourceItem] {
        resources.filter { resource in
            let matchesSearch = searchText.isEmpty || resource.title.lowercased().contains(searchText.lowercased())
            let matchesState = userState == "ALL" || resource.state == "ALL" || resource.state == userState
            return matchesSearch && matchesState
        }
    }
    
    // Add filtered discounts
    private var filteredDiscounts: [StudentDiscountItem] {
        discounts.filter { discount in
            let matchesSearch = searchText.isEmpty || 
                              discount.name.lowercased().contains(searchText.lowercased()) ||
                              discount.description.lowercased().contains(searchText.lowercased())
            return matchesSearch
        }
    }

    private func categoryButton(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 32 : 24))
            Text(title)
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 100 : 80)
        .background(Color.white)
        .foregroundColor(Color(hex: "#5a0ef6"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    private func toggleSaveResource(resource: ResourceItem) {
        guard let uid = Auth.auth().currentUser?.uid, let resourceID = resource.id else { return }

        let userRef = db.collection("users").document(uid)
        let resourceRef = userRef.collection("savedResources").document(resourceID)

        if likedResources.contains(resourceID) {
            // If the resource is already saved, remove it
            resourceRef.delete { error in
                if let error = error {
                    print("Error removing resource: \(error)")
                } else {
                    DispatchQueue.main.async {
                        likedResources.remove(resourceID)
                        // Trigger a refresh when a resource is unsaved
                        tabViewModel.refreshResourcesOnSave()
                    }
                }
            }
        } else {
            // If the resource is not saved, add it
            let resourceData: [String: Any] = [
                "id": resourceID,
                "title": resource.title,
                "phone_number": resource.phone_number ?? "",
                "website": resource.website ?? "",
                "resourceType": resource.resourceType ?? ""
            ]
            resourceRef.setData(resourceData) { error in
                if let error = error {
                    print("Error saving resource: \(error)")
                } else {
                    DispatchQueue.main.async {
                        likedResources.insert(resourceID)
                        // Trigger a refresh when a resource is saved
                        tabViewModel.refreshResourcesOnSave()
                    }
                }
            }
        }
    }

    // Load user's profile data from Firestore
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Check if user is anonymous (guest)
        if Auth.auth().currentUser?.isAnonymous == true {
            DispatchQueue.main.async {
                self.userName = "Guest"
                self.userState = "ALL"
            }
            return
        }

        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error loading user data: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                // Get user's state
                if let state = data?["location"] as? String {
                    DispatchQueue.main.async {
                        self.userState = state == "Arizona" ? "AZ" : state == "California" ? "CA" : "ALL"
                    }
                }
                // Get user's name
                if let name = data?["name"] as? String {
                    DispatchQueue.main.async {
                        self.userName = name
                    }
                }
            }
        }
    }
}

// Bounce Animation Modifier
struct BounceAnimation: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? -5 : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
    }
}

