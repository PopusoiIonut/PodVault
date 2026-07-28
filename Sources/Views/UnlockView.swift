import SwiftUI

struct UnlockView: View {
    @Binding var isUnlocked: Bool
    @State private var inputPasscode = ""
    @State private var isError = false
    @State private var attempts = 0
    
    private let correctPasscode = "7108"
    
    var body: some View {
        ZStack {
            // Background radial gradient
            RadialGradient(
                colors: [Color(hex: "00A3FF").opacity(0.15), Color(hex: "0F0F12")],
                center: .top,
                startRadius: 50,
                endRadius: 500
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 40)
                
                // Animated Lock Shield Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.02))
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle()
                                .stroke(isError ? Color.red.opacity(0.3) : Color(hex: "00A3FF").opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: isError ? Color.red.opacity(0.2) : Color(hex: "00A3FF").opacity(0.1), radius: 10)
                    
                    Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(isError ? .red : Color(hex: "00A3FF"))
                        .offset(y: isError ? 0 : -2)
                        .animation(.default, value: isUnlocked)
                }
                .modifier(ShakeEffect(animatableData: CGFloat(attempts)))
                
                VStack(spacing: 8) {
                    Text("PODVAULT")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundColor(.white)
                    
                    Text("Enter key to decrypt credentials")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Passcode Dot Indicators
                HStack(spacing: 20) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index < inputPasscode.count ? Color(hex: "00A3FF") : Color.white.opacity(0.1))
                            .frame(width: 14, height: 14)
                            .shadow(color: index < inputPasscode.count ? Color(hex: "00A3FF").opacity(0.5) : Color.clear, radius: 4)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                    }
                }
                .padding(.vertical, 10)
                
                Spacer()
                
                // Passcode Keyboard
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { num in
                        keypadButton(text: "\(num)")
                    }
                    
                    keypadButton(text: "✕", action: clearInput)
                    keypadButton(text: "0")
                    keypadButton(text: "✓", action: submitPasscode)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func keypadButton(text: String, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            if let customAction = action {
                customAction()
            } else {
                appendDigit(text)
            }
        }) {
            Text(text)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 75, height: 75)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(KeypadButtonStyle())
    }
    
    private func appendDigit(_ digit: String) {
        guard inputPasscode.count < 4 else { return }
        inputPasscode.append(digit)
        if inputPasscode.count == 4 {
            // Automatically submit after 4 digits
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                submitPasscode()
            }
        }
    }
    
    private func clearInput() {
        if !inputPasscode.isEmpty {
            inputPasscode.removeLast()
        }
    }
    
    private func submitPasscode() {
        if inputPasscode == correctPasscode {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isUnlocked = true
            }
        } else {
            withAnimation(.default) {
                isError = true
                attempts += 1
            }
            // Trigger feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                inputPasscode = ""
                isError = false
            }
        }
    }
}

// Keypad Button Interaction style
struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(configuration.isPressed ? Color(hex: "00A3FF").opacity(0.1) : Color.clear)
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Shake Effect for passcode errors
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

// Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
