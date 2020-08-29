defmodule TestApp.Repo do
  use Ecto.Repo,
    otp_app: :test_app,
    adapter: Ecto.Adapters.Postgres
end

defmodule TestApp.CatMachine do
  use StateMachine

  defmachine field: :state, repo: TestApp.Repo do
    state :asleep
    state :awake
    state :playing
    state :eating, after_enter: &Cat.feed_up/1

    event :wake do
      transition from: :asleep, to: :awake
    end

    event :give_a_mouse do
      transition from: :awake, to: :playing, unless: &Cat.hungry/1
      transition from: :awake, to: :eating, if: &Cat.hungry/1
      transition from: :playing, to: :eating
    end

    event :pet do
      transition from: [:eating, :awake], to: :playing
    end

    event :sing_a_lullaby do
      transition from: :awake, to: :asleep
      transition from: :playing, to: :asleep
    end
  end
  define_ecto_type(StateType)

  def hungry(cat) do
    cat.hungry
  end

  def feed_up(cat) do
    {:ok, %{cat | hungry: false}}
  end
end

defmodule TestApp.Cat do
  use Ecto.Schema

  schema "cats" do
    field :name, :string
    field :state, TestApp.CatMachine.StateType
    field :hungry, :boolean
  end
end
