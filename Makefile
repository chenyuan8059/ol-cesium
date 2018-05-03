SRC_JS_FILES := $(shell find src -type f -name '*.js')
EXAMPLES_JS_FILES := $(shell find examples -type f -name '*.js')
EXAMPLES_FILES := $(shell find examples -type f)
EXAMPLES_GEOJSON_FILES := $(shell find examples/data/ -name '*.geojson')
WEBPACK_CONFIG_FILES := $(shell ls buildtools/webpack.*.js) webpack.config.js

.PHONY: all
all: help

.PHONY: help
help:
	@echo "Usage: make <target>"
	@echo
	@echo "Main targets:"
	@echo
	@echo "- dist                    Create a "distribution" for the library (dist/olcesium.js)"
	@echo "- check                   Perform a number of checks on the code (lint, compile, etc.)"
	@echo "- lint                    Check the code with the linter"
	@echo "- serve                   Run a development web server for running the examples"
	@echo "- clean                   Remove generated files"
	@echo "- cleanall                Remove all the build artefacts"
	@echo "- help                    Display this help message"
	@echo

.PHONY: serve
serve: .build/node_modules.timestamp
	npm run serve

.PHONY: dist
dist: dist/olcesium.js css/olcs.css CHANGES.md .build/jsdoc.timestamp .build/dist-examples.timestamp
	cp CHANGES.md css/olcs.css dist/

.PHONY: dist-examples
dist-examples: .build/dist-examples.timestamp

.PHONY: dist-apidoc
dist-apidoc: .build/jsdoc.timestamp

.build/jsdoc.timestamp: $(SRC_JS_FILES) .build/node_modules.timestamp
	mkdir -p dist
	node node_modules/.bin/jsdoc src/olcs -d dist/apidoc
	mkdir -p $(dir $@)
	touch $@

.PHONY: lint
lint: .build/node_modules.timestamp .build/eslint.timestamp

.build/geojsonhint.timestamp: $(EXAMPLES_GEOJSON_FILES)
	$(foreach file,$?, echo $(file); node_modules/.bin/geojsonhint $(file);)
	mkdir -p $(dir $@)
	touch $@

.PHONY: check
check: lint dist

.PHONY: clean
clean:
	rm -f dist/olcesium.js
	rm -rf dist/ol
	rm -rf dist/examples
	rm -rf dist/Cesium

.PHONY: cleanall
cleanall: clean
	rm -rf .build
	rm -rf node_modules

.build/node_modules.timestamp: package.json
	npm install
	mkdir -p $(dir $@)
	touch $@

.build/eslint.timestamp: $(SRC_JS_FILES) $(EXAMPLES_JS_FILES) .build/node_modules.timestamp
	./node_modules/.bin/eslint $^
	touch $@

CS_BUILD="node_modules/@camptocamp/cesium/Build"
.build/dist-examples.timestamp: $(EXAMPLES_FILES) $(WEBPACK_CONFIG_FILES) .build/node_modules.timestamp
	mkdir -p dist/examples
	npm run build-examples
	cp -f examples/inject_ol_cesium.js dist/examples/
	mkdir -p dist/$(CS_BUILD) ; rm -rf dist/$(CS_BUILD)/* ; cp -Rf $(CS_BUILD)/Cesium* dist/$(CS_BUILD)/
	touch $@

dist/olcesium.js: $(SRC_JS_FILES) $(WEBPACK_CONFIG_FILES) .build/node_modules.timestamp
	mkdir -p $(dir $@)
	npm run build-library
