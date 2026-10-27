/*
 * Document — ports eudi-lib-ios-rqes-kit Sources/RqesKit/Document.swift.
 *
 * iOS holds a file URL; HarmonyOS Cangjie has no URL type in this layer, so we hold the
 * filesystem path as a String (the CSC/native layer takes input/output paths as strings).
 */
package ohos_app_cangjie_eudi_cjrqes_kit

public struct Document {
    // The identifier of the document.
    public let id: String
    // The filesystem path of the document (iOS: fileURL).
    public let fileURL: String

    public init(id!: String, fileURL!: String) {
        this.id = id
        this.fileURL = fileURL
    }
}
