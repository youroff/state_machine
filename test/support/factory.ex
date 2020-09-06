defmodule StateMachine.Factory do
  alias StateMachine.{State, Event, Transition, Guard}

  defmodule Cat do
    defstruct name: "Garfield", state: :asleep, hungry: false

    def is_hungry?(model) do
      model.hungry
    end
  end

  def machine_cat do
    %StateMachine{
      states: %{
        asleep:   state_asleep(),
        awake:    state_awake(),
        playing:  state_playing(),
        eating:   state_eating()
      },
      events: %{
        wake:         event_wake(),
        give_a_mouse: event_give_a_mouse(),
        sing_lullaby: event_sing_lullaby()
      }
    }
  end

  def state_asleep do
    %State{
      name: :asleep
    }
  end

  def state_awake do
    %State{
      name: :awake
    }
  end

  def state_playing do
    %State{
      name: :playing
    }
  end

  def state_eating do
    %State{
      name: :eating
    }
  end

  def event_wake do
    %Event{
      name: :wake,
      transitions: [
        %Transition{
          from: :asleep,
          to: :awake
        }
      ]
    }
  end

  def event_give_a_mouse do
    %Event{
      name: :give_a_mouse,
      transitions: [
        %Transition{
          guards: [
            %Guard{fun: &Cat.is_hungry?/1, arity: 1}
          ],
          from: :awake,
          to: :eating
        },
        %Transition{
          guards: [
            %Guard{inverted: true, arity: 1, fun: &Cat.is_hungry?/1}
          ],
          from: :awake,
          to: :playing
        },
        %Transition{
          from: :playing,
          to: :eating
        }
      ]
    }
  end

  def event_sing_lullaby do
    %Event{
      name: :wake,
      transitions: [
        %Transition{
          from: :awake,
          to: :asleep
        },
        %Transition{
          from: :eating,
          to: :asleep
        },
        %Transition{
          from: :asleep,
          to: :asleep
        }
      ]
    }
  end
end
