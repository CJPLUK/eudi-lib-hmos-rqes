/*
 * CSC endpoint HTTP layer — ports the per-endpoint clients from
 * eudi-lib-ios-rqes-csc-swift Sources/Http (SignHashClient / CredentialsListClient /
 * CredentialsInfoHttpClient). Reuses the wallet's existing HttpPoster (openid4vp_vci)
 * instead of a second networking stack.
 *
 * iOS pattern for these three (all Bearer-authenticated CSC endpoints on rsspUrl):
 *   POST rsspUrl + "/<endpoint>", Content-Type: application/json, Accept: application/json,
 *   Authorization: Bearer <token>, body = JSONEncoder(request), then handleResponse:
 *   2xx → decode JSON; else → ClientError(message, statusCode).
 *
 * getInfo (no auth) and oauth2/token (Basic auth, form body, on the OAuth server URL)
 * are handled in the OAuth chunk where they are consumed — see PORT_TODO.md.
 */
package ohos_app_cangjie_eudi_cjrqes_csc

import std.collection.*
import ohos_app_cangjie_eudi_cjopenid4vp_vci.openid4vci.network.{HttpPoster, PostError, ResponseWithHeaders}

// Join an RSSP base URL with an endpoint path, avoiding a double slash.
// iOS: String.appendingEndpoint(...).
func joinUrl(base: String, path: String): String {
    var b = base
    if (b.endsWith("/")) {
        b = b[0..b.size - 1]
    }
    return b + path
}

// POST a JSON body to a CSC endpoint. Mirrors the iOS clients' header setup and
// HandleResponse: HttpPoster.post already throws PostError on non-2xx (server/client
// error), which we surface as RqesCscException; on 2xx it returns the body string.
func cscPostJson(url: String, jsonBody: String, accessToken: ?String): String {
    let headers = HashMap<String, String>()
    match (accessToken) {
        case Some(t) => headers["Authorization"] = "Bearer ${t}"
        case None => ()
    }
    headers["Accept"] = "application/json"
    try {
        let resp: ResponseWithHeaders = HttpPoster().post(url, jsonBody, "application/json", headers)
        return resp.body
    } catch (e: PostError) {
        throw RqesCscException("CSC request to ${url} failed: ${e}")
    }
}

// CSC `credentials/list`. iOS: CredentialsListService → CredentialsListClient.
public func cscListCredentials(rsspUrl: String, request: CredentialsListRequest, accessToken: String): CredentialsListResponse {
    let body = cscPostJson(joinUrl(rsspUrl, "/credentials/list"), request.toJsonString(), Some(accessToken))
    return CredentialsListResponse.fromJsonString(body)
}

// CSC `credentials/info`. iOS: CredentialsInfoService → CredentialsInfoHttpClient.
public func cscGetCredentialInfo(rsspUrl: String, request: CredentialsInfoRequest, accessToken: String): CredentialInfo {
    let body = cscPostJson(joinUrl(rsspUrl, "/credentials/info"), request.toJsonString(), Some(accessToken))
    return CredentialInfo.fromJsonString(body)
}

// CSC `signatures/signHash` (the remote signing call). iOS: SignHashService → SignHashClient.
public func cscSignHash(rsspUrl: String, request: SignHashRequest, accessToken: String): SignHashResponse {
    let body = cscPostJson(joinUrl(rsspUrl, "/signatures/signHash"), request.toJsonString(), Some(accessToken))
    return SignHashResponse.fromJsonString(body)
}
