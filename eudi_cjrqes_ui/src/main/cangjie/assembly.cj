/*
 * assembly.cj — the RQES Domain wiring, ports eudi-lib-ios-rqes-ui Sources/Domain/DI/Assembly/
 * {ControllerAssembly, InteractorAssembly}.swift.
 *
 * iOS registers these in a Swinject container; the Harmony port uses manual constructor
 * injection (the project's established DI idiom — see eudi_logic_assembly), so these are plain
 * factory functions resolving the shared EudiRQESUi instance. The LocalizationController /
 * LogController / PreferencesController registrations support the Presentation layer and are
 * deferred to phase 4b.
 */
package ohos_app_cangjie_eudi_cjrqes_ui

// iOS: ControllerAssembly registers RQESController(rqesUi: EudiRQESUi.requireInstance()).
public func makeRQESController(): RQESController {
    return RQESControllerImpl(EudiRQESUi.instance())
}

// iOS: InteractorAssembly registers RQESInteractor(rqesUi: …, rqesController: r.force(RQESController.self)).
public func makeRQESInteractor(): RQESInteractor {
    return RQESInteractorImpl(EudiRQESUi.instance(), makeRQESController())
}
