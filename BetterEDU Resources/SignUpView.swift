import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

// ImagePicker struct to handle image selection
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { (image, _) in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var profileImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var errorMessage: String?
    @State private var isSignedUp = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var body: some View {
        NavigationView {
            ZStack {
                // Background color and bubbles from LoginView
                Color(hex: "251db4").ignoresSafeArea()
                
                ForEach(0..<5, id: \.self) { _ in
                    LavaLampBubble(bubbleColor: Color(hex: ["5a0ef6", "98b6f8", "7849fd"].randomElement()!))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VStack(spacing: 20) {
                    Spacer()

                    // Profile Image Selector
                    VStack {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            Button(action: { showingImagePicker = true }) {
                                VStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                    Text("Upload Profile Picture")
                                        .foregroundColor(.white)
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)

                    // Title
                    Text("Create an Account")
                        .font(.custom("Impact", size: 24))
                        .foregroundColor(.white)
                        .padding(.bottom, 10)

                    // Input fields styled like LoginView
                    Group {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name")
                                .font(.custom("Impact", size: 18))
                                .foregroundColor(.white)
                            TextField("Enter your name", text: $name)
                                .padding()
                                .background(Color(hex: "98b6f8"))
                                .cornerRadius(10)
                                .foregroundColor(Color(hex: "251db4"))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email")
                                .font(.custom("Impact", size: 18))
                                .foregroundColor(.white)
                            TextField("name@example.com", text: $email)
                                .padding()
                                .background(Color(hex: "98b6f8"))
                                .cornerRadius(10)
                                .foregroundColor(Color(hex: "251db4"))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Password")
                                .font(.custom("Impact", size: 18))
                                .foregroundColor(.white)
                            ZStack(alignment: .trailing) {
                                if isPasswordVisible {
                                    TextField("Password", text: $password)
                                        .padding()
                                        .background(Color(hex: "98b6f8"))
                                        .cornerRadius(10)
                                        .foregroundColor(Color(hex: "251db4"))
                                } else {
                                    SecureField("Password", text: $password)
                                        .padding()
                                        .background(Color(hex: "98b6f8"))
                                        .cornerRadius(10)
                                        .foregroundColor(Color(hex: "251db4"))
                                }
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                        .foregroundColor(.white)
                                }
                                .padding(.trailing, 10)
                            }
                        }
                    }

                    // Sign Up Button styled like Sign In
                    Button(action: { signUpUser() }) {
                        Text("Sign Up")
                            .font(.custom("Impact", size: 30))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "5a0ef6"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                    }

                    Spacer()

                }
                .padding()
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $profileImage)
                }
                .fullScreenCover(isPresented: $isSignedUp) {
                    HomePageView()
                }
            }
        }
    }

    private func signUpUser() {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = authResult?.user {
                self.uploadProfileImage(for: user)
            }
        }
    }

    private func uploadProfileImage(for user: User) {
        guard let imageData = profileImage?.jpegData(compressionQuality: 0.8) else {
            saveUserData(uid: user.uid, profileImageURL: nil)
            return
        }

        let storageRef = storage.reference().child("profile_images/\(user.uid).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.errorMessage = "Error uploading image: \(error.localizedDescription)"
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    self.errorMessage = "Error retrieving image URL: \(error.localizedDescription)"
                } else {
                    self.saveUserData(uid: user.uid, profileImageURL: url?.absoluteString)
                }
            }
        }
    }

    private func saveUserData(uid: String, profileImageURL: String?) {
        let userData: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": email,
            "profileImageURL": profileImageURL ?? ""
        ]

        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                self.errorMessage = "Error saving user data: \(error.localizedDescription)"
            } else {
                self.isSignedUp = true
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
