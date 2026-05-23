import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class TabViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var shouldRefreshResources = false
    @Published var shouldRefreshSavedResources = false
    private let db = Firestore.firestore()
    
    func refreshResources() {
        shouldRefreshResources = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldRefreshResources = false
        }
    }
    
    func refreshSavedResources() {
        shouldRefreshSavedResources = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldRefreshSavedResources = false
        }
    }
    
    func refreshResourcesOnSave() {
        // This method is kept for backward compatibility
        refreshSavedResources()
    }
} 