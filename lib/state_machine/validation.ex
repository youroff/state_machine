defmodule StateMachine.Validation do
  alias StateMachine.Introspection
  import MonEx.Result

  def __after_compile__(env, _) do
    with errors when errors != [] <- validate_all(apply(env.module, :__state_machine__, [])) do
      raise CompileError, [file: env.file, description: Enum.join(errors, "\n")]
    end
  end

  def validate_all(sm) do
    collect_error([
      validate_states_in_transitions(sm),
      validate_transitions_determinism(sm)
    ])
    |> List.flatten()
  end

  def validate_states_in_transitions(sm) do
    states = Introspection.all_states(sm)
    errors = Enum.reduce(sm.events, [], fn {event_name, event}, acc1 ->
      Enum.reduce(event.transitions, acc1, fn transition, acc2 ->
        Map.take(transition, [:to, :from])
        |> Map.values()
        |> Enum.reduce(acc2, fn state, acc3 ->
          unless state in states do
            ["Undefined state '#{state}' is used in transition on '#{event_name}' event." | acc3]
          else
            acc3
          end
        end)
      end)
    end)

    if Enum.empty? errors do
      ok(sm)
    else
      error(Enum.reverse(errors))
    end
  end

  def validate_transitions_determinism(sm) do
    errors = Enum.reduce(sm.events, [], fn {event_name, event}, acc1 ->
      Enum.reduce(event.transitions, {[], acc1}, fn transition, {ts, acc2} ->
        cond do
          transition.from in ts ->
            {ts, ["Event '#{event_name}' already has an unguarded transition from '#{transition.from}'; additional transition to '#{transition.to}' will never run." | acc2]}
          Enum.empty?(transition.guards) ->
            {[transition.from | ts], acc2}
          true ->
            {ts, acc2}
        end
      end) |> elem(1)
    end)

    if Enum.empty? errors do
      ok(sm)
    else
      error(Enum.reverse(errors))
    end
  end
end
