import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct FeedbackView: View {
    @State private var feedbackText: String = "" // State variable to bind text input
    @State private var isShowingHomePage = false
    @State private var isShowingResources = false
    @State private var isShowingSaved = false
    @State private var isShowingFeedback = false
    @State private var profileImage: UIImage? = nil // State to store the profile image
    @State private var userName: String = "[Name]" // State to store the user's name
    @State private var showSubmissionAlert = false // State to show submission alert

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                // Header Section with Profile Icon
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
                .onAppear {
                    loadProfileImage()
                    loadUserName()
                } // Load profile image and user name on appear

                // Welcome Text
                Text("Your thoughts matter to us, \(userName). Let us know how we can improve.")
                    .font(.custom("Impact", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                // Text Editor for Feedback
                TextEditor(text: $feedbackText)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                // Submit Button
                Button(action: {
                    submitFeedback()
                }) {
                    Text("Submit Feedback")
                        .font(.custom("Impact", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color(hex: "#5a0ef6"), Color(hex: "#7849fd")]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .alert(isPresented: $showSubmissionAlert) {
                    Alert(title: Text("Thank you!"), message: Text("Your feedback has been submitted."), dismissButton: .default(Text("OK")))
                }

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
                        if !isShowingSaved {
                            isShowingSaved = true
                        }
                    }
                    .fullScreenCover(isPresented: $isShowingSaved) {
                        SavedView()
                    }
                    Spacer()
                    navBarButton(icon: "bubble.left.and.bubble.right", label: "Feedback") {
                        // Do nothing if already on the Feedback tab
                    }
                    Spacer()
                }
                .padding()
                .background(Color.black)
            }
            .background(Color(hex: "251db4").ignoresSafeArea()) // Background color from palette
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

    // Function to load the user's name from Firestore
    private func loadUserName() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error loading user name: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists,
               let name = document.data()?["name"] as? String {
                DispatchQueue.main.async {
                    self.userName = name
                }
            }
        }
    }

    // Function to submit feedback to Firestore
    private func submitFeedback() {
        guard let uid = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email else { return }
        
        let feedbackData: [String: Any] = [
            "userId": uid,
            "userEmail": email,
            "feedbackText": feedbackText,
            "timestamp": Timestamp()
        ]
        
        db.collection("feedback").addDocument(data: feedbackData) { error in
            if let error = error {
                print("Error submitting feedback: \(error.localizedDescription)")
            } else {
                self.feedbackText = "" // Clear feedback text after submission
                self.showSubmissionAlert = true // Show submission confirmation alert
            }
        }
    }
}

#Preview {
    FeedbackView()
}
