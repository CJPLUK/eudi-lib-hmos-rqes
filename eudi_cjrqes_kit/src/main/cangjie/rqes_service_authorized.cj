/*
 * RQESServiceAuthorized — ports eudi-lib-ios-rqes-kit Sources/RqesKit/RQESServiceAuthorized.swift.
 *
 * The service-authorized stage: list credentials, then for a chosen credential + documents
 * calculate the hashes, build the OAuth2 authorization_details, and produce the credential
 * authorization URL. authorizeCredential exchanges the returned code for a credential token.
 *
 * Certificates are passed as parsed x509 `Cert` objects (iOS: [X509.Certificate]?) and
 * reduced to base64(DER) via toBase64String(cert.toDer()) — the exact analogue of iOS's
 * X509.Certificate.base64String. The common path passes nil and falls back to
 * credentialInfo.cert.certificates.
 */
package ohos_app_cangjie_eudi_cjrqes_kit

import std.collection.*
import stdx.encoding.base64.*
import ohos_app_cangjie_eudi_cjrqes_csc.*
import ohos_app_cangjie_eudi_cjx509.x509.core.Cert

public class RQESServiceAuthorized {
    let rqes: RQES
    let clientConfig: CSCClientConfig
    let accessToken: String
    let state: String
    let defaultHashAlgorithmOID: HashAlgorithmOID
    var defaultSigningAlgorithmOID: ?SigningAlgorithmOID
    let fileExtension: String

    var calculateHashResponse: ?DocumentDigests = None
    var documents: ?Array<Document> = None
    var outputURLs: ?Array<String> = None
    var credentialInfo: ?ListCredentialInfo = None
    var authorizationDetails: ?AuthorizationDetails = None
    var hashAlgorithmOID: ?HashAlgorithmOID = None

    public init(rqes: RQES, clientConfig!: CSCClientConfig, defaultHashAlgorithmOID!: HashAlgorithmOID,
                defaultSigningAlgorithmOID!: ?SigningAlgorithmOID, fileExtension!: String,
                state!: String, accessToken!: String) {
        this.rqes = rqes
        this.clientConfig = clientConfig
        this.defaultHashAlgorithmOID = defaultHashAlgorithmOID
        this.defaultSigningAlgorithmOID = defaultSigningAlgorithmOID
        this.fileExtension = fileExtension
        this.state = state
        this.accessToken = accessToken
    }

    // iOS: getCredentialsList — request with credentialInfo/certInfo, return the embedded infos.
    public func getCredentialsList(): Array<ListCredentialInfo> {
        let request = CredentialsListRequest(credentialInfo: true, certificates: "chain", certInfo: true)
        let response = rqes.listCredentials(request, accessToken)
        return match (response.credentialInfos) {
            case Some(infos) => infos
            case None => throw RqesCscException("Missing Credential Info")
        }
    }

    // iOS: getCredentialAuthorizationUrl — calculate hashes, build authorization_details, build URL.
    public func getCredentialAuthorizationUrl(credentialInfo: ListCredentialInfo, documents: Array<Document>,
                                              hashAlgorithmOID!: ?HashAlgorithmOID = None,
                                              certificates!: ?Array<Cert> = None): String {
        this.documents = Some(documents)
        this.credentialInfo = Some(credentialInfo)
        let hoid = hashAlgorithmOID ?? defaultHashAlgorithmOID
        this.hashAlgorithmOID = Some(hoid)

        // iOS: certificates?.map(\.base64String) ?? credentialInfo.cert.certificates
        let certs: Array<String> = match (certificates) {
            case Some(cs) =>
                let out = ArrayList<String>()
                for (c in cs) {
                    out.add(toBase64String(c.toDer()))
                }
                out.toArray()
            case None => match (credentialInfo.cert.certificates) {
                case Some(cc) => cc
                case None => throw RqesCscException("credential has no certificate chain")
            }
        }

        if (credentialInfo.key.algo.isEmpty()) {
            throw RqesCscException("Failed to retrieve list of supported signing algorithms")
        }
        this.defaultSigningAlgorithmOID = Some(SigningAlgorithmOID(credentialInfo.key.algo[0]))

        // STEP 9: calculate hashes
        let outputs = ArrayList<String>()
        for (_ in documents) {
            outputs.add(getTempFileURL())
        }
        let outputURLs = outputs.toArray()
        this.outputURLs = Some(outputURLs)

        let inputs = ArrayList<String>()
        for (d in documents) {
            inputs.add(d.fileURL)
        }
        let digests = RQESService.calculateHashes(rqes, inputs.toArray(), outputURLs, certs, hoid)
        this.calculateHashResponse = Some(digests)

        // STEP 10: build authorization_details
        let digs = ArrayList<DocumentDigest>()
        for (i in 0..digests.hashes.size) {
            digs.add(DocumentDigest.forToken(documents[i].id, digests.hashes[i]))
        }
        let item = AuthorizationDetailsItem(
            documentDigests: digs.toArray(), credentialID: credentialInfo.credentialID,
            hashAlgorithmOID: hoid, locations: Array<String>(), detailType: "credential")
        let details = AuthorizationDetails([item])
        this.authorizationDetails = Some(details)

        let credentialResponse = rqes.prepareCredentialAuthorizationRequest(state, details.toJsonString())
        return credentialResponse.authorizationCodeURL
    }

    // iOS: authorizeCredential — re-encode digests to base64, exchange code for credential token.
    public func authorizeCredential(authorizationCode: String): RQESServiceCredentialAuthorized {
        let details = requireAuthDetails().copy(digestFormat: DigestFormat.Base64)
        let tokenRequest = AccessTokenRequest(authorizationCode, state, authorizationDetails: details.toJsonString())
        let tokenResponse = rqes.requestAccessTokenAuthFlow(tokenRequest)
        return RQESServiceCredentialAuthorized(
            requireCredentialInfo(),
            rqes: rqes,
            clientConfig: clientConfig,
            credentialAccessToken: tokenResponse.accessToken,
            documents: requireDocuments(),
            calculateHashResponse: requireHashResponse(),
            hashAlgorithmOID: requireHashOID(),
            defaultSigningAlgorithmOID: defaultSigningAlgorithmOID,
            fileExtension: fileExtension,
            outputURLs: requireOutputURLs())
    }

    // iOS: static getTempFileURL(fileExtension:) — a unique path under the process temp dir.
    func getTempFileURL(): String {
        var dir = RqesTempDir.get()
        if (dir.endsWith("/")) { dir = dir[0..dir.size - 1] }
        return dir + "/" + uuidV4() + fileExtension
    }

    func requireAuthDetails(): AuthorizationDetails {
        return match (authorizationDetails) {
            case Some(v) => v
            case None => throw RqesCscException("no authorization details; call getCredentialAuthorizationUrl first")
        }
    }
    func requireCredentialInfo(): ListCredentialInfo {
        return match (credentialInfo) { case Some(v) => v; case None => throw RqesCscException("no credentialInfo") }
    }
    func requireDocuments(): Array<Document> {
        return match (documents) { case Some(v) => v; case None => throw RqesCscException("no documents") }
    }
    func requireHashResponse(): DocumentDigests {
        return match (calculateHashResponse) { case Some(v) => v; case None => throw RqesCscException("no calculated hashes") }
    }
    func requireHashOID(): HashAlgorithmOID {
        return match (hashAlgorithmOID) { case Some(v) => v; case None => throw RqesCscException("no hashAlgorithmOID") }
    }
    func requireOutputURLs(): Array<String> {
        return match (outputURLs) { case Some(v) => v; case None => throw RqesCscException("no output paths") }
    }
}
