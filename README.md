# StateMachine

*This is work in progress*

The goal of this work is to simplify building finite state machines in Elixir. Formal definition of finite state machines can be found on [Wikipedia](https://en.wikipedia.org/wiki/Finite-state_machine).

Here's an example of simple state machine created with this package:

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

# After event we get a context that contains modified (possibly) model in `model` field.
context = Cat.trigger(cat, :wake)
context.status      # => :done
context.old_state   # => :asleep
context.new_state   # => :awake
context.model.state # => :awake

# To learn about all/available states/events, use introspection:
# TODO...
```

## Overview
If you're familiar with state machines in general, you can skip the rest of this readme. 

### States
States are named conditions which state machine can inhabit. State machine can be only in one state simultaneously. State is changed in response to some external event. States in our model are represented by atoms.

### Events
Events are external messages that might cause state machine to change state. Event is a container for transitions.

### Transitions
Transitions are pairs of states: source (`from`) and destination (`to`). The definition allows multiple source states for brevity, but destination is always deterministic. However it is possible to define an event that might move state machine from one state to either of multiple states based on exection of a guard (see below).

### Callbacks
Callbacks are functions that can be called in various times during lifecycle. There are callbacks for states, events and transitions:

* before(event)
* before(transition)
* before_leave(state)
* before_enter(state)
* *** (state update) ***
* after_leave(state)
* after_enter(state)
* after(transition)
* after(event)

Callbacks can be of arity 0, 1 or 2:
* If arity is 0, the state of context is not updated. This is for side effects we don't really care about.
* If arity is 1, first argument is a model, and updated model in {:ok, model} | {:error, e} has to be returned. It will be used to update model in context, or, in case of error, it will reject the transition and set the error status.
* If arity is 2, then first argument is a mode, and second is a context. In this case you have to return context wrapped in {:ok, ...}

*Important to notice that callbacks cannot be defined inline as lambdas, because lambdas won't survive macro expansion.*

### Guards
Guards are functions that help to decide wether state machine can proceed with transition. In one event attempt it might run various guards whose transitions match formal signature, for this reason guards are not allowed to have side-effects. Guards are ran very first, before any callback. They basically just help to choose appropriate transition. For example, checking the balance before unlocking a bycicle in bikeshare system. For convenience both `if` and `unless` keywords are supported: respectively guard in `if` must return `true` to proceed and vice versa for `unless`. It's impossible to use lambdas here as well.

### Validation
State machine definition is validated automatically on compile time. It will check if states used in transitions are declared first. It also attempts to catch non-determinism, i.e. if one event has two transitions from one state without guards.

### Context

### FSM as a structure
Basic mode of operation is in some sense static. State machine definition generates some functions and attributes on the module of your choice and then you just run then in whatever environment you want. This way provides greatest level of control.

### FSM as a process
Second mode is dynamic in a way that structure that can behave as state machine becomes a separate process that accepts events as messages. This approach naturally maintains consistency of state cause concurrent events are nicely separated by process's mailbox. And it's totally feasible since processes in Elixir are cheap. Our goal is to use existing DSL to generate `gen_statem`-compatible definition. In other words it's a work in progress.

## Installation

The package can be installed
by adding `state_machine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:state_machine, "~> 0.1.0"}
  ]
end
```

The documentation can be found at [https://hexdocs.pm/state_machine](https://hexdocs.pm/state_machine).

