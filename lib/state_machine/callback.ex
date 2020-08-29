defmodule StateMachine.Callback do
  @moduledoc """
  Callback wraps a captured function, that can be called
  in a various points of a State Machine's lifecycle.
  Depending on return type (shape) of the callback,
  it can update the context or the model, or be ignored.
  """

  alias StateMachine.Context

  @type t(model) :: (model -> {:ok, model} | {:error, any} | any)
                  | (model, Context.t(model) -> {:ok, model} | {:ok, Context.t(model)} | {:error, any} | any)
                  | (-> any)

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
    case apply(cb, Enum.take([ctx.model, ctx], arity)) do
      {:ok, %Context{} = new_ctx} ->
        new_ctx
      {:ok, %{__struct__: ^strct} = model} ->
        %{ctx | model: model}
      {:error, e} ->
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
