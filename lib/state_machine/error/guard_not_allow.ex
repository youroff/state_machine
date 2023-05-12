defmodule StateMachine.Error.GuardNotAllow do
  @moduledoc """
  GuardNotAllow is a container for the metadata needed to understand why guard didn't allow event.
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
