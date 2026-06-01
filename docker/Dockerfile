FROM ghcr.io/hansvaneijsden/php-wordpress-base:latest

# OPcache status endpoint voor Munin monitoring
RUN echo '<?php echo json_encode(opcache_get_status(false)); ?>' > /tmp/opcache-status.php

# Optional: zorg dat het bestand readable is voor FPM
RUN chmod 644 /tmp/opcache-status.php