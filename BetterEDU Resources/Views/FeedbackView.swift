import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

struct FeedbackView: View {
    @State private var feedbackText: String = ""
    @StateObject private var imageLoader = ProfileImageLoader.shared
    @State private var userName: String = "[Name]"
    @State private var showSubmissionAlert = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var emailText: String = ""
    @FocusState private var isFeedbackFocused: Bool
    @FocusState private var isEmailFocused: Bool

    private let db = Firestore.firestore()
    
    // Device-specific sizing
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var spacing: CGFloat {
        isIPad ? 32 : 16  // Reduced spacing for iPhone
    }
    
    private var horizontalPadding: CGFloat {
        isIPad ? 40 : 20
    }
    
    private var profileImageSize: CGFloat {
        isIPad ? 60 : 40  // Slightly larger profile image for iPhone
    }
    
    private var titleFontSize: CGFloat {
        isIPad ? 32 : 20  // Slightly smaller title for iPhone
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
            ZStack {
                    // Background image fills screen
                Image("background")
                    .resizable()
                        .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                    // Dismiss keyboard on tap
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isFeedbackFocused = false
                            isEmailFocused = false
                        }

                    // Main content
                    VStack(spacing: spacing) {
                        // Top safe area spacing
                        Color.clear.frame(height: isIPad ? 40 : 20)
                        
                        // Content container
                        VStack(alignment: .leading, spacing: spacing) {
                            // Profile icon
                            HStack {
                                NavigationLink(destination: ProfileView().navigationBarHidden(true)) {
                                    if let image = imageLoader.profileImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .frame(width: profileImageSize, height: profileImageSize)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                            .shadow(radius: 4)
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: profileImageSize, height: profileImageSize)
                                            .foregroundColor(.white)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, horizontalPadding)

                            // Welcome text
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your thoughts matter to us,")
                                    .font(.custom("tan-nimbus", size: isIPad ? 45 : 22))
                                    .foregroundColor(.white)
                                Text(userName)
                                    .font(.custom("tan-nimbus", size: isIPad ? 45 : 32))
                                    .foregroundColor(.white)
                                Text("Let us know how we")
                                    .font(.custom("tan-nimbus", size: isIPad ? 45 : 26))
                                    .foregroundColor(.white)
                                Text("can improve.")
                                    .font(.custom("tan-nimbus", size: isIPad ? 45 : 26))
                                    .foregroundColor(.white)
                            }
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, horizontalPadding)

                            Spacer()
                                .frame(height: isIPad ? spacing : 8)

                            // Email field
                            ZStack {
                                // Glassmorphic background
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                    RoundedRectangle(cornerRadius: 16)
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
                                                lineWidth: 1
                                            )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(hex: "#5a0ef6").opacity(0.1),
                                                        Color(hex: "#7849fd").opacity(0.05)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: Color.white.opacity(0.2), radius: 2, x: -1, y: -1)
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 2)

                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.system(size: isIPad ? 20 : 16))
                                    
                                    TextField("Enter your email", text: $emailText)
                                        .focused($isEmailFocused)
                                        .foregroundColor(.white)
                                        .font(.system(size: isIPad ? 18 : 16))
                                        .tint(.white)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                                .padding(.horizontal, 16)
                            }
                            .frame(width: isIPad ? geometry.size.width * 0.8 : min(geometry.size.width * 0.85, 300))
                            .frame(height: isIPad ? 60 : 50)
                            .padding(.leading, horizontalPadding)
                            .padding(.top, isIPad ? spacing : 8)

                            Spacer()
                                .frame(height: isIPad ? spacing : 8)

                            // Feedback text editor
                            ZStack {
                                // Glassmorphic background
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
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
                                                lineWidth: 1
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(hex: "#5a0ef6").opacity(0.1),
                                                        Color(hex: "#7849fd").opacity(0.05)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: Color.white.opacity(0.2), radius: 2, x: -1, y: -1)
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 2)

                                TextEditor(text: $feedbackText)
                                    .focused($isFeedbackFocused)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .foregroundColor(.white)
                                    .tint(Color(hex: "#5a0ef6"))
                                    .font(.system(size: isIPad ? 18 : 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            .frame(width: isIPad ? geometry.size.width * 0.8 : min(geometry.size.width * 0.85, 300))
                            .frame(height: isIPad ? geometry.size.height * 0.3 : min(geometry.size.height * 0.35, 200))
                            .padding(.leading, horizontalPadding)
                            .padding(.top, isIPad ? spacing : 8)

                            Spacer()
                                .frame(height: isIPad ? spacing : 8)

                            // Submit button
                            Button {
                                isFeedbackFocused = false
                                submitFeedback()
                            } label: {
                            Text("Submit Feedback")
                                    .font(.system(size: isIPad ? 22 : 17, weight: .bold))
                                .foregroundColor(.white)
                                    .padding(.vertical, isIPad ? 20 : 14)
                                    .frame(width: isIPad ? geometry.size.width * 0.4 : min(geometry.size.width * 0.5, 200))
                                .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "#5a0ef6"), Color(hex: "#7849fd")]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                )
                                .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }
                            .padding(.leading, horizontalPadding)
                            //.padding(.top, isIPad ? spacing : 12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .ignoresSafeArea(.keyboard)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if let uid = Auth.auth().currentUser?.uid {
                ProfileImageLoader.shared.loadProfileImage(forUID: uid)
            }
            loadUserName()
            setupKeyboardObservers()
            emailText = Auth.auth().currentUser?.email ?? ""
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .alert("Thank You!", isPresented: $showSubmissionAlert) {
            Button("OK", role: .cancel) {
                // Clear the fields after submission
                feedbackText = ""
                emailText = Auth.auth().currentUser?.email ?? ""
            }
        } message: {
            Text("Your feedback has been submitted successfully. We appreciate your input!")
        }
    }

    // MARK: - Keyboard
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - User Name
    private func loadUserName() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Check if user is anonymous (guest)
        if Auth.auth().currentUser?.isAnonymous == true {
            DispatchQueue.main.async {
                self.userName = "Guest"
            }
            return
        }
        
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error loading user name: \(error.localizedDescription)")
                return
            }
            if let doc = document, doc.exists,
               let name = doc.data()?["name"] as? String {
                DispatchQueue.main.async {
                    self.userName = name
                }
            }
        }
    }

    // MARK: - Submit Feedback
    private func submitFeedback() {
        guard let uid = Auth.auth().currentUser?.uid,
              !emailText.isEmpty else { return }
        
        let feedbackData: [String: Any] = [
            "userId": uid,
            "userEmail": emailText,
            "feedbackText": feedbackText,
            "timestamp": Timestamp()
        ]
        
        db.collection("feedback").addDocument(data: feedbackData) { error in
            if let error = error {
                print("Error submitting feedback: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.showSubmissionAlert = true
                }
            }
        }
    }
}


#Preview {
    FeedbackView()
}
