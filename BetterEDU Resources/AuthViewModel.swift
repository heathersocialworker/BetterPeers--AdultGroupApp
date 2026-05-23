//
//  AuthViewModel.swift
//  BetterEDU Resources
//
//  Created by Nick Arana on 11/12/24.
//

import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isUserLoggedIn: Bool = false
    
    init() {
        // Check if a user is already logged in when the app starts
        self.isUserLoggedIn = Auth.auth().currentUser != nil
        
        // Observe authentication state changes
        Auth.auth().addStateDidChangeListener { _, user in
            self.isUserLoggedIn = user != nil
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isUserLoggedIn = false
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
