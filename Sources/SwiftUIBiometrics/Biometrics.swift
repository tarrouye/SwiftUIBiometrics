//
//  Biometrics.swift
//  SwiftUIBiometrics
//
//  Created by Théo Arrouye on 2/14/25.
//

import SwiftUI
import LocalAuthentication
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
    
    self.biometryType = context.biometryType
    self.isBiometricsAvailable = context.biometryType != .none
  }

  private func evaluatePolicy(localizedReason: String) async throws -> Bool {
    let context = LAContext()
    return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason)
  }

  public static func openSettings() {
    #if os(iOS) || os(visionOS)
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
    #elseif os(macOS)
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Biometrics") {
      NSWorkspace.shared.open(url)
    }
    #endif
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
