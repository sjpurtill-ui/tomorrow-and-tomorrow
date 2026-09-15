import Foundation
import Security
import Darwin

// Secrets travel over a private pipe, never arguments, files, or diagnostic logs.
alarm(8)
SecKeychainSetUserInteractionAllowed(false)
let service = "com.tomorrowandtomorrow.ai-connection"
let account = "local-player"
func query(_ keychain: SecKeychain? = nil) -> [String: Any] {
    var q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service, kSecAttrAccount as String: account]
    if let keychain = keychain { q[kSecMatchSearchList as String] = [keychain] }
    return q
}
func save(_ data: Data, _ keychain: SecKeychain? = nil) -> OSStatus {
    let q = query(keychain)
    let result = SecItemUpdate(q as CFDictionary, [kSecValueData as String: data] as CFDictionary)
    if result != errSecItemNotFound { return result }
    var add = q
    add.removeValue(forKey: kSecMatchSearchList as String)
    if let keychain = keychain { add[kSecUseKeychain as String] = keychain }
    add[kSecValueData as String] = data
    add[kSecAttrLabel as String] = "Tomorrow and Tomorrow — AI connection"
    return SecItemAdd(add as CFDictionary, nil)
}
func read(_ keychain: SecKeychain? = nil) -> (OSStatus, Data?) {
    var q = query(keychain)
    q[kSecReturnData as String] = true
    q[kSecMatchLimit as String] = kSecMatchLimitOne
    var value: CFTypeRef?
    let status = SecItemCopyMatching(q as CFDictionary, &value)
    return (status, value as? Data)
}
func emit(_ value: [String: Any]) {
    let bytes = try! JSONSerialization.data(withJSONObject: value)
    FileHandle.standardOutput.write(bytes)
    FileHandle.standardOutput.write(Data([10]))
}
let action = CommandLine.arguments.dropFirst().first ?? ""
if action == "self-test" {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var previous: CFArray?
    SecKeychainCopySearchList(&previous)
    var temporary: SecKeychain?
    let password = "isolated-test-only"
    let created = password.withCString { SecKeychainCreate(directory.appendingPathComponent("test.keychain").path, UInt32(password.utf8.count), $0, false, nil, &temporary) }
    var passed = created == errSecSuccess
    if let temporary = temporary {
        let first = Data("dummy-one".utf8), second = Data("dummy-two".utf8)
        passed = passed && save(first, temporary) == errSecSuccess
        passed = passed && read(temporary).1 == first
        passed = passed && save(second, temporary) == errSecSuccess
        passed = passed && read(temporary).1 == second
        passed = passed && SecItemDelete(query(temporary) as CFDictionary) == errSecSuccess
        passed = passed && read(temporary).0 == errSecItemNotFound
        SecKeychainDelete(temporary)
    }
    if let previous = previous { SecKeychainSetSearchList(previous) }
    try? FileManager.default.removeItem(at: directory)
    emit(["ok": passed]); exit(passed ? 0 : 1)
}
var status: OSStatus = errSecParam
if action == "read" {
    let result = read(); status = result.0
    if status == errSecSuccess, let bytes = result.1,
       let connection = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any] {
        emit(["ok": true, "connection": connection]); exit(0)
    }
} else if action == "save", let line = readLine(), line.utf8.count <= 16384,
          let bytes = line.data(using: .utf8),
          let data = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
          let key = data["key"] as? String, !key.isEmpty, key.count <= 8192 {
    status = save(bytes)
} else if action == "delete" {
    status = SecItemDelete(query() as CFDictionary)
    if status == errSecItemNotFound { status = errSecSuccess }
}
emit(["ok": status == errSecSuccess, "code": Int(status)])
exit(status == errSecSuccess || status == errSecItemNotFound ? 0 : 1)
