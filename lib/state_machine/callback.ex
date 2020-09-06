defmodule StateMachine.Callback do
  @moduledoc """
  Callback wraps a captured function, that can be called
  in a various points of a State Machine's lifecycle.
  Depending on return type (shape) of the callback,
  it can update the context or the model, or be ignored.
  """

  alias StateMachine.Context

  @doc """
  A type of callback that does not expect any input and potentially produces a side effect.
  Any return value is ignored, except for `{:error, e}` that stops the transition with a given error.
  """
  @type side_effect_t :: (-> any)

  @doc """
  A unary callback, receiving a model struct and that can be updated based on shape of the return:
    * `{:ok, model}` — replaces model in the context
    * `{:error, e}` — stops the transition with a given error
    * `any` — doesn't have any effect on the context
  """
  @type unary_t(model) :: (model -> {:ok, model} | {:error, any} | any)

  @doc """
  A binary callback, receiving a model struct and a context.
  Either can be updated depending on the shape of the return:
    * `{:ok, context}` — replaces context completely
    * `{:ok, model}` — replaces model in the context
    * `{:error, e}` — stops the transition with a given error
    * `any` — doesn't have any effect on the context
  """
  @type binary_t(model) :: (model, Context.t(model) -> {:ok, model} | {:ok, Context.t(model)} | {:error, any} | any)

  @type t(model) :: unary_t(model) | binary_t(model) | side_effect_t()

  @doc """
  Applying a single callback. Callback's return structurally analyzed:

  ## Callback return processing
    * `{:ok, %Context{...}}` - replace the existing context with the new one
    * `{:ok, %ModelString{...}}` - update `model` in context
    * `{:error, error}` - set context status to `:failed` and populate message
      with tuple {step, error}, where step is an atom pointing at where this happened (i.e. `:before_transition`)
    * `anything else` - return original context, here we assume functions with
      side-effects and no meaningful return
  """
  @spec apply_callback(Context.t(model), t(model), atom()) :: Context.t(model) when model: var
  def apply_callback(%{status: :init} = ctx, cb, step) do
    arity = Function.info(cb)[:arity]
    strct = ctx.model.__struct__
    case {apply(cb, Enum.take([ctx.model, ctx], arity)), arity} do

      # Only binary callback can return a new context
      {{:ok, %Context{} = new_ctx}, 2} ->
        new_ctx

      # Both binary and unary callbacks can return a new model
      {{:ok, %{__struct__: ^strct} = model}, a} when a > 0 ->
        %{ctx | model: model}

      # Any callback can fail and trigger whole transition failure
      {{:error, e}, _} ->
        %{ctx | status: :failed, error: {step, e}}

      _ ->
        ctx
    end
  end

  def apply_callback(ctx, _, _), do: ctx

  @doc """
  Applying a chain of callbacks. Application only happens if `status` hasn't been changed.
  """
  @spec apply_chain(Context.t(model), list(t(model)), atom()) :: Context.t(model) when model: var
  def apply_chain(%{status: :init} = ctx, cbs, step) when is_list(cbs) do
    Enum.reduce(cbs, ctx, &apply_callback(&2, &1, step))
  end

  def apply_chain(ctx, _, _), do: ctx
end
