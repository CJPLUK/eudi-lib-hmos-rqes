/*
 * EudiRQESUi — ports the UI-independent surface of eudi-lib-ios-rqes-ui
 * Sources/Infrastructure/EudiRQESUi.swift: the shared instance, the session/service/state
 * it holds, and the accessors the Controller/Interactor drive.
 *
 * Deferred to the Presentation phase (4b): the router (RouterGraph), the presented
 * UIViewController, the ThemeManager, DIGraph.load(), and the launcSDK() view presentation
 * inside initiate()/resume(). Here initiate()/resume() perform only their state-preparation
 * half; the actual screen launch is a 4b TODO.
 *
 * iOS models this as an `actor` for serialized access across concurrent tasks. The signing
 * flow is strictly sequential (user-driven, one step at a time) and the project's ported
 * interactors are plain UI-free seams, so this is a plain class (actor → class), matching
 * the established Harmony idiom.
 */
package ohos_app_cangjie_eudi_cjrqes_ui

import ohos_app_cangjie_eudi_cjrqes_kit.{RQESService, RQESServiceAuthorized}
import ohos_app_cangjie_eudi_cjrqes_csc.ListCredentialInfo

public class EudiRQESUi {
    private static var _shared: ?EudiRQESUi = None
    private static var _config: ?EudiRQESUiConfig = None

    private var state: RqesUiState = RqesUiState.none
    private var session: SessionData = SessionData()
    private var rqesService: ?RQESService = None
    private var rqesServiceAuthorized: ?RQESServiceAuthorized = None

    // iOS: init(config:) — loads the DI graph, builds the router/theme, registers the
    // shared instance. Router/theme/DIGraph belong to the Presentation phase (4b).
    public init(config: EudiRQESUiConfig) {
        EudiRQESUi._config = Some(config)
        EudiRQESUi._shared = Some(this)
    }

    // iOS: EudiRQESUi.instance() — the registered shared instance, or notInitialized.
    public static func instance(): EudiRQESUi {
        return match (_shared) {
            case Some(i) => i
            case None => throw EudiRQESUiError.notInitialized()
        }
    }

    static func requireConfig(): EudiRQESUiConfig {
        return match (_config) {
            case Some(c) => c
            case None => throw EudiRQESUiError.notInitialized()
        }
    }

    // iOS: initiate(on:fileUrl:) — reset, select the document, enter .initial.
    // (4b: then launcSDK presents the first screen.)
    public func initiate(fileUri: String): Unit {
        resetCache()
        updateSelectionDocument(DocumentData(documentName: lastPathComponent(fileUri), uri: fileUri))
        setState(RqesUiState.initial)
    }

    // iOS: resume(on:authorizationCode:) — advance the state machine, store the auth code.
    // (4b: then launcSDK presents the next screen.)
    public func resume(authorizationCode: String): Unit {
        setState(calculateNextState())
        updateAuthorizationCode(authorizationCode)
    }

    // ── session / service accessors (1:1 with iOS) ───────────────────────────────────
    // iOS: updateSelectionDocument(with:) / updateQTSP(with:) — both take optionals.
    public func updateSelectionDocument(document: ?DocumentData): Unit {
        session = session.copyWith(document: document)
    }
    public func updateQTSP(qtsp: ?QTSPData): Unit {
        session = session.copyWith(qtsp: qtsp)
    }
    public func updateCertificate(certificate: ListCredentialInfo): Unit {
        session = session.copyWith(certificate: certificate)
    }
    public func updateCredentialInfo(info: Array<ListCredentialInfo>): Unit {
        session = session.copyWith(credentialCertificate: info)
    }
    public func getCredentialInfo(): ?Array<ListCredentialInfo> {
        return session.credentialCertificate
    }
    public func getSessionData(): SessionData {
        return session
    }
    public func getState(): RqesUiState {
        return state
    }
    public func getRQESService(): ?RQESService {
        return rqesService
    }
    public func setRQESService(service: ?RQESService): Unit {
        rqesService = service
    }
    public func getRQESServiceAuthorized(): ?RQESServiceAuthorized {
        return rqesServiceAuthorized
    }
    public func setRQESServiceAuthorized(service: ?RQESServiceAuthorized): Unit {
        rqesServiceAuthorized = service
    }
    public func getRssps(): Array<QTSPData> {
        return EudiRQESUi.requireConfig().rssps
    }

    // ── private state machine (1:1 with iOS) ─────────────────────────────────────────
    func calculateNextState(): RqesUiState {
        return match (state) {
            case none => RqesUiState.initial
            case initial => RqesUiState.credentials
            case rssps => RqesUiState.credentials
            case credentials => RqesUiState.sign
            case sign => RqesUiState.view
            case view => RqesUiState.view
        }
    }
    func setState(s: RqesUiState): Unit {
        state = s
    }
    func resetCache(): Unit {
        session = SessionData()
        setRQESService(None)
        setRQESServiceAuthorized(None)
    }
    func updateAuthorizationCode(code: String): Unit {
        session = session.copyWith(code: code)
    }
}
