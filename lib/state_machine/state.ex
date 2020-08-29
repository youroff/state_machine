defmodule StateMachine.State do
  @moduledoc """
  State module provides a structure describing a state in the state machine definition.
  It stores state name along with various callbacks to run before/after leaving/entering a state.
  Another purpose of the module is to define a behaviour for state get/setters along with the default implementation.

  The state get/setters for basic structures and Ecto records are provided out of the box.
  """

  alias StateMachine.{Context, Callback}

  @callback get(ctx :: Context.t(any)) :: atom()
  @callback set(ctx :: Context.t(model), state :: atom) :: Context.t(model) when model: var

  @type t(model) :: %__MODULE__{
    name:  atom,
    before_enter: list(Callback.t(model)),
    after_enter: list(Callback.t(model)),
    before_leave: list(Callback.t(model)),
    after_leave: list(Callback.t(model))
  }

  @enforce_keys [:name]
  defstruct [
    :name,
    before_enter: [],
    after_enter: [],
    before_leave: [],
    after_leave: []
  ]

  @doc """
  Private function for running `before_leave(state)` callbacks.
  """
  @spec before_leave(Context.t(model)) :: Context.t(model) when model: var
  def before_leave(ctx) do
    Callback.apply_chain(ctx, ctx.definition.states[ctx.old_state].before_leave, :before_leave)
  end

  @doc """
  Private function for running `after_leave(state)` callbacks.
  """
  @spec after_leave(Context.t(model)) :: Context.t(model) when model: var
  def after_leave(ctx) do
    Callback.apply_chain(ctx, ctx.definition.states[ctx.old_state].after_leave, :after_leave)
  end

  @doc """
  Private function for running `before_enter(state)` callbacks.
  """
  @spec before_enter(Context.t(model)) :: Context.t(model) when model: var
  def before_enter(ctx) do
    Callback.apply_chain(ctx, ctx.definition.states[ctx.new_state].before_enter, :before_enter)
  end

  @doc """
  Private function for running `after_enter(state)` callbacks.
  """
  @spec after_enter(Context.t(model)) :: Context.t(model) when model: var
  def after_enter(ctx) do
    Callback.apply_chain(ctx, ctx.definition.states[ctx.new_state].after_enter, :after_enter)
  end

  @doc """
  Default implementation of a state getter.
  """
  @spec get(Context.t(any)) :: atom()
  def get(ctx) do
    Map.get(ctx.model, ctx.definition.field)
  end

  @doc """
  Default implementation of a state setter.
  """
  @spec set(Context.t(model), atom()) :: Context.t(model) when model: var
  def set(ctx, state) do
    %{ctx | model: Map.put(ctx.model, ctx.definition.field, state)}
  end
end
