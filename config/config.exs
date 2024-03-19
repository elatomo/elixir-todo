# General application configuration
import Config

# Default Bandit port
config :todo, http_port: 4040

# Import environment specific config. This must remain at the bottom of this
# file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
