defmodule HelloWeb.FormLive do
  use HelloWeb, :live_view

  defmodule Schema do
    use Ecto.Schema
    import Ecto.Changeset

    defmodule NestedItem do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :name, :string
      end

      def changeset(data, attrs) do
        data
        |> cast(attrs, [:name])
        |> validate_required(:name)
        |> validate_format(:name, ~r|a|, message: "must include the letter a")
      end
    end

    @primary_key false
    embedded_schema do
      field :name, :string

      embeds_many :nested, NestedItem, on_replace: :delete
    end

    def changeset(data, attrs) do
      data
      |> cast(attrs, [:name])
      |> cast_embed(:nested)
      |> validate_required(:name)
      |> validate_format(:name, ~r|a|, message: "must include the letter a")
    end
  end

  def handle_params(_, _, socket) do
    form =
      %Schema{nested: [%Schema.NestedItem{name: "foo"}]}
      |> Schema.changeset(%{})
      |> to_form()

    socket = assign(socket, form: form)
    {:noreply, socket}
  end

  def handle_event("change", params, socket) do
    form = to_form(Schema.changeset(%Schema{}, params["schema"]), action: :validate)
    socket = assign(socket, form: form)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.form :let={f} for={@form} phx-change="change">
      <.input field={@form[:name]} label="Name" />

      <div class="mt-10 p-2 border shadow">
        <.inputs_for :let={nested} field={f[:nested]}>
          <.input field={nested[:name]} label="Name" />
        </.inputs_for>
      </div>
    </.form>

    <pre class="mt-10"><%= inspect(@form, limit: :infinity, pretty: true) %></pre>
    """
  end
end
