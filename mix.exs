defmodule StateMachine.MixProject do
  use Mix.Project

  def project, do: [
    app: :state_machine,
    version: "0.1.3",
    elixir: "~> 1.7",
    start_permanent: Mix.env() == :prod,
    elixirc_paths: elixirc_paths(Mix.env),
    description: description(),
    package: package(),
    deps: deps()
  ]

  def application do
    [extra_applications: applications(Mix.env)]
  end

  defp applications(:test), do: [:postgrex, :ecto, :ecto_sql]
  defp applications(_), do: []

  defp description, do: """
    State Machine implementation in Elixir.
    It's a structure and optionally a gen_statem powered process.
    It validates states and transitions for integrity and features seamless Ecto-integration.
  """

  defp package, do: [
   files: ["lib", "mix.exs", "README*", "LICENSE*"],
   maintainers: ["Ivan Yurov"],
   licenses: ["Apache 2.0"],
   links: %{"GitHub" => "https://github.com/youroff/state_machine"}
  ]

  defp deps, do: [
    {:ecto, "~> 3.0", optional: true},
    {:ecto_sql, "~> 3.0", optional: true},
    {:postgrex, ">= 0.0.0", optional: true},
    {:dialyxir, "~> 0.5.1", runtime: false},
    {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
  ]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
