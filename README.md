# Albert Airline Reservation

A full-stack airline reservation app — search flights, pick a seat on a live-updating
seat map, pay via Stripe Checkout, and manage your bookings — built with **Elixir,
Phoenix LiveView, and PostgreSQL**. Rebuilt from an earlier static HTML/CSS mockup
(the original branding, copy, and layout are preserved; everything else is real now).

## Why this stack

The seat map is fundamentally a concurrency problem (many people looking at, and
occasionally racing for, the same seat) as much as it's a CRUD app. The BEAM's
concurrency model and Phoenix LiveView's server-rendered real-time UI over
WebSockets are a strong fit for that: the seat map needs no hand-written client-side
JavaScript, and Phoenix PubSub broadcasts seat-status changes to every connected
viewer for free. See `AlbertAirline.Flights.subscribe_to_seats/1` and
`AlbertAirlineWeb.FlightLive.Show`.

## Architecture

- **`AlbertAirline.Accounts`** — users, sessions, magic-link/password login
  (`mix phx.gen.auth`), `is_admin` role (never settable through a public
  changeset — only via direct DB access).
- **`AlbertAirline.Flights`** — airports, airlines, flights, seats; flight search;
  the PubSub seat-broadcast plumbing.
- **`AlbertAirline.Bookings`** — Stripe checkout, and the seat-claiming
  transaction. Deliberately reserves nothing when checkout starts (no pre-hold);
  a seat is only claimed once Stripe confirms payment, atomically, in one
  `Ecto.Multi` guarded by a partial unique index on `bookings.seat_id`. If a seat
  is lost to a race during checkout, the payment that just succeeded is
  automatically refunded.
- **`AlbertAirline.Payments`** — dispatches to a configured adapter: the real
  `StripeClient` (REST calls via `Req`) in dev/prod, a network-free `StubClient` in
  test.
- **`AlbertAirline.Contact`** — the public contact form (no login required).
- Admin UI at `/admin` (CRUD for airports/airlines/flights, gated by `is_admin`).

## Local setup

Requires Elixir 1.20.x / Erlang-OTP 29.x and PostgreSQL 16.x running locally.

```bash
mix setup          # deps.get + ecto.setup (create, migrate, seed) + assets.setup/build
mix phx.server      # http://localhost:4000
```

Seed data creates two accounts:

| Role  | Email                        | Password              |
|-------|------------------------------|------------------------|
| Admin | admin@albertairline.test     | albertairline-admin    |
| User  | demo@albertairline.test      | albertairline-demo     |

## Environment variables

| Variable            | Required in    | Purpose                                              |
|----------------------|----------------|-------------------------------------------------------|
| `STRIPE_SECRET_KEY`  | dev, prod      | Stripe test-mode secret key (`sk_test_...`) for real checkout sessions. Not required in `test`, which uses `AlbertAirline.Payments.StubClient`. Get one from your own [Stripe dashboard](https://dashboard.stripe.com/test/apikeys) — no live Stripe account exists for this project. |
| `DUFFEL_API_KEY`     | dev, prod (optional) | Duffel test-mode access token (`duffel_test_...`) for `AlbertAirline.Flights.Supplier.DuffelClient` — real flight-offer search and seat maps. Not required to run the app: nothing in the booking flow calls this yet (see GO_LIVE.md item 1). Not required in `test`, which uses `AlbertAirline.Flights.Supplier.StubClient`. Get one from a free [Duffel account](https://duffel.com) — no business verification needed for test access. |
| `DATABASE_URL`       | prod           | `ecto://USER:PASS@HOST/DATABASE`                      |
| `SECRET_KEY_BASE`    | prod           | Generate with `mix phx.gen.secret`                    |
| `PHX_HOST`           | prod           | Public hostname (e.g. `albert-airline.fly.dev`)        |
| `RESEND_API_KEY`     | prod (optional) | [Resend](https://resend.com) API key for booking/account emails. Without it, the app still runs — email delivery is logged and skipped, not a boot failure. |
| `SENTRY_DSN`         | prod (optional) | Sentry project DSN for error tracking. Without it, the app still runs — errors just aren't reported. |
| `SENTRY_ENVIRONMENT` | prod (optional) | Sentry environment label. Defaults to `"production"`. |

See [`GO_LIVE.md`](GO_LIVE.md) for the full checklist of what's left before this
can serve real customers/bookings — most of it is exactly this table: real
accounts and credentials for Stripe, Resend, Sentry, and Fly.io that only the
project owner can create.

## Testing

```bash
mix test              # full suite (creates/migrates the test DB automatically)
mix test --cover      # with coverage report
mix precommit         # compile --warnings-as-errors, deps.unlock --unused, format, test
```

Notable tests:
- `test/albert_airline/seat_claim_concurrency_test.exs` — races real concurrent
  processes against the same seat to prove the claiming transaction is actually
  race-safe, not just sequentially correct.
- `test/albert_airline_web/golden_path_test.exs` — one continuous walk through
  search → seat selection → checkout → confirmation → booking history.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every PR and push to `main`:
format check, `compile --warnings-as-errors`, unused-dependency check, and the
full test suite against a real Postgres service container.

## Deployment

Configured for [Fly.io](https://fly.io) (`fly.toml`, `Dockerfile` via
`mix phx.gen.release --docker`) — chosen for first-class Elixir/Phoenix and
distributed-BEAM support. **No app has actually been deployed from this
environment** (no Fly.io account/credentials available here). To take it live:

```bash
fly launch --no-deploy   # reuses the committed fly.toml; creates the Fly app
fly postgres create      # or use Neon/Supabase and set DATABASE_URL directly
fly postgres attach <db-app-name>
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret) STRIPE_SECRET_KEY=sk_test_...
fly deploy
```

Migrations run via `lib/albert_airline/release.ex`'s `bin/migrate`, invoked
automatically before each deploy by `fly.toml`'s `[deploy] release_command`.
