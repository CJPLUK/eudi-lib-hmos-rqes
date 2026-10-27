/*
 * CSC value types — 1:1 port of eudi-lib-ios-rqes-csc-swift Sources/Types.
 *
 * iOS models these as `RawRepresentable` structs over a String rawValue (an OPEN
 * set: any string is a valid value; the statics are just well-known constants),
 * NOT closed enums. We mirror that exactly with a String-wrapping struct so an
 * unknown value from the wire round-trips unchanged, matching iOS.
 */
package ohos_app_cangjie_eudi_cjrqes_csc

// Digest algorithm OID (CSC `hashAlgorithmOID`). iOS: Types/HashAlgorithmOID.swift
public struct HashAlgorithmOID <: ToString & Equatable<HashAlgorithmOID> {
    public let rawValue: String
    public init(rawValue: String) { this.rawValue = rawValue }
    public func toString(): String { rawValue }
    public operator func ==(o: HashAlgorithmOID): Bool { rawValue == o.rawValue }
    public operator func !=(o: HashAlgorithmOID): Bool { rawValue != o.rawValue }

    public static let SHA224: HashAlgorithmOID = HashAlgorithmOID("2.16.840.1.101.3.4.2.4")
    public static let SHA256: HashAlgorithmOID = HashAlgorithmOID("2.16.840.1.101.3.4.2.1")
    public static let SHA384: HashAlgorithmOID = HashAlgorithmOID("2.16.840.1.101.3.4.2.2")
    public static let SHA512: HashAlgorithmOID = HashAlgorithmOID("2.16.840.1.101.3.4.2.3")
    public static let SHA3_224: HashAlgorithmOID = HashAlgorithmOID("2.16.840.1.101.3.4.2.7")
    public static let SHA3_256: HashAlgorithmOID = HashAlgorithmOID("2.16.840.1.101.3.4.2.8")
    public static let SHA3_384: HashAlgorithmOID = HashAlgorithmOID("2.16.840.1.101.3.4.2.9")
    public static let SHA3_512: HashAlgorithmOID = HashAlgorithmOID("2.16.840.1.101.3.4.2.10")
    public static let MD2: HashAlgorithmOID = HashAlgorithmOID("1.2.840.113549.2.2")
    public static let MD5: HashAlgorithmOID = HashAlgorithmOID("1.2.840.113549.2.5")
}

// Signing algorithm OID (CSC `signAlgo`). iOS: Types/SigningAlgorithmOID.swift
public struct SigningAlgorithmOID <: ToString & Equatable<SigningAlgorithmOID> {
    public let rawValue: String
    public init(rawValue: String) { this.rawValue = rawValue }
    public func toString(): String { rawValue }
    public operator func ==(o: SigningAlgorithmOID): Bool { rawValue == o.rawValue }
    public operator func !=(o: SigningAlgorithmOID): Bool { rawValue != o.rawValue }

    public static let RSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.113549.1.1.1")
    public static let SHA256WithRSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.113549.1.1.11")
    public static let SHA384WithRSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.113549.1.1.12")
    public static let SHA512WithRSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.113549.1.1.13")
    public static let ECDSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.10045.2.1")
    public static let SHA256WithECDSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.10045.4.3.2")
    public static let SHA384WithECDSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.10045.4.3.3")
    public static let SHA512WithECDSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.10045.4.3.4")
    public static let DSA: SigningAlgorithmOID = SigningAlgorithmOID("1.2.840.10040.4.1")
    public static let X25519: SigningAlgorithmOID = SigningAlgorithmOID("1.3.101.110")
    public static let X448: SigningAlgorithmOID = SigningAlgorithmOID("1.3.101.111")
}

// PAdES/CAdES conformance level. iOS: Types/ConformanceLevel.swift
public struct ConformanceLevel <: ToString & Equatable<ConformanceLevel> {
    public let rawValue: String
    public init(rawValue: String) { this.rawValue = rawValue }
    public func toString(): String { rawValue }
    public operator func ==(o: ConformanceLevel): Bool { rawValue == o.rawValue }
    public operator func !=(o: ConformanceLevel): Bool { rawValue != o.rawValue }

    public static let ADES_B_B: ConformanceLevel = ConformanceLevel("ADES_B_B")
    public static let ADES_B_T: ConformanceLevel = ConformanceLevel("ADES_B_T")
    public static let ADES_B_LT: ConformanceLevel = ConformanceLevel("ADES_B_LT")
    public static let ADES_B_LTA: ConformanceLevel = ConformanceLevel("ADES_B_LTA")
}

// Signature container format (CSC `signature_format`). iOS: Types/SignatureFormat.swift
// C=CAdES, X=XAdES, P=PAdES, J=JAdES.
public struct SignatureFormat <: ToString & Equatable<SignatureFormat> {
    public let rawValue: String
    public init(rawValue: String) { this.rawValue = rawValue }
    public func toString(): String { rawValue }
    public operator func ==(o: SignatureFormat): Bool { rawValue == o.rawValue }
    public operator func !=(o: SignatureFormat): Bool { rawValue != o.rawValue }

    public static let C: SignatureFormat = SignatureFormat("C")
    public static let X: SignatureFormat = SignatureFormat("X")
    public static let P: SignatureFormat = SignatureFormat("P")
    public static let J: SignatureFormat = SignatureFormat("J")
}

// Signed envelope property (CSC `signed_envelope_property`). iOS: Types/SignedEnvelopeProperty.swift
public struct SignedEnvelopeProperty <: ToString & Equatable<SignedEnvelopeProperty> {
    public let rawValue: String
    public init(rawValue: String) { this.rawValue = rawValue }
    public func toString(): String { rawValue }
    public operator func ==(o: SignedEnvelopeProperty): Bool { rawValue == o.rawValue }
    public operator func !=(o: SignedEnvelopeProperty): Bool { rawValue != o.rawValue }

    public static let ENVELOPED: SignedEnvelopeProperty = SignedEnvelopeProperty("ENVELOPED")
    public static let ENVELOPING: SignedEnvelopeProperty = SignedEnvelopeProperty("ENVELOPING")
    public static let DETACHED: SignedEnvelopeProperty = SignedEnvelopeProperty("DETACHED")
    public static let INTERNALLY_DETACHED: SignedEnvelopeProperty = SignedEnvelopeProperty("INTERNALLY_DETACHED")
}

// Signature qualifier (eIDAS). iOS: Types/SignatureQualifier.swift
public struct SignatureQualifier <: ToString & Equatable<SignatureQualifier> {
    public let rawValue: String
    public init(rawValue: String) { this.rawValue = rawValue }
    public func toString(): String { rawValue }
    public operator func ==(o: SignatureQualifier): Bool { rawValue == o.rawValue }
    public operator func !=(o: SignatureQualifier): Bool { rawValue != o.rawValue }

    public static let EU_EIDAS_QES: SignatureQualifier = SignatureQualifier("eu_eidas_qes")
    public static let EU_EIDAS_AES: SignatureQualifier = SignatureQualifier("eu_eidas_aes")
    public static let EU_EIDAS_AESQC: SignatureQualifier = SignatureQualifier("eu_eidas_aesqc")
    public static let EU_EIDAS_QESEAL: SignatureQualifier = SignatureQualifier("eu_eidas_qeseal")
    public static let EU_EIDAS_AESEAL: SignatureQualifier = SignatureQualifier("eu_eidas_aeseal")
    public static let EU_EIDAS_AESEALQC: SignatureQualifier = SignatureQualifier("eu_eidas_aesealqc")
    public static let ZA_ECTA_AES: SignatureQualifier = SignatureQualifier("za_ecta_aes")
    public static let ZA_ECTA_OES: SignatureQualifier = SignatureQualifier("za_ecta_oes")
}
