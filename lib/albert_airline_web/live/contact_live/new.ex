defmodule AlbertAirlineWeb.ContactLive.New do
  use AlbertAirlineWeb, :live_view

  alias AlbertAirline.Contact
  alias AlbertAirline.Contact.Message
  alias AlbertAirlineWeb.RateLimit

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> RateLimit.assign_client_ip()
     |> assign(:page_title, "Contact Us")
     |> assign_form(Contact.change_message(%Message{}))}
  end

  @impl true
  def handle_event("validate", %{"message" => params}, socket) do
    changeset = Contact.change_message(%Message{}, params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"message" => params}, socket) do
    case RateLimit.check("contact:#{socket.assigns.client_ip}", :timer.minutes(1), 5) do
      :ok ->
        case Contact.create_message(params, current_user_id(socket.assigns.current_scope)) do
          {:ok, _message} ->
            {:noreply,
             socket
             |> assign_form(Contact.change_message(%Message{}))
             |> put_flash(:info, "Thanks for reaching out — we'll get back to you soon.")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end

      {:error, :rate_limited} ->
        RateLimit.deny(socket)
    end
  end

  defp current_user_id(%{user: %{id: id}}), do: id
  defp current_user_id(_no_scope), do: nil

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: "message"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="albert-card mx-auto max-w-3xl text-center">
        <h2 class="text-2xl font-bold">Contact Us</h2>

        <h3 class="mt-6 text-xl font-semibold">Connect with Us</h3>
        <p class="mt-2 text-lg">
          We're here to connect with you! Feel free to reach out through email or
          social media. Your feedback, questions, and suggestions are valuable to
          us as we continue to refine and enhance our platform.
        </p>

        <h3 class="mt-6 text-xl font-semibold">Join Our Community</h3>
        <p class="mt-2 text-lg">
          Become part of the Albert Airline community and experience travel in a
          whole new way. Join us in shaping the future of flight reservations by
          staying up to date with exclusive content and updates.
        </p>

        <h3 class="mt-6 text-xl font-semibold">Contact Form</h3>
        <p class="mt-2 text-lg">
          If you prefer, you can also use the form below to reach out to us.
          Simply provide your information and your message, and we'll get back to
          you as soon as possible.
        </p>

        <.form
          for={@form}
          id="contact-form"
          phx-change="validate"
          phx-submit="save"
          class="mx-auto mt-4 flex max-w-sm flex-col items-center gap-3 rounded-lg border border-black/30 p-4"
        >
          <.input
            field={@form[:first_name]}
            type="text"
            label="First name :"
            class="w-full rounded border border-black/40 px-2 py-1"
          />
          <.input
            field={@form[:last_name]}
            type="text"
            label="Last name :"
            class="w-full rounded border border-black/40 px-2 py-1"
          />
          <.input
            field={@form[:company_name]}
            type="text"
            label="Company name :"
            class="w-full rounded border border-black/40 px-2 py-1"
          />
          <.input
            field={@form[:email]}
            type="email"
            label="Email :"
            class="w-full rounded border border-black/40 px-2 py-1"
          />
          <.input
            field={@form[:message]}
            type="textarea"
            label="Message :"
            class="w-full rounded border border-black/40 px-2 py-1"
          />

          <button
            type="submit"
            class="mt-2 cursor-pointer rounded-md bg-[#2563eb] px-4 py-2 font-semibold text-white"
          >
            Submit
          </button>
        </.form>

        <h3 class="mt-6 text-xl font-semibold">Customer Support</h3>
        <p class="mt-2 text-lg">
          We're committed to providing exceptional customer support. If you have
          any inquiries related to bookings, reservations, or technical
          assistance, our dedicated support team is ready to assist you.
        </p>

        <h3 class="mt-6 text-xl font-semibold">We're Here for You</h3>
        <p class="mt-2 text-lg">
          At Albert, your satisfaction is our priority. Whether you have a
          question, feedback, or a suggestion for improvement, we're dedicated to
          making your experience with us exceptional.
        </p>
      </div>
    </Layouts.app>
    """
  end
end
