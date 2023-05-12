defmodule StateMachine.Error.UnknownEvent do
  @moduledoc """
  UnknownEvent is a container for the metadata needed to understand the state after an unknown event.
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
