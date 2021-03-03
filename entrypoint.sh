#!/bin/sh -e



if [ -n "$GRIDC_START_CONFIG_TUNNELS" ]; then

	if [ -z "$GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX" ]; then
	# Set to container ID
	export GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX=$HOSTNAME
	fi


GRIDC_COMMAND="gridc"


# Debug
if [ -n "$GRIDC_DEBUG" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -log=stdout"
fi


# Hub connection
if [ -n "$GRIDC_HUB" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -hub $GRIDC_HUB"
fi

# Client API
if [ -n "$GRIDC_API" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -api $GRIDC_API"
fi

# Config file
GRIDC_COMMAND="$GRIDC_COMMAND -config=/home/gridc/.gridc/gridc.cfg"


if [ "$GRIDC_START_CONFIG_TUNNELS" = "all" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND start-all"
  else
  GRIDC_COMMAND="$GRIDC_COMMAND start $GRIDC_START_CONFIG_TUNNELS" 
fi


set -x
envsubst < /home/gridc/config-template.cfg > /home/gridc/.gridc/gridc.cfg
exec $GRIDC_COMMAND

fi






GRIDC_COMMAND="gridc"

# Debug
if [ -n "$GRIDC_DEBUG" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -log=stdout"
fi


# Set the protocol.
if [ "$GRIDC_PROTOCOL" = "http" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -proto http"
elif [ "$GRIDC_PROTOCOL" = "tcp" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -proto tcp"
else
  GRIDC_COMMAND="$GRIDC_COMMAND -proto https"
fi



# Subdomain
if [ -n "$GRIDC_SUBDOMAIN" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -subdomain=$GRIDC_SUBDOMAIN"
fi



# Config file
GRIDC_COMMAND="$GRIDC_COMMAND -config=/home/gridc/.gridc/gridc.cfg"



# Hub connection
if [ -n "$GRIDC_HUB" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -hub $GRIDC_HUB"
fi


# Client API
if [ -n "$GRIDC_API" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND -api $GRIDC_API"
fi


if [ -n "$GRIDC_ADDR_DOMAIN" ]; then
  GRIDC_COMMAND="$GRIDC_COMMAND $GRIDC_ADDR_DOMAIN:$GRIDC_ADDR_PORT"
else
  GRIDC_COMMAND="$GRIDC_COMMAND $GRIDC_ADDR_PORT"
fi


set -x
envsubst < /home/gridc/config-template.cfg > /home/gridc/.gridc/gridc.cfg
exec $GRIDC_COMMAND
