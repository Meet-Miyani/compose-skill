package com.example.core.error

/**
 * Semantic, presentation-facing error kinds.
 *
 * The illustration and call-to-action on every error surface derive from
 * this type. Tiers route by situation, not by type: the same `NoNetwork`
 * is inline on a first load with no content and popup on a refresh over
 * visible content. Session expiry (401) is not a tier; the session
 * sign-out path owns it.
 */
enum class AppErrorType {
    NoNetwork,
    Timeout,
    Tls,
    Unauthorized,
    Forbidden,
    NotFound,
    ServerError,
    UpdateRequired,
    Storage,
    Generic,
}
