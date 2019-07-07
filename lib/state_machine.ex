defmodule StateMachine do
  @moduledoc ~S"""
  StateMachine package implements finite state machine (FSM) abstraction.

  What is this?

  What makes it different from other solutions?

  Main features

  Introductory Examples

  Core concepts
  - States
  - Events
  - Transitions
  - Guards
  - Callbacks
  - Context

  Introspection

  Application usage
  - Standalone
  - GenStatem (TODO)
  - Ecto integration (TODO)

  ## Guards

  ## Callbacks
  Run order:
  - before(event)
  - before(transition)
  - before_leave(state)
  - before_enter(state)
  *** TRANSITION ***
  - after_leave(state)
  - after_enter(state)
  - after(transition)
  - after(event)
  """
  alias StateMachine.{State, Event}

  @type t(m) :: %__MODULE__{
    states: %{optional(atom) => State.t(m)},
    events: %{optional(atom) => Event.t(m)},
    field:  atom
  }

  defstruct states: %{}, events: %{}, field: :state

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
