//
//  RootView.swift
//  BetterEDU Resources
//
//  Created by Nick Arana on 11/12/24.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager // firestoreManager environ object for resources
    var body: some View {
        if authViewModel.isUserLoggedIn {
            // Show the main content if the user is logged in
            HomePageView() // Or another main content view
        } else {
            // Show the LoginView if the user is not logged in
            LoginView()
        }
    }
}
