defmodule StateMachine.MixProject do
  use Mix.Project

  def project, do: [
    app: :state_machine,
    version: "0.1.0",
    elixir: "~> 1.7",
    start_permanent: Mix.env() == :prod,
    elixirc_paths: elixirc_paths(Mix.env),
    deps: deps()
  ]

  def application, do: [
    # extra_applications: [:logger]
  ]

  defp deps, do: [
    {:monex, "~> 0.1.13"},
    {:dialyxir, "~> 0.5.1", runtime: false}
  ]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
