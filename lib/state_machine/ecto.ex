defmodule StateMachine.Ecto do
  @moduledoc """
  This addition makes StateMachine fully compatible with Ecto. We abstract state setter and getter,
  in order to provide a way to update a state in the middle of transition. If the state machine uses structure,
  it is a simple `Map.put`, this is a default implementation. With Ecto, we call `change() |> Repo.update`.
  We also wrap every event in transaction, which is rolled back if transition failed to finish.
  This unlocks a lot of beautiful effects. For example, you can enqueue some tasks into db-powered queue in callbacks,
  and if transition failes, those tasks will naturally disappear.

  ### Usage
  To use Ecto, simply pass `repo` param to `defmachine`, you can optionally pass a name of the `Ecto.Type`
  implementation, that will be generated automatically under state machine namespace:

    defmodule EctoMachine do
      use StateMachine

      defmachine field: :state, repo: TestApp.Repo, ecto_type: CustomMod do
        state :resting
        state :working

        # ...
      end
    end

  In your schema you can refer to state type as `EctoMachine.CustomMod`, with `ecto_type` omitted
  it would generate `EctoMachine.StateType`. This custom type is needed to transparently use atoms as states.

  """

  @doc """
  This macro defines an Ecto.Type implementation inside of StateMachine namespace.
  The default name is `StateType`, but you can supply any module name.
  The purpose of this is to be able to cast string into atom and back safely,
  validating it against StateMachine defition.
  """
  defmacro define_ecto_type() do
    quote do
      states = Module.get_attribute(__MODULE__, :state_names)

      unless states do
        raise CompileError, [
          file: __ENV__.file,
          line: __ENV__.line,
          description: "State Ecto type should be declared inside of state machine definition"
        ]
      end

      defmodule Module.concat(__MODULE__, @ecto_type) do
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

        def load(state) do
          {:ok, String.to_atom(state)}
        end

        def dump(state) when state in @states do
          {:ok, to_string(state)}
        end

        def dump(_), do: :error

        def equal?(s1, s2), do: to_string(s1) == to_string(s2)

        def embed_as(_), do: :self
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
        %{ctx | status: :failed, message: {:set_state, e}}
    end
  end
end
