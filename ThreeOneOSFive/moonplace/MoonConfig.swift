import Foundation

/// Configuración central de Moon Place.
///
/// ⚠️ IMPORTANTE — antes de compilar, reemplaza `keyAuthAppName` y `keyAuthOwnerID`
/// con los datos de tu aplicación en https://keyauth.cc
/// (Dashboard → tu app → Settings → "Application Name" y "Owner ID").
enum MoonConfig {
    static let keyAuthAppName = "moonexternal"
    static let keyAuthOwnerID = "SQc5dKoope"
    static let keyAuthSecret = "f19bf244f73f3a81f3877c3aaf42f3a7e526d90a83795845412f7194e27fb617"
    static let keyAuthAppVersion = "1.0"
    static let keyAuthAPIURL = "https://keyauth.cc/api/1.3/"

    static let placeName = "Moon Place"
}
