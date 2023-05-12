#TODO Maybe should rename the module
defmodule StateMachine.Error.SetError do
  @moduledoc """
  SetError is a container for the metadata needed to understand why set model to state is failed.
  """

  @type t(model) :: %__MODULE__{
    context: StateMachine.Context.t(model),
    error: any
  }

  @enforce_keys [:context, :error]
  defstruct [
    :context,
    :error
  ]
end
