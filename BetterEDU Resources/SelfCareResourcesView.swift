//
//  SelfCareResourcesView.swift
//  BetterEDU Resources
//
//  Created by Nick Arana on 11/5/24.
//

import SwiftUI

struct SelfCareResourcesView: View {
    @State private var searchText = ""
    
    // Temporary placeholder data for self-care resources
    private let resources = [
        SelfCareResource(name: "Meditation Apps", description: "Find top-rated apps for guided meditation."),
        SelfCareResource(name: "Mindfulness Practices", description: "Learn about mindfulness techniques to manage stress."),
        SelfCareResource(name: "Physical Exercise Tips", description: "Resources to help you stay active and healthy.")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Self-Care Resources")
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
        .navigationTitle("Self-Care Resources")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Filter resources based on search text
    private var filteredResources: [SelfCareResource] {
        if searchText.isEmpty {
            return resources
        } else {
            return resources.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

// Sample SelfCareResource model for static data
struct SelfCareResource {
    let name: String
    let description: String
}

struct SelfCareResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        SelfCareResourcesView()
    }
}

