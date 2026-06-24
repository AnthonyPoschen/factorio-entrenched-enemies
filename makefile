MOD_NAME := $(shell jq -r '.name' ./info.json)
VERSION := $(shell jq -r '.version' ./info.json)
FILENAME := $(MOD_NAME)_$(VERSION)
UNAME_S := $(shell uname -s 2>/dev/null || echo Unknown)

ifeq ($(OS), Windows_NT)
	FACTORIO_MODS_DIR ?= $(shell cygpath -u "$$APPDATA" 2>/dev/null || printf '%s\n' "$$APPDATA")/Factorio/mods
else ifeq ($(UNAME_S), Darwin)
	FACTORIO_MODS_DIR ?= $(HOME)/Library/Application Support/factorio/mods
else
	FACTORIO_MODS_DIR ?= $(HOME)/.factorio/mods
endif

LOCATION := $(FACTORIO_MODS_DIR)/$(FILENAME)

.PHONY: build copy print-location run

build:
	@rm -f -- "$(MOD_NAME)"_*.zip
	@rm -r build || true
	@mkdir -p build && mkdir -p ../$(FILENAME) && cp -r ./ ../$(FILENAME)/ && rm -rf ../$(FILENAME)/.git ../$(FILENAME)/makefile ../$(FILENAME)/build && mv ../$(FILENAME) ./build/$(FILENAME)
	@cd build && zip -r ../$(FILENAME).zip ./ && cd ../ && rm -rf build

copy:
	rm -rf "$(LOCATION)" && mkdir -p "$(LOCATION)" && cp -r ./* "$(LOCATION)"
#	cp $(FILENAME).zip "$(APPDATA)/Factorio/mods/$(FILENAME).zip"
#	rm -rf $(FILENAME).zip

print-location:
	@echo "$(LOCATION)"

run: build copy
