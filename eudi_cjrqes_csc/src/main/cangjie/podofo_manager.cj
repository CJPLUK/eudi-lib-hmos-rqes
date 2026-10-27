/*
 * PodofoManager — the single seam that drives the native PodofoSigner, ported from
 * eudi-lib-ios-rqes-csc-swift Sources/PodofoManager. B_B only for now (see PORT_TODO).
 *
 * Two-phase, one session per input document:
 *   calculateDocumentHashes → PodofoSigner(...).calculateHash()  (base64url hash out)
 *   createSignedDocuments   → PodofoSigner.finalizeSigning(sig)   (remote signature in)
 *
 * iOS keeps the wrappers alive between the two calls in a `sessions` array indexed
 * by document order; we mirror that. Signatures returned by the CSC signHash come
 * back in the SAME order the hashes went out, so we zip by index.
 */
package ohos_app_cangjie_eudi_cjrqes_csc

import std.collection.*
import ohos_app_cangjie_eudi_cjrqes.PodofoSigner

// One in-flight signing session (iOS: PodofoManager's per-document PodofoWrapper entry).
struct PodofoSession {
    let signer: PodofoSigner
    let conformanceLevel: ConformanceLevel
    init(signer: PodofoSigner, conformanceLevel: ConformanceLevel) {
        this.signer = signer
        this.conformanceLevel = conformanceLevel
    }
}

public class PodofoManager {
    private let includeRevocationInfo: Bool
    private var sessions: ArrayList<PodofoSession> = ArrayList<PodofoSession>()

    public init(includeRevocationInfo!: Bool = false) {
        this.includeRevocationInfo = includeRevocationInfo
    }

    // iOS: calculateDocumentHashes — one PodofoSigner per document; collect the hashes
    // (base64url) and keep each wrapper alive for the matching createSignedDocuments call.
    public func calculateDocumentHashes(request: CalculateHashRequest, tsaUrl: String): DocumentDigests {
        closeSessions()
        let hashes = ArrayList<String>()
        for (doc in request.documents) {
            let signer = PodofoSigner(
                doc.conformanceLevel.rawValue,
                request.hashAlgorithmOID.rawValue,
                doc.documentInputPath,
                doc.documentOutputPath,
                request.endEntityCertificate,
                request.certificateChain)
            hashes.add(signer.calculateHash())
            sessions.add(PodofoSession(signer, doc.conformanceLevel))
        }
        return DocumentDigests(hashes.toArray())
    }

    // iOS: createSignedDocuments — inject each remote signature into its session's
    // wrapper. B_B: finalizeSigning(signature) with tsr="" and empty validation arrays.
    // B_T/B_LT/B_LTA require the TSA/DSS flow and are not implemented yet.
    public func createSignedDocuments(signatures: Array<String>, tsaUrl: String): Unit {
        if (signatures.size != sessions.size) {
            closeSessions()
            throw RqesCscException(
                "signatures/sessions count mismatch: ${signatures.size} signatures for ${sessions.size} documents")
        }
        try {
            for (i in 0..sessions.size) {
                let session = sessions[i]
                if (session.conformanceLevel.rawValue == ConformanceLevel.ADES_B_B.rawValue) {
                    session.signer.finalizeSigning(signatures[i])
                } else {
                    throw RqesCscException(
                        "conformance level ${session.conformanceLevel.rawValue} not yet implemented (B_B only)")
                }
            }
        } finally {
            closeSessions()
        }
    }

    // Release any native handles still held and reset the session list.
    private func closeSessions(): Unit {
        for (s in sessions) {
            s.signer.close()
        }
        sessions.clear()
    }
}
