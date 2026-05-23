import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ResourcesAppView: View {
    @State private var documents: [String] = []   // State array for resources
    @State private var searchText: String = ""    // State for the search text
    private var db = Firestore.firestore()
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var isShowingHomePage = false
    @State private var isShowingResources = false
    @State private var isShowingSaved = false
    @State private var isShowingFeedback = false
    @State private var profileImage: UIImage? = nil // State to store the profile image

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Header with profile icon
                HStack {
                    NavigationLink(destination: ProfileView()) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 4)
                                .padding(.leading)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.white)
                                .padding(.leading)
                        }
                    }
                    Spacer()
                }
                .padding(.top)
                .onAppear(perform: loadProfileImage) // Load profile image on appear
                
                // Title
                Text("Resources")
                    .font(.custom("Impact", size: 48))
                    .foregroundColor(.white)
                    .padding(.top, 20)  // Space from the top of the screen
                    .frame(maxWidth: .infinity, alignment: .center) // Center align the title

                // Search Bar below the title
                TextField("Search Resources...", text: $searchText)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 10) // Space between title and search bar

                Spacer()
                
                // Show fetched Firestore documents or a loading message
                if documents.isEmpty {
                    Text("Resources: \(firestoreManager.resources)")
                        .font(.custom("Impact", size: 32))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    List(documents, id: \.self) { document in
                        Text(document)
                            .foregroundColor(.white)
                    }
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
                        // Do nothing if already on Resources page
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
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Expand to fill the screen
            .background(Color(hex: "251db4"))  // Set the background color using the hex extension
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await fetchResources()
                }
            }
        }
    }
    
    // Function to fetch resources from Firebase
    private func fetchResources() async {
        let db = Firestore.firestore()
        do {
            let querySnapshot = try await db.collection("resourcesApp").getDocuments()
            // Map documents to a list of strings representing each document’s ID and data
            documents = querySnapshot.documents.map { "\($0.documentID) => \($0.data())" }
        } catch {
            print("Error getting documents: \(error)")
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

struct ResourcesAppView_Previews: PreviewProvider {
    static var previews: some View {
        ResourcesAppView()
            .environmentObject(FirestoreManager())
    }
}
