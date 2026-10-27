# eudi_cjrqes_csc — CSC API client (Cangjie HAR)

Cangjie port of [eudi-lib-ios-rqes-csc-swift](https://github.com/eu-digital-identity-wallet/eudi-lib-ios-rqes-csc-swift):
the Cloud Signature Consortium (CSC v2) client used to talk to a remote QTSP.

- Package: `ohos_app_cangjie_eudi_cjrqes_csc`
- OAuth2 service / credential authorization with PKCE (`oauth.cj`, `authorization_details.cj`)
- CSC endpoints `credentials/list`, `credentials/info`, `signatures/signHash` (`csc_http.cj`, `requests.cj`, `responses.cj`)
- Document hashing and signature injection through `eudi_cjrqes` (`podofo_manager.cj`)

Depends on `eudi_cjrqes`, `eudi_lib_openid4vp_vci` (HTTP + PKCE) and `eudi_lib_core_crypto`.
