defmodule StateMachine.Guard do
  @moduledoc """
  Guards are functions that help to decide whether it's allowed to proceed with Event
  or Transition. They might serve different purposes:

  * Preventing a state machine from getting into a state unless some criteria met
  * Creating event with multiple target states with a single source state

  Guards should not have any side-effects, cause they are getting run no matter
  if transition is successful or not, and also to determine the list of possible events
  for a certain state.
  """
  alias StateMachine.{Context, Guard, Event, Transition}
  import StateMachine.Utils, only: [keyword_splat: 2]

  @type t(model) :: %__MODULE__{
    inverted: boolean,
    arity: integer,
    fun: (model, Context.t(model) -> boolean) | (model -> boolean) | (-> boolean)
  }

  @enforce_keys [:fun, :arity]
  defstruct [:fun, :arity, inverted: false]

  @doc """
  Unifies `if` and `unless` guards into a single stream of guards.
  """
  @spec prepare(keyword()) :: list(t(any))
  def prepare(opts) do
    ifs = keyword_splat(opts, :if)
    |> Enum.map(&%Guard{fun: &1, arity: Function.info(&1)[:arity]})

    unlesses = keyword_splat(opts, :unless)
    |> Enum.map(&%Guard{inverted: true, fun: &1, arity: Function.info(&1)[:arity]})

    ifs ++ unlesses
  end

  @doc """
  Check runs guards associated with given Event or Transition
  and returns true if all passed. First argument of the guard is a model,
  second argument is the context.
  """
  @spec check(Context.t(m), Event.t(m) | Transition.t(m)) :: boolean when m: var
  def check(ctx, %{guards: guards}) do
    Enum.all?(guards, fn guard ->
      guard.inverted == !apply(guard.fun, Enum.take([ctx.model, ctx], guard.arity))
    end)
  end
end
