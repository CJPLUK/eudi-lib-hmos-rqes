/*
 * podofo_signer.cj
 *
 * Cangjie binding over the C ABI exposed by libpodofo_rqes.so (podofo_ffi.h).
 * Mirrors the Android PoDoFoWrapper.java / iOS PodofoWrapper.h surface: a
 * handle-based RQES remote-signing session on top of EUDI's PoDoFo fork
 * (PdfRemoteSignDocumentSession).
 *
 * Flow:
 *   let signer = PodofoSigner("ADES_B_B", sha256Oid, inPdf, outPdf, certB64, chain)
 *   let hash = signer.calculateHash()          // -> send to remote CSC signer
 *   signer.finalizeSigning(signedHash)          // <- inject returned signature
 *   signer.close()
 */

package ohos_app_cangjie_eudi_cjrqes

// ---------------------------------------------------------------------------
// C ABI (resolved from libpodofo_rqes.so at link time; see cjpm link-options)
// ---------------------------------------------------------------------------
foreign {
    func podofo_create(conformanceLevel: CString, hashAlgorithm: CString,
                       inputPath: CString, outputPath: CString, certificate: CString,
                       chainCerts: CPointer<CString>, chainCertsCount: Int32): CPointer<Unit>

    func podofo_free_handle(handle: CPointer<Unit>): Unit
    func podofo_is_loaded(handle: CPointer<Unit>): Int32
    func podofo_print_state(handle: CPointer<Unit>): Unit

    func podofo_calculate_hash(handle: CPointer<Unit>): CString

    func podofo_finalize_signing(handle: CPointer<Unit>, signedHash: CString, tsr: CString,
                                 certs: CPointer<CString>, certsCount: Int32,
                                 crls: CPointer<CString>, crlsCount: Int32,
                                 ocsps: CPointer<CString>, ocspsCount: Int32): Int32

    func podofo_begin_signing_lta(handle: CPointer<Unit>): CString

    func podofo_finish_signing_lta(handle: CPointer<Unit>, tsr: CString,
                                   certs: CPointer<CString>, certsCount: Int32,
                                   crls: CPointer<CString>, crlsCount: Int32,
                                   ocsps: CPointer<CString>, ocspsCount: Int32): Int32

    func podofo_get_crl_from_certificate(handle: CPointer<Unit>, base64Cert: CString): CString
    func podofo_extract_signer_cert_from_tsr(handle: CPointer<Unit>, base64Tsr: CString): CString
    func podofo_extract_issuer_cert_from_tsr(handle: CPointer<Unit>, base64Tsr: CString): CString
    func podofo_get_ocsp_from_certificate(handle: CPointer<Unit>, base64Cert: CString, base64IssuerCert: CString): CString
    func podofo_build_ocsp_request(handle: CPointer<Unit>, base64Cert: CString, base64IssuerCert: CString): CString
    func podofo_get_certificate_issuer_url(handle: CPointer<Unit>, base64Cert: CString): CString

    func podofo_last_error(handle: CPointer<Unit>): CString
    func podofo_free_string(s: CString): Unit
}

// conformanceLevel is passed as a raw string ("ADES_B_B" | "ADES_B_T" | "ADES_B_LT" |
// "ADES_B_LTA"), mirroring iOS PodofoManager which passes doc.conformanceLevel.rawValue
// to the native wrapper. The typed ConformanceLevel lives in the CSC layer.

/** SHA-256 digest OID, the algorithm the CSC hash flow uses by default. */
public let SHA256_OID: String = "2.16.840.1.101.3.4.2.1"

public class PodofoException <: Exception {
    public init(message: String) {
        super(message)
    }
}

// ---------------------------------------------------------------------------
// Marshaling helpers
// ---------------------------------------------------------------------------

/**
 * Allocates a C `char*[]` from a Cangjie String array. Empty -> (null, 0).
 * The returned buffer AND every element must be released with freeCStringArray.
 */
func toCStringArray(items: Array<String>): (CPointer<CString>, Int32) {
    let n = items.size
    if (n == 0) {
        return (CPointer<CString>(), 0)
    }
    let buf = unsafe { LibC.malloc<CString>(count: n) }
    for (i in 0..n) {
        unsafe { buf.write(i, LibC.mallocCString(items[i])) }
    }
    return (buf, Int32(n))
}

func freeCStringArray(buf: CPointer<CString>, n: Int32): Unit {
    if (n == 0 || buf.isNull()) {
        return
    }
    for (i in 0..Int64(n)) {
        unsafe { LibC.free(buf.read(i)) }
    }
    unsafe { LibC.free(buf) }
}

// ---------------------------------------------------------------------------
// PodofoSigner
// ---------------------------------------------------------------------------

public class PodofoSigner {
    private var handle: CPointer<Unit>
    private var closed: Bool = false

    /**
     * Opens a remote-signing session for `inputPath`, writing the signed PDF to
     * `outputPath`. `certificate` and every `chainCertificates` entry are
     * base64(DER). Throws PodofoException if the native session fails to init.
     */
    public init(conformanceLevel: String, hashAlgorithmOid: String,
                inputPath: String, outputPath: String, certificate: String,
                chainCertificates: Array<String>) {
        let cl = unsafe { LibC.mallocCString(conformanceLevel) }
        let ha = unsafe { LibC.mallocCString(hashAlgorithmOid) }
        let inp = unsafe { LibC.mallocCString(inputPath) }
        let outp = unsafe { LibC.mallocCString(outputPath) }
        let cert = unsafe { LibC.mallocCString(certificate) }
        let (chain, chainN) = toCStringArray(chainCertificates)
        try {
            handle = unsafe { podofo_create(cl, ha, inp, outp, cert, chain, chainN) }
        } finally {
            unsafe { LibC.free(cl) }
            unsafe { LibC.free(ha) }
            unsafe { LibC.free(inp) }
            unsafe { LibC.free(outp) }
            unsafe { LibC.free(cert) }
            freeCStringArray(chain, chainN)
        }
        if (handle.isNull()) {
            throw PodofoException("podofo_create failed")
        }
    }

    /** True if the native session is initialized. */
    public func isLoaded(): Bool {
        ensureOpen()
        return unsafe { podofo_is_loaded(handle) } == 1
    }

    /** Prints internal state to the native log (debug). */
    public func printState(): Unit {
        ensureOpen()
        unsafe { podofo_print_state(handle) }
    }

    /** Step 1: returns the base64 hash to send to the remote CSC signer. */
    public func calculateHash(): String {
        ensureOpen()
        return takeString(unsafe { podofo_calculate_hash(handle) }, "calculateHash")
    }

    /** Step 2: injects the remote signature and optional DSS/LTV material. */
    public func finalizeSigning(signedHash: String, tsr!: String = "",
                                certificates!: Array<String> = [],
                                crls!: Array<String> = [],
                                ocsps!: Array<String> = []): Unit {
        ensureOpen()
        let sh = unsafe { LibC.mallocCString(signedHash) }
        let t = unsafe { LibC.mallocCString(tsr) }
        let (c, cn) = toCStringArray(certificates)
        let (r, rn) = toCStringArray(crls)
        let (o, on) = toCStringArray(ocsps)
        var rc: Int32 = -1
        try {
            rc = unsafe { podofo_finalize_signing(handle, sh, t, c, cn, r, rn, o, on) }
        } finally {
            unsafe { LibC.free(sh) }
            unsafe { LibC.free(t) }
            freeCStringArray(c, cn)
            freeCStringArray(r, rn)
            freeCStringArray(o, on)
        }
        if (rc != 0) {
            throw PodofoException("finalizeSigning: ${lastError()}")
        }
    }

    /** LTA step 1: returns the base64 hash to send to the Timestamping Authority. */
    public func beginSigningLTA(): String {
        ensureOpen()
        return takeString(unsafe { podofo_begin_signing_lta(handle) }, "beginSigningLTA")
    }

    /** LTA step 2: finalizes the archive timestamp with the TSA response. */
    public func finishSigningLTA(tsr: String, certificates!: Array<String> = [],
                                 crls!: Array<String> = [], ocsps!: Array<String> = []): Unit {
        ensureOpen()
        let t = unsafe { LibC.mallocCString(tsr) }
        let (c, cn) = toCStringArray(certificates)
        let (r, rn) = toCStringArray(crls)
        let (o, on) = toCStringArray(ocsps)
        var rc: Int32 = -1
        try {
            rc = unsafe { podofo_finish_signing_lta(handle, t, c, cn, r, rn, o, on) }
        } finally {
            unsafe { LibC.free(t) }
            freeCStringArray(c, cn)
            freeCStringArray(r, rn)
            freeCStringArray(o, on)
        }
        if (rc != 0) {
            throw PodofoException("finishSigningLTA: ${lastError()}")
        }
    }

    public func getCrlFromCertificate(base64Cert: String): String {
        return call1(base64Cert, "getCrlFromCertificate", { h, a => unsafe { podofo_get_crl_from_certificate(h, a) } })
    }
    public func extractSignerCertFromTSR(base64Tsr: String): String {
        return call1(base64Tsr, "extractSignerCertFromTSR", { h, a => unsafe { podofo_extract_signer_cert_from_tsr(h, a) } })
    }
    public func extractIssuerCertFromTSR(base64Tsr: String): String {
        return call1(base64Tsr, "extractIssuerCertFromTSR", { h, a => unsafe { podofo_extract_issuer_cert_from_tsr(h, a) } })
    }
    public func getOCSPFromCertificate(base64Cert: String, base64IssuerCert: String): String {
        return call2(base64Cert, base64IssuerCert, "getOCSPFromCertificate", { h, a, b => unsafe { podofo_get_ocsp_from_certificate(h, a, b) } })
    }
    public func buildOCSPRequest(base64Cert: String, base64IssuerCert: String): String {
        return call2(base64Cert, base64IssuerCert, "buildOCSPRequest", { h, a, b => unsafe { podofo_build_ocsp_request(h, a, b) } })
    }
    public func getCertificateIssuerUrl(base64Cert: String): String {
        return call1(base64Cert, "getCertificateIssuerUrl", { h, a => unsafe { podofo_get_certificate_issuer_url(h, a) } })
    }

    /** Releases the native session. Idempotent. */
    public func close(): Unit {
        if (!closed && handle.isNotNull()) {
            unsafe { podofo_free_handle(handle) }
        }
        closed = true
    }

    // --- internals ---------------------------------------------------------

    private func ensureOpen(): Unit {
        if (closed) {
            throw PodofoException("PodofoSigner is closed")
        }
    }

    private func lastError(): String {
        let cs = unsafe { podofo_last_error(handle) }
        if (cs.isNull()) {
            return ""
        }
        return cs.toString() // owned by the handle; must NOT be freed
    }

    // Takes ownership of a char* returned by the C layer: copies to a Cangjie
    // String and frees the native buffer. NULL is treated as an error.
    private func takeString(cs: CString, op: String): String {
        if (cs.isNull()) {
            throw PodofoException("${op}: ${lastError()}")
        }
        let s = cs.toString()
        unsafe { podofo_free_string(cs) }
        return s
    }

    private func call1(arg: String, op: String, f: (CPointer<Unit>, CString) -> CString): String {
        ensureOpen()
        let a = unsafe { LibC.mallocCString(arg) }
        let out = f(handle, a)
        unsafe { LibC.free(a) }
        return takeString(out, op)
    }

    private func call2(arg1: String, arg2: String, op: String, f: (CPointer<Unit>, CString, CString) -> CString): String {
        ensureOpen()
        let a = unsafe { LibC.mallocCString(arg1) }
        let b = unsafe { LibC.mallocCString(arg2) }
        let out = f(handle, a, b)
        unsafe { LibC.free(a) }
        unsafe { LibC.free(b) }
        return takeString(out, op)
    }
}
