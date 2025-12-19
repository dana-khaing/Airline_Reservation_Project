defmodule AlbertAirlineWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AlbertAirlineWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col">
      <a
        href="#main-content"
        class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:rounded-lg focus:bg-(--surface) focus:px-4 focus:py-2 focus:font-semibold focus:text-(--text-default)"
      >
        Skip to main content
      </a>

      <nav class="border-b border-(--border-default) bg-(--surface)">
        <div class="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-y-2 px-4 py-3 sm:px-8">
          <.link navigate="/" class="text-base font-semibold tracking-tight text-(--text-default)">
            Albert Airline
          </.link>
          <div class="flex flex-wrap items-center gap-1 sm:gap-2">
            <.nav_link href="/about">About</.nav_link>
            <.nav_link href="/contact">Contact Us</.nav_link>
            <.theme_toggle />
            <%= if @current_scope && @current_scope.user do %>
              <.nav_link :if={@current_scope.user.is_admin} href="/admin">Admin</.nav_link>
              <.nav_link href="/account">My Bookings</.nav_link>
              <.nav_link href="/users/settings">{@current_scope.user.email}</.nav_link>
              <.link
                href="/users/log-out"
                method="delete"
                class="rounded-md px-3 py-2 text-sm font-medium text-(--text-muted) hover:bg-(--surface-muted) hover:text-(--text-default)"
              >
                Log out
              </.link>
            <% else %>
              <.link
                navigate="/users/log-in"
                class="rounded-md bg-brand-600 px-3 py-2 text-sm font-medium text-white hover:bg-brand-700"
              >
                Log in
              </.link>
            <% end %>
          </div>
        </div>
      </nav>

      <main id="main-content" class="flex-1 px-4 py-10 sm:px-8">
        <div class="mx-auto max-w-5xl">
          {render_slot(@inner_block)}
        </div>
      </main>

      <.flash_group flash={@flash} />

      <footer class="border-t border-(--border-default) px-4 py-6 sm:px-8">
        <div class="mx-auto flex max-w-5xl flex-col items-end gap-1 text-right">
          <div class="flex flex-wrap justify-end gap-x-3 text-sm text-(--text-muted)">
            <.link href="/terms" class="hover:underline">Terms of Service</.link>
            <.link href="/privacy" class="hover:underline">Privacy Policy</.link>
            <.link href="/refund-policy" class="hover:underline">Refund Policy</.link>
          </div>
          <p class="text-sm text-(--text-muted)">powered by albert enterprise.</p>
        </div>
      </footer>
    </div>
    """
  end

  attr :href, :string, required: true
  slot :inner_block, required: true

  defp nav_link(assigns) do
    ~H"""
    <.link
      href={@href}
      class="rounded-md px-3 py-2 text-sm font-medium text-(--text-muted) hover:bg-(--surface-muted) hover:text-(--text-default)"
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders the admin section's shell: a distinct, utilitarian chrome
  (sidebar nav, no public footer/marketing chrome) so the admin area
  reads as a clearly separate, restricted zone rather than the public
  site with a table dropped in. Every admin LiveView renders through
  this instead of `app/1`.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :map, default: nil

  attr :active, :atom,
    default: nil,
    values: [nil, :dashboard, :airports, :airlines, :flights],
    doc: "which sidebar item to highlight"

  slot :inner_block, required: true

  def admin(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col lg:flex-row">
      <a
        href="#main-content"
        class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:rounded-lg focus:bg-(--surface) focus:px-4 focus:py-2 focus:font-semibold focus:text-(--text-default)"
      >
        Skip to main content
      </a>

      <aside class="flex shrink-0 flex-col gap-1 border-b border-(--border-default) bg-(--surface) p-4 lg:w-60 lg:border-b-0 lg:border-r lg:p-6">
        <.link navigate="/admin" class="mb-4 flex items-center gap-2 px-2">
          <span class="text-sm font-semibold text-(--text-default)">Albert Airline</span>
          <span class="rounded-full bg-brand-50 px-2 py-0.5 text-xs font-semibold text-brand-700 dark:bg-brand-950 dark:text-brand-300">
            Admin
          </span>
        </.link>

        <nav class="flex flex-wrap gap-1 lg:flex-col">
          <.admin_nav_link navigate="/admin" active={@active == :dashboard}>
            Dashboard
          </.admin_nav_link>
          <.admin_nav_link navigate="/admin/airports" active={@active == :airports}>
            Airports
          </.admin_nav_link>
          <.admin_nav_link navigate="/admin/airlines" active={@active == :airlines}>
            Airlines
          </.admin_nav_link>
          <.admin_nav_link navigate="/admin/flights" active={@active == :flights}>
            Flights
          </.admin_nav_link>
        </nav>

        <.link
          navigate="/"
          class="mt-auto hidden px-2 pt-4 text-sm text-(--text-muted) hover:text-(--text-default) lg:block"
        >
          ← Back to site
        </.link>
      </aside>

      <div class="flex flex-1 flex-col">
        <header class="flex items-center justify-end gap-3 border-b border-(--border-default) bg-(--surface) px-4 py-3 sm:px-6">
          <.theme_toggle />
          <span :if={@current_scope && @current_scope.user} class="text-sm text-(--text-muted)">
            {@current_scope.user.email}
          </span>
          <.link
            :if={@current_scope && @current_scope.user}
            href="/users/log-out"
            method="delete"
            class="text-sm font-medium text-(--text-muted) hover:text-(--text-default)"
          >
            Log out
          </.link>
        </header>

        <main id="main-content" class="flex-1 bg-(--surface-muted) px-4 py-6 sm:px-6">
          {render_slot(@inner_block)}
        </main>

        <.flash_group flash={@flash} />
      </div>
    </div>
    """
  end

  attr :navigate, :string, required: true
  attr :active, :boolean, default: false
  slot :inner_block, required: true

  defp admin_nav_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "rounded-md px-3 py-2 text-sm font-medium",
        @active && "bg-brand-50 text-brand-700 dark:bg-brand-950 dark:text-brand-300",
        !@active && "text-(--text-muted) hover:bg-(--surface-muted) hover:text-(--text-default)"
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Light/dark theme toggle. A colocated hook persists the choice as a
  `theme` cookie client-side, which `AlbertAirlineWeb.Router.put_theme/2`
  reads server-side on the next request — so the very first response
  already carries the right `data-theme`, no inline script or
  flash-of-wrong-theme needed (see `root.html.heex`).

  "System" resolves once, at click time, to whatever the OS currently
  reports (`prefers-color-scheme`), rather than tracking it continuously
  — simpler, and avoids a persistent client-side media-query listener.
  """
  attr :id, :string, default: "theme-toggle"

  def theme_toggle(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook=".ThemeToggle"
      class="inline-flex items-center gap-0.5 rounded-full border border-(--border-default) bg-(--surface) p-1"
    >
      <button
        type="button"
        class="rounded-full p-1.5 text-(--text-muted) hover:bg-(--surface-muted) hover:text-(--text-default)"
        data-phx-theme="system"
        aria-label="Match system theme"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>
      <button
        type="button"
        class="rounded-full p-1.5 text-(--text-muted) hover:bg-(--surface-muted) hover:text-(--text-default)"
        data-phx-theme="light"
        aria-label="Light theme"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>
      <button
        type="button"
        class="rounded-full p-1.5 text-(--text-muted) hover:bg-(--surface-muted) hover:text-(--text-default)"
        data-phx-theme="dark"
        aria-label="Dark theme"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ThemeToggle">
      export default {
        mounted() {
          this.el.querySelectorAll("[data-phx-theme]").forEach((btn) => {
            btn.addEventListener("click", () => {
              let theme = btn.dataset.phxTheme
              if (theme === "system") {
                theme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
              }
              document.documentElement.dataset.theme = theme
              document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
            })
          })
        }
      }
    </script>
    """
  end
end
