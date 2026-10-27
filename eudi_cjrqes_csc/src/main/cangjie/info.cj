/*
 * CSC `info` endpoint — iOS: Services/InfoService + Http/InfoClient +
 * Requests/InfoServiceRequest + Responses/InfoServiceResponse.
 *
 * Used by RQES.prepareServiceAuthorizationRequest to discover the OAuth2 server URL
 * (the `oauth2` field), which becomes issuerURL for the authorize/token calls.
 * We parse the flat fields B_B needs; the nested capability metadata (methods,
 * signAlgorithms, oauth2Servers…) is parsed opportunistically — see PORT_TODO.md.
 */
package ohos_app_cangjie_eudi_cjrqes_csc

import stdx.encoding.json.*

// iOS: Requests/InfoServiceRequest (lang defaults to "en-US").
public struct InfoServiceRequest {
    public let lang: String
    public init(lang!: String = "en-US") { this.lang = lang }

    public func toJsonString(): String {
        let obj = JsonObject()
        obj.put("lang", JsonString(lang))
        return obj.toJsonString()
    }
}

// iOS: Responses/InfoServiceResponse. `oauth2` is the OAuth2 authorization server URL.
public struct InfoServiceResponse {
    public let oauth2: String
    public let oauth2Issuer: ?String
    public let name: ?String
    public let region: ?String
    public let description: ?String
    public let conformanceLevels: ?Array<String>

    public init(oauth2!: String, oauth2Issuer!: ?String = None, name!: ?String = None,
                region!: ?String = None, description!: ?String = None,
                conformanceLevels!: ?Array<String> = None) {
        this.oauth2 = oauth2
        this.oauth2Issuer = oauth2Issuer
        this.name = name
        this.region = region
        this.description = description
        this.conformanceLevels = conformanceLevels
    }

    public static func fromJsonString(s: String): InfoServiceResponse {
        let obj = rootObject(s)
        return InfoServiceResponse(
            oauth2: reqStr(obj, "oauth2"),
            oauth2Issuer: optStr(obj, "oauth2Issuer"),
            name: optStr(obj, "name"),
            region: optStr(obj, "region"),
            description: optStr(obj, "description"),
            conformanceLevels: optStrArray(obj, "conformanceLevels"))
    }
}

// CSC `info` (public, no Bearer auth). iOS: InfoService → InfoClient (POST /info, JSON body).
public func cscGetInfo(rsspUrl: String, request: InfoServiceRequest): InfoServiceResponse {
    let body = cscPostJson(joinUrl(rsspUrl, "/info"), request.toJsonString(), None)
    return InfoServiceResponse.fromJsonString(body)
}
