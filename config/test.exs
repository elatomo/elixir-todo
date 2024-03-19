import Config

# Print only warnings and errors during test
config :logger, level: :warning

# Run on a different port than the default to prevent clashes
config :todo, http_port: 4041
