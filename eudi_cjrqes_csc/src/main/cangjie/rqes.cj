/*
 * RQES — the public facade, ported from eudi-lib-ios-rqes-csc-swift Sources/Main/RQES.swift.
 *
 * Threads the whole B_B flow together: discovers the OAuth2 server via `info`, runs the
 * PKCE authorize/token exchange, lists/queries credentials, and drives PodofoManager for
 * the hash → signHash → embed round-trip.
 *
 * State mirrors iOS RQES:
 *   - issuerURL   : set by prepareServiceAuthorizationRequest (from info.oauth2), then used
 *                   by the credential authorize and the token exchange.
 *   - codeVerifier: the PKCE verifier from the last prepare*, consumed by requestAccessTokenAuthFlow
 *                   (iOS keeps it in a PKCEState singleton; we hold it on the instance).
 */
package ohos_app_cangjie_eudi_cjrqes_csc

public class RQES {
    private let cscClientConfig: CSCClientConfig
    private let rsspId: String
    private var issuerURL: String = ""
    private var codeVerifier: ?String = None
    private let podofoManager: PodofoManager

    public init(cscClientConfig: CSCClientConfig) {
        this.cscClientConfig = cscClientConfig
        this.rsspId = cscClientConfig.rsspId
        this.podofoManager = PodofoManager(includeRevocationInfo: cscClientConfig.includeRevocationInfo)
    }

    // iOS: prepareServiceAuthorizationRequest — fetch `info`, adopt its oauth2 URL as the
    // issuer, then build the service-scope authorize URL. Stashes the PKCE verifier.
    public func prepareServiceAuthorizationRequest(walletState: String): AuthorizationPrepareResponse {
        let info = cscGetInfo(rsspId, InfoServiceRequest())
        this.issuerURL = info.oauth2
        let (resp, verifier) = oauthPrepareServiceRequest(walletState, cscClientConfig, issuerURL)
        this.codeVerifier = Some(verifier)
        return resp
    }

    // iOS: prepareCredentialAuthorizationRequest — credential-scope authorize (needs the
    // issuerURL already set by a prior service prepare). Stashes a fresh PKCE verifier.
    public func prepareCredentialAuthorizationRequest(
        walletState: String, authorizationDetails: String
    ): AuthorizationPrepareResponse {
        let (resp, verifier) = oauthPrepareCredentialRequest(
            walletState, cscClientConfig, authorizationDetails, issuerURL)
        this.codeVerifier = Some(verifier)
        return resp
    }

    // iOS: requestAccessTokenAuthFlow — exchange the auth code for a token using the PKCE
    // verifier stored by the matching prepare*. Consumes the verifier (iOS PKCEState.reset).
    public func requestAccessTokenAuthFlow(request: AccessTokenRequest): AccessTokenResponse {
        let verifier = match (codeVerifier) {
            case Some(v) => v
            case None => throw RqesCscException(
                "no PKCE code verifier; call prepareServiceAuthorizationRequest / prepareCredentialAuthorizationRequest first")
        }
        let token = oauthGetToken(request, cscClientConfig, issuerURL, verifier)
        this.codeVerifier = None
        return token
    }

    // --- CSC credential + signature endpoints (Bearer-authenticated) -------------------

    public func listCredentials(
        request: CredentialsListRequest, accessToken: String
    ): CredentialsListResponse {
        return cscListCredentials(rsspId, request, accessToken)
    }

    public func getCredentialInfo(
        request: CredentialsInfoRequest, accessToken: String
    ): CredentialInfo {
        return cscGetCredentialInfo(rsspId, request, accessToken)
    }

    public func signHash(
        request: SignHashRequest, accessToken: String
    ): SignHashResponse {
        return cscSignHash(rsspId, request, accessToken)
    }

    // --- PodofoManager-driven local hashing / embedding --------------------------------

    // iOS: calculateDocumentHashes — delegates to PodofoManager (one PodofoSigner per doc).
    public func calculateDocumentHashes(request: CalculateHashRequest): DocumentDigests {
        return podofoManager.calculateDocumentHashes(request, cscClientConfig.tsaUrl)
    }

    // iOS: createSignedDocuments — embed the remote signatures into the prepared documents.
    public func createSignedDocuments(signatures: Array<String>): Unit {
        podofoManager.createSignedDocuments(signatures, cscClientConfig.tsaUrl)
    }
}
