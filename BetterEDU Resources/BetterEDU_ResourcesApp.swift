import SwiftUI
import Firebase
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct BetterEDU_ResourcesApp: App {
    // Initialize AppDelegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    // add firestore manager to view the resources from firebase
    @StateObject var firestoreManager = FirestoreManager()
    // Add AuthViewModel to manage authentication state
    @StateObject private var authViewModel = AuthViewModel()
    
    //init() {
    //        FirebaseApp.configure()
   // }
    
    var body: some Scene {
        WindowGroup {
            RootView() // Use RootView as the main entry point
                .environmentObject(authViewModel) // Pass authViewModel to the entire app
                .environmentObject(firestoreManager) // pass firestoreManager to the entire app
        }
    }
}
