# Rebuilding `libpodofo_rqes.so`

`eudi_cjrqes/libs/arm64-v8a/libpodofo_rqes.so` is a **vendored, reproducible**
cross-compiled artifact — the EUDI PoDoFo fork (with the RQES remote-signing
engine) plus our thin C ABI bridge, statically linked into one OHOS shared
library. Committing the binary keeps the whole app buildable on any host OS
(mac/Linux/Windows) with **zero native toolchain** on the consumer side — the
`.so` is an `aarch64-linux-ohos` binary, identical regardless of who built it,
exactly like the vendored `libcrypto_openssl.z.so` already in this project and
like iOS shipping PoDoFo as a binary `xcframework`.

This document lets a maintainer regenerate that binary. It is **not** run during
the app build.

## What's inside

Statically linked, in one `.so` exporting only the `podofo_*` C symbols:

| Component | Source | Recipe |
|---|---|---|
| PoDoFo fork (RQES engine) | github.com/eu-digital-identity-wallet/eudi-lib-podofo @ `v0.3.8` | `recipes/podofo/HPKBUILD` |
| OpenSSL 1.1.1u | gitee mirror | `recipes/openssl/HPKBUILD` |
| FreeType 2.13.0 | gitee mirror | `recipes/freetype2/HPKBUILD` |
| libxml2 2.11.3 | gitee mirror | `recipes/libxml2/HPKBUILD` |
| libpng 1.6.39 | sourceforge | `recipes/libpng/HPKBUILD` |
| zlib | **static** (`usr/zlib/$ARCH/lib/libz.a`, from the libpng build) — hidden, NOT `-lz` |
| C ABI bridge | `bridge/podofo_ffi.{h,cpp}` | — |

## Prerequisites (maintainer machine)

- DevEco Studio with the OHOS **native** SDK. Export its parent as `OHOS_SDK`:
  `export OHOS_SDK=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony`
- Host build tools: `cmake` (>=3.26), `make`, `perl`, `ninja`, `pkg-config`,
  `autoconf`, `automake`, `wget` (macOS: `brew install pkg-config autoconf automake wget`).
- The [lycium](https://gitee.com/openharmony-sig/tpc_c_cplusplus) cross-compile
  framework (`git clone --filter=tree:0 https://gitee.com/openharmony-sig/tpc_c_cplusplus`).
- Compiler-name shim: the fork's OpenSSL recipe expects `aarch64-linux-ohos-clang`;
  newer SDKs only ship `aarch64-unknown-linux-ohos-clang`. Copy lycium's
  `Buildtools/toolchain.tar.gz` wrappers into `$OHOS_SDK/native/llvm/bin/`
  (they just forward `clang --target=aarch64-linux-ohos`).

## Steps

1. Copy the five recipe dirs under `recipes/` into lycium's `thirdparty/`.
2. From lycium root, build the dependency chain then PoDoFo (deps must be in args):
   ```sh
   export OHOS_SDK=.../openharmony
   ./build.sh openssl
   ./build.sh freetype2 libxml2 libpng
   ./build.sh podofo          # clones the fork, builds it static
   ```
   Products land in `lycium/usr/<pkg>/arm64-v8a/{lib,include}`.
3. Link the bridge + all static libs into the single shared object
   (`ARCH=arm64-v8a`, `USR=lycium/usr`, `LLVM=$OHOS_SDK/native/llvm/bin`):
   ```sh
   "$LLVM/aarch64-linux-ohos-clang++" -std=c++17 -fPIC -shared bridge/podofo_ffi.cpp \
     -Ibridge \
     -I"$USR/podofo/$ARCH/include" -I"$USR/freetype2/$ARCH/include/freetype2" \
     -I"$USR/openssl/$ARCH/include" -I"$USR/libxml2/$ARCH/include/libxml2" \
     -Wl,--no-undefined -Wl,--exclude-libs,ALL \
     -Wl,--whole-archive \
       "$USR/podofo/$ARCH/lib/libpodofo.a" \
       "$USR/podofo/$ARCH/lib/libpodofo_private.a" \
       "$USR/podofo/$ARCH/lib/libpodofo_3rdparty.a" \
     -Wl,--no-whole-archive \
     -Wl,--start-group \
       "$USR/freetype2/$ARCH/lib/libfreetype.a" "$USR/libxml2/$ARCH/lib/libxml2.a" \
       "$USR/libpng/$ARCH/lib/libpng.a" \
       "$USR/openssl/$ARCH/lib/libssl.a" "$USR/openssl/$ARCH/lib/libcrypto.a" \
       "$USR/zlib/$ARCH/lib/libz.a" \
     -Wl,--end-group \
     -o ../eudi_cjrqes/libs/arm64-v8a/libpodofo_rqes.so
   ```
   ⚠️ **zlib MUST be linked statically here (`libz.a` inside the group), NOT `-lz`.**
   The lycium libpng build already produces `usr/zlib/$ARCH/lib/libz.a`. Dynamic `-lz`
   makes the `.so` DT_NEEDED `libz.so` and import zlib symbols; inside the full wallet
   app the process also loads `libstdx.compress.zlib.so` (a full zlib exporting the same
   symbols globally, with a symbol-version table), so the loader binds libpodofo's zlib
   relocations to that instead of the system libz and SIGSEGVs during dlopen relocation —
   the app crashes at startup before any Cangjie code runs. Static zlib + `--exclude-libs,ALL`
   makes zlib internal/hidden, so there is no `libz.so` dependency and no symbol clash. (The
   standalone C device test never hit this because that process has no stdx zlib.)
4. Sanity-check the result:
   ```sh
   "$LLVM/llvm-nm" -D libpodofo_rqes.so | grep ' T podofo_'   # 16 exported symbols, nothing else
   ```

## Gotchas (learned the hard way)

- **PoDoFo needs libpng**: `PdfImage::getTransformation` lives inside
  `#ifdef PODOFO_HAVE_PNG_LIB` but is called unconditionally; without PNG the
  link fails with an undefined symbol. The recipe enables PNG.
- **`-DPODOFO_BUILD_EXAMPLES=OFF`** is required — the fork's example app pulls in
  `find_package(CURL REQUIRED)`; the library itself does not use curl.
- **`--whole-archive`** on the three podofo archives (they cross-reference each
  other); **`--exclude-libs,ALL`** keeps the `.so` from re-exporting openssl/etc;
  do **not** add `-fvisibility=hidden` (it would hide the `podofo_*` exports too).
- ⚠️ **`libc++_shared.so` MUST be bundled into the app** (`entry/libs/arm64-v8a/libc++_shared.so`,
  copied from `$OHOS_SDK/native/llvm/lib/aarch64-linux-ohos/libc++_shared.so`). Although the
  device has `/system/lib64/libc++_shared.so`, the app's restricted native module namespace
  (`/data/storage/.../libs/arm64/`) does NOT inherit it, so loading libpodofo fails with
  `Error loading shared library libc++_shared.so (needed by libpodofo_rqes.so)` → SIGSEGV at
  startup. Pure-Cangjie libs don't hit this (they use the Cangjie runtime, not libc++); libpodofo
  is the only C++ lib, so nothing else bundles it. Runtime deps after the fix: `libc.so` (system)
  + the bundled `libc++_shared.so`; zlib is now static (see step 3). Both `libpodofo_rqes.so` and
  every OHOS device.
