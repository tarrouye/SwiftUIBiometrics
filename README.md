## SwiftUIBiometrics

A lightweight library to easily protect screens in your SwiftUI app with Biometric auth.

### Installation


### Usage
Add `https://github.com/tarrouye/SwiftUIBiometrics` in the [“Swift Package Manager” tab in Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).


#### Protecting a screen
To protect a screen with biometrics, simply apply the `.biometricProtection` modifier to it

```
func biometricProtection(
  isUnlocked: Bool = false,
  titleFont: Font = .title2,
  subtitleFont: Font = .body,
  buttonFont: Font = .headline,
  accentColor: Color = Color.accentColor,
  localizedReason: String = String(localized: "Authenticate to access this content")
) -> some View { }
```

You can optionally pass `isUnlocked` to pre-unlock the screen. For example, if the biometric protection is enabled/disabled by a user setting. 

You can also pass several fonts and a color to customize the UI of the screen, as well as a reason to pass along to the LocalAuthentication request. 

#### Protecting a toggle
```
BiometricToggle<Content: View>(
  isEnabled: Binding<Bool>, 
  @ViewBuilder label: @escaping () -> Content
) {
  _isEnabled = isEnabled
  self.label = label
}
```

Works similarly to `SwiftUI.Toggle`, but toggling the switch will be protected by biometric auth. 

This is perfect to use in a settings view where you allow the user to enable/disable biometric protection for other screens.

To use a `BiometricToggle`, you must inject a `Biometrics` object into the `Environment`. 

```
@State var biometrics = Biometrics()
@State var isToggleEnabled: Bool = false
@State var isToggleEnabled2: Bool = false

[...]

var body: some View {
  VStack {
    BiometricToggle(isEnabled: $isToggleEnabled) {
      Text("Enable protection")
    }

    BiometricToggle(isEnabled: $isToggleEnabled2) {
      Text("Enable protection 2")
    }
  }
  .environment(biometrics)
}
```

#### Full Example

Full Example, using @AppStorage to persist setting state

```
import SwiftUI
import SwiftUIBiometrics

struct ExampleView: View {
  @State private var biometrics = Biometrics()

  @AppStorage("protectDetails") private var shouldProtectDetails: Bool = false

  var body: some View {
    NavigationStack {
      if biometrics.isBiometricsAvailable {
        BiometricToggle(isEnabled: $shouldProtectDetails) {
          VStack(alignment: .leading) {
            Text("Protect Details with \(biometrics.biometryName)")

            Text("Require authentication to access details view")
              .foregroundStyle(.gray)
          }
        }
        .padding()

        NavigationLink("Show Details") {
          DetailsView()
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
      } else {
        Text("Biometrics are not available on this device.")
      }
    }
    .environment(biometrics)

  }
}

struct DetailsView: View {
  @AppStorage("protectDetails") private var shouldProtectDetails: Bool = false

  var body: some View {
      Text("Sensitive content")
      .padding()
      .biometricProtection(isUnlocked: !shouldProtectDetails)
  }
}

#Preview {
  ExampleView()
}
```
