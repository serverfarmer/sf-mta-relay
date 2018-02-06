#!/bin/bash
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.custom
. /opt/farm/scripts/functions.install
. /opt/farm/scripts/functions.dialog


if [ "$SMTP" != "true" ]; then
	echo "install sf-mta-forwarder extension instead of sf-mta-relay"
	exit 0
fi

DOMAIN=`external_domain`

common=/opt/farm/ext/mta-relay/templates
base=$common/$OSVER

if [ -f $base/postfix.tpl ]; then
	/opt/farm/ext/repos/package/install.sh postfix
	/opt/farm/ext/repos/package/install.sh libsasl2-modules
	/opt/farm/ext/repos/package/install.sh bsd-mailx
	save_original_config /etc/postfix/main.cf

	map="/etc/postfix/sasl/passwd"
	if [ ! -f $map.db ]; then
		if [ "$SMTP_RELAY" = "" ]; then
			SMTP_RELAY="`input \"enter external smtp relay hostname\" smtp.gmail.com`"
			echo -n "[$SMTP_RELAY] enter login: "
			read SMTP_USERNAME
			echo -n "[$SMTP_RELAY] enter password for $SMTP_USERNAME: "
			stty -echo
			read SMTP_PASSWORD
			stty echo
			echo ""  # force a carriage return to be output
		fi
		echo "$SMTP_RELAY  $SMTP_USERNAME:$SMTP_PASSWORD" >$map
		chmod 0600 $map
		postmap $map
	fi

	echo "setting up postfix"
	relay="`cat $map |grep -v ^# |head -n 1 |cut -f 1 -d' '`"
	cat $base/postfix.tpl |sed -e s/%%host%%/$HOST/g -e s/%%domain%%/$DOMAIN/g -e s/%%smtp%%/$relay/g >/etc/postfix/main.cf

	echo "setting up mail aliases"
	SHORT="${HOST%%.*}"
	cat $common/aliases-$OSTYPE.tpl |sed -e s/%%host%%/$SHORT/g -e s/%%domain%%/$DOMAIN/g >/etc/aliases
	newaliases

	echo "setting up transport maps"
	touch /etc/postfix/transport
	postmap /etc/postfix/transport

	echo "setting up virtual aliasing"
	touch /etc/postfix/virtual_aliases
	postmap /etc/postfix/virtual_aliases

	echo "setting up sender address rewriting"
	touch /etc/postfix/sender_address_rewriting
	postmap /etc/postfix/sender_address_rewriting

	echo "setting up sender canonical maps"
	touch /etc/postfix/sender_canonical
	postmap /etc/postfix/sender_canonical

	echo "setting up sender bcc notifications"
	touch /etc/postfix/sender_bcc_notifications
	postmap /etc/postfix/sender_bcc_notifications

	echo "setting up recipient canonical maps"
	touch /etc/postfix/recipient_canonical
	postmap /etc/postfix/recipient_canonical

	echo "setting up recipient bcc notifications"
	touch /etc/postfix/recipient_bcc_notifications
	postmap /etc/postfix/recipient_bcc_notifications

	service postfix restart
fi
