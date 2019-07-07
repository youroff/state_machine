defmodule StateMachine.Callback do
  alias StateMachine.{Context}
  import MonEx.Result
  alias MonEx.Result

  # TODO: Maybe instead of any as a fallback case for void, use :ok
  @type t(model) :: (model -> Result.t(model, any) | any)
                  | (model, Context.t(model) -> Result.t(Context.t(model), any) | any)
                  | (-> any)

  @spec apply_callback(Context.t(model), t(model)) :: Context.t(model) when model: var
  def apply_callback(%{status: :init} = ctx, cb) do
    arity = Function.info(cb)[:arity]
    case apply(cb, Enum.take([ctx.model, ctx], arity)) do
      ok(result) -> case arity do
        1 -> %{ctx | model: result}
        2 -> result
        _ -> ctx
      end
      error(e) ->
        %{ctx | status: :failed, message: e}
      _ ->
        ctx
    end
  end

  def apply_callback(ctx, _), do: ctx

  @spec apply_chain(Context.t(model), list(t(model))) :: Context.t(model) when model: var
  def apply_chain(%{status: :init} = ctx, cbs) when is_list(cbs) do
    Enum.reduce(cbs, ctx, &apply_callback(&2, &1))
  end

  def apply_chain(ctx, _), do: ctx
end
