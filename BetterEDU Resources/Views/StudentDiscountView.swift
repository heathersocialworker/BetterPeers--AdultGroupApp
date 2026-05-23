import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// Student Discount Model
struct StudentDiscountItem: Identifiable, Codable {
    @DocumentID var id: String?
    var category: String
    var description: String
    var discount: String
    var link: String
    var name: String
    var requirements: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case description
        case discount
        case link
        case name
        case requirements
    }
}

struct StudentDiscountView: View {
    @State private var discounts: [StudentDiscountItem] = []
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    @State private var availableFilters: [String] = ["All"]
    @StateObject private var imageLoader = ProfileImageLoader.shared
    private var db = Firestore.firestore()
    
    private var gridColumns: [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ]
        } else {
            return [GridItem(.flexible())]
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Header with profile icon
                HStack {
                    NavigationLink(destination: ProfileView().navigationBarHidden(true)) {
                        if let image = imageLoader.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 35, 
                                       height: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 35)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 4)
                                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 35, 
                                       height: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 35)
                                .foregroundColor(.white)
                                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                        }
                    }
                    Spacer()
                }
                .padding(.top)
                .onAppear(perform: {
                    if let uid = Auth.auth().currentUser?.uid {
                        ProfileImageLoader.shared.loadProfileImage(forUID: uid)
                    }
                    fetchDiscounts()
                })
                
                // Title
                Text("Student Discounts")
                    .font(.custom("Lobster1.4", size: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 60))
                    .foregroundColor(.white)
                    .padding(.top, -1)
                    .padding(.bottom, -10)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Search and Filter Section
                HStack {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search discounts...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.black)
                            .tint(.blue)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    // Filter Menu
                    Menu {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(availableFilters, id: \.self) { filter in
                                Text(filter).tag(filter)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedFilter)
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 14))
                                .foregroundColor(.white)
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 12 : 10))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                .padding(.top, 10)

                // Display filtered discounts
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16) {
                        if filteredDiscounts.isEmpty {
                            Text("No discounts found.")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .gridCellColumns(gridColumns.count)
                        } else {
                            ForEach(filteredDiscounts) { discount in
                                DiscountCard(discount: discount)
                            }
                        }
                    }
                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16)
                    .padding(.top, 12)
                    .padding(.bottom, 90)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func fetchDiscounts() {
        db.collection("studentDisc")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching documents: \(error)")
                } else {
                    guard let documents = querySnapshot?.documents else {
                        print("No documents found in studentDisc.")
                        return
                    }
                    
                    let fetchedDiscounts = documents.compactMap { document in
                        do {
                            return try document.data(as: StudentDiscountItem.self)
                        } catch {
                            print("Error decoding document \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                    DispatchQueue.main.async {
                        self.discounts = fetchedDiscounts
                        updateAvailableFilters()
                    }
                }
            }
    }

    private func updateAvailableFilters() {
        let categories = Set(discounts.map { $0.category })
        availableFilters = ["All"] + Array(categories).sorted()
    }

    private var filteredDiscounts: [StudentDiscountItem] {
        discounts.filter { discount in
            let matchesFilter = selectedFilter == "All" || discount.category == selectedFilter
            let matchesSearch = searchText.isEmpty || 
                              discount.name.lowercased().contains(searchText.lowercased()) ||
                              discount.description.lowercased().contains(searchText.lowercased())
            return matchesFilter && matchesSearch
        }
    }
}

struct DiscountCard: View {
    let discount: StudentDiscountItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header section with name and category
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(discount.name)
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 22 : 19, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(discount.category)
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 14 : 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#5a0ef6").opacity(0.3), Color(hex: "#7849fd").opacity(0.3)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }
                
                // Discount amount section with icon
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.green)
                    Text(discount.discount)
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 17, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Description section
            VStack(alignment: .leading, spacing: 12) {
                Text(discount.description)
                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                
                // Requirements section with icon
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14))
                    
                    Text(discount.requirements)
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 14 : 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Action button section
            Link(destination: URL(string: discount.link)!) {
                HStack {
                    Text("Get Discount")
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 14, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 14 : 12))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#5a0ef6"), Color(hex: "#7849fd")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
            }
        }
        .padding(UIDevice.current.userInterfaceIdiom == .pad ? 20 : 16)
        .frame(maxWidth: .infinity)
        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 280 : 240)
        .background(
            ZStack {
                Color.black.opacity(0.4)
                
                // Glassmorphic effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
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
                    lineWidth: 0.5
                )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct StudentDiscountView_Previews: PreviewProvider {
    static var previews: some View {
        StudentDiscountView()
    }
} 
