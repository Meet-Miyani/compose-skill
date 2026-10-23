# Auth and Realtime

Load when wiring bearer refresh, session expiry, or a WebSocket/SSE feed in the data layer.

## Bearer refresh

1. **Mark the refresh request so it never re-triggers refresh (non-negotiable).** The `refreshTokens` block issues its token-endpoint call with `markAsRefreshTokenRequest()` (verified: https://ktor.io/docs/client-bearer-auth.html); an unmarked refresh call that itself returns 401 re-enters `refreshTokens` and loops. *Prevents:* infinite refresh loop on an expired refresh token.
2. **Keep login, register and the token-refresh call off the authenticated client (non-negotiable).** Issue them on a client instance without the Auth plugin, or the rule-6 isolated no-auth client; `sendWithoutRequest` only chooses proactive versus after-401 attachment — returning true sends the token proactively (verified: https://ktor.io/docs/client-bearer-auth.html) — and never exempts a path. Attaching a stale token to the login call turns every sign-in into a 401. *Prevents:* sign-in that can never succeed while logged out.
3. **Return null from `refreshTokens` when refresh fails, and route it to session sign-out (non-negotiable).** Return new tokens on success; return null when refresh is not possible and the original request is not retried (verified: https://api.ktor.io/ktor-client-auth/io.ktor.client.plugins.auth.providers/-bearer-auth-config/refresh-tokens.html), so the session controller signs the user out at the app shell, e.g. clearing stored note-session tokens and opening sign-in. *Prevents:* dead session retried forever.
4. **Treat 401 session expiry as an auth lifecycle transition, never a popup or inline tier (non-negotiable).** Session expiry is none of the popup/inline/silent tiers; suppress 401 at the app error host (`HandleAppErrors`) and map it to the session sign-out handler per CONTRACT_BRIEF §4.7. *Prevents:* non-actionable "unauthorized" popup over the notes list.
5. **Load initial tokens from storage with `loadTokens`, convert app tokens to plugin tokens only at the plugin boundary (non-negotiable).** `loadTokens` returns stored `BearerTokens` (verified: https://ktor.io/docs/client-bearer-auth.html); the app owns its token store and mapping, and the plugin sees only `BearerTokens` at install time. *Prevents:* storage shape leaking into every call site.
6. **Isolated refresh client is the explicit-separation option (default).** Instead of request marking, the refresh path may use a dedicated no-auth client that is closed after use; pick marking or the isolated client per call site, never both on one path. *Prevents:* auth interception firing inside its own refresh.

## Realtime transport

7. **Server-push text feeds go to SSE; bidirectional, binary, or realtime collaboration goes to WebSocket (non-negotiable).** A note-update broadcast the server pushes over HTTP is SSE; two devices editing one note together is WebSocket, per the SKILL.md realtime feed choice. *Prevents:* a socket held open for a one-way text feed, or polling where a duplex channel was needed.
8. **Set a WebSocket keep-alive ping or the connection dies silently (non-negotiable).** Configure `pingIntervalMillis` (or `pingInterval`) on the `WebSockets` install so ping frames keep the session alive (verified: https://ktor.io/docs/client-websockets.html); an idle note-collaboration socket with no ping is reaped by intermediaries with no close frame. *Prevents:* collaboration feed that freezes with no error.
9. **SSE rides the client with no extra dependency (default).** `install(SSE)` needs only the client core artifact and no new engine artifact (verified: https://ktor.io/docs/client-server-sent-events.html); do not add a dependency for it. *Prevents:* dependency bloat for a built-in plugin.
10. **Reconnect is a named poll with the silent tier; a user-visible feed failure surfaces with retry (non-negotiable).** Silent auto-reconnect (`maxReconnectionAttempts` with `reconnectionTime`, verified: https://ktor.io/docs/client-server-sent-events.html) covers background note-sync ticks via `launchGuarded(onError = {})`; a feed the user is watching (open note detail) that stays down surfaces inline or popup with a retry holding the error. *Prevents:* reconnect spam on a watched screen, and a dead feed with no recovery.

## Red flags

| Thought | Reality |
|---|---|
| "I'll skip the refresh-request marking; the refresh endpoint always succeeds." | No. This-file rule 1: one 401 on the refresh call loops without `markAsRefreshTokenRequest()`. |
| "I'll attach the token to login too, for consistency." | No. This-file rule 2 (SKILL.md rule 5: failures propagate, never get manufactured): login/register go on the no-auth client; `sendWithoutRequest` never exempts a path. |
| "I'll show a popup when refresh fails so the user knows." | No. This-file rules 3–4: null means sign-out at the shell; 401 is suppressed at the host, never a tier. |
| "I'll read `BearerTokens` straight from storage everywhere." | No. This-file rule 5 (SKILL.md rule 1: DTOs/wire types stay inside data): convert only at the plugin boundary. |
| "I'll use a WebSocket for the note-update broadcast; it is more realtime." | No. This-file rule 7: one-way text push is SSE. |
| "I'll leave the ping at default; the socket stays open." | No. This-file rule 8: set the keep-alive or idle sockets die silently. |
| "I'll retry the watched note feed silently so no error ever shows." | No. This-file rule 10 (SKILL.md rule 5): background polls stay silent; a watched feed surfaces with retry. |

## Verification

- [ ] Refresh call carries the refresh-request marking or uses the isolated no-auth client, never neither: yes or no.
- [ ] Login/register paths go on the no-auth client, never through the bearer provider: yes or no.
- [ ] Failed refresh returns null and reaches session sign-out; no popup/inline wiring on 401: yes or no.
- [ ] 401 suppressed at the app error host: `grep -rn "Unauthorized\|401" --include='*.kt' <error-host-root>` shows the suppression mapping and no popup call.
- [ ] No storage type crosses the plugin boundary: `grep -rn "BearerTokens" --include='*.kt' <data-root>` shows only the client-install and mapper files.
- [ ] Every feed names its transport per rule 7: yes or no.
- [ ] WebSocket install sets a keep-alive: `grep -rn "pingInterval" --include='*.kt' <data-root>` returns the install line.
- [ ] Reconnect policy names the poll; watched-feed failure holds a retry: yes or no.
