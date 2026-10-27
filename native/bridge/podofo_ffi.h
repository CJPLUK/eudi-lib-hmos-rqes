// podofo_ffi.h
//
// C ABI bridge over EUDI's PoDoFo fork (PdfRemoteSignDocumentSession), for
// consumption from Cangjie via `foreign func`. Mirrors the Android JNI wrapper
// (src/wrapper/podofo_jni.*) and the iOS PodofoWrapper.h, exposing the same
// RQES remote-signing surface as flat C functions.
//
// Conventions:
//   * Handle: opaque void* (a PoDoFoWrapper*). NULL means creation failed.
//   * Returned char* are heap-allocated; the caller MUST free with
//     podofo_free_string(). NULL return means "no value / error".
//   * Functions returning int use 0 for success, -1 for error.
//   * On any error the human-readable message is retrievable via
//     podofo_last_error(handle) (per-handle) until the next call.
//   * String-array params are (const char* const* items, int count).

#ifndef PODOFO_FFI_H
#define PODOFO_FFI_H

#ifdef __cplusplus
extern "C" {
#endif

// --- Session lifecycle ---------------------------------------------------

/// Creates a signing session. conformanceLevel is one of
/// "ADES_B_B" | "ADES_B_T" | "ADES_B_LT" | "ADES_B_LTA".
/// Returns an opaque handle, or NULL on failure.
void* podofo_create(const char* conformanceLevel,
                    const char* hashAlgorithm,
                    const char* inputPath,
                    const char* outputPath,
                    const char* certificate,
                    const char* const* chainCerts,
                    int chainCertsCount);

/// Destroys a session created by podofo_create(). NULL-safe.
void podofo_free_handle(void* handle);

/// Returns 1 if the session is initialized, 0 otherwise.
int podofo_is_loaded(void* handle);

/// Prints internal state (debug). NULL-safe.
void podofo_print_state(void* handle);

// --- Core signing flow ---------------------------------------------------

/// Step 1: prepares the PDF and returns the base64 hash to be signed remotely.
/// Heap-allocated; free with podofo_free_string(). NULL on error.
char* podofo_calculate_hash(void* handle);

/// Step 2: injects the remote-signed value (and optional DSS/LTV material).
/// certs/crls/ocsps are arrays of base64 strings (may be NULL with count 0).
/// Returns 0 on success, -1 on error.
int podofo_finalize_signing(void* handle,
                            const char* signedHash,
                            const char* tsr,
                            const char* const* certs, int certsCount,
                            const char* const* crls, int crlsCount,
                            const char* const* ocsps, int ocspsCount);

// --- LTA (Long-Term Archive) ---------------------------------------------

/// Begins LTA: returns the base64 hash to send to the TSA. NULL on error.
char* podofo_begin_signing_lta(void* handle);

/// Finishes LTA with a timestamp response and optional DSS/LTV material.
/// Returns 0 on success, -1 on error.
int podofo_finish_signing_lta(void* handle,
                              const char* tsr,
                              const char* const* certs, int certsCount,
                              const char* const* crls, int crlsCount,
                              const char* const* ocsps, int ocspsCount);

// --- Certificate / revocation helpers ------------------------------------
// Each returns a heap-allocated string (free with podofo_free_string), NULL on error.

char* podofo_get_crl_from_certificate(void* handle, const char* base64Cert);
char* podofo_extract_signer_cert_from_tsr(void* handle, const char* base64Tsr);
char* podofo_extract_issuer_cert_from_tsr(void* handle, const char* base64Tsr);
char* podofo_get_ocsp_from_certificate(void* handle, const char* base64Cert, const char* base64IssuerCert);
char* podofo_build_ocsp_request(void* handle, const char* base64Cert, const char* base64IssuerCert);
char* podofo_get_certificate_issuer_url(void* handle, const char* base64Cert);

// --- Error handling / memory ---------------------------------------------

/// Returns the last error message for this handle (empty string if none).
/// The pointer is owned by the handle; do NOT free it.
const char* podofo_last_error(void* handle);

/// Frees a string returned by any podofo_* function. NULL-safe.
void podofo_free_string(char* s);

#ifdef __cplusplus
}
#endif

#endif // PODOFO_FFI_H
