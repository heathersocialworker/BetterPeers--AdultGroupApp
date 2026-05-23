//
//  EmergencyHotlinesView.swift
//  BetterEDU Resources
//
//  Created by Nick Arana on 11/5/24.
//

import SwiftUI

struct EmergencyHotlinesView: View {
    @State private var searchText = ""
    
    // Temporary placeholder data for emergency hotlines
    private let hotlines = [
        EmergencyHotline(name: "National Suicide Prevention Lifeline", description: "Call 1-800-273-TALK (8255)"),
        EmergencyHotline(name: "Crisis Text Line", description: "Text HOME to 741741"),
        EmergencyHotline(name: "SAMHSA’s National Helpline", description: "Call 1-800-662-HELP (4357) for substance abuse help.")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Emergency Hotlines")
                .font(.custom("Impact", size: 30))
                .foregroundColor(Color(hex: "98b6f8"))
                .padding(.top)

            // Search Bar
            TextField("Search Hotlines", text: $searchText)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)

            // Hotline List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(filteredHotlines, id: \.name) { hotline in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(hotline.name)
                                .font(.headline)
                                .foregroundColor(Color(hex: "251db4"))
                            
                            Text(hotline.description)
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
        .navigationTitle("Emergency Hotlines")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Filter hotlines based on search text
    private var filteredHotlines: [EmergencyHotline] {
        if searchText.isEmpty {
            return hotlines
        } else {
            return hotlines.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

// Sample EmergencyHotline model for static data
struct EmergencyHotline {
    let name: String
    let description: String
}

struct EmergencyHotlinesView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyHotlinesView()
    }
}
