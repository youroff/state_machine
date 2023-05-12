defmodule StateMachine.DSL do
  @moduledoc """
  These macros help generating State Machine definition in a given Module.
  """

  alias StateMachine.{State, Event, Transition, Context, Guard, Introspection}
  import StateMachine.Utils, only: [keyword_splat: 2]

  @doc """
  Creates a main block for a State Machine definition. Compile time checks and validations help
  ensuring correct usage of this and other macros.

      use StateMachine

      defmachine field: :custom do
        # ... states, events, transitions
      end

  ## Options
    * `:field` - what field in the model structure holds the state value. Default: `:state`.
    * `:repo` - the Ecto Repo module. If provider, the support for Ecto is activated, including
      state getter/setters, Ecto.Type generation and custom `trigger` function.
    * `:state_type` - name for `Ecto.Type` implementation for State type. Generated inside of the module namespace.
      If you state machine is `App.StateMachine`, then `Ecto.Type` implementation will be
      accessible on `App.StateMachine.(state_type)`. Default: `StateType`.
    * `:event_type` - name for `Ecto.Type` implementation for Event type. Default: `EventType`.
  """
  defmacro defmachine(opts \\ [], block) do
    head =
      quote do
        if Keyword.has_key?(unquote(opts), :ecto_type) do
          raise CompileError, [
            file: __ENV__.file,
            line: __ENV__.line,
            description: "Option `ecto_type` is deprecated, use `state_type` and `event_type` to generate EctoType implementations respectively"
          ]
        end

        @after_compile StateMachine.Validation
        Module.register_attribute(__MODULE__, :states, accumulate: true)
        Module.register_attribute(__MODULE__, :events, accumulate: true)
        Module.put_attribute(__MODULE__, :in_defmachine, true)
        Module.put_attribute(__MODULE__, :field, Keyword.get(unquote(opts), :field, :state))
        Module.put_attribute(__MODULE__, :repo, Keyword.get(unquote(opts), :repo))
        Module.put_attribute(__MODULE__, :state_type, Keyword.get(unquote(opts), :state_type, StateType))
        Module.put_attribute(__MODULE__, :event_type, Keyword.get(unquote(opts), :event_type, EventType))
        unquote(block)
      end

    out =
      quote unquote: false do
        state_names = Enum.map(@states, & &1.name)
        Module.put_attribute(__MODULE__, :state_names, state_names)

        event_names = Enum.map(@events, & &1.name)
        Module.put_attribute(__MODULE__, :event_names, event_names)

        states = @states |> Enum.reverse |> Enum.reduce(%{}, fn state, acc ->
          Map.put(acc, state.name, state)
        end)

        events = @events |> Enum.reverse |> Enum.reduce(%{}, fn event, acc ->
          Map.put(acc, event.name, event)
        end)

        field = @field

        getter = if @repo, do: &StateMachine.Ecto.get/1, else: &State.get/1
        setter = if @repo, do: &StateMachine.Ecto.set/2, else: &State.set/2

        misc = if @repo, do: [repo: @repo], else: []

        Module.delete_attribute(__MODULE__, :states)
        Module.delete_attribute(__MODULE__, :events)
        Module.delete_attribute(__MODULE__, :field)
        Module.delete_attribute(__MODULE__, :in_defmachine)

        def __state_machine__, do: %StateMachine{
          field: unquote(field),
          states: unquote(Macro.escape(states)),
          events: unquote(Macro.escape(events)),
          state_getter: unquote(Macro.escape(getter)),
          state_setter: unquote(Macro.escape(setter)),
          misc: unquote(Macro.escape(misc))
        }

        introspection_functions()
        if @repo do
          require StateMachine.Ecto
          StateMachine.Ecto.define_ecto_type(:state)
          StateMachine.Ecto.define_ecto_type(:event)

          ecto_action_functions()
        else
          action_functions()
        end

        unless Enum.empty?(state_names) do
          @type state :: unquote(Enum.reduce(state_names, &{:|, [], [&1, &2]}))
        end

        unless Enum.empty?(event_names) do
          @type event :: unquote(Enum.reduce(event_names, &{:|, [], [&1, &2]}))
        end

        Module.delete_attribute(__MODULE__, :repo)
        Module.delete_attribute(__MODULE__, :state_type)
        Module.delete_attribute(__MODULE__, :event_type)
        Module.delete_attribute(__MODULE__, :state_names)
        Module.delete_attribute(__MODULE__, :event_names)
      end

    quote do
      unquote(head)
      unquote(out)
    end
  end

  @doc """
  Creates a State record with any atom as a name.
  Supports defining callbacks for before/after leaving/entering given state.
  For detailed description of Callbacks, see the module documentation,
  but currently only fully qualified function capture is supported: `&Module.fun/arity`

      defmachine do
        state :sleeping, after_leave: &Kitchen.brew_coffee/1
        state :working, before_enter: [&Commute.drive/1, &Commute.grab_a_newspaper/1]
      end

  ## Options
    * `:before_leave` - run the callback before leaving this state.
    * `:after_leave` - run the callback after leaving this state.
    * `:before_enter` - run the callback before entering this state.
    * `:after_enter` - run the callback after entering this state.
  """
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

  @doc """
  Creates an Event record which encapsulates one or more Transitions.
  Conceptually an Event is an external signal to change the state.
  Events can be accompanied by Guards — additional conditions, allowing
  for implementing more complex logic than supported by theoretical
  state machines.

  Using guards allow for transitions from one to the multiple states,
  based on condition.


      defmachine do
        # for state defs, see `state`

        event :wake_up, if: &Bedroom.slept_eight_hours?/1 do
          # for transition defs, see `transition`
        end
      end

  ## Options
    * `:before` - run the callback before the event.
    * `:after` - run the callback after the event.
    * `:if` - positive guard, must return `true` to proceed.
    * `:unless` - negative guard, must return `false` to proceed.
  """
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

  @doc """
  Defines a Transition, a path from one or more states to a single state.
  The same Event can contain all crazy combinations of transitions,
  but the resolution happens from top to bottom, from left to right.
  First matching transition will run.


      defmachine do
        # for state defs, see `state`

        event :wake_up do
          transition from: :sleeping, to: :sleeping,
            if: &Calendar.weekend?/0,
            unless: &Bedroom.slept_ten_hours?/1
          transition from: :sleeping, to: :awake
        end
      end

  ## Options
    * `:before` - run the callback before the transition.
    * `:after` - run the callback after the transition.
    * `:if` - positive guard, must return `true` to proceed.
    * `:unless` - negative guard, must return `false` to proceed.
  """
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

  @doc false
  defmacro introspection_functions do
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

      def trigger_with_context(model, event, payload \\ nil) do
        Context.build(__state_machine__(), model)
        |> Event.trigger(event, payload)
      end
    end
  end

  @doc false
  defmacro action_functions do
    quote do
      def trigger(model, event, payload \\ nil) do
        case trigger_with_context(model, event, payload) do
          {:ok, %Context{status: :done, model: model}} -> {:ok, model}
          {:error, error} -> {:error, error}
        end
      end
    end
  end

  @doc false
  defmacro ecto_action_functions do
    quote do
      def trigger(model, event, payload \\ nil) do
        repo = __state_machine__().misc[:repo]
        repo.transaction fn ->
          case trigger_with_context(model, event, payload) do
            {:ok, %Context{status: :done, model: model}} -> model
            {:error, error} -> repo.rollback(error)
          end
        end
      end
    end
  end

  @doc """
  Experimental macro to generate GenStatem definition. See source...
  """
  defmacro define_gen_statem do
    quote do
      def start_link(model) do
        :gen_statem.start_link(__MODULE__, model, [])
      end

      def trigger_cast(sm_pid, event, payload \\ nil) do
        :gen_statem.cast(sm_pid, {event, payload})
      end

      # TODO: opts?
      def trigger_call(sm_pid, event, payload \\ nil) do
        :gen_statem.call(sm_pid, {event, payload})
      end

      def init(model) do
        context = Context.build(__state_machine__(), model)
        {:ok, context.definition.state_getter.(context), model}
      end

      def handle_event(kind, {event, payload}, state, model) do
        case __MODULE__.trigger(model, event, payload) do
          {:ok, new_model} ->
            context = Context.build(__state_machine__(), new_model)
            new_state = context.definition.state_getter.(context)
            {:next_state, new_state, new_model, actions(kind, {:ok, new_model})}
          {:error, e} ->
            {:next_state, state, model, actions(kind, {:error, e})}
        end
      end

      def callback_mode do
        :handle_event_function
      end

      defp actions(:cast, _) do
        []
      end

      defp actions({:call, from}, resp) do
        [{:reply, from, resp}]
      end
    end
  end
end
