//
//  BiometricToggle.swift
//  SwiftUIBiometrics
//
//  Created by Théo Arrouye on 2/14/25.
//

import SwiftUI

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
        showError(toggled: toggled)
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
