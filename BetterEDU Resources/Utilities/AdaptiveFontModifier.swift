import SwiftUI

struct AdaptiveFontModifier: ViewModifier {
    let fontSize: CGFloat
    let weight: Font.Weight
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: adaptiveFontSize, weight: weight))
    }
    
    private var adaptiveFontSize: CGFloat {
        let scale = UIDevice.current.userInterfaceIdiom == .pad ? 1.3 : 1.0
        return fontSize * scale
    }
}

extension View {
    func adaptiveFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(AdaptiveFontModifier(fontSize: size, weight: weight))
    }
} 