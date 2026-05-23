import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct BetterEDU_ResourcesApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showReviewPopup = false
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .onAppear {
                    // Increment app open count
                    ReviewManager.shared.incrementAppOpenCount()
                    
                    // Check if we should show review popup
                    if ReviewManager.shared.shouldRequestReview() {
                        showReviewPopup = true
                    }
                }
                .sheet(isPresented: $showReviewPopup) {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        ReviewPopupView {
                            ReviewManager.shared.requestReview()
                            ReviewManager.shared.markAsReviewed()
                        }
                    }
                    .presentationBackground(.clear)
                }
        }
    }
}
