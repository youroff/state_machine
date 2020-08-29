defmodule StateMachine.Ecto do
  @moduledoc """
  Ecto additions simplify working with Ecto structures. When using StateMachine with Ecto,
  we assume that model is a changeset. This introduces indirection in reading and updating
  state.

  TODO: Full example
  """

  @doc """
  This macro defines an Ecto.Type implementation inside of StateMachine namespace.
  The default name would be `StateType`, but you can supply any module name.
  The purpose of this is to be able to cast string into atom and back safely,
  validating it against StateMachine defition.
  """
  defmacro define_ecto_type(name \\ StateType) do
    quote do
      states = Module.get_attribute(__MODULE__, :state_names)
      unless states do
        raise CompileError, [
          file: __ENV__.file,
          line: __ENV__.line,
          description: "State Ecto type should be declared after state machine definition"
        ]
      end

      defmodule unquote(name) do
        @behaviour Ecto.Type
        @states states

        def type, do: :string

        def cast(state) do
          if s = Enum.find(@states, &to_string(&1) == to_string(state)) do
            {:ok, s}
          else
            :error
          end
        end

        # This might be also
        def load(state) do
          {:ok, String.to_atom(state)}
        end

        def dump(state) when state in @states do
          {:ok, to_string(state)}
        end

        def dump(_), do: :error
      end
    end
  end

  @behaviour StateMachine.State

  @impl true
  def get(ctx) do
    Map.get(ctx.model, ctx.definition.field)
  end

  @impl true
  def set(ctx, state) do
    Ecto.Changeset.change(ctx.model, [{ctx.definition.field, state}])
    |> ctx.definition.misc[:repo].update()
    |> case do
      {:ok, model} ->
        %{ctx | model: model}
      {:error, e} ->
        %{ctx | status: :failed, message: e}
    end
  end
end
