.PHONY: help
help:  ## Show help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: autoformat
autoformat:  ## Autoformats code
	mix format

.PHONY: test
test:  ## Run the tests
	mix test

.PHONY: clean
clean:  ## Remove all build artifacts
	mix clean
