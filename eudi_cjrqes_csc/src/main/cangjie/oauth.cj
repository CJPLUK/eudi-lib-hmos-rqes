/*
 * CSC OAuth2 authorization + token exchange — ports
 * eudi-lib-ios-rqes-csc-swift Sources/Services/{PrepareAuthorizationRequestService,
 * OAuth2TokenService} + Sources/PKCE + Requests/OAuth2TokenRequest + Types/Scope.
 *
 * PKCE is reused from openid4vp_vci (PKCEGenerator): its codeVerifier() is a 43-char
 * value from the PKCE unreserved charset and generateCodeChallenge = Base64Url(SHA256),
 * byte-identical to iOS's SHA256→base64url — so it is functionally equivalent to iOS's
 * UUID-based 43-char verifier (the value is per-session random either way; the server
 * only checks challenge == S256(verifier)).
 *
 * verifier persistence: iOS keeps it in a PKCEState singleton between authorize and
 * token. Here prepare*() RETURNS the verifier and the caller (facade / PodofoManager
 * orchestration) threads it into requestAccessTokenAuthFlow — explicit, no global state.
 */
package ohos_app_cangjie_eudi_cjrqes_csc

import std.collection.*
import stdx.encoding.base64.*
import ohos_app_cangjie_eudi_cjopenid4vp_vci.openid4vci.pkce.PKCEGenerator
import ohos_app_cangjie_eudi_cjopenid4vp_vci.openid4vci.network.{HttpPoster, PostError}

// OAuth2 scope. iOS: Types/Scope.swift
public struct Scope <: ToString & Equatable<Scope> {
    public let rawValue: String
    public init(rawValue: String) { this.rawValue = rawValue }
    public func toString(): String { rawValue }
    public operator func ==(o: Scope): Bool { rawValue == o.rawValue }
    public operator func !=(o: Scope): Bool { rawValue != o.rawValue }

    public static let SERVICE: Scope = Scope("service")
    public static let CREDENTIAL: Scope = Scope("credential")
}

// iOS: Responses/AuthorizationPrepareResponse — just the built authorize URL.
public struct AuthorizationPrepareResponse {
    public let authorizationCodeURL: String
    public init(authorizationCodeURL!: String) { this.authorizationCodeURL = authorizationCodeURL }
}

// Percent-encode an OAuth query value. iOS uses `.oauthQueryValueAllowed`
// (urlQueryAllowed minus '+'); we encode everything except RFC3986 unreserved
// (A-Za-z0-9 -._~), which is stricter but decodes to the same value (safe for
// authorization_details JSON; a no-op for a base64url code_challenge).
func percentEncodeOAuth(s: String): String {
    let sb = StringBuilder()
    for (b in s.toArray()) {
        let c = Rune(b)
        if ((b >= b'A' && b <= b'Z') || (b >= b'a' && b <= b'z') || (b >= b'0' && b <= b'9')
            || c == r'-' || c == r'.' || c == r'_' || c == r'~') {
            sb.append(c)
        } else {
            sb.append("%")
            sb.append(hexUpper(b))
        }
    }
    return sb.toString()
}

func hexUpper(b: UInt8): String {
    let digits = "0123456789ABCDEF"
    let arr = digits.toArray()
    let hi = arr[Int64(b >> 4)]
    let lo = arr[Int64(b & 0x0F)]
    return String.fromUtf8([hi, lo])
}

// Join base + endpoint path avoiding a double slash. iOS: appendingEndpoint.
func joinAuthUrl(base: String, path: String): String {
    var b = base
    if (b.endsWith("/")) { b = b[0..b.size - 1] }
    return b + path
}

// One authorize-URL query item "k=v" (value raw, matching iOS percentEncodedQueryItems).
func qi(key: String, value: String): String {
    return "${key}=${value}"
}

// Build the /oauth2/authorize URL for the given scope. Shared by service/credential.
// iOS: PrepareAuthorizationRequestService.prepare{Service,Credential}Request.
func buildAuthorizeUrl(issuerURL: String, config: CSCClientConfig, scope: Scope,
                       walletState: String, codeChallenge: String,
                       authorizationDetails: ?String): String {
    let items = ArrayList<String>()
    items.add(qi("response_type", "code"))
    items.add(qi("client_id", config.oauth2Client.clientId))
    items.add(qi("redirect_uri", config.authFlowRedirectionURI))
    items.add(qi("scope", scope.rawValue))
    items.add(qi("code_challenge", percentEncodeOAuth(codeChallenge)))
    items.add(qi("code_challenge_method", "S256"))
    items.add(qi("state", walletState))
    match (authorizationDetails) {
        case Some(ad) => items.add(qi("authorization_details", percentEncodeOAuth(ad)))
        case None => ()
    }
    var query = ""
    var first = true
    for (it in items) {
        if (first) { query = it; first = false } else { query = query + "&" + it }
    }
    return joinAuthUrl(issuerURL, "/oauth2/authorize") + "?" + query
}

// Generates PKCE, builds the service-scope authorize URL. Returns (response, codeVerifier).
// Caller MUST keep codeVerifier and pass it to requestAccessTokenAuthFlow.
// iOS: RQES.prepareServiceAuthorizationRequest.
public func oauthPrepareServiceRequest(
    walletState: String, config: CSCClientConfig, issuerURL: String
): (AuthorizationPrepareResponse, String) {
    let verifier = pkceVerifier()
    let challenge = PKCEGenerator.generateCodeChallenge(verifier)
    let url = buildAuthorizeUrl(issuerURL, config, Scope.SERVICE, walletState, challenge, None)
    return (AuthorizationPrepareResponse(authorizationCodeURL: url), verifier)
}

// Credential-scope authorize (adds authorization_details). iOS: RQES.prepareCredentialAuthorizationRequest.
public func oauthPrepareCredentialRequest(
    walletState: String, config: CSCClientConfig, authorizationDetails: String, issuerURL: String
): (AuthorizationPrepareResponse, String) {
    let verifier = pkceVerifier()
    let challenge = PKCEGenerator.generateCodeChallenge(verifier)
    let url = buildAuthorizeUrl(issuerURL, config, Scope.CREDENTIAL, walletState, challenge, Some(authorizationDetails))
    return (AuthorizationPrepareResponse(authorizationCodeURL: url), verifier)
}

func pkceVerifier(): String {
    return match (PKCEGenerator.codeVerifier()) {
        case Some(v) => v
        case None => throw RqesCscException("failed to generate PKCE code verifier")
    }
}

// Exchange the authorization code for an access token. iOS: OAuth2TokenService.getToken
// → OAuth2TokenClient (POST issuerURL/oauth2/token, form body, Basic client auth).
public func oauthGetToken(
    request: AccessTokenRequest, config: CSCClientConfig, issuerURL: String, codeVerifier: String
): AccessTokenResponse {
    // form body — iOS OAuth2TokenRequest.toEncodedFormBody (values raw, authorization_details encoded)
    let parts = ArrayList<String>()
    parts.add(qi("client_id", config.oauth2Client.clientId))
    parts.add(qi("redirect_uri", config.authFlowRedirectionURI))
    parts.add(qi("grant_type", "authorization_code"))
    parts.add(qi("code_verifier", codeVerifier))
    parts.add(qi("code", request.code))
    parts.add(qi("state", request.state))
    match (request.authorizationDetails) {
        case Some(ad) => parts.add(qi("authorization_details", percentEncodeOAuth(ad)))
        case None => ()
    }
    var body = ""
    var first = true
    for (p in parts) {
        if (first) { body = p; first = false } else { body = body + "&" + p }
    }

    let headers = HashMap<String, String>()
    let basic = toBase64String("${config.oauth2Client.clientId}:${config.oauth2Client.clientSecret}".toArray())
    headers["Authorization"] = "Basic ${basic}"
    try {
        let resp = HttpPoster().post(joinAuthUrl(issuerURL, "/oauth2/token"), body,
            "application/x-www-form-urlencoded", headers)
        return AccessTokenResponse.fromJsonString(resp.body)
    } catch (e: PostError) {
        throw RqesCscException("OAuth2 token request failed: ${e}")
    }
}
