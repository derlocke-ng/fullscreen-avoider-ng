# Fullscreen Avoider NG — for working on it from a checkout. kiwi uses
# install.sh; extensions.gnome.org gets the zip from `make pack`.
UUID=fullscreen-avoider-ng@kiwi-network.eu
SCHEMA=schemas/org.gnome.shell.extensions.fullscreen-avoider-ng.gschema.xml
BUILDDIR=build

.PHONY: pack install uninstall test clean

# the zip to upload to extensions.gnome.org: build/$(UUID).shell-extension.zip
pack:
	mkdir -p $(BUILDDIR)
	gnome-extensions pack src --force --out-dir=$(BUILDDIR) --schema=$(SCHEMA)

install:
	./install.sh install

uninstall:
	./install.sh uninstall

test:
	bash tests/check-version.sh
	bash tests/lint.sh
	bash tests/install.sh

clean:
	rm -rf $(BUILDDIR)
