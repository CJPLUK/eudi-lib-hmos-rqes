/*
 * CSC client configuration — 1:1 port of
 * eudi-lib-ios-rqes-csc-swift Sources/Requests/CSCClientConfig.swift.
 */
package ohos_app_cangjie_eudi_cjrqes_csc

// OAuth2 client credentials for the QTSP authorization server.
// iOS: CSCClientConfig.OAuth2Client
public struct OAuth2Client {
    public let clientId: String
    public let clientSecret: String

    public init(clientId: String, clientSecret: String) {
        this.clientId = clientId
        this.clientSecret = clientSecret
    }
}

// Configuration for the CSC (RSSP/QTSP) client.
// iOS: CSCClientConfig — tsaUrl defaults to "" and includeRevocationInfo to false,
// matching the Swift init's default parameter values.
public struct CSCClientConfig {
    public let oauth2Client: OAuth2Client
    public let authFlowRedirectionURI: String
    public let rsspId: String
    public let tsaUrl: String
    public let includeRevocationInfo: Bool

    public init(
        oauth2Client: OAuth2Client,
        authFlowRedirectionURI: String,
        rsspId: String,
        tsaUrl!: String = "",
        includeRevocationInfo!: Bool = false
    ) {
        this.oauth2Client = oauth2Client
        this.authFlowRedirectionURI = authFlowRedirectionURI
        this.rsspId = rsspId
        this.tsaUrl = tsaUrl
        this.includeRevocationInfo = includeRevocationInfo
    }
}
