/*
 * path_utils.cj — the URL helpers iOS gets from Foundation (lastPathComponent /
 * pathExtension). This layer carries file paths as Strings, so these operate on the path.
 */
package ohos_app_cangjie_eudi_cjrqes_ui

// iOS: URL.lastPathComponent — the final path segment (filename).
func lastPathComponent(path: String): String {
    var p = path
    // Drop a single trailing slash the way URL does.
    if (p.size > 1 && p.endsWith("/")) { p = p[0..p.size - 1] }
    let idx = lastIndexOf(p, r'/')
    return match (idx) {
        case Some(i) => p[i + 1..p.size]
        case None => p
    }
}

// iOS: URL.pathExtension — the extension of the last path component, without the dot ("" if none).
func pathExtension(path: String): String {
    let name = lastPathComponent(path)
    let idx = lastIndexOf(name, r'.')
    return match (idx) {
        case Some(i) where i > 0 && i < name.size - 1 => name[i + 1..name.size]
        case _ => ""
    }
}

func lastIndexOf(s: String, c: Rune): ?Int64 {
    let bytes = s.toArray()
    let target = UInt8(UInt32(c))
    var found: ?Int64 = None
    for (i in 0..bytes.size) {
        if (bytes[i] == target) { found = Some(i) }
    }
    return found
}
