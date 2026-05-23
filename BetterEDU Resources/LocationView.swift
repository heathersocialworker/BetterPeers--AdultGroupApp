import SwiftUI

struct LocationView: View {
    @State private var selectedState: String = ""
    @State private var searchText: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    // Sample list of states (you can expand this as needed)
    let states = ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(hex: "3b3aaf"), Color(hex: "1d1ba9")]),
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                
                // Custom Back Arrow in the Top-Left Corner
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    Spacer()
                }
                .padding([.top, .leading])

                Text("Set Location")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, -10)

                // Search Field with Icon and custom placeholder color
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    TextField("Search for your state", text: $searchText)
                        .foregroundColor(.white)
                        .placeholder(when: searchText.isEmpty) {
                            Text("Search for your state")
                                .foregroundColor(Color.white.opacity(0.9)) // More visible placeholder color
                        }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)

                // Filtered List of States
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredStates, id: \.self) { state in
                            Button(action: {
                                selectedState = state
                            }) {
                                HStack {
                                    Text(state)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedState == state {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(selectedState == state ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .background(Color.clear)
                .cornerRadius(10)

                Spacer()

                // Save Button with a distinct style
                Button(action: {
                    saveLocation()
                }) {
                    Text("Save")
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "251db4"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    // Filter states based on the search text
    private var filteredStates: [String] {
        if searchText.isEmpty {
            return states
        } else {
            return states.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Placeholder function to handle save action
    private func saveLocation() {
        // Code to save the selected location, e.g., storing in UserDefaults or database
        print("Saved Location: \(selectedState)")
    }
}

// Custom modifier for TextField placeholder
extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                content()
            }
            self
        }
    }
}

#Preview {
    LocationView()
}
