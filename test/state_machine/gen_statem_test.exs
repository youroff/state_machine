defmodule StateMachineGenStatemTest do
  use ExUnit.Case, async: true

  defmodule TestMachine do
    use StateMachine

    defstruct [:name, :state, hungry: true]

    defmachine field: :state do
      state :asleep, after_enter: &TestMachine.get_hungry/1
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

    def get_hungry(cat) do
      {:ok, %{cat | hungry: true}}
    end
  end

  test "GenStatem behavior" do
    cat = %TestMachine{state: :playing, name: "Yo"}
    assert TestMachine.hungry(cat)

    {:ok, sm} = TestMachine.start_link(cat)

    assert {:ok, cat} = TestMachine.trigger_call(sm, :give_a_mouse)
    refute TestMachine.hungry(cat)
    assert cat.state == :eating

    assert {:error, {:transition, "Couldn't resolve transition"}} = TestMachine.trigger_call(sm, :sing_a_lullaby)

    assert {:ok, %{state: :playing, hungry: false}} = TestMachine.trigger_call(sm, :pet)
    assert {:ok, %{state: :asleep, hungry: true}} = TestMachine.trigger_call(sm, :sing_a_lullaby)
  end
end
