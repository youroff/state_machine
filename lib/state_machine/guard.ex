defmodule StateMachine.Guard do
  @moduledoc ~S"""
  Guards are functions bound to Events and Transitions that help to decide
  whether it's allowed to proceed. They might serve different purposes:
  * Protecting state maching from getting into some state unless some criteria met
  * Creating event with multiple target states

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
  and returns true if all passed, guard returning. Second argument
  is the context, that gets passed on to each guard.

  """
  @spec check(Context.t(m), Event.t(m) | Transition.t(m)) :: boolean when m: var
  def check(ctx, %{guards: guards}) do
    Enum.reduce_while(guards, true, fn guard, _ -> check_guard(ctx, guard) end)
  end

  @spec check_guard(Context.t(m), t(m)) :: {:cont, boolean} | {:halt, boolean} when m: var
  defp check_guard(ctx, %Guard{inverted: inv, fun: f, arity: n}) do
    if inv == !!apply(f, Enum.take([ctx.model, ctx], n)) do
      {:halt, false}
    else
      {:cont, true}
    end
  end
end
