.PHONY: install uninstall update test clean

PREFIX := /usr/local/src/munin-php-opcache

install:
	sudo ./install.sh

uninstall:
	sudo ./uninstall.sh

update:
	git pull origin main
	sudo ./install.sh

test:
	@echo "Testing plugin..."
	@for container in $$(docker ps --format "{{.Names}}" | grep -E 'php$$'); do \
		echo "=== Testing $$container ==="; \
		sudo munin-run php_opcache_$$container config | head -5; \
		sudo munin-run php_opcache_$$container | head -5; \
		echo ""; \
	done

clean:
	git clean -fdX