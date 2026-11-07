defmodule StateMachine.TransitionLawsTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Lynx.Case

  alias StateMachine.Transition

  laws "transition" do
    law loop_when_same(state),
      expects: Transition.loop?(%{from: state, to: state}) == true,
      proof: ~LEAN"""
      have keys :
          Lynx.Term.getMapKeys [Lynx.Term.atom "from", Lynx.Term.atom "to"]
            (Lynx.Term.map [(Lynx.Term.atom "to", state), (Lynx.Term.atom "from", state)]) =
            [state, state] := by
        simp [Lynx.Term.getMapKeys, List.mapM_cons, List.mapM_nil, List.find?_cons, List.find?_nil,
          Lynx.Term.exactCompare_atoms, Lynx.Term.exactCompare_self]
      simp [«loop_when_same:ensures/1», Elixir.StateMachine.Transition.«loop?/1»,
        Erlang.erlang.«==/2», Erlang.erlang.«=:=/2», keys, Lynx.Term.exactCompare_self,
        Lynx.Term.compare_self, Lynx.Except.tryWith_ok]
      """

    law loop_when_different(source, target),
      requires: source !== target,
      expects: Transition.loop?(%{from: source, to: target}) == false,
      proof: ~LEAN"""
      have distinct : Lynx.Term.exactCompare target source ≠ .eq := by
        simp [«loop_when_different:requires/2», Erlang.erlang.«=/=/2»] at requires
        by_cases h : Lynx.Term.exactCompare source target = .eq
        · simp [h] at requires
        · intro same
          have swap :=
            Std.OrientedCmp.eq_swap (cmp := Lynx.Term.exactCompare) (a := target) (b := source)
          exact h (Ordering.swap_eq_eq.mp (by simpa [same] using swap.symm))
      have keys :
          Lynx.Term.getMapKeys [Lynx.Term.atom "from", Lynx.Term.atom "to"]
            (Lynx.Term.map [(Lynx.Term.atom "to", target), (Lynx.Term.atom "from", source)]) =
            [source, target] := by
        simp [Lynx.Term.getMapKeys, List.mapM_cons, List.mapM_nil, List.find?_cons, List.find?_nil,
          Lynx.Term.exactCompare_atoms, Lynx.Term.exactCompare_self]
      simp [«loop_when_different:ensures/2», Elixir.StateMachine.Transition.«loop?/1»,
        Erlang.erlang.«==/2», Erlang.erlang.«=:=/2», keys, distinct, Lynx.Term.compare_self,
        Lynx.Except.tryWith_ok]
      """

    law finalize_keeps_done(payload),
      expects:
        Transition.finalize(%{status: :done, payload: payload}) ==
          %{status: :done, payload: payload},
      proof: ~LEAN"""
      have keys :
          Lynx.Term.getMapKeys [Lynx.Term.atom "status"]
            (Lynx.Term.map
              [(Lynx.Term.atom "payload", payload), (Lynx.Term.atom "status", Lynx.Term.atom "done")]) =
            [Lynx.Term.atom "done"] := by
        simp [Lynx.Term.getMapKeys, List.mapM_cons, List.mapM_nil, List.find?_cons, List.find?_nil,
          Lynx.Term.exactCompare_atoms, Lynx.Term.exactCompare_self]
      simp [«finalize_keeps_done:ensures/1», Elixir.StateMachine.Transition.«finalize/1»,
        Erlang.erlang.«==/2», keys, Lynx.Term.compare_self]
      """

    law finalize_from_init(payload),
      expects:
        Transition.finalize(%{status: :init, payload: payload}) ==
          %{status: :done, payload: payload},
      proof: ~LEAN"""
      let input :=
        Lynx.Term.map
          [(Lynx.Term.atom "payload", payload), (Lynx.Term.atom "status", Lynx.Term.atom "init")]
      let updated :=
        Lynx.Term.map [
          (Lynx.Term.atom "status", Lynx.Term.atom "done"),
          (Lynx.Term.atom "payload", payload),
          (Lynx.Term.atom "status", Lynx.Term.atom "init")]
      let done :=
        Lynx.Term.map
          [(Lynx.Term.atom "payload", payload), (Lynx.Term.atom "status", Lynx.Term.atom "done")]
      have finished : Elixir.StateMachine.Transition.«finalize/1» input = .ok updated := by
        simp [input, updated, Elixir.StateMachine.Transition.«finalize/1», Lynx.Term.getMapKeys,
          List.mapM_cons, List.mapM_nil, List.find?_cons, List.find?_nil,
          Lynx.Term.exactCompare_atoms, Lynx.Term.exactCompare_self, Erlang.erlang.«is_map/1»,
          Erlang.maps.«update/3», Lynx.Except.tryWith_ok]
      have same : Lynx.Term.compare updated done = .eq := by
        apply Erlang.maps.compare_eq_of_get
        intro key
        by_cases statusKey : Lynx.Term.exactCompare key (Lynx.Term.atom "status") = .eq
        · have key_status : key = Lynx.Term.atom "status" :=
            (Lynx.Term.exactCompare_eq_atom key "status").mp statusKey
          subst key_status
          simp [updated, done, Erlang.maps.«get/2», List.find?_cons, List.find?_nil,
            Lynx.Term.exactCompare_atoms, Lynx.Term.exactCompare_self]
        · by_cases payloadKey : Lynx.Term.exactCompare key (Lynx.Term.atom "payload") = .eq
          · have key_payload : key = Lynx.Term.atom "payload" :=
              (Lynx.Term.exactCompare_eq_atom key "payload").mp payloadKey
            subst key_payload
            simp [updated, done, Erlang.maps.«get/2», List.find?_cons, List.find?_nil,
              Lynx.Term.exactCompare_atoms, Lynx.Term.exactCompare_self]
          · simp [updated, done, Erlang.maps.«get/2», List.find?_cons, List.find?_nil,
              decide_eq_false statusKey, decide_eq_false payloadKey]
      simp [«finalize_from_init:ensures/1», input, done, finished, same, Erlang.erlang.«==/2»]
      """
  end
end
