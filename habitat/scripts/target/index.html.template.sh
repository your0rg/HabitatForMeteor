#!/bin/bash

cat <<EODIF
<HTML>
	<HEAD>
		<TITLE>${VIRTUAL_HOST_DOMAIN_NAME} Dummy index file</TITLE>
	</HEAD>
	<BODY>
      You are seeing the main page of ${VIRTUAL_HOST_DOMAIN_NAME}.
	</BODY>
</HTML>
EODIF
