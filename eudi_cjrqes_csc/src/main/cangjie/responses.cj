/*
 * CSC response models — 1:1 port of eudi-lib-ios-rqes-csc-swift Sources/Responses.
 * fromJsonString() parses per each Swift struct's CodingKeys.
 */
package ohos_app_cangjie_eudi_cjrqes_csc

import stdx.encoding.json.*
import std.collection.*

// OAuth2 token response. iOS: Responses/AccessResponse.swift (AccessTokenResponse)
public struct AccessTokenResponse {
    public let accessToken: String          // "access_token"
    public let tokenType: String            // "token_type"
    public let expiresIn: Int64             // "expires_in"
    public let refreshToken: ?String        // "refresh_token"
    public let scope: ?String

    public init(accessToken!: String, tokenType!: String, expiresIn!: Int64,
                refreshToken!: ?String = None, scope!: ?String = None) {
        this.accessToken = accessToken
        this.tokenType = tokenType
        this.expiresIn = expiresIn
        this.refreshToken = refreshToken
        this.scope = scope
    }

    public static func fromJsonString(s: String): AccessTokenResponse {
        let obj = rootObject(s)
        return AccessTokenResponse(
            accessToken: reqStr(obj, "access_token"),
            tokenType: reqStr(obj, "token_type"),
            expiresIn: optInt(obj, "expires_in") ?? 0,
            refreshToken: optStr(obj, "refresh_token"),
            scope: optStr(obj, "scope"))
    }
}

// CSC signHash response. iOS: Responses/SignHashResponse.swift
public struct SignHashResponse {
    public let signatures: ?Array<String>
    public let responseID: ?String          // "response_id"

    public init(signatures!: ?Array<String> = None, responseID!: ?String = None) {
        this.signatures = signatures
        this.responseID = responseID
    }

    public static func fromJsonString(s: String): SignHashResponse {
        let obj = rootObject(s)
        return SignHashResponse(
            signatures: optStrArray(obj, "signatures"),
            responseID: optStr(obj, "response_id"))
    }
}

// CSC `credentials/list` response. iOS: Responses/CredentialsListResponse.swift
public struct CredentialsListResponse {
    public let credentialIDs: Array<String>
    public let credentialInfos: ?Array<ListCredentialInfo>
    public let onlyValid: ?Bool

    public init(credentialIDs!: Array<String>, credentialInfos!: ?Array<ListCredentialInfo> = None,
                onlyValid!: ?Bool = None) {
        this.credentialIDs = credentialIDs
        this.credentialInfos = credentialInfos
        this.onlyValid = onlyValid
    }

    public static func fromJsonString(s: String): CredentialsListResponse {
        let obj = rootObject(s)
        let infos: ?Array<ListCredentialInfo> = match (obj.get("credentialInfos")) {
            case Some(ja: JsonArray) =>
                let out = ArrayList<ListCredentialInfo>()
                for (item in ja.getItems()) {
                    match (item) {
                        case jo: JsonObject => out.add(ListCredentialInfo.fromJsonObject(jo))
                        case _ => ()
                    }
                }
                Some(out.toArray())
            case _ => None
        }
        return CredentialsListResponse(
            credentialIDs: optStrArray(obj, "credentialIDs") ?? Array<String>(),
            credentialInfos: infos,
            onlyValid: optBool(obj, "onlyValid"))
    }
}

// Per-credential detail embedded in credentials/list (when credentialInfo=true). iOS:
// CredentialsListResponse.CredentialInfo — differs from the standalone CredentialInfo by
// the required `credentialID`; reuses the same key/cert/auth blocks. RqesKit's
// getCredentialsList() returns these and reads credentialID / cert.certificates / key.algo.
public struct ListCredentialInfo {
    public let credentialID: String
    public let description: ?String
    public let signatureQualifier: ?SignatureQualifier
    public let key: CredentialKeyInfo
    public let cert: CredentialCertificateInfo
    public let auth: ?CredentialAuthInfo
    public let multisign: ?Int64
    public let lang: ?String
    public let scal: ?String

    public init(credentialID!: String, key!: CredentialKeyInfo, cert!: CredentialCertificateInfo,
                description!: ?String = None, signatureQualifier!: ?SignatureQualifier = None,
                auth!: ?CredentialAuthInfo = None, multisign!: ?Int64 = None,
                lang!: ?String = None, scal!: ?String = None) {
        this.credentialID = credentialID
        this.key = key
        this.cert = cert
        this.description = description
        this.signatureQualifier = signatureQualifier
        this.auth = auth
        this.multisign = multisign
        this.lang = lang
        this.scal = scal
    }

    static func fromJsonObject(obj: JsonObject): ListCredentialInfo {
        let certInfo = match (optObject(obj, "cert")) {
            case Some(co) => CredentialCertificateInfo.fromJsonObject(co)
            case None => CredentialCertificateInfo.fromJsonObject(JsonObject())
        }
        let authInfo: ?CredentialAuthInfo = match (optObject(obj, "auth")) {
            case Some(ao) => Some(CredentialAuthInfo.fromJsonObject(ao))
            case None => None
        }
        let sq: ?SignatureQualifier = match (optStr(obj, "signatureQualifier")) {
            case Some(v) => Some(SignatureQualifier(v))
            case None => None
        }
        return ListCredentialInfo(
            credentialID: reqStr(obj, "credentialID"),
            key: CredentialKeyInfo.fromJsonObject(optObject(obj, "key") ?? JsonObject()),
            cert: certInfo,
            description: optStr(obj, "description"),
            signatureQualifier: sq,
            auth: authInfo,
            multisign: optInt(obj, "multisign"),
            lang: optStr(obj, "lang"),
            scal: optStr(obj, "scal"))
    }
}

// Certificate block of a credential. iOS: CredentialInfo.CertificateInfo (all fields).
public struct CredentialCertificateInfo {
    public let status: ?String
    public let certificates: ?Array<String>
    public let issuerDN: ?String
    public let serialNumber: ?String
    public let subjectDN: ?String
    public let validFrom: ?String
    public let validTo: ?String
    public let qcStatements: ?Array<String>
    public let policy: ?Array<String>

    public init(status!: ?String, certificates!: ?Array<String>, issuerDN!: ?String,
                serialNumber!: ?String, subjectDN!: ?String, validFrom!: ?String, validTo!: ?String,
                qcStatements!: ?Array<String> = None, policy!: ?Array<String> = None) {
        this.status = status
        this.certificates = certificates
        this.issuerDN = issuerDN
        this.serialNumber = serialNumber
        this.subjectDN = subjectDN
        this.validFrom = validFrom
        this.validTo = validTo
        this.qcStatements = qcStatements
        this.policy = policy
    }

    static func fromJsonObject(obj: JsonObject): CredentialCertificateInfo {
        return CredentialCertificateInfo(
            status: optStr(obj, "status"),
            certificates: optStrArray(obj, "certificates"),
            issuerDN: optStr(obj, "issuerDN"),
            serialNumber: optStr(obj, "serialNumber"),
            subjectDN: optStr(obj, "subjectDN"),
            validFrom: optStr(obj, "validFrom"),
            validTo: optStr(obj, "validTo"),
            qcStatements: optStrArray(obj, "qcStatements"),
            policy: optStrArray(obj, "policy"))
    }
}

// Key block of a credential. iOS: CredentialInfo.KeyInfo
public struct CredentialKeyInfo {
    public let status: String
    public let algo: Array<String>
    public let len: Int64
    public let curve: ?String

    public init(status!: String, algo!: Array<String>, len!: Int64, curve!: ?String = None) {
        this.status = status
        this.algo = algo
        this.len = len
        this.curve = curve
    }

    static func fromJsonObject(obj: JsonObject): CredentialKeyInfo {
        return CredentialKeyInfo(
            status: reqStr(obj, "status"),
            algo: optStrArray(obj, "algo") ?? Array<String>(),
            len: optInt(obj, "len") ?? 0,
            curve: optStr(obj, "curve"))
    }
}

// Authorization object of a credential. iOS: CredentialInfo.AuthObject (type/id required).
public struct CredentialAuthObject {
    public let objType: String              // "type"
    public let id: String
    public let format: ?String
    public let label: ?String
    public let description: ?String

    public init(objType!: String, id!: String, format!: ?String = None,
                label!: ?String = None, description!: ?String = None) {
        this.objType = objType
        this.id = id
        this.format = format
        this.label = label
        this.description = description
    }

    static func fromJsonObject(obj: JsonObject): CredentialAuthObject {
        return CredentialAuthObject(
            objType: reqStr(obj, "type"),
            id: reqStr(obj, "id"),
            format: optStr(obj, "format"),
            label: optStr(obj, "label"),
            description: optStr(obj, "description"))
    }
}

// Authorization block of a credential (SCAL / PIN / OTP mode). iOS: CredentialInfo.AuthInfo
public struct CredentialAuthInfo {
    public let mode: ?String
    public let expression: ?String
    public let objects: ?Array<CredentialAuthObject>

    public init(mode!: ?String = None, expression!: ?String = None,
                objects!: ?Array<CredentialAuthObject> = None) {
        this.mode = mode
        this.expression = expression
        this.objects = objects
    }

    static func fromJsonObject(obj: JsonObject): CredentialAuthInfo {
        let objs: ?Array<CredentialAuthObject> = match (obj.get("objects")) {
            case Some(ja: JsonArray) =>
                let out = ArrayList<CredentialAuthObject>()
                for (item in ja.getItems()) {
                    match (item) {
                        case jo: JsonObject => out.add(CredentialAuthObject.fromJsonObject(jo))
                        case _ => ()
                    }
                }
                Some(out.toArray())
            case _ => None
        }
        return CredentialAuthInfo(
            mode: optStr(obj, "mode"),
            expression: optStr(obj, "expression"),
            objects: objs)
    }
}

// CSC `credentials/info` response. iOS: Responses/CredentialInfoResponse.swift (CredentialInfo)
public struct CredentialInfo {
    public let description: ?String
    public let signatureQualifier: ?SignatureQualifier
    public let key: CredentialKeyInfo
    public let cert: ?CredentialCertificateInfo
    public let auth: ?CredentialAuthInfo
    public let multisign: Int64
    public let lang: ?String
    public let scal: ?String

    public init(key!: CredentialKeyInfo, multisign!: Int64, description!: ?String = None,
                signatureQualifier!: ?SignatureQualifier = None, cert!: ?CredentialCertificateInfo = None,
                auth!: ?CredentialAuthInfo = None, lang!: ?String = None, scal!: ?String = None) {
        this.key = key
        this.multisign = multisign
        this.description = description
        this.signatureQualifier = signatureQualifier
        this.cert = cert
        this.auth = auth
        this.lang = lang
        this.scal = scal
    }

    public static func fromJsonString(s: String): CredentialInfo {
        let obj = rootObject(s)
        let keyObj = optObject(obj, "key") ?? JsonObject()
        let certInfo: ?CredentialCertificateInfo = match (optObject(obj, "cert")) {
            case Some(co) => Some(CredentialCertificateInfo.fromJsonObject(co))
            case None => None
        }
        let authInfo: ?CredentialAuthInfo = match (optObject(obj, "auth")) {
            case Some(ao) => Some(CredentialAuthInfo.fromJsonObject(ao))
            case None => None
        }
        let sq: ?SignatureQualifier = match (optStr(obj, "signatureQualifier")) {
            case Some(v) => Some(SignatureQualifier(v))
            case None => None
        }
        return CredentialInfo(
            key: CredentialKeyInfo.fromJsonObject(keyObj),
            multisign: optInt(obj, "multisign") ?? 0,
            description: optStr(obj, "description"),
            signatureQualifier: sq,
            cert: certInfo,
            auth: authInfo,
            lang: optStr(obj, "lang"),
            scal: optStr(obj, "scal"))
    }
}

// Local output of PodofoManager.calculateDocumentHashes. iOS: Responses/DocumentDigestsResponse.swift
public struct DocumentDigests {
    public let hashes: Array<String>
    public init(hashes: Array<String>) { this.hashes = hashes }

    // Normalize each digest to `output`. iOS: init(digests:output:) — used before signHash
    // (.base64) and the authorize/token authorization_details.
    public init(digests!: Array<String>, output!: DigestFormat) {
        let out = ArrayList<String>()
        for (d in digests) {
            out.add(DigestNormalizer.normalize(d, to: output))
        }
        this.hashes = out.toArray()
    }

    public static func forAuthorization(digests: Array<String>): DocumentDigests {
        return DocumentDigests(digests: digests, output: DigestFormat.Base64UrlNoPadding)
    }

    public static func forToken(digests: Array<String>): DocumentDigests {
        return DocumentDigests(digests: digests, output: DigestFormat.Base64)
    }
}

// ── JSON parse helpers ─────────────────────────────────────────────────────
func rootObject(s: String): JsonObject {
    match (JsonValue.fromStr(s)) {
        case jobj: JsonObject => return jobj
        case _ => throw RqesCscException("expected a JSON object")
    }
}

func optStr(obj: JsonObject, key: String): ?String {
    match (obj.get(key)) {
        case Some(js: JsonString) => Some(js.getValue())
        case _ => None
    }
}

func reqStr(obj: JsonObject, key: String): String {
    match (optStr(obj, key)) {
        case Some(v) => v
        case None => throw RqesCscException("missing required string field '${key}'")
    }
}

func optInt(obj: JsonObject, key: String): ?Int64 {
    match (obj.get(key)) {
        case Some(ji: JsonInt) => Some(ji.getValue())
        case _ => None
    }
}

func optBool(obj: JsonObject, key: String): ?Bool {
    match (obj.get(key)) {
        case Some(jb: JsonBool) => Some(jb.getValue())
        case _ => None
    }
}

func optObject(obj: JsonObject, key: String): ?JsonObject {
    match (obj.get(key)) {
        case Some(jo: JsonObject) => Some(jo)
        case _ => None
    }
}

func optStrArray(obj: JsonObject, key: String): ?Array<String> {
    match (obj.get(key)) {
        case Some(ja: JsonArray) =>
            let out = ArrayList<String>()
            for (item in ja.getItems()) {
                match (item) {
                    case js: JsonString => out.add(js.getValue())
                    case _ => ()
                }
            }
            Some(out.toArray())
        case _ => None
    }
}
