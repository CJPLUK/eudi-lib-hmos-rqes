/*
 * Digest normalization — ports eudi-lib-ios-rqes-csc-swift Sources/Responses/
 * DocumentDigestsResponse.swift's DigestFormat + DigestNormalizer.
 *
 * PodofoSigner.calculateHash emits a base64url (sometimes percent-encoded) hash, but
 * the CSC signHash call and the token-phase authorization_details need specific formats:
 *   - base64            : standard, padded — used for signHash + token authorization_details
 *   - base64UrlNoPadding: url-safe, no '=' — used for the authorize-phase authorization_details
 * DigestNormalizer decodes whatever form it is given (standard base64, base64url, or
 * percent-encoded) and re-encodes to the requested target. Without it signHash would send
 * a wrong-format hash and the QTSP would reject the signature.
 *
 * base64 codec reused: stdx toBase64String/fromBase64String (standard) + core_crypto
 * Base64Url.encode/decode (url-safe no-pad).
 */
package ohos_app_cangjie_eudi_cjrqes_csc

import std.collection.*
import stdx.encoding.base64.*
import eudi_lib_core_crypto.Base64Url

// iOS: enum DigestFormat { case base64; case base64URLNoPadding }
public enum DigestFormat {
    | Base64
    | Base64UrlNoPadding
}

// iOS: internal enum DigestNormalizer.
public class DigestNormalizer {
    // Decode `input` (standard base64 / base64url / percent-encoded) and re-encode to `format`.
    // iOS: DigestNormalizer.normalize(_:to:).
    public static func normalize(input: String, to!: DigestFormat): String {
        let trimmed = trimWhitespace(input)
        if (trimmed.isEmpty()) {
            throw RqesCscException("Digest must not be blank")
        }
        // Accept percent-encoded input too (iOS: removingPercentEncoding).
        let decodedText = percentDecode(trimmed)

        // Try standard Base64 first.
        match (fromBase64String(decodedText)) {
            case Some(data) => return encode(data, to)
            case None => ()
        }
        // Then Base64URL (no padding, -/_).
        try {
            let data = Base64Url.decode(decodedText)
            return encode(data, to)
        } catch (_: Exception) {
            throw RqesCscException("Digest must be a valid Base64 or Base64URL encoded string")
        }
    }

    static func encode(data: Array<UInt8>, format: DigestFormat): String {
        return match (format) {
            case Base64 => toBase64String(data)
            case Base64UrlNoPadding => Base64Url.encode(data)
        }
    }
}

// Trim leading/trailing whitespace + newlines (iOS: .whitespacesAndNewlines).
func trimWhitespace(s: String): String {
    let bytes = s.toArray()
    var lo = 0
    var hi = bytes.size
    while (lo < hi && isWs(bytes[lo])) { lo += 1 }
    while (hi > lo && isWs(bytes[hi - 1])) { hi -= 1 }
    if (lo == 0 && hi == bytes.size) { return s }
    return String.fromUtf8(bytes[lo..hi])
}

func isWs(b: UInt8): Bool {
    return b == b' ' || b == b'\t' || b == b'\n' || b == b'\r'
}

// Percent-decode "%XX" escapes; leaves everything else untouched. iOS: removingPercentEncoding.
func percentDecode(s: String): String {
    let bytes = s.toArray()
    let out = ArrayList<UInt8>()
    var i = 0
    while (i < bytes.size) {
        if (bytes[i] == b'%' && i + 2 < bytes.size) {
            let hi = hexVal(bytes[i + 1])
            let lo = hexVal(bytes[i + 2])
            if (hi >= 0 && lo >= 0) {
                out.add(UInt8(hi * 16 + lo))
                i += 3
                continue
            }
        }
        out.add(bytes[i])
        i += 1
    }
    return String.fromUtf8(out.toArray())
}

func hexVal(b: UInt8): Int64 {
    if (b >= b'0' && b <= b'9') { return Int64(b - b'0') }
    if (b >= b'a' && b <= b'f') { return Int64(b - b'a') + 10 }
    if (b >= b'A' && b <= b'F') { return Int64(b - b'A') + 10 }
    return -1
}
