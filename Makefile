check_uncommitted:
	@if git diff-index --quiet HEAD --; then \
		echo '\033[32mNo uncommitted changes found.\033[0m'; \
	else \
		echo '\033[31mUncommitted changes detected. Aborting.\033[0m'; \
		exit 1; \
	fi

# merge the current branch to main and push
merge_main: check_uncommitted
	# get the name of the current branch
	$(eval BRANCH := $(shell git branch --show-current))
	# merge the current branch to main
	git checkout main
	git merge $(BRANCH)
	git push

# Run the formatters manually
# Define a variable for swift-format options
SWIFT_FORMAT_OPTIONS = -i -p --ignore-unparsable-files --configuration .swift-format
# Define a variable for target directories. This makes it easy to add more directories later if needed
SWIFT_FORMAT_TARGETS = ./Sources ./Tests
# Placeholders to be replaced by the setup script:
# - ElevenLabs
# - ElevenLabsUrlSessionClient
# - ElevenLabsTypes
format: check_uncommitted
	# find can take multiple starting directories
	# xargs -r (or --no-run-if-empty for GNU xargs) ensures swift-format isn't run if no files are found
	find $(SWIFT_FORMAT_TARGETS) -name "*.swift" -not -path "*/GeneratedSources/*" | xargs -r swift-format $(SWIFT_FORMAT_OPTIONS)
	git add .
	# git commit -m "Format code"

test-on-linux:
	docker run -v "$PWD:/code" -w /code swift:latest swift test

DOWNLOAD_OPENAPI_URL=https://api.elevenlabs.io/openapi.json
download-openapi:
	# Download the openapi.json file from remote repo as original.json file
	curl -o original.json $(DOWNLOAD_OPENAPI_URL)
	# Create a copy of original.json as openapi.json
	cp original.json openapi.json
	# Replace 9223372036854776000 with 922337203685477600 
	sed -i '' 's/9223372036854776000/922337203685477600/g' ./openapi.json

overlay-openapi:
	openapi-format --no-sort ./openapi.json --overlayFile overlay.json -o ./openapi.json
	openapi-format --no-sort ./openapi.json --overlayFile overlay_generated.json -o ./openapi.json

generate-openapi:
	swift run swift-openapi-generator generate \
	  --output-directory Sources/ElevenLabsTypes/GeneratedSources \
	  --config ./openapi-generator-config-types.yaml \
	  ./openapi.json

	swift run swift-openapi-generator generate \
	  --output-directory Sources/ElevenLabs/GeneratedSources \
	  --config ./openapi-generator-config-client.yaml \
	  ./openapi.json

	swift run swift-openapi-generator generate \
	  --output-directory Sources/ElevenLabsUrlSessionClient/GeneratedSources \
	  --config ./openapi-generator-config-client.yaml \
	  ./openapi.json

prepare-openapi:
	make download-openapi
	make overlay-openapi
	make generate-openapi
