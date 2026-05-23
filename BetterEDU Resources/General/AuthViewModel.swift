//
//  AuthViewModel.swift
//  BetterEDU Resources
//
//
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
    
    func deleteAccount() {
            guard let user = Auth.auth().currentUser else {
                print("No user is currently logged in.")
                return
            }

            // Step 1: Delete the user's data from Firestore
            let db = Firestore.firestore()
            let userId = user.uid

            db.collection("users").document(userId).delete { error in
                if let error = error {
                    print("Error deleting user data from Firestore: \(error.localizedDescription)")
                    return
                }

                // Step 2: Delete the user's Firebase Authentication account
                user.delete { error in
                    if let error = error {
                        print("Error deleting user account: \(error.localizedDescription)")
                    } else {
                        print("User account successfully deleted.")
                        DispatchQueue.main.async {
                            self.isUserLoggedIn = false
                        }
                    }
                }
            }
        }

}
