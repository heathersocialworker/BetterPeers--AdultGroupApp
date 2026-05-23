import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Image Cache Manager
final class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Configure cache
        cache.countLimit = 100 // Maximum number of images to store
        cache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// Profile Image Loading Manager
final class ProfileImageLoader: ObservableObject {
    static let shared = ProfileImageLoader()
    @Published var profileImage: UIImage? = nil
    private let db = Firestore.firestore()
    
    private init() {}
    
    func loadProfileImage(forUID uid: String, completion: ((UIImage?) -> Void)? = nil) {
        // First check cache
        if let cachedImage = ImageCache.shared.get(forKey: uid) {
            self.profileImage = cachedImage
            completion?(cachedImage)
            return
        }
        
        // If not in cache, load from Firestore
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let document = document,
               let profileImageURLString = document.data()?["profileImageURL"] as? String,
               let url = URL(string: profileImageURLString) {
                
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        // Store in cache
                        ImageCache.shared.set(image, forKey: uid)
                        
                        DispatchQueue.main.async {
                            self?.profileImage = image
                            completion?(image)
                        }
                    }
                }.resume()
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var tabViewModel: TabViewModel
    @StateObject private var imageLoader = ProfileImageLoader.shared
    @State private var userName: String = "[Name]"
    @State private var email: String = "[Email]"
    @State private var selectedLocation: String = "[Location]"
    @State private var selectedSchool: String = "[School]"
    @State private var showDeleteConfirmation = false
    @State private var isEditingName = false
    @State private var tempUserName = ""
    @State private var showLocationPicker = false
    @State private var showSchoolPicker = false
    @State private var isLocationDropdownOpen = false
    @State private var isSchoolDropdownOpen = false
    @State private var navigateToSavedResources = false
    @State private var isShowingImagePicker = false
    @State private var profileImage: UIImage?
    @State private var showEmailAlert = false
    
    private let locations = ["ALL", "California", "Arizona"]
    private let schoolsByState = [
        "California": ["UC Berkeley", "UCLA", "UC San Diego", "Stanford University", "USC"],
        "Arizona": ["Arizona State University", "University of Arizona", "Northern Arizona University"]
    ]
    
    private var availableSchools: [String] {
        if selectedLocation == "ALL" {
            return []
        }
        return schoolsByState[selectedLocation] ?? []
    }

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private var isIPad: Bool {
        sizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background Image
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Dismiss Button
                            HStack {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: isIPad ? 32 : 24))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, isIPad ? 50 : 110)

                            // Profile Image
                            Button(action: { isShowingImagePicker = true }) {
                                if let image = imageLoader.profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: isIPad ? 160 : 100, height: isIPad ? 160 : 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: isIPad ? 160 : 100, height: isIPad ? 160 : 100)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: isIPad ? 40 : 30))
                                        )
                                }
                            }

                            // User Name
                            HStack {
                                if isEditingName {
                                    TextField("Enter name", text: $tempUserName)
                                        .font(.system(size: isIPad ? 28 : 22, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .background(Color.black.opacity(0.4))
                                        .cornerRadius(8)
                                        .onSubmit {
                                            if !tempUserName.isEmpty {
                                                userName = tempUserName
                                                updateUserData(field: "name", value: tempUserName)
                                            }
                                            isEditingName = false
                                        }
                                } else {
                                    Text(userName)
                                        .font(.system(size: isIPad ? 28 : 22, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                // Only show edit button for non-guest users
                                if Auth.auth().currentUser?.isAnonymous == false {
                                    Button(action: { 
                                        if !isEditingName {
                                            tempUserName = userName
                                            isEditingName = true
                                        } else {
                                            if !tempUserName.isEmpty {
                                                userName = tempUserName
                                                updateUserData(field: "name", value: tempUserName)
                                            }
                                            isEditingName = false
                                        }
                                    }) {
                                        Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: isIPad ? 24 : 20))
                                    }
                                }
                            }
                            .frame(maxWidth: isIPad ? 700 : 350)
                            .padding(.horizontal)

                            // Info Cards and Actions
                            VStack(spacing: 12) {
                                Button(action: {
                                    showEmailAlert = true
                                }) {
                                    infoCard(title: "Email", value: email, icon: "envelope.fill")
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // Location Dropdown
                                    Button(action: { isLocationDropdownOpen.toggle() }) {
                                        infoCard(title: "Location", value: selectedLocation, icon: "location.fill")
                                    }
                                    .frame(width: isIPad ? 700 : 350)
                                    
                                    if isLocationDropdownOpen {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(locations, id: \.self) { location in
                                                Button(action: {
                                                    selectedLocation = location
                                                    // Reset school selection when location changes
                                                    if location == "ALL" {
                                                        selectedSchool = "[School]"
                                                    }
                                                    isLocationDropdownOpen = false
                                                    // Update in Firestore
                                                    updateUserData(field: "location", value: location)
                                                }) {
                                                    HStack {
                                                        Text(location)
                                                            .foregroundColor(.white)
                                                        if location == "ALL" {
                                                            Spacer()
                                                            Text("See all resources")
                                                                .font(.system(size: isIPad ? 14 : 12))
                                                                .foregroundColor(.white.opacity(0.7))
                                                        }
                                                    }
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 16)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .background(selectedLocation == location ? Color.black.opacity(0.6) : Color.clear)
                                            }
                                        }
                                        .background(Color.black.opacity(0.4))
                                        .cornerRadius(12)
                                        .padding(.top, 4)
                                    }

                                    // School Dropdown
                                    Button(action: { isSchoolDropdownOpen.toggle() }) {
                                        infoCard(title: "School", value: selectedSchool, icon: "book.fill")
                                    }
                                    .frame(width: isIPad ? 700 : 350)
                                    .disabled(selectedLocation == "[Location]" || selectedLocation == "ALL")
                                    
                                    if isSchoolDropdownOpen && selectedLocation != "[Location]" && selectedLocation != "ALL" {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(availableSchools, id: \.self) { school in
                                                Button(action: {
                                                    selectedSchool = school
                                                    isSchoolDropdownOpen = false
                                                    // Update in Firestore
                                                    updateUserData(field: "school", value: school)
                                                }) {
                                                    Text(school)
                                                        .foregroundColor(.white)
                                                        .padding(.vertical, 8)
                                                        .padding(.horizontal, 16)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .background(selectedSchool == school ? Color.black.opacity(0.6) : Color.clear)
                                            }
                                        }
                                        .background(Color.black.opacity(0.4))
                                        .cornerRadius(12)
                                        .padding(.top, 4)
                                    }
                                }
                                .animation(.easeInOut, value: isLocationDropdownOpen)
                                .animation(.easeInOut, value: isSchoolDropdownOpen)

                                Button(action: {
                                    dismiss()
                                    tabViewModel.selectedTab = 2  // Switch to Saved tab
                                }) {
                                    actionButton(icon: "heart.fill", text: "Saved Resources", color: .purple)
                                }
                                
                                Button(action: {
                                    dismiss()
                                    authViewModel.signOut()
                                }) {
                                    actionButton(icon: "arrow.right.square.fill", text: "Log Out", color: .purple)
                                }
                                
                                // Only show delete account button for non-guest users
                                if Auth.auth().currentUser?.isAnonymous == false {
                                    Button(action: {
                                        showDeleteConfirmation = true
                                    }) {
                                        actionButton(icon: "trash", text: "Delete Account", color: .red)
                                    }
                                }
                            }
                            .frame(maxWidth: isIPad ? 700 : 350)
                            .padding(.horizontal, isIPad ? 40 : 16)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isIPad ? 150 : 30)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear { loadUserData() }
                .sheet(isPresented: $isShowingImagePicker) {
                    PhotoPicker(selectedImage: $profileImage, onImagePicked: saveProfileImage)
                }
                .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) { authViewModel.deleteAccount() }
                } message: {
                    Text("Are you sure you want to delete your account? This action cannot be undone.")
                }
                .alert("Email Cannot Be Changed", isPresented: $showEmailAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("For security reasons, your email address cannot be changed.")
                }
            }
        }
    }

    private func infoCard(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 24 : 20))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: isIPad ? 16 : 14))
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.system(size: isIPad ? 20 : 17))
            }
            Spacer()
            if title == "Email" {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: isIPad ? 18 : 14))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: isIPad ? 20 : 16))
            }
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
    }

    private func actionButton(icon: String, text: String, color: Color = .white) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 24 : 20))
            Text(text)
                .font(.system(size: isIPad ? 20 : 17, weight: .semibold))
            Spacer()
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            Group {
                if text == "Log Out" {
                    Color.purple
                } else if text == "Delete Account" {
                    Color.red
                } else {
                    Color.black.opacity(0.4)
                }
            }
        )
        .cornerRadius(12)
    }
    
    // MARK: - Data Management Functions
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: No user ID available")
            return
        }
        
        print("Loading user data for UID: \(uid)")
        
        // Check if user is anonymous (guest)
        if Auth.auth().currentUser?.isAnonymous == true {
            DispatchQueue.main.async {
                self.userName = "Guest"
                self.email = "Guest Account"
                self.selectedLocation = "ALL"  // Set default to ALL for guests
                self.selectedSchool = "[School]"
                self.isEditingName = false // Ensure editing mode is disabled for guests
            }
            return
        }
        
        // Listen for real-time updates for non-guest users
        db.collection("users").document(uid)
            .addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("Error fetching document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = documentSnapshot, document.exists,
                      let data = document.data() else {
                    print("No document data found")
                    return
                }
                
                print("Received user data update")
                
                DispatchQueue.main.async {
                    self.userName = data["name"] as? String ?? "[Name]"
                    self.email = data["email"] as? String ?? "[Email]"
                    self.selectedLocation = data["location"] as? String ?? "ALL"  // Default to ALL if no location set
                    self.selectedSchool = data["school"] as? String ?? "[School]"
                    
                    // Load profile image using the shared loader
                    if let uid = Auth.auth().currentUser?.uid {
                        ProfileImageLoader.shared.loadProfileImage(forUID: uid)
                    }
                }
            }
    }
    
    private func saveProfileImage(_ image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("❌ Error: Failed to get user ID or convert image to data")
            return
        }
        
        print("🔄 Starting profile image upload for user: \(uid)")
        print("📦 Image data size: \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))")
        
        // Update UI immediately with the new image
        DispatchQueue.main.async {
            ProfileImageLoader.shared.profileImage = image
            ImageCache.shared.set(image, forKey: uid)
            print("✅ Updated UI with new image")
        }
        
        // Create a reference to Firebase Storage
        let storageRef = storage.reference()
        let imageRef = storageRef.child("profile_images/\(uid).jpg")
        print("📝 Storage reference created: profile_images/\(uid).jpg")
        
        // Create metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload the new image data directly
        print("⬆️ Starting image upload...")
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Error uploading image: \(error.localizedDescription)")
                print("❌ Full error details: \(error)")
                return
            }
            
            print("✅ Image uploaded successfully, size: \(metadata?.size ?? 0) bytes")
            print("🔍 Getting download URL...")
            
            // Get the download URL
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Error getting download URL: \(error.localizedDescription)")
                    print("❌ Full error details: \(error)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("❌ Error: Could not get download URL")
                    return
                }
                
                print("✅ Got download URL: \(downloadURL.absoluteString)")
                
                // Update Firestore with the new URL
                print("💾 Updating Firestore document...")
                self.db.collection("users").document(uid).updateData([
                    "profileImageURL": downloadURL.absoluteString,
                    "lastUpdated": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print("❌ Error updating profile image URL in Firestore: \(error.localizedDescription)")
                        print("❌ Full error details: \(error)")
                    } else {
                        print("✅ Profile image URL successfully updated in Firestore")
                    }
                }
            }
        }
    }
    
    private func updateUserName(_ newName: String) {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "name": newName
        ]) { error in
            if let error = error {
                print("Error updating name: \(error.localizedDescription)")
            } else {
                self.userName = newName
            }
        }
    }
    
    private func updateUserData(field: String, value: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            field: value
        ]) { error in
            if let error = error {
                print("Error updating \(field): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - PhotoPicker
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
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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
