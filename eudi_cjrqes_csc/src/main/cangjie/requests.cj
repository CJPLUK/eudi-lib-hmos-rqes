/*
 * CSC request models — 1:1 port of eudi-lib-ios-rqes-csc-swift Sources/Requests.
 * JSON/form field names follow each Swift struct's CodingKeys EXACTLY (note the
 * mix of camelCase and snake_case the CSC v2 wire uses).
 */
package ohos_app_cangjie_eudi_cjrqes_csc

import stdx.encoding.json.*
import std.collection.*

// OAuth2 token-exchange inputs. iOS: Requests/AccessTokenRequest.swift
// A plain data holder — OAuth2TokenService builds the actual form body.
public struct AccessTokenRequest {
    public let code: String
    public let state: String
    public let authorizationDetails: ?String

    public init(code: String, state: String, authorizationDetails!: ?String = None) {
        this.code = code
        this.state = state
        this.authorizationDetails = authorizationDetails
    }
}

// CSC `signatures/signHash` request body. iOS: Requests/SignHashRequest.swift
public struct SignHashRequest {
    public let credentialID: String
    public let sad: ?String                 // CodingKey "SAD"
    public let hashes: Array<String>
    public let hashAlgorithmOID: HashAlgorithmOID
    public let signAlgo: SigningAlgorithmOID
    public let signAlgoParams: ?String      // "sign_algo_params"
    public let operationMode: ?String       // "operationMode"
    public let validityPeriod: ?Int64       // "validity_period"
    public let responseURI: ?String         // "response_uri"
    public let clientData: ?String          // "client_data"

    public init(
        credentialID: String,
        hashes: Array<String>,
        hashAlgorithmOID: HashAlgorithmOID,
        signAlgo: SigningAlgorithmOID,
        sad!: ?String = None,
        signAlgoParams!: ?String = None,
        operationMode!: ?String = None,
        validityPeriod!: ?Int64 = None,
        responseURI!: ?String = None,
        clientData!: ?String = None
    ) {
        this.credentialID = credentialID
        this.hashes = hashes
        this.hashAlgorithmOID = hashAlgorithmOID
        this.signAlgo = signAlgo
        this.sad = sad
        this.signAlgoParams = signAlgoParams
        this.operationMode = operationMode
        this.validityPeriod = validityPeriod
        this.responseURI = responseURI
        this.clientData = clientData
    }

    // JSON body. Optional fields are omitted when None (Swift Codable drops nils).
    public func toJsonString(): String {
        let obj = JsonObject()
        obj.put("credentialID", JsonString(credentialID))
        putOptStr(obj, "SAD", sad)
        let arr = jsonStringArray(hashes)
        obj.put("hashes", arr)
        obj.put("hashAlgorithmOID", JsonString(hashAlgorithmOID.rawValue))
        obj.put("signAlgo", JsonString(signAlgo.rawValue))
        putOptStr(obj, "sign_algo_params", signAlgoParams)
        putOptStr(obj, "operationMode", operationMode)
        match (validityPeriod) {
            case Some(v) => obj.put("validity_period", JsonInt(v))
            case None => ()
        }
        putOptStr(obj, "response_uri", responseURI)
        putOptStr(obj, "client_data", clientData)
        return obj.toJsonString()
    }
}

// Document to be hashed/signed. iOS: CalculateHashRequest.Document
public struct CalculateHashDocument {
    public let documentInputPath: String
    public let documentOutputPath: String
    public let signatureFormat: SignatureFormat
    public let conformanceLevel: ConformanceLevel
    public let signedEnvelopeProperty: SignedEnvelopeProperty
    public let container: String

    public init(
        documentInputPath: String,
        documentOutputPath: String,
        signatureFormat: SignatureFormat,
        conformanceLevel: ConformanceLevel,
        signedEnvelopeProperty: SignedEnvelopeProperty,
        container: String
    ) {
        this.documentInputPath = documentInputPath
        this.documentOutputPath = documentOutputPath
        this.signatureFormat = signatureFormat
        this.conformanceLevel = conformanceLevel
        this.signedEnvelopeProperty = signedEnvelopeProperty
        this.container = container
    }
}

// Local input to PodofoManager.calculateDocumentHashes (not a wire request).
// iOS: Requests/CalculateHashRequest.swift
public struct CalculateHashRequest {
    public let documents: Array<CalculateHashDocument>
    public let endEntityCertificate: String
    public let certificateChain: Array<String>
    public let hashAlgorithmOID: HashAlgorithmOID

    public init(
        documents: Array<CalculateHashDocument>,
        endEntityCertificate: String,
        certificateChain: Array<String>,
        hashAlgorithmOID: HashAlgorithmOID
    ) {
        this.documents = documents
        this.endEntityCertificate = endEntityCertificate
        this.certificateChain = certificateChain
        this.hashAlgorithmOID = hashAlgorithmOID
    }
}

// CSC `credentials/list` request. iOS: Requests/CredentialsListRequest.swift
// Sent as application/x-www-form-urlencoded via toFormBody().
public struct CredentialsListRequest {
    public let userID: ?String
    public let credentialInfo: ?Bool
    public let certificates: ?String
    public let certInfo: ?Bool               // default true (Swift init)
    public let authInfo: ?Bool
    public let onlyValid: ?Bool
    public let lang: ?String
    public let clientData: ?String

    public init(
        userID!: ?String = None,
        credentialInfo!: ?Bool = None,
        certificates!: ?String = None,
        certInfo!: ?Bool = Some(true),
        authInfo!: ?Bool = None,
        onlyValid!: ?Bool = None,
        lang!: ?String = None,
        clientData!: ?String = None
    ) {
        this.userID = userID
        this.credentialInfo = credentialInfo
        this.certificates = certificates
        this.certInfo = certInfo
        this.authInfo = authInfo
        this.onlyValid = onlyValid
        this.lang = lang
        this.clientData = clientData
    }

    // JSON body — what CredentialsListClient actually sends (JSONEncoder → CodingKeys:
    // user_id / credentialInfo / certInfo / auth_info / only_valid / client_data).
    public func toJsonString(): String {
        let obj = JsonObject()
        putOptStr(obj, "user_id", userID)
        match (credentialInfo) { case Some(b) => obj.put("credentialInfo", JsonBool(b)); case None => () }
        putOptStr(obj, "certificates", certificates)
        match (certInfo) { case Some(b) => obj.put("certInfo", JsonBool(b)); case None => () }
        match (authInfo) { case Some(b) => obj.put("auth_info", JsonBool(b)); case None => () }
        match (onlyValid) { case Some(b) => obj.put("only_valid", JsonBool(b)); case None => () }
        putOptStr(obj, "lang", lang)
        putOptStr(obj, "client_data", clientData)
        return obj.toJsonString()
    }

    // form-urlencoded variant. iOS has toFormBody() but CredentialsListClient uses JSON;
    // kept for parity / alternate transports.
    public func toFormBody(): String {
        let parts = ArrayList<String>()
        addFormStr(parts, "user_id", userID)
        addFormBool(parts, "credential_info", credentialInfo)
        addFormStr(parts, "certificates", certificates)
        addFormBool(parts, "cert_info", certInfo)
        addFormBool(parts, "auth_info", authInfo)
        addFormBool(parts, "only_valid", onlyValid)
        addFormStr(parts, "lang", lang)
        addFormStr(parts, "client_data", clientData)
        return joinAmp(parts)
    }
}

// CSC `credentials/info` request. iOS: Requests/CredentialsInfoRequest.swift
public struct CredentialsInfoRequest {
    public let credentialID: String
    public let certificates: ?String         // default "chain"
    public let certInfo: ?Bool               // default true
    public let authInfo: ?Bool               // default true; "auth_info"
    public let lang: ?String
    public let clientData: ?String           // "client_data"

    public init(
        credentialID: String,
        certificates!: ?String = Some("chain"),
        certInfo!: ?Bool = Some(true),
        authInfo!: ?Bool = Some(true),
        lang!: ?String = None,
        clientData!: ?String = None
    ) {
        this.credentialID = credentialID
        this.certificates = certificates
        this.certInfo = certInfo
        this.authInfo = authInfo
        this.lang = lang
        this.clientData = clientData
    }

    public func toJsonString(): String {
        let obj = JsonObject()
        obj.put("credentialID", JsonString(credentialID))
        putOptStr(obj, "certificates", certificates)
        match (certInfo) { case Some(b) => obj.put("certInfo", JsonBool(b)); case None => () }
        match (authInfo) { case Some(b) => obj.put("auth_info", JsonBool(b)); case None => () }
        putOptStr(obj, "lang", lang)
        putOptStr(obj, "client_data", clientData)
        return obj.toJsonString()
    }
}

// ── shared helpers ─────────────────────────────────────────────────────────
func putOptStr(obj: JsonObject, key: String, v: ?String): Unit {
    match (v) {
        case Some(s) => obj.put(key, JsonString(s))
        case None => ()
    }
}

func jsonStringArray(items: Array<String>): JsonArray {
    var arr = JsonArray()
    for (s in items) {
        arr = arr.add(JsonString(s))
    }
    return arr
}

func addFormStr(parts: ArrayList<String>, key: String, v: ?String): Unit {
    match (v) {
        case Some(s) => parts.add("${key}=${s}")
        case None => ()
    }
}

func addFormBool(parts: ArrayList<String>, key: String, v: ?Bool): Unit {
    match (v) {
        case Some(b) => parts.add("${key}=${if (b) { "true" } else { "false" }}")
        case None => ()
    }
}

func joinAmp(parts: ArrayList<String>): String {
    var out = ""
    var first = true
    for (p in parts) {
        if (first) { out = p; first = false } else { out = out + "&" + p }
    }
    return out
}
