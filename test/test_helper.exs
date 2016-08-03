ExUnit.start

Mix.Task.run "ecto.create", ~w(-r BadMammaJamma.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r BadMammaJamma.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(BadMammaJamma.Repo)

