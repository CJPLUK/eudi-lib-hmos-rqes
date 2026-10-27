/*
 * temp_dir.cj — process-wide writable directory for signed-document output.
 *
 * iOS obtains this from Foundation's global NSTemporaryDirectory(); HarmonyOS has no
 * equivalent callable from a context-less logic module, so the wallet sets it once at
 * startup (the same place it wires AppContextHolder — `RqesTempDir.set(ctx.filesDir)`).
 * Modeling it as a process-global mirrors iOS's global exactly and keeps RQESService.init
 * byte-identical to the iOS initializer (no tempDir parameter leaks into the API).
 */
package ohos_app_cangjie_eudi_cjrqes_kit

import ohos_app_cangjie_eudi_cjrqes_csc.*

public class RqesTempDir {
    private static var dir: ?String = None

    // Called once at app startup, e.g. RqesTempDir.set(abilityContext.filesDir).
    public static func set(path: String): Unit {
        dir = Some(path)
    }

    // The configured directory. Throws if the wallet never set it (a wiring error).
    public static func get(): String {
        return match (dir) {
            case Some(d) => d
            case None => throw RqesCscException(
                "RqesTempDir not set — call RqesTempDir.set(context.filesDir) at app startup")
        }
    }
}
