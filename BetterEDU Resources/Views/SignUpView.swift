import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String?
    @State private var isShowingError = false
    @State private var isSignedUp = false
    @State private var keyboardHeight: CGFloat = 0
    @Environment(\.horizontalSizeClass) var sizeClass

    private let db = Firestore.firestore()

    // Custom text field modifier
    private func customTextField(_ text: String, binding: Binding<String>) -> some View {
        Group {
            TextField("", text: binding)
        }
        .padding()
        .foregroundColor(.black)
        .background(Color.white.opacity(0.9))
        .cornerRadius(25)
        .overlay(
            Text(text)
                .foregroundColor(Color.black.opacity(0.6))
                .padding(.leading, 16)
                .opacity(binding.wrappedValue.isEmpty ? 1 : 0),
            alignment: .leading
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: sizeClass == .regular ? 30 : 20) {
                            Image("BetterLogo2")
                                .resizable()
                                .scaledToFit()
                                .frame(height: sizeClass == .regular ? 300 : 200)
                                .padding(.top, sizeClass == .regular ? 40 : 20)

                            Text("Create Your Account")
                                .font(.custom("Impact", size: sizeClass == .regular ? 30 : 22))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            // Form fields
                            formFields()

                            // Error message
                            if let errorMessage = errorMessage, isShowingError {
                                Text(errorMessage)
                                    .font(.system(size: 16, weight: .medium))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(10)
                                    .padding(.horizontal, sizeClass == .regular ? 24 : 16)
                                    .frame(maxWidth: sizeClass == .regular ? 700 : 350)
                                    .transition(.opacity)
                            }

                            // Action buttons
                            actionButtons()

                            // Sign-in link
                            HStack {
                                Text("Already have an account?")
                                    .foregroundColor(.white)
                                NavigationLink(destination: LoginView()) {
                                    Text("Sign In")
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.vertical, sizeClass == .regular ? 30 : 15)
                        }
                        .padding(.horizontal, sizeClass == .regular ? 40 : 16)
                        .frame(maxWidth: sizeClass == .regular ? 700 : 600)
                        .padding(.bottom, keyboardHeight + 40)
                        .animation(.easeOut(duration: 0.3), value: keyboardHeight)
                    }

                    Spacer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear { addKeyboardObservers() }
        .onDisappear { removeKeyboardObservers() }
        .fullScreenCover(isPresented: $isSignedUp) {
            HomePageView()
        }
    }

    // MARK: - Form Fields
    @ViewBuilder
    private func formFields() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldLabel("Name")
            customTextField("Name", binding: $name)
                .autocapitalization(.words)

            fieldLabel("Email")
            customTextField("Email", binding: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            fieldLabel("Password")
            ZStack(alignment: .trailing) {
                if isPasswordVisible {
                    customTextField("Password", binding: $password)
                } else {
                    SecureField("", text: $password)
                        .padding()
                        .foregroundColor(.black)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(25)
                        .overlay(
                            Text("Password")
                                .foregroundColor(Color.black.opacity(0.6))
                                .padding(.leading, 16)
                                .opacity(password.isEmpty ? 1 : 0),
                            alignment: .leading
                        )
                }
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .foregroundColor(.black)
                        .padding(.trailing, 16)
                }
            }
        }
        .padding(.horizontal, sizeClass == .regular ? 24 : 16)
        .frame(maxWidth: sizeClass == .regular ? 700 : 350)
    }

    // MARK: - Action Buttons
    @ViewBuilder
    private func actionButtons() -> some View {
        VStack(spacing: 12) {
            Button(action: signUpUser) {
                Text("Sign Up")
                    .font(.custom("Impact", size: sizeClass == .regular ? 26 : 22))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "5a0ef6"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: sizeClass == .regular ? 700 : 350)
        .padding(.horizontal, sizeClass == .regular ? 24 : 16)
    }

    // MARK: - Helpers
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("Impact", size: sizeClass == .regular ? 20 : 18))
            .foregroundColor(.white)
    }

    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = 0
        }
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func signUpUser() {
        // Clear any previous error
        errorMessage = nil
        isShowingError = false
        
        // Input validation
        if name.isEmpty && email.isEmpty && password.isEmpty {
            errorMessage = "Please fill in all fields"
            isShowingError = true
            return
        } else if name.isEmpty {
            errorMessage = "Please enter your name"
            isShowingError = true
            return
        } else if email.isEmpty {
            errorMessage = "Please enter your email"
            isShowingError = true
            return
        } else if password.isEmpty {
            errorMessage = "Please enter your password"
            isShowingError = true
            return
        }
        
        // Basic email format validation
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            isShowingError = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                handleAuthError(error)
            } else if let user = authResult?.user {
                saveUserData(uid: user.uid)
            }
        }
    }

    private func saveUserData(uid: String) {
        let userData: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": email
        ]

        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                self.errorMessage = "Error saving user data: \(error.localizedDescription)"
                self.isShowingError = true
            } else {
                self.isSignedUp = true
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: Error) {
        let authError = error as NSError
        
        // Convert Firebase error codes to user-friendly messages
        switch authError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            errorMessage = "The email address is not valid."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            errorMessage = "This email is already in use with another account."
        case AuthErrorCode.weakPassword.rawValue:
            errorMessage = "The password is too weak. Please use a stronger password."
        case AuthErrorCode.networkError.rawValue:
            errorMessage = "Network error. Please check your connection and try again."
        default:
            errorMessage = "Sign up failed: \(error.localizedDescription)"
        }
        
        isShowingError = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}

