import SwiftUI
import StoreKit

class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    
    @AppStorage("lastReviewRequest") private var lastReviewRequest: Double = 0
    @AppStorage("appOpenCount") private var appOpenCount: Int = 0
    @AppStorage("hasReviewed") private var hasReviewed: Bool = false
    
    private let minimumDaysBetweenRequests = 30.0
    private let minimumAppOpens = 3
    
    private init() {}
    
    func incrementAppOpenCount() {
        appOpenCount += 1
    }
    
    func shouldRequestReview() -> Bool {
        // Don't request if user has already reviewed
        guard !hasReviewed else { return false }
        
        // Check if enough time has passed since last request
        let currentTime = Date().timeIntervalSince1970
        let timeSinceLastRequest = currentTime - lastReviewRequest
        guard timeSinceLastRequest >= (minimumDaysBetweenRequests * 24 * 60 * 60) else { return false }
        
        // Check if user has opened the app enough times
        guard appOpenCount >= minimumAppOpens else { return false }
        
        return true
    }
    
    func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        // Update last request time
        lastReviewRequest = Date().timeIntervalSince1970
        
        // Request review
        SKStoreReviewController.requestReview(in: scene)
    }
    
    func markAsReviewed() {
        hasReviewed = true
    }
} 