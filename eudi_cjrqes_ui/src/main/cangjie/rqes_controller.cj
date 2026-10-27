/*
 * RQESController — ports eudi-lib-ios-rqes-ui Sources/Domain/Controller/RQESController.swift.
 *
 * Thin seam over the RqesKit services held by the EudiRQESUi facade: it resolves the current
 * RQESService / RQESServiceAuthorized from the facade (throwing noRQESServiceProvided when
 * absent) and forwards each signing-flow call. iOS returns URL; this layer returns the URL
 * String (RqesKit already returns authorization URLs as Strings).
 *
 * CredentialInfo (iOS: RqesKit.CredentialInfo = CredentialsListResponse.CredentialInfo) is
 * the CSC layer's ListCredentialInfo.
 */
package ohos_app_cangjie_eudi_cjrqes_ui

import ohos_app_cangjie_eudi_cjrqes_kit.{RQESService, RQESServiceAuthorized, RQESServiceCredentialAuthorized, Document}
import ohos_app_cangjie_eudi_cjrqes_csc.ListCredentialInfo

public interface RQESController {
    func getServiceAuthorizationUrl(): String
    func authorizeService(authorizationCode: String): RQESServiceAuthorized
    func authorizeCredential(authorizationCode: String): RQESServiceCredentialAuthorized
    func signDocuments(authorizationCode: String): Array<Document>
    func getCredentialsList(): Array<ListCredentialInfo>
    func getCredentialAuthorizationUrl(credentialInfo: ListCredentialInfo, documents: Array<Document>): String
}

public class RQESControllerImpl <: RQESController {
    private let rqesUi: EudiRQESUi

    public init(rqesUi: EudiRQESUi) {
        this.rqesUi = rqesUi
    }

    public func getServiceAuthorizationUrl(): String {
        return requireService().getServiceAuthorizationUrl()
    }

    public func authorizeService(authorizationCode: String): RQESServiceAuthorized {
        return requireService().authorizeService(authorizationCode)
    }

    // iOS: getRQESService() — the fresh (unauthorized) service used to start the flow.
    private func requireService(): RQESService {
        return match (rqesUi.getRQESService()) {
            case Some(s) => s
            case None => throw EudiRQESUiError.noRQESServiceProvided()
        }
    }

    public func authorizeCredential(authorizationCode: String): RQESServiceCredentialAuthorized {
        return requireServiceAuthorized().authorizeCredential(authorizationCode)
    }

    public func signDocuments(authorizationCode: String): Array<Document> {
        let authorized = authorizeCredential(authorizationCode)
        return authorized.signDocuments()
    }

    public func getCredentialsList(): Array<ListCredentialInfo> {
        return requireServiceAuthorized().getCredentialsList()
    }

    public func getCredentialAuthorizationUrl(credentialInfo: ListCredentialInfo,
                                              documents: Array<Document>): String {
        return requireServiceAuthorized().getCredentialAuthorizationUrl(credentialInfo, documents)
    }

    // iOS: getRQESServiceAuthorized() — the service-authorized instance stored after authorizeService.
    private func requireServiceAuthorized(): RQESServiceAuthorized {
        return match (rqesUi.getRQESServiceAuthorized()) {
            case Some(s) => s
            case None => throw EudiRQESUiError.noRQESServiceProvided()
        }
    }
}
