// podofo_ffi.cpp
//
// C ABI bridge over EUDI's PoDoFo fork. Reuses the platform-neutral wrapper
// logic from the fork's Android JNI layer (src/wrapper/podofo_jni.cpp),
// dropping JNI/android_log, and exposes flat C functions for Cangjie FFI.

#include "podofo_ffi.h"

#include <podofo/podofo.h>
#include <podofo/main/PdfRemoteSignDocumentSession.h>

#include <string>
#include <vector>
#include <memory>
#include <optional>
#include <cstdlib>
#include <cstring>

using PoDoFo::PdfRemoteSignDocumentSession;
using PoDoFo::ValidationData;

// -------------------------------------------------------------------------
// Session object: thin wrapper over PdfRemoteSignDocumentSession, holding the
// last error message so the C layer can surface it to Cangjie.
// (Ported from the fork's PoDoFoWrapper C++ class; JNI removed.)
// -------------------------------------------------------------------------
namespace {

class PoDoFoSession {
public:
    std::unique_ptr<PdfRemoteSignDocumentSession> session;
    std::string lastError;

    static PoDoFoSession* create(const std::string& conformanceLevel,
                                 const std::string& hashAlgorithm,
                                 const std::string& inputPath,
                                 const std::string& outputPath,
                                 const std::string& certificate,
                                 const std::vector<std::string>& chainCertificates) {
        auto* self = new PoDoFoSession();
        try {
            self->session = std::make_unique<PdfRemoteSignDocumentSession>(
                conformanceLevel, hashAlgorithm, inputPath, outputPath,
                certificate, chainCertificates, std::nullopt);
            return self;
        } catch (const std::exception& e) {
            self->lastError = e.what();
            delete self;
            return nullptr;
        } catch (...) {
            delete self;
            return nullptr;
        }
    }
};

// Build a std::vector<std::string> from a C string array.
std::vector<std::string> toVector(const char* const* items, int count) {
    std::vector<std::string> out;
    if (!items || count <= 0) return out;
    out.reserve(count);
    for (int i = 0; i < count; ++i) {
        if (items[i]) out.emplace_back(items[i]);
    }
    return out;
}

// Assemble ValidationData from the three base64 arrays.
//
// iOS/Android parity: the reference wrappers build a ValidationData whenever the
// caller passes arrays (they are always non-nil from PodofoManager), i.e. the
// `std::optional` is effectively always engaged in every real flow — the
// nullopt case only exists for a caller that passes all-nil, which never
// happens. We mirror that exactly by ALWAYS returning an engaged optional, even
// when empty. This is behaviourally identical to the reference implementations:
//   - finishSigning() gates DSS creation on the conformance level (B_LT/B_LTA
//     only) and always receives a non-empty set there;
//   - finishSigningLTA() additionally guards on `!validationData->empty()`, so
//     an empty set skips DSS creation just as nullopt would.
// Returning an engaged-but-empty optional therefore removes any divergence from
// the iOS `if (certificates || crls || ocsps)` path without changing output.
std::optional<ValidationData> toValidationData(const char* const* certs, int nCerts,
                                               const char* const* crls, int nCrls,
                                               const char* const* ocsps, int nOcsps) {
    ValidationData vd;
    for (const auto& c : toVector(certs, nCerts)) vd.addCertificate(c);
    for (const auto& c : toVector(crls, nCrls))   vd.addCRL(c);
    for (const auto& c : toVector(ocsps, nOcsps)) vd.addOCSP(c);
    return vd;
}

// Duplicate a std::string into a heap char* (caller frees via podofo_free_string).
char* dup(const std::string& s) {
    char* p = static_cast<char*>(std::malloc(s.size() + 1));
    if (!p) return nullptr;
    std::memcpy(p, s.c_str(), s.size() + 1);
    return p;
}

PoDoFoSession* cast(void* h) { return static_cast<PoDoFoSession*>(h); }

} // namespace

// -------------------------------------------------------------------------
// C ABI
// -------------------------------------------------------------------------
extern "C" {

void* podofo_create(const char* conformanceLevel,
                    const char* hashAlgorithm,
                    const char* inputPath,
                    const char* outputPath,
                    const char* certificate,
                    const char* const* chainCerts,
                    int chainCertsCount) {
    return PoDoFoSession::create(
        conformanceLevel ? conformanceLevel : "",
        hashAlgorithm ? hashAlgorithm : "",
        inputPath ? inputPath : "",
        outputPath ? outputPath : "",
        certificate ? certificate : "",
        toVector(chainCerts, chainCertsCount));
}

void podofo_free_handle(void* handle) {
    delete cast(handle);
}

int podofo_is_loaded(void* handle) {
    auto* s = cast(handle);
    return (s && s->session) ? 1 : 0;
}

void podofo_print_state(void* handle) {
    auto* s = cast(handle);
    if (s && s->session) {
        try { s->session->printState(); } catch (...) {}
    }
}

char* podofo_calculate_hash(void* handle) {
    auto* s = cast(handle);
    if (!s || !s->session) return nullptr;
    try {
        std::string hash = s->session->beginSigning();
        return hash.empty() ? nullptr : dup(hash);
    } catch (const std::exception& e) {
        s->lastError = e.what();
        return nullptr;
    }
}

int podofo_finalize_signing(void* handle,
                            const char* signedHash,
                            const char* tsr,
                            const char* const* certs, int certsCount,
                            const char* const* crls, int crlsCount,
                            const char* const* ocsps, int ocspsCount) {
    auto* s = cast(handle);
    if (!s || !s->session) return -1;
    if (!signedHash || !*signedHash) { s->lastError = "signedHash is empty"; return -1; }
    try {
        auto vd = toValidationData(certs, certsCount, crls, crlsCount, ocsps, ocspsCount);
        s->session->finishSigning(signedHash, tsr ? tsr : "", vd);
        return 0;
    } catch (const std::exception& e) {
        s->lastError = e.what();
        return -1;
    }
}

char* podofo_begin_signing_lta(void* handle) {
    auto* s = cast(handle);
    if (!s || !s->session) return nullptr;
    try {
        std::string hash = s->session->beginSigningLTA();
        return hash.empty() ? nullptr : dup(hash);
    } catch (const std::exception& e) {
        s->lastError = e.what();
        return nullptr;
    }
}

int podofo_finish_signing_lta(void* handle,
                              const char* tsr,
                              const char* const* certs, int certsCount,
                              const char* const* crls, int crlsCount,
                              const char* const* ocsps, int ocspsCount) {
    auto* s = cast(handle);
    if (!s || !s->session) return -1;
    try {
        auto vd = toValidationData(certs, certsCount, crls, crlsCount, ocsps, ocspsCount);
        s->session->finishSigningLTA(tsr ? tsr : "", vd);
        return 0;
    } catch (const std::exception& e) {
        s->lastError = e.what();
        return -1;
    }
}

// -- cert/revocation helpers: shared body via a small macro -----------------
#define PODOFO_STR_CALL(expr)                                   \
    auto* s = cast(handle);                                     \
    if (!s || !s->session) return nullptr;                     \
    try {                                                       \
        std::string r = (expr);                                \
        return r.empty() ? nullptr : dup(r);                   \
    } catch (const std::exception& e) {                        \
        s->lastError = e.what();                               \
        return nullptr;                                        \
    }

char* podofo_get_crl_from_certificate(void* handle, const char* base64Cert) {
    PODOFO_STR_CALL(s->session->getCrlFromCertificate(base64Cert ? base64Cert : ""))
}
char* podofo_extract_signer_cert_from_tsr(void* handle, const char* base64Tsr) {
    PODOFO_STR_CALL(s->session->extractSignerCertFromTSR(base64Tsr ? base64Tsr : ""))
}
char* podofo_extract_issuer_cert_from_tsr(void* handle, const char* base64Tsr) {
    PODOFO_STR_CALL(s->session->extractIssuerCertFromTSR(base64Tsr ? base64Tsr : ""))
}
char* podofo_get_ocsp_from_certificate(void* handle, const char* base64Cert, const char* base64IssuerCert) {
    PODOFO_STR_CALL(s->session->getOCSPFromCertificate(base64Cert ? base64Cert : "", base64IssuerCert ? base64IssuerCert : ""))
}
char* podofo_build_ocsp_request(void* handle, const char* base64Cert, const char* base64IssuerCert) {
    PODOFO_STR_CALL(s->session->buildOCSPRequestFromCertificates(base64Cert ? base64Cert : "", base64IssuerCert ? base64IssuerCert : ""))
}
char* podofo_get_certificate_issuer_url(void* handle, const char* base64Cert) {
    PODOFO_STR_CALL(s->session->getCertificateIssuerUrlFromCertificate(base64Cert ? base64Cert : ""))
}
#undef PODOFO_STR_CALL

const char* podofo_last_error(void* handle) {
    auto* s = cast(handle);
    return (s && !s->lastError.empty()) ? s->lastError.c_str() : "";
}

void podofo_free_string(char* p) {
    std::free(p);
}

} // extern "C"
