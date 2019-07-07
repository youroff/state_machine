defmodule StateMachine.MixProject do
  use Mix.Project

  def project, do: [
    app: :state_machine,
    version: "0.1.0",
    elixir: "~> 1.7",
    start_permanent: Mix.env() == :prod,
    elixirc_paths: elixirc_paths(Mix.env),
    description: description(),
    package: package(),
    deps: deps()
  ]

  def application, do: [
    # extra_applications: [:logger]
  ]

  defp description do
    """
    State Machine implementation in Elixir. The goal is to make it easily convertible into gen_statem. At this point — it's still exprimental.
    """
  end

  defp package, do: [
   files: ["lib", "mix.exs", "README*", "LICENSE*"],
   maintainers: ["Ivan Yurov"],
   licenses: ["Apache 2.0"],
   links: %{"GitHub" => "https://github.com/youroff/state_machine"}
  ]

  defp deps, do: [
    {:monex, "~> 0.1"},
    {:dialyxir, "~> 0.5.1", runtime: false}
  ]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
