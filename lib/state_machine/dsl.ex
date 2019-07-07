defmodule StateMachine.DSL do
  alias StateMachine
  alias StateMachine.{State, Event, Transition, Context, Guard, Introspection}
  import StateMachine.Utils, only: [keyword_splat: 2]

  defmacro defmachine(opts \\ [], block) do
    head =
      quote do
        @after_compile StateMachine.Validation
        Module.register_attribute(__MODULE__, :states, accumulate: true)
        Module.register_attribute(__MODULE__, :events, accumulate: true)
        Module.put_attribute(__MODULE__, :in_defmachine, true)
        Module.put_attribute(__MODULE__, :field, Keyword.get(unquote(opts), :field, :state))
        unquote(block)
      end

    out =
      quote unquote: false do
        states = @states |> Enum.reverse |> Enum.reduce(%{}, fn state, acc ->
          Map.put(acc, state.name, state)
        end)

        events = @events |> Enum.reverse |> Enum.reduce(%{}, fn event, acc ->
          Map.put(acc, event.name, event)
        end)

        field = @field

        Module.delete_attribute(__MODULE__, :states)
        Module.delete_attribute(__MODULE__, :events)
        Module.delete_attribute(__MODULE__, :field)
        Module.delete_attribute(__MODULE__, :in_defmachine)

        def __state_machine__, do: %StateMachine{
          field: unquote(field),
          states: unquote(Macro.escape(states)),
          events: unquote(Macro.escape(events))
        }

        aux_functions()
      end

    quote do
      unquote(head)
      unquote(out)
    end
  end

  defmacro state(name, opts \\ []) when is_atom(name) do
    quote do
      unless Module.get_attribute(__MODULE__, :in_defmachine) do
        raise CompileError, [file: __ENV__.file, line: __ENV__.line, description: "Calling `state` outside of state machine definition"]
      end
      @states %State{
        name: unquote(Macro.escape(name)),
        before_leave: keyword_splat(unquote(opts), :before_leave),
        after_leave:  keyword_splat(unquote(opts), :after_leave),
        before_enter: keyword_splat(unquote(opts), :before_enter),
        after_enter:  keyword_splat(unquote(opts), :after_enter)
      }
    end
  end

  defmacro event(name, opts \\ [], block) when is_atom(name) do
    head =
      quote do
        unless Module.get_attribute(__MODULE__, :in_defmachine) do
          raise CompileError, [file: __ENV__.file, line: __ENV__.line, description: "Calling `event` outside of state machine definition"]
        end

        Module.register_attribute(__MODULE__, :transitions, accumulate: true)
        Module.put_attribute(__MODULE__, :in_event, true)
        unquote(block)
      end

    transitions =
      quote unquote: false do
        transitions = @transitions |> Enum.reverse
        Module.delete_attribute(__MODULE__, :transitions)
        transitions
      end

    out =
      quote do
        Module.delete_attribute(__MODULE__, :in_event)
        @events %Event{
          name: unquote(name),
          transitions: unquote(transitions),
          before: keyword_splat(unquote(opts), :before),
          after:  keyword_splat(unquote(opts), :after),
          guards: Guard.prepare(unquote(opts))
        }
      end

    quote do
      unquote(head)
      unquote(out)
    end
  end

  defmacro transition(opts) do
    quote do
      unless Module.get_attribute(__MODULE__, :in_event) do
        raise CompileError, [file: __ENV__.file, line: __ENV__.line, description: "Calling `transition` outside of `event` block"]
      end

      Enum.each(StateMachine.Utils.keyword_splat(unquote(opts), :from), fn from ->
        @transitions %Transition{
          from: from,
          to:   Keyword.get(unquote(opts), :to),
          before: keyword_splat(unquote(opts), :before),
          after:  keyword_splat(unquote(opts), :after),
          guards: Guard.prepare(unquote(opts))
        }
      end)
    end
  end

  defmacro aux_functions do
    quote do
      def all_states do
        Introspection.all_states(__state_machine__())
      end

      def all_events do
        Introspection.all_events(__state_machine__())
      end

      def allowed_events(model) do
        Context.build(__state_machine__(), model)
        |> Introspection.allowed_events()
      end

      def trigger(model, event, payload \\ nil) do
        Context.build(__state_machine__(), model)
        |> Event.trigger(event, payload)
      end
    end
  end
end
