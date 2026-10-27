/*
 * uuid.cj — RFC 4122 v4 UUID string, standing in for iOS `UUID().uuidString`.
 *
 * Used for the OAuth2 `state` (CSRF token) and for temp output filenames. iOS uses
 * Foundation UUID; we build the same 8-4-4-4-12 lowercase-hex form from 16 secure-random
 * bytes (core_crypto Rng, the same CSPRNG the reused PKCE generator draws from).
 */
package ohos_app_cangjie_eudi_cjrqes_kit

import eudi_lib_core_crypto.Rng

public func uuidV4(): String {
    let b = Rng.bytes(16)
    // Version 4 + RFC 4122 variant bits.
    b[6] = (b[6] & 0x0F) | 0x40
    b[8] = (b[8] & 0x3F) | 0x80
    let sb = StringBuilder()
    for (i in 0..16) {
        if (i == 4 || i == 6 || i == 8 || i == 10) {
            sb.append("-")
        }
        sb.append(hex2(b[i]))
    }
    return sb.toString()
}

func hex2(b: UInt8): String {
    let digits = "0123456789abcdef".toArray()
    return String.fromUtf8([digits[Int64(b >> 4)], digits[Int64(b & 0x0F)]])
}
