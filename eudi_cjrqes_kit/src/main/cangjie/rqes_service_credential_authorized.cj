/*
 * RQESServiceCredentialAuthorized — ports eudi-lib-ios-rqes-kit
 * Sources/RqesKit/RQESServiceCredentialAuthorized.swift.
 *
 * Final stage: sign the previously-calculated hashes with the authorized credential, then
 * embed the returned signatures locally to produce the signed documents.
 *
 * The signHash call re-encodes the digests to base64 via DocumentDigests(digests:output:)
 * — PodofoSigner emits base64url, but the CSC signHash contract wants base64. This is the
 * DigestNormalizer trigger flagged throughout the port.
 */
package ohos_app_cangjie_eudi_cjrqes_kit

import std.collection.*
import ohos_app_cangjie_eudi_cjrqes_csc.*

public class RQESServiceCredentialAuthorized {
    let rqes: RQES
    let clientConfig: CSCClientConfig
    let credentialInfo: ListCredentialInfo
    let credentialAccessToken: String
    let documents: Array<Document>
    let calculateHashResponse: DocumentDigests
    let hashAlgorithmOID: HashAlgorithmOID
    let defaultSigningAlgorithmOID: ?SigningAlgorithmOID
    let fileExtension: String
    let outputURLs: Array<String>

    public init(credentialInfo: ListCredentialInfo, rqes!: RQES, clientConfig!: CSCClientConfig,
                credentialAccessToken!: String, documents!: Array<Document>,
                calculateHashResponse!: DocumentDigests, hashAlgorithmOID!: HashAlgorithmOID,
                defaultSigningAlgorithmOID!: ?SigningAlgorithmOID, fileExtension!: String,
                outputURLs!: Array<String>) {
        this.credentialInfo = credentialInfo
        this.rqes = rqes
        this.clientConfig = clientConfig
        this.credentialAccessToken = credentialAccessToken
        this.documents = documents
        this.calculateHashResponse = calculateHashResponse
        this.hashAlgorithmOID = hashAlgorithmOID
        this.defaultSigningAlgorithmOID = defaultSigningAlgorithmOID
        this.fileExtension = fileExtension
        this.outputURLs = outputURLs
    }

    // iOS: signDocuments — signHash (base64-normalized) then createSignedDocuments locally.
    public func signDocuments(signAlgorithmOID!: ?SigningAlgorithmOID = None): Array<Document> {
        let signAlgo = match (signAlgorithmOID) {
            case Some(a) => a
            case None => match (defaultSigningAlgorithmOID) {
                case Some(a) => a
                case None => throw RqesCscException("No signing algorithm provided")
            }
        }

        // STEP 12: sign the calculated hashes (normalized base64url → base64 for the CSC call).
        let normalizedHashes = DocumentDigests(digests: calculateHashResponse.hashes, output: DigestFormat.Base64).hashes
        let signHashRequest = SignHashRequest(
            credentialInfo.credentialID, normalizedHashes, hashAlgorithmOID, signAlgo, operationMode: "S")
        let signHashResponse = rqes.signHash(signHashRequest, credentialAccessToken)
        let signatures = match (signHashResponse.signatures) {
            case Some(s) => s
            case None => throw RqesCscException("No signatures provided")
        }

        // STEP 13: embed the signatures locally (no network / access token needed).
        rqes.createSignedDocuments(signatures)

        // The signed documents live at the output paths chosen during hash calculation.
        let out = ArrayList<Document>()
        for (i in 0..documents.size) {
            out.add(Document(id: documents[i].id, fileURL: outputURLs[i]))
        }
        return out.toArray()
    }
}
