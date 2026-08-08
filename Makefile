.PHONY: install uninstall update test clean

PREFIX := /usr/local/src/munin-php-opcache

install:
	sudo bash install.sh

uninstall:
	sudo bash uninstall.sh

update:
	git pull origin main
	sudo bash install.sh

test:
	@echo "Testing opcache multi plugin..."
	@sudo munin-run php_opcache_multi config | head -15
	@sudo munin-run php_opcache_multi | head -15

clean:
	git clean -fdX