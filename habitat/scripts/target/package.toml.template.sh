#!/bin/bash

cat <<END
# Launch core.mongodb with --group ${YOUR_PKG} and --org ${YOUR_ORG}
# Additionally, pass in --permanent-peer to the start command
[cfg.services.core.mongodb.${YOUR_PKG}.${YOUR_ORG}]
start = "--permanent-peer --strategy at-once"

# Launch the ${YOUR_PKG} into the same group and org. No config required
[cfg.services.${YOUR_ORG}.${YOUR_PKG}.${YOUR_PKG}.${YOUR_ORG}]
END
