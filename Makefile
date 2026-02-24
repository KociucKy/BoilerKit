BINARY_NAME = boilerkit
INSTALL_PATH = /usr/local/bin/$(BINARY_NAME)

.PHONY: install uninstall

install:
	swift build -c release
	sudo cp .build/release/$(BINARY_NAME) $(INSTALL_PATH)
	@echo "Installed $(BINARY_NAME) to $(INSTALL_PATH)"

uninstall:
	rm -f $(INSTALL_PATH)
	@echo "Removed $(BINARY_NAME) from $(INSTALL_PATH)"
