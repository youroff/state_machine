#TODO Maybe should rename the module
defmodule StateMachine.Error.CallbackError do
  @moduledoc """
  CallbackError is a container for the metadata needed to understand why сallback is failed.
  """

  @type t(model) :: %__MODULE__{
    context: StateMachine.Context.t(model),
    step: atom,
    error: any
  }

  @enforce_keys [:context, :step, :error]
  defstruct [
    :context,
    :step,
    :error
  ]
end
