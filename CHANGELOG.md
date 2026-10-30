# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.10] - 2026-10-30

### Fixed

- Ecto transitions persist with `Repo.update_all`, matching the primary key and the previous state. If another transition has already moved the row, this one fails with `{:set_state, :stale}` instead of writing over it.
- Schemas that define `updated_at` get that timestamp refreshed in the same update.
- `StateMachine.Utils.normalize_function/2` was misspelled on its fallback clause, so an invalid callback raised `FunctionClauseError` instead of `ArgumentError` (#8).

## [0.1.9] - 2025-11-24

### Changed

- Definition checks run in `@before_compile`. A missing `defmachine`, or an invalid definition, fails while the module is compiling.

## [0.1.8] - 2025-06-27

### Added

- Events accept `:passthrough`. When no transition matches the current state and passes its guards, the event stays in the current state instead of failing (#7).

## [0.1.7] - 2025-06-02

### Added

- Generated Ecto enums expose `values/0` and a `@type t` covering their atoms.

### Changed

- `cast/1`, `load/1`, and `dump/1` on generated enums are compiled per value. `load/1` returns `:error` for an unknown value.
- State and event Ecto types are generated only when the machine defines states or events.

## [0.1.6] - 2021-10-30

### Changed

- Ecto enum modules are built through `StateMachine.Ecto.define_enum/1`.

## [0.1.5] - 2021-10-15

### Added

- An Ecto type for events (`event_type`, default `EventType`), alongside the state type.
- `@type state` and `@type event` on the machine module.

### Changed

- `ecto_type` is no longer accepted. Use `state_type` and `event_type`. Passing `ecto_type` is a compile error.

## [0.1.4] - 2020-09-15

### Changed

- Requires Elixir `~> 1.10`.
- A generated `:gen_statem` keeps the model as its state data and answers calls with the result of `trigger/3`.
- A transition that stays in the same state no longer runs the event callbacks (#2).
- Callback results are matched by arity. Only a 2-arity callback may replace the whole context. `{:error, reason}` from any callback fails the transition.

### Fixed

- A missing event or transition fails the context with an error tuple instead of raising.

## [0.1.3] - 2020-08-29

### Changed

- Removed the Monex dependency. Callbacks return `{:ok, model}`, `{:ok, context}`, or `{:error, reason}`.

## [0.1.2] - 2020-08-29

### Added

- Introspection helpers: `all_states/1`, `all_events/1`, and `allowed_events/1`.

### Changed

- Context status is `:init`, `:failed`, or `:done`. The earlier `:impossible` and `:rejected` statuses are both `:failed`, and the failure is stored in `error`.

## [0.1.1] - 2020-08-29

### Added

- Passing `repo:` to `defmachine` persists the new state through Ecto and wraps each event in a transaction that rolls back when the transition fails.

## [0.1.0] - 2020-08-05

### Added

- `defmachine` DSL for states, events, transitions, guards, and callbacks, checked when the module compiles.
- Optional `:gen_statem` process generated from the same definition.
- Generated `Ecto.Type` for the state field, casting atoms to and from strings.

[Unreleased]: https://github.com/youroff/state_machine/compare/9e54fbe...HEAD
[0.1.10]: https://github.com/youroff/state_machine/compare/1e1e66d...9e54fbe
[0.1.9]: https://github.com/youroff/state_machine/compare/682cd55...1e1e66d
[0.1.8]: https://github.com/youroff/state_machine/compare/812bfa8...682cd55
[0.1.7]: https://github.com/youroff/state_machine/compare/acc78ee...812bfa8
[0.1.6]: https://github.com/youroff/state_machine/compare/4768e53...acc78ee
[0.1.5]: https://github.com/youroff/state_machine/compare/4f741ad...4768e53
[0.1.4]: https://github.com/youroff/state_machine/compare/b0f1a77...4f741ad
[0.1.3]: https://github.com/youroff/state_machine/compare/d04b372...b0f1a77
[0.1.2]: https://github.com/youroff/state_machine/compare/4fe38fd...d04b372
[0.1.1]: https://github.com/youroff/state_machine/compare/72e3333...4fe38fd
[0.1.0]: https://github.com/youroff/state_machine/commit/72e3333
