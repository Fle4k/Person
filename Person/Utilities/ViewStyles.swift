import SwiftUI

extension Color {
    static var dynamicText: Color {
        Color(.label)  // Automatically adapts to light/dark mode
    }
    
    static var dynamicBackground: Color {
        Color(.systemBackground)  // Automatically adapts to light/dark mode
    }
    
    static var dynamicFill: Color {
        Color(.label)  // Same as text color, inverts automatically
    }
}

struct CustomSegmentedPickerStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.dynamicFill)
                UISegmentedControl.appearance().setTitleTextAttributes(
                    [.foregroundColor: UIColor(Color.dynamicBackground)],
                    for: .selected)
                UISegmentedControl.appearance().setTitleTextAttributes(
                    [.foregroundColor: UIColor(Color.dynamicText)],
                    for: .normal)
            }
    }
} 