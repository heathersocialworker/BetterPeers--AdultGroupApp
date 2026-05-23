import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HomePageView: View {
    @State private var selectedTab = 0
    @State private var isShowingResources = false
    @State private var isShowingSaved = false
    @State private var isShowingFeedback = false
    @State private var profileImage: UIImage? = nil // State to store the profile image
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header Section with profile picture on the top left
                HStack {
                    // Navigation link for the profile icon with image
                    NavigationLink(destination: ProfileView()) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 4)
                                .padding(.leading)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .padding(.leading)
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                
                Text("BetterEDU Resources")
                    .font(.custom("Impact", size: 40))
                    .foregroundColor(Color(hex: "98b6f8")) // Custom color from palette
                    .aspectRatio(contentMode: .fit)
                    .padding(.top)
                
                Text("Mental Health Resources for Students")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Search Bar
                Spacer(minLength: 1)
                TextField("Search Resources", text: .constant(""))
                    .padding()
                    .background(Color(hex: "98b6f8"))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // HStack for FAQ and Saved tabs
                HStack {
                    // FAQ Tab
                    Button(action: {
                        selectedTab = 0 // Home tab
                    }) {
                        Text("FAQ")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "98b6f8"))
                            .foregroundColor(Color(hex: "251db4"))
                            .cornerRadius(10)
                    }
                    
                    // Saved Tab
                    Button(action: {
                        selectedTab = 1 // Saved tab
                    }) {
                        Text("Saved")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "98b6f8"))
                            .foregroundColor(Color(hex: "251db4"))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 1)
                
                // Scrollable Resource List
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Navigation to Financial Services
                        NavigationLink(destination: FinancialServicesView()) {
                            HStack {
                                Image(systemName: "building.columns.fill")
                                Text("Financial Services")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(hex: "251db4"))
                            .cornerRadius(10)
                        }
                        
                        // Navigation to Emergency Hotlines
                        NavigationLink(destination: EmergencyHotlinesView()) {
                            HStack {
                                Image(systemName: "phone.arrow.up.right.fill")
                                Text("Emergency Hotlines")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(hex: "251db4"))
                            .cornerRadius(10)
                        }
                        
                        // Navigation to Self-Care Resources
                        NavigationLink(destination: SelfCareResourcesView()) {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("Self-Care Resources")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(hex: "251db4"))
                            .cornerRadius(10)
                        }
                        
                        // Navigation to Academic Stress Support
                        NavigationLink(destination: AcademicStressView()) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Academic Stress Support")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(hex: "251db4"))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Bottom Navigation Bar
                HStack {
                    Spacer()
                    navBarButton(icon: "house", label: "Home") {
                        // Do nothing if already on Home
                    }
                    Spacer()
                    navBarButton(icon: "magnifyingglass", label: "Search") {
                        if !isShowingResources {
                            isShowingResources = true
                        }
                    }
                    .fullScreenCover(isPresented: $isShowingResources) {
                        ResourcesAppView()
                    }
                    Spacer()
                    navBarButton(icon: "heart.fill", label: "Saved") {
                        if !isShowingSaved {
                            isShowingSaved = true
                        }
                    }
                    .fullScreenCover(isPresented: $isShowingSaved) {
                        SavedView()
                    }
                    Spacer()
                    navBarButton(icon: "bubble.left.and.bubble.right", label: "Feedback") {
                        if !isShowingFeedback {
                            isShowingFeedback = true
                        }
                    }
                    .fullScreenCover(isPresented: $isShowingFeedback) {
                        FeedbackView()
                    }
                    Spacer()
                }
                .padding()
                .background(Color.black)
            }
            .background(Color(hex: "251db4").ignoresSafeArea()) // Background color from the mockup
            .onAppear(perform: loadProfileImage) // Load profile image on appear
        }
    }
    
    // Helper function for the bottom navigation buttons
    private func navBarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                Text(label).font(.footnote)
            }
            .foregroundColor(.white)
        }
    }
    
    // Function to load the user's profile image from Firestore
    private func loadProfileImage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error loading profile image URL: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists,
               let profileImageURLString = document.data()?["profileImageURL"] as? String,
               let url = URL(string: profileImageURLString) {
                
                fetchImage(from: url)
            }
        }
    }
    
    // Helper function to fetch an image from a URL
    private func fetchImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching profile image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = uiImage
                }
            }
        }.resume()
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
    }
}

// Custom extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
