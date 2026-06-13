#!/bin/sh
# ref: email-catchall/files/build.d/setup-catchall.sh
set -e

require-installed mail-mta/postfix
require-installed net-mail/dovecot

# postfix
echo '/.*@.*/ mail' > /etc/postfix/virtual
echo "virtual_alias_maps = pcre:/etc/postfix/virtual" >> /etc/postfix/main.cf
postmap /etc/postfix/virtual
echo '// .' > /etc/postfix/any_destination
echo "mydestination = pcre:/etc/postfix/any_destination" >> /etc/postfix/main.cf
postmap /etc/postfix/any_destination
sed -i 's/^inet_protocols = .*/inet_protocols = all/' /etc/postfix/main.cf
sed -i 's/^mail:\(.*\)/#mail:\1/' /etc/mail/aliases
newaliases

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
