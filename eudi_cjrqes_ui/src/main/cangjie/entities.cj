/*
 * EudiRQESUi Domain entities — ports eudi-lib-ios-rqes-ui Sources/Domain/Entities
 * (QTSPData, DocumentData, SessionData, EudiRQESUiError) + the EudiRQESUi.State machine enum.
 *
 * This is the UI-independent "logic 底座" of the RQES signing SDK: the data the flow
 * threads (selected document, chosen QTSP, chosen credential, auth code, credential list)
 * and the state the flow advances through. No ArkUI here (mirrors the project's UI-free
 * interactor rule); the SwiftUI→ArkUI Presentation layer is a later phase.
 *
 * URL → String path (this layer has no URL type; iOS reduces URLs to paths at the RqesKit
 * boundary anyway). CredentialInfo = RqesKit's CredentialsListResponse.CredentialInfo =
 * the CSC layer's ListCredentialInfo.
 */
package ohos_app_cangjie_eudi_cjrqes_ui

import ohos_app_cangjie_eudi_cjrqes_csc.{HashAlgorithmOID, ListCredentialInfo}

// iOS: Domain/Entities/QTSPData.swift — one remote signing service provider entry.
public struct QTSPData {
    public let name: String
    public let rsspId: String
    public let tsaUrl: ?String
    public let clientId: String
    public let clientSecret: String
    public let authFlowRedirectionURI: String
    public let hashAlgorithm: HashAlgorithmOID
    public let includeRevocationInfo: Bool

    public init(name!: String, rsspId!: String, tsaUrl!: ?String, clientId!: String,
                clientSecret!: String, authFlowRedirectionURI!: String,
                hashAlgorithm!: HashAlgorithmOID, includeRevocationInfo!: Bool) {
        this.name = name
        this.rsspId = rsspId
        this.tsaUrl = tsaUrl
        this.clientId = clientId
        this.clientSecret = clientSecret
        this.authFlowRedirectionURI = authFlowRedirectionURI
        this.hashAlgorithm = hashAlgorithm
        this.includeRevocationInfo = includeRevocationInfo
    }
}

// iOS: Domain/Entities/DocumentData.swift — the document selected for signing.
// `uri` is a filesystem path (iOS: URL).
public struct DocumentData {
    public let documentName: String
    public let uri: String

    public init(documentName!: String, uri!: String) {
        this.documentName = documentName
        this.uri = uri
    }
}

// iOS: Domain/Entities/SessionData.swift (@Copyable) — the mutable flow state carried by
// the EudiRQESUi facade. Cangjie has no @Copyable; copyWith() reproduces the Swift copy(…).
public struct SessionData {
    public let document: ?DocumentData
    public let qtsp: ?QTSPData
    public let certificate: ?ListCredentialInfo
    public let code: ?String
    public let credentialCertificate: ?Array<ListCredentialInfo>

    public init(document!: ?DocumentData = None, qtsp!: ?QTSPData = None,
                certificate!: ?ListCredentialInfo = None, code!: ?String = None,
                credentialCertificate!: ?Array<ListCredentialInfo> = None) {
        this.document = document
        this.qtsp = qtsp
        this.certificate = certificate
        this.code = code
        this.credentialCertificate = credentialCertificate
    }

    // Swift @Copyable copy(field:) — pass Some(newValue) to replace a field, None to keep it.
    // (Note: mirrors iOS where copy(x:) always replaces; here a field is only replaced when a
    //  value is supplied, so callers pass the field they intend to change.)
    public func copyWith(document!: ?DocumentData = None, qtsp!: ?QTSPData = None,
                         certificate!: ?ListCredentialInfo = None, code!: ?String = None,
                         credentialCertificate!: ?Array<ListCredentialInfo> = None): SessionData {
        return SessionData(
            document: coalesce(document, this.document),
            qtsp: coalesce(qtsp, this.qtsp),
            certificate: coalesce(certificate, this.certificate),
            code: coalesce(code, this.code),
            credentialCertificate: coalesce(credentialCertificate, this.credentialCertificate))
    }
}

func coalesce<T>(newV: ?T, oldV: ?T): ?T {
    return match (newV) {
        case Some(_) => newV
        case None => oldV
    }
}

// iOS: EudiRQESUi.State — the signing flow state machine.
public enum RqesUiState {
    | none
    | initial
    | rssps
    | credentials
    | sign
    | view

    public func id(): String {
        return match (this) {
            case none => "none"
            case initial => "initial"
            case rssps => "rssps"
            case credentials => "credentials"
            case sign => "sign"
            case view => "view"
        }
    }
}

// iOS: Domain/Entities/Error/EudiRQESUiError.swift
public class EudiRQESUiError <: Exception {
    public init(message: String) { super(message) }

    public static func notInitialized(): EudiRQESUiError {
        EudiRQESUiError("You need to initialize the EudiRQESUi SDK first with an EudiRQESUiConfig Impl")
    }
    public static func invalidState(stateName: String): EudiRQESUiError {
        EudiRQESUiError("State is Invalid - ${stateName}")
    }
    public static func unableToFetchCredentials(): EudiRQESUiError {
        EudiRQESUiError("unableToFetchCredentials")
    }
    public static func unableToSignHashDocument(): EudiRQESUiError {
        EudiRQESUiError("unableToSignHashDocument")
    }
    public static func unableToOpenURL(): EudiRQESUiError {
        EudiRQESUiError("unableToOpenURL")
    }
    public static func noRQESServiceProvided(): EudiRQESUiError {
        EudiRQESUiError("noRQESServiceProvided")
    }
    public static func noDocumentProvided(): EudiRQESUiError {
        EudiRQESUiError("noDocumentProvided")
    }
}
