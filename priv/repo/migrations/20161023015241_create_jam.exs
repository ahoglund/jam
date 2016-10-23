defmodule BadMammaJamma.Repo.Migrations.CreateJam do
  use Ecto.Migration

  def change do
    create table(:jams) do

      timestamps
    end

  end
end
