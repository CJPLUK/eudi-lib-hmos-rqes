# eudi_cjrqes — PoDoFo signing binding (Cangjie HAR)

Cangjie `foreign func` binding over the vendored `libs/arm64-v8a/libpodofo_rqes.so`
(EUDI PoDoFo fork + C ABI bridge). Exposes `PodofoSigner`, the PAdES remote-signing
session whose 14 methods are 1:1 with the iOS `PodofoWrapper` / Android `PoDoFoWrapper`.

- Package: `ohos_app_cangjie_eudi_cjrqes`
- Source: `src/main/cangjie/podofo_signer.cj`
- Linking: `cjpm.toml` passes `-L ./libs/arm64-v8a -lpodofo_rqes`; the consuming app must
  also ship `libpodofo_rqes.so` and `libc++_shared.so` in its own `entry/libs/arm64-v8a/`.

See the repository [README](../README.md) for usage and [`native/REBUILD.md`](../native/REBUILD.md)
to regenerate the native library.
