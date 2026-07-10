# coach-proxy

Server-side relay for Forge's AI coach. Holds the Anthropic key so no client
ever ships one.

```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase functions deploy coach-proxy
```

Point clients at `https://<project-ref>.functions.supabase.co/coach-proxy`:

- **iOS** — scheme env `FORGE_COACH_PROXY_URL`, or `CoachProxyURL` in the
  gitignored `Secrets.plist`. The app auto-selects `liveProxy` mode (proxy
  beats a local dev key; with neither it stays in offline mock mode).
- **Web** — call it like the Messages API, minus the `x-api-key` header.

Guardrails: model allowlist (opus-4-8 / sonnet-4-6 / haiku-4-5), max_tokens
cap 2048, 64 KB body limit, CORS enabled. Any upstream error is relayed as-is;
the iOS client falls back to its offline mock on non-200.

TODO when accounts ship: verify Supabase auth JWT, per-user rate limiting,
usage metering, and waitlist sync.
