#!/bin/bash

function add_config_value() {
  local key=${1}
  local value=${2}
  [ "${key}" == "" ] && echo "ERROR: No key set !!" && exit 1
  [ "${value}" == "" ] && echo "ERROR: No value set !!" && exit 1

  echo "Set configuration option key=${key} with value=${value}"
  postconf -e "${key} = ${value}"
}

[ -z "${SMTP_SERVER}" ] && echo "SMTP_SERVER is not set" && exit 1
[ ! -z "${SMTP_USERNAME}" -a -z "${SMTP_PASSWORD}" ] && echo "SMTP_USERNAME is set but SMTP_PASSWORD is not set" && exit 1

echo port=$SMTP_PORT
SMTP_PORT="${SMTP_PORT:-587}"

if [ ! -z "${SERVER_HOSTNAME}" ]; then
  DOMAIN=`echo ${SERVER_HOSTNAME} | awk 'BEGIN{FS=OFS="."}{print $(NF-1),$NF}'`
  add_config_value "myhostname" ${SERVER_HOSTNAME}
  add_config_value "mydomain" ${DOMAIN}
fi
add_config_value "mydestination" "${DESTINATION:-localhost}"

# Set necessary config options
add_config_value "relayhost" "[${SMTP_SERVER}]:${SMTP_PORT}"
#add_config_value "smtp_use_tls" "yes"
if [ ! -z "${SMTP_USERNAME}" ]; then
  add_config_value "smtp_sasl_auth_enable" "yes"
  add_config_value "smtp_sasl_security_options" "noanonymous"
  add_config_value "smtp_sasl_password_maps" "hash:/etc/postfix/sasl_passwd"
fi

if [ "${SMTP_PORT}" = "465" ]; then
  add_config_value "smtp_tls_wrappermode" "yes"
  add_config_value "smtp_tls_security_level" "encrypt"
else
  add_config_value "smtp_tls_security_level" "may"
fi

add_config_value "smtpd_sasl_auth_enable" "yes"

# Bind to both IPv4 and IPv4
add_config_value "inet_protocols" "all"

# Add gateway IP
echo adding mynetworks ${POSTFIX_SUBNET_PREFIX}.1 
add_config_value "mynetworks" "${POSTFIX_SUBNET_PREFIX}.0/24 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"

echo "setting password for $SMTP_USERNAME ..."
pass_file=/etc/postfix/sasl_passwd
if [ ! -f $pass_file -a ! -z "${SMTP_USERNAME}" ]; then
  grep -q "${SMTP_SERVER}" $pass_file  > /dev/null 2>&1
  if [ $? -gt 0 ]; then
    echo "Adding SASL authentication configuration"
    echo "[${SMTP_SERVER}]:${SMTP_PORT} ${SMTP_USERNAME}:${SMTP_PASSWORD}" >> $pass_file
    postmap $pass_file
    rm -f $pass_file
  fi
fi

echo "starting service..."
rsyslogd

# If host mounting /var/spool/postfix, we need to delete old pid file before
# starting services
rm -f /var/spool/postfix/pid/master.pid

service postfix start
tail -f /dev/null

#/usr/lib/postfix/sbin/master -c /etc/postfix -d 2>&1

#/usr/sbin/postfix -c /etc/postfix start-fg
#exec /usr/sbin/postfix -c /etc/postfix start-fg
#tail -F /var/log/mail.log
