# PodVault 🔐

> **Turn your iPod Touch into a dedicated, air-gapped crypto hardware vault and live portfolio tracker.**

PodVault is a purpose-built Swift/SwiftUI iOS application engineered specifically for compact devices—optimised from **iPod Touch 7th Gen onward (iOS 15.0+)** to modern iPhones. It transforms legacy or dedicated secondary Apple devices into hardened crypto companions.

---

## 🛡️ Two-Tier Security Architecture

PodVault separates routine glanceability from deep key custody using two strictly isolated security barriers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PODVAULT SECURITY MODEL                         │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  [ Level 1: Gatekeeper PIN (4 Digits) ]                                │
│  └─ Daily portfolio valuation, live balance checks via JSON-RPC        │
│  └─ Sparkline market charts & interactive NFT gallery                  │
│  └─ Watch-only mode: Zero private keys or seed phrases unmasked        │
│                                                                        │
│  ───────────────────────────────────────────────────────────────────   │
│                                                                        │
│  [ Level 2: Cold Vault Master Passcode ]                               │
│  └─ Gated behind separate master passcode                              │
│  └─ Master seed phrases (BIP-39), private keys, hardware PINs          │
│  └─ Ephemeral memory & auto-locks immediately upon backgrounding       │
│  └─ Backed by secure iOS Keychain enclave                             │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

1. **First-Launch Setup Wizard**: When freshly installed, the wizard guides the user through setting and confirming both the Level 1 Gatekeeper PIN and the Level 2 Master Passcode before any wallet or keys can be entered.
2. **Level 1 (Gatekeeper PIN)**: Fast daily unlock for monitoring portfolio balances, crypto market sparklines, and NFT collectibles without exposing sensitive credentials.
3. **Level 2 (Deep Cold Vault)**: Isolated section requiring the distinct master passcode to view, copy, or export private keys, recovery phrases, and hardware PINs. Automatically re-seals as soon as the app transitions to the background.
4. **Biometric Agnostic**: Intelligently detects biometric hardware. Operates seamlessly on iPod Touch (which lacks Touch ID / Face ID) while supporting biometrics if run on modern iPhones or iPads.

---

## 📱 Hardware & OS Compatibility

- **Target Deployment**: iOS 15.0+
- **Primary Target Device**: iPod Touch (7th Generation, Apple A10 Fusion, 4.0-inch Retina Display: 320 × 568 pt)
- **Compact UI Engine**: Every screen, modal, and numpad is dynamically proportioned with adaptive typography and scrollable layouts to eliminate clipping or vertical squishing on 4.0" displays.
- **Zero iOS 16+ Hard Dependencies**: Uses universal SwiftUI modifiers compatible across iOS 15 through iOS 18+.

---

## ⚡ Core Features

- **Live Ethereum Balance Lookups**: Integrated direct Ethereum JSON-RPC client fetching live on-chain balances without relying on centralized API keys.
- **WalletConnect v2 Ready**: Infrastructure configured for dApp connections and remote signing workflows.
- **Visual Sparkline Analytics**: Live portfolio tracking with price change deltas and clean SVG-style sparkline charts.
- **Curated NFT Gallery**: High-resolution digital collectible viewing with full metadata breakdowns.
- **Dark Glassmorphic UI**: High-contrast, cyber-minimalist design tailored for distraction-free security operations.

---

## 🛠️ Build & Installation

### Prerequisites

- macOS with Xcode 15+ installed
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Building from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/PopusoiIonut/PodVault.git
   cd PodVault
   ```

2. **Generate the Xcode Project**:
   ```bash
   xcodegen generate
   ```

3. **Open in Xcode & Deploy**:
   ```bash
   open PodVault.xcodeproj
   ```
   Select your connected iPod Touch or iOS device in Xcode and press `Cmd + R` to build and deploy.

---

## 📄 License

Proprietary / BitForge Security.
