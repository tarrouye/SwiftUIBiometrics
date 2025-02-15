//
//  BiometricProtectionModifier.swift
//  Vapor
//
//  Created by Théo Arrouye on 2/14/25.
//

#if canImport(SwiftUI) && canImport(LocalAuthentication)

import SwiftUI
import LocalAuthentication

@available(macOS 14.0, *)
@available(iOS 17.0, *)
@available(macCatalyst 17.0, *)
@available(visionOS 1.0, *)
private struct BiometricProtectionModifier: ViewModifier {
  @State private var biometrics = Biometrics()

  @State private var isUnlocked: Bool = false
  @State private var error: String? = nil
  @State private var showingAlert = false

  @State private var authTrigger: Bool = false

  private let localizedReason: String
  private let titleFont: Font
  private let subtitleFont: Font
  private let buttonFont: Font
  private let accentColor: Color

  init(
    isUnlocked: Bool,
    titleFont: Font,
    subtitleFont: Font,
    buttonFont: Font,
    accentColor: Color,
    localizedReason: String
  ) {
    self.isUnlocked = isUnlocked
    self.titleFont = titleFont
    self.subtitleFont = subtitleFont
    self.buttonFont = buttonFont
    self.accentColor = accentColor
    self.localizedReason = localizedReason
  }

  func body(content: Content) -> some View {
    if isUnlocked {
      content
    } else {
      lockedView
    }
  }

  private var lockedView: some View {
    lockedContent
      .padding()
      .task(id: authTrigger) {
        guard !isUnlocked else { return }
        await authenticate()
      }
      .alert(isPresented: $showingAlert) {
        Alert(
          title: Text("Authentication Failed"),
          message: Text(error ?? "Please try again"),
          dismissButton: .default(Text("OK"))
        )
      }
  }

  private var lockedContent: some View {
    VStack(spacing: 20) {
      // Dynamic icon based on available biometry
      Image(systemName: biometrics.biometryIcon)
        .font(.system(size: 56))
        .foregroundStyle(accentColor)

      Text("\(biometrics.biometryName) Required")
        .font(titleFont)
        .fontWeight(.semibold)

      Text("Please authenticate to continue")
        .font(subtitleFont)
        .foregroundColor(.secondary)

      Button {
        authTrigger.toggle()
      } label: {
        Text("Continue")
      }
      .font(buttonFont)
      .buttonStyle(.bordered)
      .buttonBorderShape(.capsule)
      .tint(accentColor)
      .padding(.top, 20)
    }
  }

  private func authenticate() async {
    if biometrics.isBiometricsAvailable {
      do {
        let success = try await biometrics.authenticate(localizedReason: localizedReason)

        await MainActor.run {
          if success {
            isUnlocked = true
          } else {
            setError(String(localized: "Authentication failed"))
          }
        }
      } catch {
        await MainActor.run {
          handleAuthenticationError(error)
        }
      }
    } else {
      // Biometric authentication not available
      await MainActor.run {
        setError(String(localized: "Biometric authentication is not available on this device."))
      }
    }
  }

  private func handleAuthenticationError(_ error: Error) {
    if let laError = error as? LAError {
      handleLAError(laError)
    } else {
      setError(String(localized: "Authentication failed: \(error.localizedDescription)"))
    }
  }

  private func handleLAError(_ error: LAError) {
    switch error.code {
    case .authenticationFailed:
      setError(String(localized: "\(biometrics.biometryName) did not recognize you"))
    case .userCancel:
      setError(String(localized: "You canceled \(biometrics.biometryName) authentication"))
    case .userFallback:
      setError(String(localized: "You chose to use password instead"))
    case .biometryNotAvailable:
      setError(String(localized: "\(biometrics.biometryName) is not available on this device"))
    case .biometryNotEnrolled:
      setError(String(localized: "You haven't set up \(biometrics.biometryName) on this device"))
    case .biometryLockout:
      setError(String(localized: "\(biometrics.biometryName) is locked out due to too many failed attempts"))
    default:
      setError(String(localized: "Authentication failed: \(error.localizedDescription)"))
    }
  }

  @MainActor
  private func setError(_ errorMessage: String) {
    error = errorMessage
    showingAlert = true
  }
}

// Extension to make it easier to use
@available(macOS 14.0, *)
@available(iOS 17.0, *)
@available(macCatalyst 17.0, *)
@available(visionOS 1.0, *)
public extension View {
  func biometricProtection(
    isUnlocked: Bool = false,
    titleFont: Font = .title2,
    subtitleFont: Font = .body,
    buttonFont: Font = .headline,
    accentColor: Color = Color.accentColor,
    localizedReason: String = String(localized: "Authenticate to access this content")
  ) -> some View {
    modifier(
      BiometricProtectionModifier(
        isUnlocked: isUnlocked,
        titleFont: titleFont,
        subtitleFont: subtitleFont,
        buttonFont: buttonFont,
        accentColor: accentColor,
        localizedReason: localizedReason
      )
    )
  }
}
#endif
