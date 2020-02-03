#!/bin/sh
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.install
. /opt/farm/scripts/functions.dialog


do_postmap() {
	echo "setting up $2"
	touch $1
	postmap $1
}


if [ "$SMTP" != "true" ]; then
	echo "install sf-mta-forwarder extension instead of sf-mta-relay"
	exit 0
fi

DOMAIN=`/opt/farm/config/get-external-domain.sh`

common=/opt/farm/ext/mta-relay/templates
base=$common/$OSVER

if [ -f $base/postfix.tpl ]; then
	/opt/farm/ext/packages/utils/install.sh postfix libsasl2-modules bsd-mailx

	oldmd5=`md5sum /etc/postfix/main.cf`
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
	newmd5=`md5sum /etc/postfix/main.cf`

	echo "setting up mail aliases"
	SHORT="${HOST%%.*}"
	cat $common/aliases-$OSTYPE.tpl |sed -e s/%%host%%/$SHORT/g -e s/%%domain%%/$DOMAIN/g >/etc/aliases
	newaliases

	do_postmap /etc/postfix/transport "transport maps"
	do_postmap /etc/postfix/virtual_aliases "virtual aliasing"
	do_postmap /etc/postfix/sender_address_rewriting "sender address rewriting"
	do_postmap /etc/postfix/sender_canonical "sender canonical maps"
	do_postmap /etc/postfix/sender_bcc_notifications "sender bcc notifications"
	do_postmap /etc/postfix/recipient_canonical "recipient canonical maps"
	do_postmap /etc/postfix/recipient_bcc_notifications "recipient bcc notifications"

	if [ "$oldmd5" != "$newmd5" ]; then
		service postfix restart
	else
		echo "skipping postfix restart, configuration has not changed"
	fi
fi
