package com.example.core.error

/**
 * The only error a ViewModel or `UiState` may hold.
 *
 * Immutable after construction. Compose-free, so `:core:error` stays a
 * zero-dependency leaf. Server title and message preserve what the backend
 * sent; UI copy prefers them over the per-type defaults. Illustration and
 * call-to-action always derive from [type], never from server text.
 *
 * A failure and a business state are different channels: "empty" and
 * "not found" are `UiState` fields, never an `AppError`, and an `AppError`
 * is never collapsed into a business flag.
 */
data class AppError(
    val type: AppErrorType,
    val serverTitle: String? = null,
    val serverMessage: String? = null,
    val httpStatus: Int? = null,
)
