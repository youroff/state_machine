defmodule StateMachine.Utils do
  @spec keyword_splat(keyword(), atom(), any) :: list(any)
  def keyword_splat(keyword, key, default \\ []) do
    case Keyword.get(keyword, key) do
      xs when is_list(xs) -> xs
      x when not is_nil(x) -> [x]
      _ -> default
    end
  end

  @doc false
  @spec function_arity(function()) :: 0 | 1 | 2
  def function_arity(fun) when is_function(fun, 0), do: 0
  def function_arity(fun) when is_function(fun, 1), do: 1
  def function_arity(fun) when is_function(fun, 2), do: 2

  @spec normalize_function(module(), (any -> any) | atom()) :: (any -> any)
  def normalize_function(_, f) when is_function(f, 1) do
    f
  end

  def normalize_function(mod, name) when is_atom(name) do
    Function.capture(mod, name, 1)
  end

  def normalize_function(_, x) do
    raise ArgumentError,
          "Expecting `:fun` of arity 1 from current module or captured function `&Mod.fun/1` as a callback, given: #{inspect(x)}"
  end
end
