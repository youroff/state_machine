defmodule StateMachine.State do
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

  @spec before_leave(Context.t(model)) :: Context.t(model) when model: var
  def before_leave(ctx) do
    Callback.apply_chain(ctx, ctx.definition.states[ctx.old_state].before_leave)
  end

  @spec after_leave(Context.t(model)) :: Context.t(model) when model: var
  def after_leave(ctx) do
    Callback.apply_chain(ctx, ctx.definition.states[ctx.old_state].after_leave)
  end

  @spec before_enter(Context.t(model)) :: Context.t(model) when model: var
  def before_enter(ctx) do
    Callback.apply_chain(ctx, ctx.definition.states[ctx.new_state].before_enter)
  end

  @spec after_enter(Context.t(model)) :: Context.t(model) when model: var
  def after_enter(ctx) do
    Callback.apply_chain(ctx, ctx.definition.states[ctx.new_state].after_enter)
  end

  def get(ctx) do
    Map.get(ctx.model, ctx.definition.field)
  end

  def set(ctx, state) do
    %{ctx | model: Map.put(ctx.model, ctx.definition.field, state)}
  end
end
