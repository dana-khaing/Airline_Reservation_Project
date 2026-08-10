# Go-Live Checklist

Everything the app's code, tests, and CI can verify already passes (`mix
precommit`: format, `compile --warnings-as-errors`, unused-dep check, full
test suite). What's left to actually serve real customers and take real
payments falls into two kinds:

- Things that need the project owner's own identity, business registration,
  and banking details — no one else can complete these, including an AI
  assistant with full repo access.
- A few concrete technical items that were deliberately scoped out of earlier
  PRs and noted there, listed again here so they don't get lost.

Nothing below is required to run the app as a demo/portfolio piece in Stripe
**test** mode — it's only required to sell real seats to real customers.

## 1. Real flight inventory

**This is the biggest open gap and isn't started.** The app currently sells
seats on flights created by hand through `/admin` or `priv/repo/seeds.exs` —
there is no connection to real airline schedules, fares, or seat availability.
Selling real flights means one of:

- Integrating a GDS/NDC aggregator (e.g. Duffel, Amadeus for Developers,
  Travelport) — each requires its own business application, contract, and
  API credentials, and a non-trivial amount of new code (a `Flights.Supplier`
  adapter, most likely, mirroring how `Payments` already abstracts over a
  real/stub client).
- Or deliberately keeping this as an admin-curated flight list (a smaller
  operator model) — in which case this item is done as-is, and the rest of
  this checklist is what actually matters.

Decide which model this is before treating anything else here as "launch
readiness."

## 2. Accounts and credentials (owner-only)

None of these can be created on the project owner's behalf — each requires
real identity verification, a bank account, or both.

- [ ] **Stripe**: switch from test mode (`sk_test_...`) to a live account —
      requires business verification and a bank account for payouts. Update
      `STRIPE_SECRET_KEY` in production once live.
- [ ] **Resend** (or another transactional email provider): create an
      account, verify a real sending domain, get an API key for
      `RESEND_API_KEY`. Until this is set, production email delivery is
      silently skipped (logged, non-fatal — see `config/runtime.exs`).
- [ ] Replace the placeholder sender addresses — `bookings@example.com`
      (`AlbertAirline.Bookings.BookingNotifier`) and `contact@example.com`
      (`AlbertAirline.Accounts.UserNotifier`) — with real addresses at the
      verified sending domain.
- [ ] **Sentry**: create a project, get a DSN for `SENTRY_DSN`. Until this is
      set, errors aren't reported anywhere (also logged, non-fatal).
- [ ] **Fly.io** (or chosen host): create an account and payment method.
      `fly.toml`/`Dockerfile` are already committed and ready
      (`mix phx.gen.release --docker`) but no app has actually been deployed
      from this environment. See README.md "Deployment" for the exact
      commands.
- [ ] **Domain name**: a real domain for `PHX_HOST` instead of the default
      `*.fly.dev` subdomain, if wanted.

## 3. Legal

Three draft pages exist (`/terms`, `/privacy`, `/refund-policy`) — each is
explicitly marked as a draft, not legal advice, in a banner at the top of the
page itself.

- [ ] Have a lawyer review and adapt all three, especially for aviation
      consumer-protection rules that vary by jurisdiction (EU261 in the
      EU/UK, DOT rules in the US) and can override what a business's own
      policy says.
- [ ] Fill in the placeholders left in `terms.html.heex`: governing
      law/jurisdiction, and any real liability caps counsel wants.
- [ ] Fill in the placeholder cancellation-fee schedule in
      `refund_policy.html.heex` (currently: full refund on cancel, no fee —
      confirm that's the intended real policy).
- [ ] Register the business entity these documents will actually name, if
      not already done.

## 4. Deferred technical items

Noted in their originating PRs, listed again so they're not forgotten:

- [ ] **Rate limiting behind a reverse proxy** (PR #23): `RateLimiter` keys
      on `conn.remote_ip` / the LiveView socket's peer IP directly — correct
      for direct connections, but Fly.io (and most hosts) sit behind a
      proxy, so this will need a `RemoteIp`-style plug reading
      `X-Forwarded-For` once actually deployed, or every request will appear
      to come from the same proxy IP and share one rate-limit bucket.
- [ ] **Sentry request context** (PR #22): `Sentry.PlugContext` (adds
      request path/params to error reports) isn't wired in, to avoid
      touching the Endpoint's error-handling setup in that pass. Crash
      reports still include the exception and stacktrace via the logger
      handler, just without that extra context.
- [ ] **Admin CRUD form duplication**: the airport/airline/flight admin forms
      share real duplicated structure, surveyed during an earlier refactor
      pass and deliberately left alone — extracting a shared abstraction for
      3 call sites risked being premature. Worth revisiting only if a 4th
      similar form gets added.

## 5. Operational basics

- [ ] Database backups (Fly Postgres or whichever host is chosen — not
      configured by anything in this repo).
- [ ] A real support inbox behind the addresses used in the legal pages and
      contact flow, distinct from the transactional `bookings@`/`contact@`
      sender addresses above.
- [ ] Decide on and document an on-call/incident process for Sentry alerts,
      once Sentry is actually live (item 2).
