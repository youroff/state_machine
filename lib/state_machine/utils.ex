defmodule StateMachine.Utils do

  @spec keyword_splat(keyword(), atom(), any) :: list(any)
  def keyword_splat(keyword, key, default \\ []) do
    case Keyword.get(keyword, key) do
      xs when is_list(xs) -> xs
      x when not is_nil(x) -> [x]
      _ -> default
    end
  end

  @spec normalize_function(module(), (any -> any) | atom()) :: (any -> any)
  def normalize_function(_, f) when is_function(f, 1) do
    f
  end

  def normalize_function(mod, name) when is_atom(name) do
    Function.capture(mod, name, 1)
  end

  def normalize_funciton(_, x) do
    raise ArgumentError, "Expecting `:fun` of arity 1 from current module or captured function `&Mod.fun/1` as a callback, given: #{inspect x}"
  end
end
