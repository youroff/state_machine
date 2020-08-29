defmodule StateMachine.Context do
  @moduledoc """
  Context is a container for all metadata supporting the transition.
  Normally users should not have anything to do with Contexts,
  however some public functions might expose it. For example, user can
  (but discuraged) manipulate the Context in callbacks.
  """

  @type t(model) :: %__MODULE__{
    definition: StateMachine.t(model),
    model: model,
    status: :init | :failed | :done,
    error: any,
    event: atom,
    old_state: atom,
    new_state: atom,
    payload: any
  }

  @enforce_keys [:definition, :model]
  defstruct [
    :definition,
    :model,
    {:status, :init},
    :error,
    :event,
    :old_state,
    :new_state,
    :payload
  ]

  @doc """
  Builds a fresh context based on State Machine definition and a model struct.
  """
  @spec build(StateMachine.t(model), model) :: t(model) when model: var
  def build(definition, model) when is_struct(model) do
    ctx = %__MODULE__{
      definition: definition,
      model: model
    }
    %{ctx | old_state: ctx.definition.state_getter.(ctx)}
  end
end
