//
//  RootView.swift
//  BetterEDU Resources
//
//  Created by Nick Arana on 11/12/24.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.isUserLoggedIn {
            NavView() // Use NavView for navigation
        } else {
            LoginView() // Show the login screen
        }
    }
}
