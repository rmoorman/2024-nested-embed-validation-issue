defmodule HelloWeb.FormLive do
  use HelloWeb, :live_view

  defmodule Schema do
    use Ecto.Schema
    import Ecto.Changeset

    defmodule Nested do
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

    defmodule NestedDeeper do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        embeds_many :nested, Nested, on_replace: :delete
      end

      def changeset(data, attrs) do
        data
        |> cast(attrs, [])
        |> cast_embed(:nested)
      end
    end

    @primary_key false
    embedded_schema do
      field :name, :string

      embeds_many :nested, Nested, on_replace: :delete
      embeds_many :nested_with_let, Nested, on_replace: :delete
      embeds_many :nested_deeper, NestedDeeper, on_replace: :delete
    end

    def changeset(data, attrs) do
      data
      |> cast(attrs, [:name])
      |> cast_embed(:nested)
      |> cast_embed(:nested_with_let)
      |> cast_embed(:nested_deeper)
      |> validate_required(:name)
      |> validate_format(:name, ~r|a|, message: "must include the letter a")
    end
  end

  def handle_params(_, _, socket) do
    form =
      %Schema{
        nested: [%Schema.Nested{name: "foo"}],
        nested_with_let: [%Schema.Nested{name: "foo"}],
        nested_deeper: [
          %Schema.NestedDeeper{nested: [%Schema.Nested{name: "foo"}]}
        ]
      }
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
        <.inputs_for :let={nested} field={@form[:nested]}>
          <.input field={nested[:name]} label="Name" />
        </.inputs_for>
      </div>

      <div class="mt-10 p-2 border shadow">
        <.inputs_for :let={nested} field={f[:nested_with_let]}>
          <.input field={nested[:name]} label="Name" />
        </.inputs_for>
      </div>

      <div class="mt-10 p-2 border shadow">
        <.inputs_for :let={nested_deeper} field={@form[:nested_deeper]}>
          <.inputs_for :let={nested} field={nested_deeper[:nested]}>
            <.input field={nested[:name]} label="Name" />
          </.inputs_for>
        </.inputs_for>
      </div>
    </.form>

    <pre class="mt-10"><%= inspect(@form, limit: :infinity, pretty: true) %></pre>
    """
  end
end
