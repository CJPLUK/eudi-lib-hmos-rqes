# eudi_lib_rqes

RQES (Remote Qualified Electronic Signature) native foundation for the EUDI
HarmonyOS wallet — the Cangjie/HarmonyOS counterpart of the iOS
`eudi-lib-podofo` layer.

It wraps the EUDI **PoDoFo fork** (`PdfRemoteSignDocumentSession`, the PAdES
remote-signing engine) behind a thin C ABI, and exposes it to Cangjie via a
`foreign func` binding. The signing surface (14 methods) is 1:1 with the iOS
`PodofoWrapper` / Android `PoDoFoWrapper`:

```
create → calculateHash → (remote CSC signHash) → finalizeSigning → signed PDF
```
plus B-LTA archive-timestamp steps and CRL/OCSP/TSR certificate helpers.

## Layout

```
eudi_cjrqes/                        HarmonyOS HAR module (consumed by the app)
  src/main/cangjie/podofo_signer.cj   Cangjie binding: PodofoSigner class
  libs/arm64-v8a/libpodofo_rqes.so    vendored cross-compiled native library
eudi_cjrqes_csc/                    CSC v2 client (port of eudi-lib-ios-rqes-csc-swift)
eudi_cjrqes_kit/                    RQES kit facade (port of eudi-lib-ios-rqes-kit)
eudi_cjrqes_ui/                     RQES UI domain layer (port of eudi-lib-ios-rqes-ui)
native/
  bridge/podofo_ffi.{h,cpp}           C ABI bridge source (compiled into the .so)
  recipes/                            lycium HPKBUILD recipes for each native dep
  REBUILD.md                          how to regenerate the .so reproducibly
```

## Native library

`libpodofo_rqes.so` is a vendored, reproducible `aarch64-linux-ohos` binary
(PoDoFo fork + OpenSSL + FreeType + libxml2 + libpng + our bridge, statically
linked; exports only `podofo_*`). Committing the binary keeps the app buildable
on any host OS with no native toolchain, mirroring how iOS ships PoDoFo as a
binary xcframework. To regenerate it, see [`native/REBUILD.md`](native/REBUILD.md).

## Usage (Cangjie)

```cangjie
import ohos_app_cangjie_eudi_cjrqes.*

let signer = PodofoSigner(
    conformanceLevel: ConformanceLevel.AdesBB,
    hashAlgorithmOid: SHA256_OID,
    inputPath: inPdfPath, outputPath: outPdfPath,
    certificate: endEntityCertBase64, chainCertificates: chainBase64)
let hash = signer.calculateHash()          // → send to the remote CSC signer
signer.finalizeSigning(signedHash)          // ← inject the returned signature
signer.close()
```
