/*
 * RQESService — ports eudi-lib-ios-rqes-kit Sources/RqesKit/RQESService.swift.
 *
 * Entry point of the orchestration layer: wraps the CSC-layer RQES facade and drives the
 * service-authorization handshake, then hands off to RQESServiceAuthorized. Also holds the
 * shared hash-calculation helper used by the credential-authorization step.
 *
 * Platform adaptations vs iOS (all forced, none behavioral):
 *   - URL → String file paths (this layer has no URL type).
 *   - UUID().uuidString → uuidV4() (core_crypto Rng) — functionally identical (Cangjie has
 *     no UUID type; this produces the same RFC 4122 v4 string from the same CSPRNG class).
 *   - NSTemporaryDirectory() → RqesTempDir (a process-global the wallet sets at startup) —
 *     mirrors iOS's global tmp dir, so this initializer stays 1:1 with the iOS one.
 */
package ohos_app_cangjie_eudi_cjrqes_kit

import std.collection.*
import ohos_app_cangjie_eudi_cjrqes_csc.*

public class RQESService {
    let clientConfig: CSCClientConfig
    var state: ?String = None
    let rqes: RQES
    let defaultHashAlgorithmOID: HashAlgorithmOID
    let defaultSigningAlgorithmOID: SigningAlgorithmOID
    let fileExtension: String

    // iOS: init(clientConfig:defaultHashAlgorithmOID:.SHA256, defaultSigningAlgorithmOID:.SHA256WithRSA, fileExtension:".pdf").
    public init(clientConfig!: CSCClientConfig,
                defaultHashAlgorithmOID!: HashAlgorithmOID = HashAlgorithmOID.SHA256,
                defaultSigningAlgorithmOID!: SigningAlgorithmOID = SigningAlgorithmOID.SHA256WithRSA,
                fileExtension!: String = ".pdf") {
        this.clientConfig = clientConfig
        this.defaultHashAlgorithmOID = defaultHashAlgorithmOID
        this.defaultSigningAlgorithmOID = defaultSigningAlgorithmOID
        this.fileExtension = fileExtension
        this.rqes = RQES(clientConfig)
    }

    // iOS: getServiceAuthorizationUrl — creates the state, builds the service authorize URL.
    public func getServiceAuthorizationUrl(): String {
        let s = uuidV4()
        this.state = Some(s)
        let response = rqes.prepareServiceAuthorizationRequest(s)
        return response.authorizationCodeURL
    }

    // iOS: authorizeService — exchanges the auth code for a token, returns the authorized service.
    public func authorizeService(authorizationCode: String): RQESServiceAuthorized {
        let s = requireState()
        let tokenRequest = AccessTokenRequest(authorizationCode, s)
        let tokenResponse = rqes.requestAccessTokenAuthFlow(tokenRequest)
        return RQESServiceAuthorized(
            rqes,
            clientConfig: clientConfig,
            defaultHashAlgorithmOID: defaultHashAlgorithmOID,
            defaultSigningAlgorithmOID: defaultSigningAlgorithmOID,
            fileExtension: fileExtension,
            state: s,
            accessToken: tokenResponse.accessToken)
    }

    func requireState(): String {
        return match (state) {
            case Some(s) => s
            case None => throw RqesCscException("no state; call getServiceAuthorizationUrl first")
        }
    }

    // iOS: static calculateHashes — builds the CalculateHashRequest for the given documents
    // and delegates to the RQES facade (PodofoManager).
    static func calculateHashes(rqes: RQES, documents: Array<String>, outputURLs: Array<String>,
                                certificates: Array<String>, hashAlgorithmOID: HashAlgorithmOID,
                                signatureFormat!: SignatureFormat = SignatureFormat.P,
                                conformanceLevel!: ConformanceLevel = ConformanceLevel.ADES_B_B,
                                signedEnvelopeProperty!: SignedEnvelopeProperty = SignedEnvelopeProperty.ENVELOPED): DocumentDigests {
        let docs = ArrayList<CalculateHashDocument>()
        for (i in 0..documents.size) {
            docs.add(CalculateHashDocument(
                documents[i], outputURLs[i], signatureFormat, conformanceLevel, signedEnvelopeProperty, "No"))
        }
        let chain = if (certificates.size > 1) { certificates[1..certificates.size] } else { Array<String>() }
        let request = CalculateHashRequest(docs.toArray(), certificates[0], chain, hashAlgorithmOID)
        return rqes.calculateDocumentHashes(request)
    }

    // iOS: getTempFileURL — a unique writable path under the process temp directory.
    func getTempFileURL(): String {
        var dir = RqesTempDir.get()
        if (dir.endsWith("/")) { dir = dir[0..dir.size - 1] }
        return dir + "/" + uuidV4() + fileExtension
    }
}
