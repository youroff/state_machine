defmodule TestApp.Migration do
  use Ecto.Migration

  def change do
    create table(:cats) do
      add :name, :string
      add :state, :string
      add :hungry, :boolean
    end
  end
end
