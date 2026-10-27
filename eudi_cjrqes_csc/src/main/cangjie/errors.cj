/*
 * CSC layer error type. iOS: Sources/Errors throw domain-specific errors;
 * we surface them as one exception with a message (the wallet layer maps as needed).
 */
package ohos_app_cangjie_eudi_cjrqes_csc

public class RqesCscException <: Exception {
    public init(message: String) {
        super(message)
    }
}
