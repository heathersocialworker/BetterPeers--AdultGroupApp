import SwiftUI

struct ReviewPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    let onReview: () -> Void
    
    var body: some View {
        VStack(spacing: sizeClass == .regular ? 20 : 16) {
            // Header
            Text("Enjoying BetterEDU Resources?")
                .font(.custom("Impact", size: sizeClass == .regular ? 24 : 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Message
            Text("Your feedback helps us improve and reach more students who need support.")
                .font(.system(size: sizeClass == .regular ? 18 : 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, sizeClass == .regular ? 24 : 16)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    onReview()
                    dismiss()
                }) {
                    Text("Rate BetterEDU")
                        .font(.custom("Impact", size: sizeClass == .regular ? 20 : 18))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "5a0ef6"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: { dismiss() }) {
                    Text("Maybe Later")
                        .font(.custom("Impact", size: sizeClass == .regular ? 18 : 16))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 8)
        }
        .padding(sizeClass == .regular ? 32 : 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, sizeClass == .regular ? 40 : 24)
    }
} 