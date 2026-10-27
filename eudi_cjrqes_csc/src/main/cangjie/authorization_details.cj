/*
 * OAuth2 `authorization_details` model — ports eudi-lib-ios-rqes-csc-swift
 * Sources/Requests/AuthorizationDetails.swift + Sources/Types/HashType.swift.
 *
 * Built in RqesKit's credential-authorization step and JSON-stringified into the
 * `authorization_details` query/form parameter. Two encodings of the same digests are
 * needed across the flow: base64url-no-padding for the authorize call, base64 for the
 * token call — hence copy(digestFormat:), which re-normalizes each digest via DigestNormalizer.
 *
 * Wire shape (Swift Codable): hashAlgorithmOID (RawRepresentable+Codable, single rawValue)
 * and hashType (enum:String) both encode as BARE STRINGS, not objects. nil optionals are
 * omitted (encodeIfPresent). AuthorizationDetails encodes as a top-level JSON array.
 */
package ohos_app_cangjie_eudi_cjrqes_csc

import std.collection.*
import stdx.encoding.json.*

// iOS: enum HashType: String { SDR, DTBSR, SODR }
public enum HashType {
    | SDR
    | DTBSR
    | SODR

    public func toRawValue(): String {
        return match (this) {
            case SDR => "SDR"
            case DTBSR => "DTBSR"
            case SODR => "SODR"
        }
    }

    public static func fromRawValue(s: String): ?HashType {
        return match (s) {
            case "SDR" => Some(SDR)
            case "DTBSR" => Some(DTBSR)
            case "SODR" => Some(SODR)
            case _ => None
        }
    }
}

// iOS: struct DocumentDigest. hashType defaults to .DTBSR; circumstantialData optional.
public struct DocumentDigest {
    public let label: String
    public let hash: String
    public let hashType: ?HashType
    public let circumstantialData: ?String

    public init(label!: String, hash!: String, hashType!: ?HashType = Some(HashType.DTBSR),
                circumstantialData!: ?String = None) {
        this.label = label
        this.hash = hash
        this.hashType = hashType
        this.circumstantialData = circumstantialData
    }

    // Format-aware: normalizes `hash` to `output`. iOS: init(label:hash:output:hashType:circumstantialData:).
    public init(label!: String, hash!: String, output!: DigestFormat,
                hashType!: ?HashType = Some(HashType.DTBSR), circumstantialData!: ?String = None) {
        this.label = label
        this.hash = DigestNormalizer.normalize(hash, to: output)
        this.hashType = hashType
        this.circumstantialData = circumstantialData
    }

    public static func forAuthorization(label: String, hash: String): DocumentDigest {
        return DocumentDigest(label: label, hash: hash, output: DigestFormat.Base64UrlNoPadding)
    }
    public static func forToken(label: String, hash: String): DocumentDigest {
        return DocumentDigest(label: label, hash: hash, output: DigestFormat.Base64)
    }
    public static func forSigning(label: String, hash: String): DocumentDigest {
        return DocumentDigest(label: label, hash: hash, output: DigestFormat.Base64)
    }

    func toJson(): JsonObject {
        let obj = JsonObject()
        obj.put("label", JsonString(label))
        obj.put("hash", JsonString(hash))
        match (hashType) {
            case Some(ht) => obj.put("hashType", JsonString(ht.toRawValue()))
            case None => ()
        }
        match (circumstantialData) {
            case Some(cd) => obj.put("circumstantialData", JsonString(cd))
            case None => ()
        }
        return obj
    }
}

// iOS: struct AuthorizationDetailsItem. `type` is a Cangjie keyword → field detailType (JSON key "type").
public struct AuthorizationDetailsItem {
    public let documentDigests: Array<DocumentDigest>
    public let credentialID: String
    public let hashAlgorithmOID: HashAlgorithmOID
    public let locations: Array<String>
    public let detailType: String
    public let numSignatures: Int64

    public init(documentDigests!: Array<DocumentDigest>, credentialID!: String,
                hashAlgorithmOID!: HashAlgorithmOID, locations!: Array<String>,
                detailType!: String, numSignatures!: Int64 = 1) {
        this.documentDigests = documentDigests
        this.credentialID = credentialID
        this.hashAlgorithmOID = hashAlgorithmOID
        this.locations = locations
        this.detailType = detailType
        this.numSignatures = numSignatures
    }

    // Re-normalize every digest's hash into `digestFormat`. iOS: copy(digestFormat:).
    public func copy(digestFormat!: DigestFormat): AuthorizationDetailsItem {
        let converted = ArrayList<DocumentDigest>()
        for (d in documentDigests) {
            converted.add(DocumentDigest(label: d.label, hash: d.hash, output: digestFormat,
                                         hashType: d.hashType, circumstantialData: d.circumstantialData))
        }
        return AuthorizationDetailsItem(
            documentDigests: converted.toArray(), credentialID: credentialID,
            hashAlgorithmOID: hashAlgorithmOID, locations: locations, detailType: detailType,
            numSignatures: numSignatures)
    }

    func toJson(): JsonObject {
        let obj = JsonObject()
        var digs = JsonArray()
        for (d in documentDigests) {
            digs = digs.add(d.toJson())
        }
        obj.put("documentDigests", digs)
        obj.put("credentialID", JsonString(credentialID))
        obj.put("hashAlgorithmOID", JsonString(hashAlgorithmOID.rawValue))
        var locs = JsonArray()
        for (l in locations) {
            locs = locs.add(JsonString(l))
        }
        obj.put("locations", locs)
        obj.put("type", JsonString(detailType))
        obj.put("numSignatures", JsonInt(numSignatures))
        return obj
    }
}

// iOS: typealias AuthorizationDetails = [AuthorizationDetailsItem]. Encoded as a JSON array.
public struct AuthorizationDetails {
    public let items: Array<AuthorizationDetailsItem>
    public init(items: Array<AuthorizationDetailsItem>) { this.items = items }

    // iOS: authorizationDetails.compactMap { $0.copy(digestFormat:) }.
    public func copy(digestFormat!: DigestFormat): AuthorizationDetails {
        let out = ArrayList<AuthorizationDetailsItem>()
        for (it in items) {
            out.add(it.copy(digestFormat: digestFormat))
        }
        return AuthorizationDetails(out.toArray())
    }

    // iOS: JSONUtils.stringify(authorizationDetails) — a top-level JSON array.
    public func toJsonString(): String {
        var arr = JsonArray()
        for (it in items) {
            arr = arr.add(it.toJson())
        }
        return arr.toJsonString()
    }
}
