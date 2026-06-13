#!/bin/sh
# ref: email-catchall/files/build.d/setup-catchall.sh
set -e

require-installed mail-mta/postfix
require-installed net-mail/dovecot

# postfix (Postfix 3.7+ inline PCRE、postmap不要)
postconf -e 'virtual_alias_maps = pcre:{ { /.*@.*/ mail } }'
postconf -e 'virtual_alias_domains ='
postconf -e 'mydestination = static:anything'
postconf -e 'local_recipient_maps = static:anything'
postconf -e 'inet_protocols = all'
postconf -e 'myhostname = localhost'
sed -i 's/^mail:\(.*\)/#mail:\1/' /etc/mail/aliases

# dovecot
sed -i 's/^mail_home =\(.*\)/#mail_home =\1/' /etc/dovecot/dovecot.conf
sed -i 's/^mail_driver =.*/mail_driver = maildir/' /etc/dovecot/dovecot.conf
sed -i 's/^mail_path =.*/mail_path = ~\/.maildir/' /etc/dovecot/dovecot.conf
sed -i 's/^#first_valid_uid =.*/first_valid_uid = 0/' /etc/dovecot/dovecot.conf
sed -i 's/^  cert_file =\(.*\)/# cert_file =\1/' /etc/dovecot/dovecot.conf
sed -i 's/^  key_file =\(.*\)/# key_file =\1/' /etc/dovecot/dovecot.conf
echo 'auth_allow_cleartext = yes' >> /etc/dovecot/dovecot.conf
cat << 'EOS' > /etc/dovecot/conf.d/auth-catchall.conf
passdb static {
  fields {
    nopassword = yes
  }
}

userdb static {
  fields {
    uid = mail
    gid = mail
    home = /var/spool/mail
  }
}
EOS
