# This Postfix configuration file is maintained by Server Farmer.

myhostname = %%host%%
myorigin = %%domain%%
mydestination = %%host%%, localhost.$mydomain, localhost
relayhost = [%%smtp%%]:587
mynetworks = 127.0.0.1, 192.168.0.0/16, 172.16.0.0/12, 10.0.0.0/8

inet_interfaces = all
inet_protocols = ipv4
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
recipient_delimiter = +

smtp_generic_maps        = hash:/etc/postfix/sender_address_rewriting
sender_bcc_maps          = hash:/etc/postfix/sender_bcc_notifications
sender_canonical_maps    = hash:/etc/postfix/sender_canonical
recipient_bcc_maps       = hash:/etc/postfix/recipient_bcc_notifications
recipient_canonical_maps = hash:/etc/postfix/recipient_canonical
virtual_alias_maps       = hash:/etc/postfix/virtual_aliases
transport_maps           = hash:/etc/postfix/transport

biff = no
readme_directory = no
append_dot_mydomain = no
mailbox_size_limit = 0

smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl/passwd
smtp_sasl_security_options = noanonymous

smtpd_banner = $myhostname ESMTP
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, defer_unauth_destination
