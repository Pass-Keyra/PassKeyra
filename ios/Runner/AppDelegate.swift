import Flutter
import UIKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let biometricKeywrapChannelName = "biometric_keywrap"
  private let keychainService = "com.passkeyra.biometric_keywrap"
  private let keychainAccount = "session_key_v1"
  private let keyReferenceToken = "ios_key_ref_v1"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: biometricKeywrapChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(FlutterError(code: "IOS_DEALLOC", message: "AppDelegate indisponible", details: nil))
          return
        }
        switch call.method {
        case "wrapKeyMaterial":
          guard
            let args = call.arguments as? [String: Any],
            let plaintextBase64 = args["plaintextBase64"] as? String,
            let plaintext = Data(base64Encoded: plaintextBase64)
          else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "plaintextBase64 manquant", details: nil))
            return
          }
          do {
            try self.storeWrappedKeyMaterial(plaintext)
            let tokenBase64 = Data(self.keyReferenceToken.utf8).base64EncodedString()
            result(tokenBase64)
          } catch {
            result(FlutterError(code: "IOS_WRAP_ERROR", message: error.localizedDescription, details: nil))
          }

        case "unwrapKeyMaterial":
          guard
            let args = call.arguments as? [String: Any],
            let wrappedBase64 = args["wrappedBase64"] as? String,
            let tokenData = Data(base64Encoded: wrappedBase64),
            let token = String(data: tokenData, encoding: .utf8),
            token == self.keyReferenceToken
          else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "wrappedBase64 invalide", details: nil))
            return
          }
          do {
            let rawKey = try self.readWrappedKeyMaterial()
            result(rawKey.base64EncodedString())
          } catch {
            result(FlutterError(code: "IOS_UNWRAP_ERROR", message: error.localizedDescription, details: nil))
          }

        case "clearWrappingKey":
          self.deleteWrappedKeyMaterial()
          result(nil)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func storeWrappedKeyMaterial(_ plaintext: Data) throws {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount
    ]

    let update: [String: Any] = [
      kSecValueData as String: plaintext,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]

    let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
    if updateStatus == errSecSuccess {
      return
    }
    if updateStatus != errSecItemNotFound {
      throw NSError(
        domain: NSOSStatusErrorDomain,
        code: Int(updateStatus),
        userInfo: [NSLocalizedDescriptionKey: "Keychain update failed (\(updateStatus))"]
      )
    }

    query[kSecValueData as String] = plaintext
    query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    let addStatus = SecItemAdd(query as CFDictionary, nil)
    if addStatus != errSecSuccess {
      throw NSError(
        domain: NSOSStatusErrorDomain,
        code: Int(addStatus),
        userInfo: [NSLocalizedDescriptionKey: "Keychain add failed (\(addStatus))"]
      )
    }
  }

  private func readWrappedKeyMaterial() throws -> Data {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess else {
      throw NSError(
        domain: NSOSStatusErrorDomain,
        code: Int(status),
        userInfo: [NSLocalizedDescriptionKey: "Keychain read failed (\(status))"]
      )
    }
    guard let data = item as? Data else {
      throw NSError(
        domain: "PassKeyraKeywrap",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Keychain item has invalid format"]
      )
    }
    return data
  }

  private func deleteWrappedKeyMaterial() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount
    ]
    SecItemDelete(query as CFDictionary)
  }
}
