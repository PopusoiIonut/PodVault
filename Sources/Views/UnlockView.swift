import SwiftUI
import LocalAuthentication

enum UnlockMode {
    case level1Gate
    case level2Master
    case setup
}

struct UnlockView: View {
    var mode: UnlockMode = .level1Gate
    @Binding var isUnlocked: Bool
    var onComplete: (() -> Void)? = nil
    
    @ObservedObject private var vaultService = KeychainVaultService.shared
    @State private var inputPasscode = ""
    @State private var isError = false
    @State private var attempts = 0
    @State private var biometryIcon: String? = nil
    
    // Setup state
    @State private var setupStep = 0
    @State private var tempLevel1 = ""
    @State private var tempLevel2 = ""
    @State private var setupSubtitle = "Create 4-Digit Quick PIN (Level 1)"
    
    private var isCompact: Bool {
        UIScreen.main.bounds.height <= 568 || UIScreen.main.bounds.width <= 320
    }
    
    private var buttonDimension: CGFloat {
        isCompact ? 60 : 72
    }
    
    private var gridSpacing: CGFloat {
        isCompact ? 12 : 18
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background radial gradient
                RadialGradient(
                    colors: [
                        mode == .level2Master ? Color(hex: "FF3B30").opacity(0.12) : Color(hex: "00A3FF").opacity(0.14),
                        Color(hex: "0B0B0E")
                    ],
                    center: .top,
                    startRadius: 30,
                    endRadius: geometry.size.height * 0.8
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: isCompact ? 14 : 22) {
                    Spacer(minLength: isCompact ? 10 : 30)
                    
                    // Animated Lock Shield Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.03))
                            .frame(width: isCompact ? 64 : 80, height: isCompact ? 64 : 80)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isError ? Color.red.opacity(0.4) :
                                        (mode == .level2Master ? Color(hex: "FF3B30").opacity(0.3) : Color(hex: "00A3FF").opacity(0.25)),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: isError ? Color.red.opacity(0.3) :
                                (mode == .level2Master ? Color(hex: "FF3B30").opacity(0.2) : Color(hex: "00A3FF").opacity(0.15)),
                                radius: 10
                            )
                        
                        Image(systemName: iconName)
                            .font(.system(size: isCompact ? 28 : 34))
                            .foregroundColor(
                                isError ? .red :
                                (mode == .level2Master ? Color(hex: "FF3B30") : Color(hex: "00A3FF"))
                            )
                            .offset(y: isError ? 0 : -2)
                    }
                    .modifier(ShakeEffect(animatableData: CGFloat(attempts)))
                    
                    // Title and Description
                    VStack(spacing: 6) {
                        Text(headerTitle)
                            .font(.system(size: isCompact ? 20 : 26, weight: .bold, design: .rounded))
                            .tracking(isCompact ? 2 : 3)
                            .foregroundColor(.white)
                        
                        Text(headerSubtitle)
                            .font(.system(size: isCompact ? 12 : 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Passcode Dot Indicators
                    HStack(spacing: isCompact ? 16 : 20) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index < inputPasscode.count ? activeColor : Color.white.opacity(0.12))
                                .frame(width: isCompact ? 12 : 14, height: isCompact ? 12 : 14)
                                .shadow(color: index < inputPasscode.count ? activeColor.opacity(0.5) : Color.clear, radius: 4)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical, isCompact ? 4 : 8)
                    
                    Spacer(minLength: isCompact ? 10 : 20)
                    
                    // Passcode Numeric Keyboard
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(buttonDimension), spacing: gridSpacing), count: 3),
                        spacing: gridSpacing
                    ) {
                        ForEach(1...9, id: \.self) { num in
                            keypadButton(text: "\(num)")
                        }
                        
                        // Bottom row: Biometric or empty
                        if let icon = biometryIcon, mode != .setup {
                            biometricButton(icon: icon)
                        } else {
                            Color.clear.frame(width: buttonDimension, height: buttonDimension)
                        }
                        
                        keypadButton(text: "0")
                        
                        // Delete / Backspace
                        keypadIconButton(icon: "delete.backward.fill", action: clearInput)
                    }
                    .padding(.bottom, isCompact ? 20 : 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            checkBiometry()
            if mode == .setup || (!vaultService.isConfigured && mode == .level1Gate) {
                // Initialize setup state if needed
                setupSubtitle = "Set 4-Digit Quick PIN (Level 1)"
            } else if biometryIcon != nil && mode == .level1Gate {
                authenticateWithBiometrics()
            }
        }
    }
    
    private var activeColor: Color {
        if mode == .level2Master {
            return Color(hex: "FF3B30")
        }
        return Color(hex: "00A3FF")
    }
    
    private var iconName: String {
        if isUnlocked {
            return "lock.open.fill"
        }
        if mode == .level2Master {
            return "shield.checkerboard"
        }
        if isSetupMode {
            return "key.horizontal.fill"
        }
        return "lock.fill"
    }
    
    private var isSetupMode: Bool {
        mode == .setup || (!vaultService.isConfigured && mode == .level1Gate)
    }
    
    private var headerTitle: String {
        if isSetupMode {
            switch setupStep {
            case 0: return "VAULT SETUP"
            case 1: return "CONFIRM PIN"
            case 2: return "MASTER KEY"
            case 3: return "CONFIRM MASTER"
            default: return "VAULT SETUP"
            }
        }
        if mode == .level2Master {
            return "COLD VAULT (LEVEL 2)"
        }
        return "PODVAULT"
    }
    
    private var headerSubtitle: String {
        if isSetupMode {
            switch setupStep {
            case 0: return "Step 1 of 4: Set Level 1 Quick PIN"
            case 1: return "Step 2 of 4: Re-enter Level 1 PIN"
            case 2: return "Step 3 of 4: Set Level 2 Master Key"
            case 3: return "Step 4 of 4: Re-enter Master Key"
            default: return "Configure hardware vault passcodes"
            }
        }
        if mode == .level2Master {
            return "Enter Level 2 Master Key to unmask seed phrases"
        }
        return "Enter 4-digit PIN to access dashboard"
    }
    
    private func keypadButton(text: String) -> some View {
        Button(action: {
            appendDigit(text)
        }) {
            Text(text)
                .font(.system(size: isCompact ? 22 : 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: buttonDimension, height: buttonDimension)
                .background(
                    RoundedRectangle(cornerRadius: isCompact ? 18 : 22)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: isCompact ? 18 : 22)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(KeypadButtonStyle())
    }
    
    private func keypadIconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 18 : 22, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: buttonDimension, height: buttonDimension)
                .background(
                    RoundedRectangle(cornerRadius: isCompact ? 18 : 22)
                        .fill(Color.white.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: isCompact ? 18 : 22)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(KeypadButtonStyle())
    }
    
    private func biometricButton(icon: String) -> some View {
        Button(action: {
            authenticateWithBiometrics()
        }) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 22 : 26, weight: .medium))
                .foregroundColor(activeColor)
                .frame(width: buttonDimension, height: buttonDimension)
                .background(
                    RoundedRectangle(cornerRadius: isCompact ? 18 : 22)
                        .fill(activeColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: isCompact ? 18 : 22)
                                .stroke(activeColor.opacity(0.2), lineWidth: 1)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                processPasscode()
            }
        }
    }
    
    private func clearInput() {
        if !inputPasscode.isEmpty {
            inputPasscode.removeLast()
        }
    }
    
    private func processPasscode() {
        if isSetupMode {
            handleSetupStep()
            return
        }
        
        if mode == .level2Master {
            if vaultService.verifyLevel2(passcode: inputPasscode) {
                triggerSuccess()
            } else {
                triggerError()
            }
        } else {
            if vaultService.verifyLevel1(passcode: inputPasscode) {
                triggerSuccess()
            } else {
                triggerError()
            }
        }
    }
    
    private func handleSetupStep() {
        switch setupStep {
        case 0:
            tempLevel1 = inputPasscode
            inputPasscode = ""
            withAnimation { setupStep = 1 }
        case 1:
            if inputPasscode == tempLevel1 {
                inputPasscode = ""
                withAnimation { setupStep = 2 }
            } else {
                triggerError()
                setupStep = 0
            }
        case 2:
            tempLevel2 = inputPasscode
            inputPasscode = ""
            withAnimation { setupStep = 3 }
        case 3:
            if inputPasscode == tempLevel2 {
                vaultService.savePasscodes(level1: tempLevel1, level2: tempLevel2)
                triggerSuccess()
            } else {
                triggerError()
                setupStep = 2
            }
        default:
            break
        }
    }
    
    private func triggerSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isUnlocked = true
        }
        onComplete?()
    }
    
    private func triggerError() {
        withAnimation(.default) {
            isError = true
            attempts += 1
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            inputPasscode = ""
            isError = false
        }
    }
    
    private func checkBiometry() {
        let context = LAContext()
        var error: NSError?
        // iPod Touch does NOT support Touch ID or Face ID, so canEvaluatePolicy returns false
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .touchID {
                biometryIcon = "touchid"
            } else if context.biometryType == .faceID {
                biometryIcon = "faceid"
            }
        } else {
            biometryIcon = nil
        }
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return }
        
        let reason = "Unlock PodVault and decrypt credentials"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                if success {
                    self.triggerSuccess()
                }
            }
        }
    }
}

// Keypad Button Style
struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Shake Effect for Error Feedback
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0
        ))
    }
}

// Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
