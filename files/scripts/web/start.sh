#!/bin/bash
rm -r /etc/apache2/sites-enabled/*
chown -Rf www-data.www-data /var/www/html/

    if [ ! -s /etc/apache2/certs/intermediate.crt ];

then
	ln -s /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled
fi







































apache2ctl -DFOREGROUND
