defmodule StateMachine.Callback do
  @moduledoc """
  Callback defines a captured function, that can be called
  in a various points of a State Machine's lifecycle.
  Depending on return type (shape) of the callback,
  it can update the context or the model, stop the transition with error, or be ignored.
  """

  alias StateMachine.Context
  alias StateMachine.Error

  @type side_effect_t :: (-> any)

  @type unary_t(model) :: (model -> {:ok, model} | {:error, any} | any)

  @type binary_t(model) ::
          (model, Context.t(model) ->
             {:ok, model} | {:ok, Context.t(model)} | {:error, any} | any)

  @type t(model) :: unary_t(model) | binary_t(model) | side_effect_t()

  @doc """
  Applying a single callback. There are three types of callbacks supported:

  ## Unary (unary_t type)
  A unary callback, receiving a model struct and that can be updated
  in current conetxt based on shape of the return:
    * `{:ok, model}` — replaces model in the context
    * `{:error, e}` — stops the transition with a given error
    * `any` — doesn't have any effect on the context

  ## Binary (binary_t type)
  A binary callback, receiving a model struct and a context.
  Either can be updated depending on the shape of the return:
    * `{:ok, context}` — replaces context completely
    * `{:ok, model}` — replaces model in the context
    * `{:error, e}` — stops the transition with a given error
    * `any` — doesn't have any effect on the context

  ## Side effects  (side_effect_t type)
  A type of callback that does not expect any input and potentially produces a side effect.
  Any return value is ignored, except for `{:error, e}` that stops the transition with a given error.
  """
  @spec apply_callback(Context.t(model), t(model), atom()) ::
          {:ok, Context.t(model)} | {:error, Error.CallbackError.t(model)}
        when model: var
  def apply_callback(%{status: :init} = ctx, cb, step) do
    arity = Function.info(cb)[:arity]
    strct = ctx.model.__struct__

    case {apply(cb, Enum.take([ctx.model, ctx], arity)), arity} do
      # Only binary callback can return a new context
      {{:ok, %Context{} = new_ctx}, 2} ->
        {:ok, new_ctx}

      # Both binary and unary callbacks can return a new model
      {{:ok, %{__struct__: ^strct} = model}, a} when a > 0 ->
        {:ok, %{ctx | model: model}}

      # Any callback can fail and trigger whole transition failure
      {{:error, e}, _} ->
        {:error, %Error.CallbackError{context: ctx, step: step, error: e}}

      _ ->
        {:ok, ctx}
    end
  end

  def apply_callback(ctx, _, _), do: {:ok, ctx}

  @doc """
  Applying a chain of callbacks. Application only happens if `status` hasn't been changed.
  """
  @spec apply_chain(Context.t(model), list(t(model)), atom()) ::
          {:ok, Context.t(model)} | {:error, Error.CallbackError.t(model)}
        when model: var
  def apply_chain(%{status: :init} = ctx, cbs, step) when is_list(cbs) do
    Enum.reduce_while(cbs, {:ok, ctx}, fn cb, {:ok, context} ->
      case apply_callback(context, cb, step) do
        {:ok, new_context} -> {:cont, {:ok, new_context}}
        {:error, e} -> {:halt, {:error, e}}
      end
    end)
  end

  def apply_chain(ctx, _, _), do: {:ok, ctx}
end
