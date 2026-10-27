/*
 * EudiRQESUiConfig — ports eudi-lib-ios-rqes-ui Sources/Infrastructure/Config/
 * EudiRQESUiConfig.swift. The integrating wallet implements this to supply the QTSP list
 * and logging preference (iOS: RQESConfig in the wallet's logic-business).
 *
 * iOS also declares `translations` and `theme` on this protocol; both drive the Presentation
 * layer (localization + ArkUI theming) and are deferred to the Presentation phase (4b).
 */
package ohos_app_cangjie_eudi_cjrqes_ui

public interface EudiRQESUiConfig {
    // Remote signing service provider list.
    prop rssps: Array<QTSPData>
    // Whether the SDK may print logs.
    prop printLogs: Bool
}
