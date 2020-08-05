defmodule StateMachineGenStatemTest do
  use ExUnit.Case, async: true
  import MonEx.Result

  defmodule TestMachine do
    use StateMachine

    defstruct [:name, :state, hungry: true]

    defmachine field: :state do
      state :asleep
      state :awake
      state :playing
      state :eating, after_enter: &TestMachine.feed_up/1

      event :wake do
        transition from: :asleep, to: :awake
      end

      event :give_a_mouse do
        transition from: :awake, to: :playing, unless: &TestMachine.hungry/1
        transition from: :awake, to: :eating, if: &TestMachine.hungry/1
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

    define_gen_statem()

    def hungry(cat) do
      cat.hungry
    end

    def feed_up(cat) do
      {:ok, %{cat | hungry: false}}
    end
  end

  test "GenStatem behavior" do
    model = %TestMachine{state: :playing, name: "Yo"}
    ok(sm) = TestMachine.start_link(model)

    TestMachine.trigger_call(sm, :give_a_mouse)
    # |> IO.inspect
    # :timer.sleep(500)
    # IO.inspect(sm)
  end
end
