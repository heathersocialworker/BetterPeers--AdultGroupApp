import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Access AuthViewModel for logout
    @State private var userName: String = "[Name]"
    @State private var email: String = "[Email]"
    @State private var profileImage: UIImage? = nil
    @State private var profileImageURL: URL?
    @State private var isShowingImagePicker = false
    @State private var errorMessage: String?
    @State private var isShowingSavedResources = false // Full screen cover state for SavedView
    
    @State private var selectedLocation: String = "[Location]" // User's selected location
    @State private var isLocationDropdownExpanded: Bool = false // Dropdown toggle for location
    @State private var selectedSchool: String = "[School]" // User's selected school
    @State private var isSchoolDropdownExpanded: Bool = false // Dropdown toggle for school

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(hex: "251db4")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header Section with Close Button
                    HStack {
                        Spacer()
                        Button(action: {
                            // Action to close or navigate back
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .padding(.trailing)

                    // Editable Profile Picture
                    VStack {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 4)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 30))
                                )
                                .shadow(radius: 4)
                        }
                        
                        Text("Change Profile Picture")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .padding(.top, 8)
                            .onTapGesture {
                                isShowingImagePicker = true
                            }
                    }
                    .padding(.bottom, 20)

                    // Display User Name
                    Text(userName)
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()

                    // Display Email Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Email")
                            .foregroundColor(.white)
                            .font(.headline)
                        TextField("Email", text: .constant(email)) // Display only, not editable
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                            .disabled(true)
                    }
                    .padding(.horizontal)

                    // Location Dropdown
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Location")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Button(action: {
                            withAnimation {
                                isLocationDropdownExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text(selectedLocation)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: isLocationDropdownExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                        
                        if isLocationDropdownExpanded {
                            VStack(spacing: 0) {
                                locationOption("Arizona")
                                Divider().background(Color.white)
                                locationOption("California")
                            }
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // School Dropdown
                    VStack(alignment: .leading, spacing: 10) {
                        Text("School")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Button(action: {
                            withAnimation {
                                isSchoolDropdownExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text(selectedSchool)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: isSchoolDropdownExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                        
                        if isSchoolDropdownExpanded {
                            VStack(spacing: 0) {
                                ForEach(filteredSchools, id: \.self) { school in
                                    schoolOption(school)
                                }
                            }
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Saved Resources Button with full screen cover
                    Button(action: {
                        isShowingSavedResources = true // Trigger full screen cover
                    }) {
                        profileRow(icon: "heart.fill", text: "Saved Resources")
                    }
                    .padding(.horizontal)
                    .fullScreenCover(isPresented: $isShowingSavedResources) {
                        SavedView()
                            .navigationBarHidden(true) // Ensure no navigation bar on SavedView
                    }

                    Spacer()

                    // Logout Button
                    Button(action: {
                        authViewModel.signOut() // Log out using AuthViewModel
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Log Out")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                loadUserData()
            }
            .sheet(isPresented: $isShowingImagePicker) {
                PhotoPicker(selectedImage: $profileImage, onImagePicked: saveProfileImage)
            }
            .navigationBarHidden(true) // Hide the default navigation bar if needed
        }
    }
    
    // Function to load user data from Firestore
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                self.errorMessage = "Error loading user data: \(error.localizedDescription)"
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                self.userName = data?["name"] as? String ?? "[Name]"
                self.email = data?["email"] as? String ?? "[Email]"
                self.selectedLocation = data?["location"] as? String ?? "[Location]"
                self.selectedSchool = data?["school"] as? String ?? "[School]"

                if let profileImageURLString = data?["profileImageURL"] as? String,
                   let url = URL(string: profileImageURLString) {
                    self.profileImageURL = url
                    loadImage(from: url)
                }
            }
        }
    }
    
    // Load profile image from a URL
    private func loadImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = uiImage
                }
            }
        }
        task.resume()
    }
    
    // Save profile image to Firebase Storage and Firestore
    private func saveProfileImage(_ image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let storageRef = storage.reference().child("profile_images/\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                self.errorMessage = "Error uploading profile image: \(error.localizedDescription)"
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    self.errorMessage = "Error retrieving profile image URL: \(error.localizedDescription)"
                } else if let url = url {
                    self.profileImageURL = url
                    self.updateProfileImageURL(uid: uid, url: url)
                }
            }
        }
    }
    
    // Update the profile image URL in Firestore
    private func updateProfileImageURL(uid: String, url: URL) {
        db.collection("users").document(uid).updateData(["profileImageURL": url.absoluteString]) { error in
            if let error = error {
                self.errorMessage = "Error saving profile image URL: \(error.localizedDescription)"
            }
        }
    }
    
    // Update location in Firestore
    private func updateLocation(_ location: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData(["location": location]) { error in
            if let error = error {
                self.errorMessage = "Error updating location: \(error.localizedDescription)"
            } else {
                self.selectedLocation = location // Update the UI with the new location
                self.selectedSchool = "[School]" // Reset the school selection when location changes
            }
        }
    }
    
    // Update school in Firestore
    private func updateSchool(_ school: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData(["school": school]) { error in
            if let error = error {
                self.errorMessage = "Error updating school: \(error.localizedDescription)"
            } else {
                self.selectedSchool = school // Update the UI with the new school
            }
        }
    }

    // Helper function to display a location option in the dropdown
    private func locationOption(_ location: String) -> some View {
        Button(action: {
            withAnimation {
                isLocationDropdownExpanded = false
            }
            updateLocation(location)
        }) {
            Text(location)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Helper function to display a school option in the dropdown
    private func schoolOption(_ school: String) -> some View {
        Button(action: {
            withAnimation {
                isSchoolDropdownExpanded = false
            }
            updateSchool(school)
        }) {
            Text(school)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // Filter schools based on location
    private var filteredSchools: [String] {
        let arizonaSchools = ["Arizona State University", "University of Arizona", "Northern Arizona University"]
        let californiaSchools = [
            "Stanford University", "California Institute of Technology", "University of California, Berkeley",
            "University of Southern California", "University of California, Los Angeles"
        ]
        
        switch selectedLocation {
        case "Arizona":
            return arizonaSchools
        case "California":
            return californiaSchools
        default:
            return []
        }
    }
    
    // Helper function to create profile rows
    private func profileRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
            Text(text)
                .foregroundColor(.white)
                .fontWeight(.bold)
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
    }
}

// PhotoPicker struct to handle image selection from the photo library
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ProfileView()
}
