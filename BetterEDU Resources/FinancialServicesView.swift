//
//  FinancialServicesView.swift
//  BetterEDU Resources
//
//  Created by Nick Arana on 11/5/24.
//

import SwiftUI

struct FinancialServicesView: View {
    // Temporary placeholder data for resources
    @State private var searchText = ""
    private let resources = [
        FinancialResource(name: "Scholarship Finder", description: "Find scholarships and grants available for students."),
        FinancialResource(name: "Financial Aid Office", description: "Contact your school's financial aid office for assistance."),
        FinancialResource(name: "Student Loan Help", description: "Resources to help you manage and understand student loans.")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Financial Services")
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
        .navigationTitle("Financial Services")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Filter resources based on search text
    private var filteredResources: [FinancialResource] {
        if searchText.isEmpty {
            return resources
        } else {
            return resources.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

// Sample FinancialResource model for static data
struct FinancialResource {
    let name: String
    let description: String
}

struct FinancialServicesView_Previews: PreviewProvider {
    static var previews: some View {
        FinancialServicesView()
    }
}

