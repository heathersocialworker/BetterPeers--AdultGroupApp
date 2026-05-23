import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LocationDropdown: View {
    @Binding var userState: String
    @State private var isDropdownOpen = false
    @Environment(\.horizontalSizeClass) var sizeClass
    private let locations = ["ALL", "CA", "AZ", "NV"]
    private let db = Firestore.firestore()
    
    private var isIPad: Bool {
        sizeClass == .regular
    }
    
    private func getStateName(_ code: String) -> String {
        switch code {
            case "CA": return "California"
            case "AZ": return "Arizona"
            case "NV": return "Nevada"
            default: return code
        }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Location Button
            Button(action: { isDropdownOpen.toggle() }) {
                Text("Showing: \(getStateName(userState))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color(hex: "5a0ef6").opacity(0.6))
                    .cornerRadius(8)
            }
            
            // Dropdown Menu
            if isDropdownOpen {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(locations, id: \.self) { location in
                        Button(action: {
                            updateLocation(to: location)
                            isDropdownOpen = false
                        }) {
                            HStack {
                                Text(getStateName(location))
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
                            .background(userState == location ? Color.black.opacity(0.6) : Color.clear)
                        }
                    }
                }
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                .padding(.top, 4)
                .frame(width: 200)
                .zIndex(1) // Ensure dropdown appears above other content
            }
        }
        .animation(.easeInOut, value: isDropdownOpen)
    }
    
    private func updateLocation(to location: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Update local state
        userState = location
        
        // Update in Firestore
        db.collection("users").document(uid).updateData([
            "state": location,  // Update state field
            "location": getStateName(location)  // Update location field with full state name
        ]) { error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
            } else {
                // Trigger refresh across all views
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshUserLocation"), object: nil)
                }
            }
        }
    }
} 
