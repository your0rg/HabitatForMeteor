#!/bin/bash

cat <<EOCLIT
# Use a 4096 bit RSA key instead of 2048.
rsa-key-size = 4096

# Set email and domains.
email = ${CERT_EMAIL}
domains = ${VIRTUAL_HOST_DOMAIN_NAME}

# Text interface.
text = True

# No prompts.
non-interactive = True

# Suppress the Terms of Service agreement interaction.
agree-tos = True

# Use the standalone authenticator.
authenticator = standalone
EOCLIT
