defmodule StateMachine.Context do
  @type t(model) :: %__MODULE__{
    definition: StateMachine.t(model),
    model: model,
    status: :init | :impossible | :rejected | :failed | :done,
    message: any,
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
    :message,
    :event,
    :old_state,
    :new_state,
    :payload
  ]

  @spec build(StateMachine.t(model), model) :: t(model) when model: var
  def build(sm, model) do
    %__MODULE__{
      definition: sm,
      model: model,
      old_state: Map.get(model, sm.field) # figure out more general solution
    }
  end

  @spec get_state(Context.t(any)) :: atom
  def get_state(ctx) do
    Map.get(ctx.model, ctx.definition.field)
  end
end
