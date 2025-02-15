//
//  Biometrics.swift
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
@Observable
@MainActor
public class Biometrics {
  public private(set) var isBiometricsAvailable: Bool = false
  public private(set) var biometryType: LABiometryType = .none

  public init() {
    checkBiometricAvailability()
  }

  public func authenticate(localizedReason: String) async throws -> Bool {
    try await evaluatePolicy(localizedReason: localizedReason)
  }

  private func checkBiometricAvailability() {
    let context = LAContext()
    var error: NSError?

    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      self.isBiometricsAvailable = true
      self.biometryType = context.biometryType
    } else {
      self.isBiometricsAvailable = false
      self.biometryType = .none
    }
  }

  private func evaluatePolicy(localizedReason: String) async throws -> Bool {
    let context = LAContext()
    return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason)
  }

  public var biometryName: String {
    switch biometryType {
    case .faceID:
      return "Face ID"
    case .touchID:
      return "Touch ID"
    default:
      return String(localized: "Biometric Authentication")
    }
  }

  /// SFSymbol name corresponding to the biometryType for this device
  public var biometryIcon: String {
    switch biometryType {
    case .faceID:
      return "faceid"
    case .touchID:
      return "touchid"
    default:
      return "lock.shield"
    }
  }
}
