defmodule StateMachine do
  @moduledoc """
  StateMachine package implements state machine abstraction.
  It supports Ecto out of the box and can work as both
  data structure and a process powered by gen_statem.

  Check out the [article](https://dev.to/youroff/state-machines-for-business-np8) for motivation.

  Here's an example of a simple state machine created with this package:

      ```elixir
      defmodule Cat do
        use StateMachine

        defstruct [:name, :state, hungry: true]

        defmachine field: :state do
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

        def hungry(cat) do
          cat.hungry
        end

        def feed_up(cat) do
          {:ok, %{cat | hungry: false}}
        end
      end
      ```

  And later use it like this:

      ```elixir
      cat = %Cat{name: "Thomas", state: :asleep}

      {:ok, %Cat{state: :awake}} = Cat.trigger(cat, :wake)
      ```

  ## Features
  * Validation of state machine definition at compile time
  * Full support for callbacks (on states, events and transitions) and guards (on events and transitions)
  * Optional payload can be supplied with the event
  * One-line conversion to a state machine as a process (powered by gen_statem)
  * With Ecto support activated every transition is wrapped in transaction
  * With Ecto support activated the Ecto.Type implementation is generated automatically
  """
  alias StateMachine.{State, Event, Context}

  @type t(m) :: %__MODULE__{
    states: %{optional(atom) => State.t(m)},
    events: %{optional(atom) => Event.t(m)},
    field:  atom(),
    state_getter: (Context.t(m) -> atom()),
    state_setter: (Context.t(m), atom() -> Context.t(m)),
    misc: keyword()
  }

  defstruct states: %{},
    events: %{},
    field: :state,
    state_getter: &State.get/1,
    state_setter: &State.set/2,
    misc: []

  defmacro __using__(_) do
    quote do
      import StateMachine.DSL
      alias StateMachine.Introspection

      @after_compile StateMachine
    end
  end

  def __after_compile__(env, _) do
    unless function_exported?(env.module, :__state_machine__, 0) do
      raise CompileError, file: env.file, description: "Define state machine using `defmachine` macro"
    end
  end
end
