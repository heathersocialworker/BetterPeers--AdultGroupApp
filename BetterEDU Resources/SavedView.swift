import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SavedView: View {
    // State to manage the list of saved resources (could be populated dynamically)
    @State private var savedResources: [Resource] = [
        Resource(imageName: "financial_resources", title: "Financial Resources", subtitle: "Saved"),
        Resource(imageName: "educational_resources", title: "Educational Resources", subtitle: "Saved"),
        Resource(imageName: "mental_health_resources", title: "Mental Health Resources", subtitle: "Saved")
    ]
    
    // Navigation states for bottom nav bar
    @State private var isShowingHomePage = false
    @State private var isShowingResources = false
    @State private var isShowingSaved = false
    @State private var isShowingFeedback = false
    @State private var profileImage: UIImage? = nil // State to store the profile image
    
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(hex: "251db4").ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header with profile picture on the left
                    HStack {
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
                                    .foregroundColor(.white)
                                    .padding(.leading)
                            }
                        }
                        Spacer()
                    }

                    // Title
                    Text("My saved resources")
                        .font(.custom("Impact", size: 28))
                        .foregroundColor(.white)
                        .padding()

                    // Scrollable grid of saved resources
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(savedResources) { resource in
                                ResourceView(resource: resource)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Bottom Navigation Bar
                    HStack {
                        Spacer()
                        navBarButton(icon: "house", label: "Home") {
                            if !isShowingHomePage {
                                isShowingHomePage = true
                            }
                        }
                        .fullScreenCover(isPresented: $isShowingHomePage) {
                            HomePageView()
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
                            // Do nothing if already on the Saved tab
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
            }
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

// Resource model conforming to Identifiable for dynamic lists
struct Resource: Identifiable {
    let id = UUID() // Unique ID for each resource
    let imageName: String
    let title: String
    let subtitle: String
}

// View for individual saved resources
struct ResourceView: View {
    let resource: Resource

    var body: some View {
        VStack {
            Image(resource.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .cornerRadius(10)

            Text(resource.title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 5)

            Text(resource.subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    SavedView()
}

