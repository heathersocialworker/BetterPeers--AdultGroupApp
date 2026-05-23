import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ResourceCardView: View {
    let resource: ResourceItem
    @State private var isLiked: Bool = false
    @State private var showGuestAlert = false
    @State private var isAnimating = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tabViewModel: TabViewModel
    private let db = Firestore.firestore()
    
    // Parse phone numbers outside of the view body
    private var parsedPhoneNumbers: [String] {
        guard let phoneNumber = resource.phone_number, !phoneNumber.isEmpty else {
            return []
        }
        
        let lowercased = phoneNumber.lowercased()
        var numbers: [String] = []
        
        // Check if this contains multiple numbers with different separators
        if lowercased.contains("or") {
            // Split by OR/or
            let orComponents = phoneNumber.components(separatedBy: "OR")
            for component in orComponents {
                let subComponents = component.components(separatedBy: "or")
                for subComponent in subComponents {
                    numbers.append(subComponent.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        } else if phoneNumber.contains(",") {
            // Split by comma
            let commaComponents = phoneNumber.components(separatedBy: ",")
            for component in commaComponents {
                numbers.append(component.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } else {
            // Just a single number
            numbers = [phoneNumber]
        }
        
        return numbers
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(resource.title)
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 17, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            if let description = resource.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 16))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
            }

            if let phoneNumber = resource.phone_number, !phoneNumber.isEmpty {
                // Create a vertical stack of phone number links
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(parsedPhoneNumbers, id: \.self) { number in
                        // Check if this is a text message number
                        let isTextNumber = number.lowercased().contains("text")
                        
                        // Get just the digits for the URL
                        let formattedPhone = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                        
                        // Only create a link if we have digits
                        if !formattedPhone.isEmpty {
                            // Choose appropriate URL scheme based on whether it's for texting or calling
                            let urlScheme = isTextNumber ? "sms:" : "tel:"
                            
                            if let phoneURL = URL(string: "\(urlScheme)\(formattedPhone)") {
                                Link(destination: phoneURL) {
                                    HStack {
                                        // Use message icon for text numbers, phone icon for call numbers
                                        Image(systemName: isTextNumber ? "message.fill" : "phone.fill")
                                            .foregroundColor(isTextNumber ? .blue : .green)
                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14))
                                        
                                        Text(number)
                                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 15))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(1)
                                            .underline()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Display email if available
            if let email = resource.email, !email.isEmpty {
                if let emailURL = URL(string: "mailto:\(email)") {
                    Link(destination: emailURL) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14))
                            Text(email)
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 15))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                                .underline()
                        }
                    }
                }
            }

            // Bottom row with website and save button
            HStack {
                if let website = resource.website, !website.isEmpty, let url = URL(string: website) {
                    Link(destination: url) {
                        HStack {
                            Text("Visit Website")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 14 : 12))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#5a0ef6"), Color(hex: "#7849fd")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                }
                
                // Save Button with animation
                Button(action: handleSaveResource) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20))
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
            }
        }
        .padding(UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#333333"), Color(hex: "#222222")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        .onAppear(perform: checkIfResourceIsSaved)
        .onChange(of: tabViewModel.shouldRefreshResources) { _ in
            checkIfResourceIsSaved()
        }
        .alert("Sign In Required", isPresented: $showGuestAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign In") {
                authViewModel.signOut()
            }
        } message: {
            Text("You need to create an account or sign in to save resources.")
        }
    }
    
    private func handleSaveResource() {
        if Auth.auth().currentUser?.isAnonymous == true {
            showGuestAlert = true
        } else {
            withAnimation {
                isAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
                toggleSaveResource()
            }
        }
    }

    private func checkIfResourceIsSaved() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid).collection("savedResources").document(resource.id ?? "")

        userRef.getDocument { document, error in
            DispatchQueue.main.async {
                isLiked = document?.exists == true
            }
        }
    }

    private func toggleSaveResource() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let userRef = db.collection("users").document(uid)
        let resourceRef = userRef.collection("savedResources").document(resource.id ?? "")

        if isLiked {
            resourceRef.delete { error in
                if error == nil {
                    DispatchQueue.main.async {
                        isLiked = false
                        tabViewModel.refreshSavedResources()
                    }
                }
            }
        } else {
            let resourceData: [String: Any] = [
                "id": resource.id ?? "",
                "title": resource.title,
                "description": resource.description ?? "",
                "phone_number": resource.phone_number ?? "",
                "email": resource.email ?? "",
                "website": resource.website ?? "",
                "resourceType": resource.resourceType ?? "",
                "state": resource.state ?? ""
            ]
            resourceRef.setData(resourceData) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        isLiked = true
                        tabViewModel.refreshSavedResources()
                    }
                }
            }
        }
    }
} 