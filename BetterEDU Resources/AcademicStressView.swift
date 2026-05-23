//
//  AcademicStressView.swift
//  BetterEDU Resources
//
//  Created by Nick Arana on 11/5/24.
//

import SwiftUI

struct AcademicStressView: View {
    @State private var searchText = ""
    
    // Temporary placeholder data for academic stress resources
    private let resources = [
        AcademicStressResource(name: "Time Management Tips", description: "Learn how to manage your time effectively to reduce stress."),
        AcademicStressResource(name: "Study Techniques", description: "Explore various study techniques to improve learning and retention."),
        AcademicStressResource(name: "Stress Relief Activities", description: "Discover activities that help relieve academic stress.")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Academic Stress Support")
                .font(.custom("Impact", size: 30))
                .foregroundColor(Color(hex: "98b6f8"))
                .padding(.top)

            // Search Bar
            TextField("Search Resources", text: $searchText)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)

            // Resource List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(filteredResources, id: \.name) { resource in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(resource.name)
                                .font(.headline)
                                .foregroundColor(Color(hex: "251db4"))
                            
                            Text(resource.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .padding()
        .background(Color(hex: "251db4").ignoresSafeArea())
        .navigationTitle("Academic Stress Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Filter resources based on search text
    private var filteredResources: [AcademicStressResource] {
        if searchText.isEmpty {
            return resources
        } else {
            return resources.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

// Sample AcademicStressResource model for static data
struct AcademicStressResource {
    let name: String
    let description: String
}

struct AcademicStressView_Previews: PreviewProvider {
    static var previews: some View {
        AcademicStressView()
    }
}

