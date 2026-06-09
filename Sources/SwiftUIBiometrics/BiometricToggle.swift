//
//  BiometricToggle.swift
//  SwiftUIBiometrics
//
//  Created by Théo Arrouye on 2/14/25.
//

import SwiftUI
import LocalAuthentication

@available(macOS 14.0, *)
@available(iOS 17.0, *)
@available(macCatalyst 17.0, *)
@available(visionOS 1.0, *)
public struct BiometricToggle<Content: View>: View {

  @Environment(Biometrics.self) private var biometrics

  @Binding private var isEnabled: Bool
  @State private var isToggling = false
  @State private var showAlert = false
  @State private var alertMessage = ""
  @State private var showSettingsAlert = false

  let label: () -> Content

  public init(isEnabled: Binding<Bool>, @ViewBuilder label: @escaping () -> Content) {
    _isEnabled = isEnabled
    self.label = label
  }

  public var body: some View {
    Toggle(isOn: Binding(
      get: { isEnabled },
      set: { _ in isToggling = true }
    )) {
      label()
    }
    .disabled(!biometrics.isBiometricsAvailable || isToggling)
    .onChange(of: isToggling) { _, newValue in
      if newValue {
        Task {
          await toggleProtection()
        }
      }
    }
    .alert(isPresented: $showAlert) {
      Alert(
        title: Text("Biometric Protection"),
        message: Text(alertMessage),
        dismissButton: .default(Text("OK"))
      )
    }
    .withBioSettingsPermissionAlert(isPresented: $showSettingsAlert)
  }

  private func toggleProtection() async {
    let toggled = !isEnabled

    do {
      let enableString = toggled ? String(localized: "Enable") : String(localized: "Disable")
      let success = try await biometrics.authenticate(localizedReason: String(localized: "\(enableString) biometric protection for this screen"))
      await MainActor.run {
        if success {
          isEnabled = toggled
        } else {
          showError(toggled: toggled)
        }

        isToggling = false
      }
    } catch {
      await MainActor.run {
        if biometrics.isBiometricsAvailable, let laError = error as? LAError, laError.code == .biometryNotAvailable {
          showSettingsAlert = true
        } else {
          showError(toggled: toggled)
        }
        isToggling = false
      }
    }
  }

  private func showError(toggled: Bool) {
    let enableString = toggled ? String(localized: "enable") : String(localized: "disable")
    alertMessage = String(localized: "Unable to \(enableString) \(biometrics.biometryName) protection. Please try again.")
    showAlert = true
  }
}

extension View {
  func withBioSettingsPermissionAlert(isPresented: Binding<Bool>) -> some View {
    alert(String(localized: "Permission Denied"), isPresented: isPresented) {
      Button(String(localized: "Cancel"), role: .cancel) { }
      Button(String(localized: "Open Settings")) {
        Biometrics.openSettings()
      }
    } message: {
      Text(String(localized: "Biometric authentication is denied. Please enable it in Settings."))
    }
  }
}
