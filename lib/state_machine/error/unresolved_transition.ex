defmodule StateMachine.Error.UnresolvedTransition do
  @moduledoc """
  UnresolvedTransition is a container for the metadata needed to understand why transition is unresolved.
  """

  @type t(model) :: %__MODULE__{
    context: StateMachine.Context.t(model),
    event: atom
  }

  @enforce_keys [:context, :event]
  defstruct [
    :context,
    :event
  ]
end
