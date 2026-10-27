# eudi_cjrqes_csc — 移植待办（对齐 iOS eudi-lib-ios-rqes-csc-swift）

本文件记录 CSC 层移植中**刻意延后**或**后续步骤必须补**的点。每项标注触发时机。

## 数据层（chunk ①，已完成）遗留

- [x] **CredentialsListResponse.credentialInfos**（`[CredentialInfo]?`）— ✅ 已补齐（Phase 3 触发）
  - RqesKit `getCredentialsList()` 直接读 `response.credentialInfos`（不再单独 getCredentialInfo），故必须补。
  - 已加 `ListCredentialInfo` struct（内嵌版，比独立 CredentialInfo 多必填 `credentialID`，复用 CredentialKeyInfo/CredentialCertificateInfo/CredentialAuthInfo），并在 CredentialsListResponse 解析 `credentialInfos` 数组。

- [ ] **必填字段宽松解析**：`AccessTokenResponse.expiresIn` / `CredentialInfo.multisign` / `CredentialsListResponse.credentialIDs` 缺失时给默认值(0/空)，iOS 会解码失败(required)。
  - 现状：更健壮(不崩)。
  - **触发补上**：若需严格对齐 iOS 的"缺字段即失败"契约(一般不需要;真实 QTSP 都会返回这些字段)。

- [ ] **ExpressibleByStringLiteral**（types.cj 的 6 个 rawValue struct）
  - iOS 支持 `let x: HashAlgorithmOID = "..."`，仓颉无此语法糖。非功能差异，一般不用补。

## 后续步骤必须补的点

- [x] **DigestNormalizer（base64url → base64）** — ✅ 已补齐（`digest.cj`）
  - 已移植 `DigestFormat`(Base64/Base64UrlNoPadding) + `DigestNormalizer.normalize`(trim→percent-decode→试标准base64→试base64url→按目标重编) + `DocumentDigests.init(digests:,output:)` + forToken/forAuthorization。
  - 复用 stdx `toBase64String/fromBase64String` + core_crypto `Base64Url.encode/decode`。
  - RqesKit signDocuments 已用 `DocumentDigests(digests: hashes, output: Base64).hashes` 规范化后再 signHash。

- [x] **CredentialsInfoRequest / CredentialsListRequest 的 wire 格式** — ✅ 已核对（② HTTP 层）
  - iOS CredentialsInfoHttpClient + CredentialsListClient 都用 `JSONEncoder().encode(request)` 发 **JSON**（不是 form）。
  - 已给 CredentialsListRequest 补 `toJsonString()`（按 CodingKeys：user_id/credentialInfo/certInfo/auth_info/only_valid/client_data）；toFormBody 保留但不是 wire 格式。CredentialsInfoRequest 的 toJsonString 正确。

- [ ] **JSON 可选字段编码：省略 vs null** — 触发时机：**真实 QTSP 联调**
  - 现状：None 时省略字段（对齐 Swift Codable 的 encodeIfPresent 行为）。
  - **验证**：用真实 QTSP 沙箱确认 CSC v2 接受"省略"而非要求 null。绝大多数接受省略。

- [x] **Phase 1 PodofoSigner 重构**（enum ConformanceLevel → String）— ✅ 已完成（⑤PodofoManager 时）
  - iOS PodofoManager 传 `doc.conformanceLevel.rawValue`（String）给 native wrapper。
  - 已把 `PodofoSigner.init` 的 conformanceLevel 改成收 `String`（删掉 enum ConformanceLevel，`LibC.mallocCString(conformanceLevel)` 直接用）。只改 Cangjie 绑定，未重编 .so。

## ④ 门面 + ⑤ PodofoManager（已完成 + 编译验证）遗留

- [ ] **B_T / B_LT / B_LTA 编排未实现** — 触发时机：做更高 conformance level 时
  - `PodofoManager.createSignedDocuments` 目前只走 B_B 分支（`finalizeSigning(sig)`，tsr=""、空验证数组）；非 B_B 抛 RqesCscException。
  - `calculateDocumentHashes` / `createSignedDocuments` 的 `tsaUrl` 参数已留（对齐 iOS 签名）但 B_B 未用（故编译期 unused 警告，预期）。
  - **触发补上**：B_T 用 TSA 时间戳、B_LT/B_LTA 用 DSS/LTV 材料（PodofoSigner 已备 beginSigningLTA/finishSigningLTA + CRL/OCSP/TSR 提取方法）。

- [ ] **InfoServiceResponse 只解析 B_B 所需扁平字段** — 触发时机：需要能力协商时
  - 现只解析 `oauth2`(必需) + oauth2Issuer/name/region/description/conformanceLevels(可选)。
  - iOS 全字段含 methods / signAlgorithms / oauth2Servers 等嵌套能力元数据，未解析。

## Phase 3 = RqesKit 编排层（新模块 eudi_cjrqes_kit，已完成 + 编译验证）遗留

移植 iOS eudi-lib-ios-rqes-kit：Document / RQESService / RQESServiceAuthorized /
RQESServiceCredentialAuthorized。以下为**平台强制偏离**（非行为差异）与**待办**：

- [ ] **接入主工程（app 构建注册）** — 触发时机：Phase 4 rqes-ui 真正调用 RQESService 时
  - eudi_cjrqes_csc + eudi_cjrqes_kit 两个模块尚未加进根 hvigorfile.ts DEPS / entry/cjpm.toml 依赖 / 根 build-profile.json5（目前只有 Phase 0/1 的 eudi_cjrqes native 接了）。
  - 当 UI 层要 import RQESService 时，按 eudi_cjrqes 的接入方式补三处注册。

**保真度复审结论（重要）**：原先笼统标的 5 项"平台偏离"，复审后只有临时目录来源是真受限，其余要么本就功能等价、要么已升级为真 1:1：

- [x] **URL → String（文件路径）** — 功能等价，非缺陷。Cangjie 无 Foundation URL 类型；iOS 自身也是 `url.path`(String) 传进签名层，跨层数据完全一致。
- [x] **UUID().uuidString → uuidV4()** — 功能 1:1。Cangjie std 无 UUID 类型；`uuid.cj` 用 core_crypto Rng 产出同格式 RFC4122 v4 串（同 CSPRNG 类）。
- [x] **X509.Certificate → Cert（对象级真 1:1，已升级）** — 原来收 `?Array<String>`，现改收 `?Array<Cert>`（`ohos_app_cangjie_eudi_cjx509.x509.core.Cert`），`toBase64String(c.toDer())` = iOS `X509.Certificate.base64String`。getCredentialAuthorizationUrl 与 iOS 签名对象级一致。kit 新增依赖 eudi_cjx509。
- [x] **NSTemporaryDirectory() → RqesTempDir 全局（构造器恢复 1:1，已升级）** — 改用进程级全局 `RqesTempDir`（`temp_dir.cj`，钱包启动时 `RqesTempDir.set(ctx.filesDir)`，同项目 AppContextHolder 模式），**镜像 iOS NSTemporaryDirectory 的全局性**，`RQESService.init` 去掉 tempDir 参数、与 iOS 逐字节一致。唯一真受限点：目录来源必须外部注入（纯 logic 模块拿不到 context），但输出行为 = dir/uuid+ext 完全一致。Phase 4 钱包要调 RqesTempDir.set。
- [x] **JSONUtils.stringify → AuthorizationDetails.toJsonString()** — 功能 1:1，同一序列化。authorization_details 里 hashAlgorithmOID/hashType 编码成**裸字符串**（Swift RawRepresentable+Codable / enum:String 行为），已对齐；顶层 JSON 数组。

**仓颉编译坑（本层新增）**：`a ?? b` 的 b 必须非 Option（`?T ?? ?T` 报 mismatched types，要用嵌套 match）；`import pkg.*` 通配导入可用；跨模块编译要把依赖 .cjo 目录全部 --import-path（kit 需 csc.cjo + cjrqes.cjo + vci/core_crypto cjbins）。
