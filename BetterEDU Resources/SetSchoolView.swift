import SwiftUI

struct SetSchoolView: View {
    @State private var selectedCollege: String = ""
    @State private var searchText: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    // List of colleges in California and Arizona
    let colleges = [
        "Stanford University", "California Institute of Technology", "University of California, Berkeley",
        "University of Southern California", "University of California, Los Angeles",
        "University of California, San Diego", "University of California, Irvine",
        "University of California, Davis", "University of California, Santa Barbara",
        "San Diego State University", "California State University, Fullerton",
        "California Polytechnic State University, San Luis Obispo", "Santa Clara University",
        "Arizona State University", "University of Arizona", "Northern Arizona University"
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(hex: "3b3aaf"), Color(hex: "1d1ba9")]),
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                
                // Custom Back Arrow and Title in the Top-Left Corner
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    
                    Text("Set School")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding([.top, .leading, .trailing])

                // Search Field with Icon and custom placeholder color
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    TextField("Search for your college", text: $searchText)
                        .foregroundColor(.white)
                        .placeholder(when: searchText.isEmpty) {
                            Text("Search for your college")
                                .foregroundColor(Color.white.opacity(0.9))
                        }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)

                // Filtered List of Colleges
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredColleges, id: \.self) { college in
                            Button(action: {
                                selectedCollege = college
                            }) {
                                HStack {
                                    Text(college)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedCollege == college {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(selectedCollege == college ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
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
                    saveCollege()
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
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    // Filter colleges based on the search text
    private var filteredColleges: [String] {
        if searchText.isEmpty {
            return colleges
        } else {
            return colleges.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Placeholder function to handle save action
    private func saveCollege() {
        print("Saved College: \(selectedCollege)")
    }
}


#Preview {
    SetSchoolView()
}
