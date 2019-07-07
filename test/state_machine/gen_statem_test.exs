defmodule StateMachineGenStatemTest do
  use ExUnit.Case, async: true

  defmodule TestMachine do
    def start_link() do
      :gen_statem.start_link(__MODULE__, nil, [])
    end

    def init(model) do
      {:ok, [], []}
    end

    def callback_mode do
      :state_functions
    end
  end


  test "GenStatem behavior" do
    TestMachine.start_link() |> IO.inspect
  end
end
