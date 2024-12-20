FILENAME := $(shell jq -r '.name +"_"+ .version' ./info.json)
ifeq ($(OS), Windows_NT)
	APPDATA := $(shell /mnt/c/Windows/System32/cmd.exe /C "echo %APPDATA%" | sed -e "s/\\\/\//g" -e "s/^./\L&/" -e "s/://g" -e "s/^/\/mnt\//")
	LOCATION := "$(APPDATA)/Factorio/mods/$(FILENAME)"
else
	LOCATION = ${HOME}/Library/Application\ Support/factorio/mods/$(FILENAME)
endif
.PHONY: build copy

build:
	@rm entrenched-enemies_* || true
	@rm -r build || true
	@mkdir -p build && mkdir -p ../$(FILENAME) && cp -r ./ ../$(FILENAME)/ && rm -rf ../$(FILENAME)/.git ../$(FILENAME)/makefile ../$(FILENAME)/build && mv ../$(FILENAME) ./build/$(FILENAME)
	@cd build && zip -r ../$(FILENAME).zip ./ && cd ../ && rm -rf build

copy:
	rm -rf $(LOCATION) && mkdir -p $(LOCATION) && cp -r ./* $(LOCATION)
#	cp $(FILENAME).zip "$(APPDATA)/Factorio/mods/$(FILENAME).zip"
#	rm -rf $(FILENAME).zip

run: build copy

wsl-setup:
	apt get jq zip make
