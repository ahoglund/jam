use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bad_mamma_jamma, BadMammaJamma.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :bad_mamma_jamma, BadMammaJamma.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "bad_mamma_jamma_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
