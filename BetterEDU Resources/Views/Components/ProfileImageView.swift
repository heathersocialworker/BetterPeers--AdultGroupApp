import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ProfileImageView: View {
    @StateObject private var imageLoader = ProfileImageLoader.shared
    let size: CGFloat
    let showBorder: Bool
    
    init(size: CGFloat = 35, showBorder: Bool = true) {
        self.size = size
        self.showBorder = showBorder
    }
    
    var body: some View {
        NavigationLink(destination: ProfileView().navigationBarHidden(true)) {
            if let image = imageLoader.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(showBorder ? Circle().stroke(Color.white, lineWidth: 2) : nil)
                    .shadow(radius: 4)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            if let uid = Auth.auth().currentUser?.uid {
                ProfileImageLoader.shared.loadProfileImage(forUID: uid)
            }
        }
    }
}

#Preview {
    ProfileImageView()
} 