# This file is for you! Edit it to implement your own hooks (make targets) into
# the project as automated steps to be executed on locally and in the CD pipeline.

include scripts/init.mk

# ==============================================================================

# Example CI/CD targets are: dependencies, build, publish, deploy, clean, etc.

dependencies: # Install dependencies needed to build and test the project @Pipeline
	# TODO: Implement installation of your project dependencies

build: # Build the project artefact @Pipeline
	# TODO: Implement the artefact build step

publish: # Publish the project artefact @Pipeline
	# TODO: Implement the artefact publishing step

deploy: # Deploy the project artefact to the target environment @Pipeline
	# TODO: Implement the artefact deployment step

clean:: # Clean-up project resources (main) @Operations
	# TODO: Implement project resources clean-up step

config:: # Configure development environment (main) @Configuration
	# Install tools from .tool-versions and mise.toml
	mise install
	# Install git hooks
	pre-commit install --install-hooks --hook-type commit-msg

test-validations: test-commit-validator test-workflow-pinning # Run validation tests for new features @Testing

test-commit-validator: # Test conventional commit validator implementation @Testing
	bash tests/test-conventional-commit.sh

test-workflow-pinning: # Test workflow security pinning (immutable refs) @Testing
	bash tests/test-workflow-security.sh

# ==============================================================================

${VERBOSE}.SILENT: \
	build \
	clean \
	config \
	dependencies \
	deploy \
	test-validations \
	test-commit-validator \
	test-workflow-pinning
