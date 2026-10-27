/*
 * RQESInteractor — ports eudi-lib-ios-rqes-ui Sources/Domain/Interactor/RQESInteractor.swift.
 *
 * The signing-flow orchestrator: reads/writes the EudiRQESUi session, builds the RQESService
 * from the chosen QTSP, and drives the RQESController through service authorization, credential
 * fetch/selection, credential authorization, and the final sign. Pure UI-free logic seam
 * (iOS: `final actor`); the ArkUI ViewModels of the Presentation phase (4b) will call it and
 * marshal the blocking calls off the UI thread via spawn{}.
 */
package ohos_app_cangjie_eudi_cjrqes_ui

import ohos_app_cangjie_eudi_cjrqes_kit.{Document, RQESService, uuidV4}
import ohos_app_cangjie_eudi_cjrqes_csc.{CSCClientConfig, OAuth2Client, ListCredentialInfo}

// iOS fetchCredentials returns Result<[CredentialInfo], Error>; Cangjie has no Result, so a
// small sum type carries either the credentials or the failure for the ViewModel to branch on.
public enum FetchCredentialsResult {
    | success(Array<ListCredentialInfo>)
    | failure(Exception)
}

public interface RQESInteractor {
    func signDocument(): ?Document
    func getSession(): ?SessionData
    func getQTSps(): Array<QTSPData>
    func fetchCredentials(): FetchCredentialsResult
    func updateQTSP(qtsp: ?QTSPData): Unit
    func updateDocument(url: String): Unit
    func createRQESService(qtsp: QTSPData): Unit
    func saveCertificate(certificate: ListCredentialInfo): Unit
    func openAuthrorizationURL(): String
    func openCredentialAuthrorizationURL(): String
}

public class RQESInteractorImpl <: RQESInteractor {
    private let rqesUi: EudiRQESUi
    private let rqesController: RQESController

    public init(rqesUi: EudiRQESUi, rqesController: RQESController) {
        this.rqesUi = rqesUi
        this.rqesController = rqesController
    }

    // iOS: createRQESService — needs the selected document's extension; builds & stores the service.
    public func createRQESService(qtsp: QTSPData): Unit {
        let uri = match (currentDocument()) {
            case Some(d) => d.uri
            case None => throw EudiRQESUiError.noDocumentProvided()
        }
        let fileExtension = pathExtension(uri)
        if (fileExtension.isEmpty()) {
            throw EudiRQESUiError.noDocumentProvided()
        }
        let tsa = match (qtsp.tsaUrl) {
            case Some(t) => t
            case None => ""
        }
        let clientConfig = CSCClientConfig(
            OAuth2Client(qtsp.clientId, qtsp.clientSecret),
            qtsp.authFlowRedirectionURI,
            qtsp.rsspId,
            tsaUrl: tsa,
            includeRevocationInfo: qtsp.includeRevocationInfo)
        rqesUi.setRQESService(RQESService(
            clientConfig: clientConfig,
            defaultHashAlgorithmOID: qtsp.hashAlgorithm,
            fileExtension: ".${fileExtension}"))
    }

    // iOS: signDocument — sign with the stored auth code, return the first signed document.
    public func signDocument(): ?Document {
        let code = currentCode()
        return match (code) {
            case Some(c) =>
                let signed = rqesController.signDocuments(c)
                if (signed.isEmpty()) { None } else { Some(signed[0]) }
            case None => throw EudiRQESUiError.unableToSignHashDocument()
        }
    }

    public func getSession(): ?SessionData {
        return Some(rqesUi.getSessionData())
    }

    public func updateQTSP(qtsp: ?QTSPData): Unit {
        rqesUi.updateQTSP(qtsp)
    }

    // iOS: updateDocument — keep the existing name, swap the uri to the new url.
    public func updateDocument(url: String): Unit {
        match (currentDocument()) {
            case Some(d) => rqesUi.updateSelectionDocument(DocumentData(documentName: d.documentName, uri: url))
            case None => ()
        }
    }

    // iOS: getQTSps — the configured RSSP list, or [] if unavailable.
    public func getQTSps(): Array<QTSPData> {
        try {
            return rqesUi.getRssps()
        } catch (_: Exception) {
            return Array<QTSPData>()
        }
    }

    public func openAuthrorizationURL(): String {
        return rqesController.getServiceAuthorizationUrl()
    }

    // iOS: openCredentialAuthrorizationURL — needs the selected document + chosen certificate.
    public func openCredentialAuthrorizationURL(): String {
        let sess = rqesUi.getSessionData()
        let uriOpt: ?String = match (sess.document) {
            case Some(d) => Some(d.uri)
            case None => None
        }
        match ((uriOpt, sess.certificate)) {
            case (Some(uri), Some(certificate)) =>
                let unsignedDocuments = [Document(id: uuidV4(), fileURL: uri)]
                return rqesController.getCredentialAuthorizationUrl(certificate, unsignedDocuments)
            case _ => throw EudiRQESUiError.noDocumentProvided()
        }
    }

    // iOS: fetchCredentials — cached list if present; else authorize the service and list credentials.
    public func fetchCredentials(): FetchCredentialsResult {
        match (rqesUi.getCredentialInfo()) {
            case Some(creds) => return FetchCredentialsResult.success(creds)
            case None => ()
        }
        match (currentCode()) {
            case Some(code) =>
                try {
                    let authorized = rqesController.authorizeService(code)
                    rqesUi.setRQESServiceAuthorized(authorized)
                    let creds = rqesController.getCredentialsList()
                    rqesUi.updateCredentialInfo(creds)
                    return FetchCredentialsResult.success(creds)
                } catch (e: Exception) {
                    return FetchCredentialsResult.failure(e)
                }
            case None => return FetchCredentialsResult.failure(EudiRQESUiError.unableToFetchCredentials())
        }
    }

    public func saveCertificate(certificate: ListCredentialInfo): Unit {
        rqesUi.updateCertificate(certificate)
    }

    // ── helpers ──────────────────────────────────────────────────────────────────────
    private func currentDocument(): ?DocumentData {
        return rqesUi.getSessionData().document
    }
    private func currentCode(): ?String {
        return rqesUi.getSessionData().code
    }
}
