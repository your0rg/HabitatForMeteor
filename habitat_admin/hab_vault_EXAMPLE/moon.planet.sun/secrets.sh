## Script dependencies
###

# The sudoer password for the account that will install Habitat
export SETUP_USER_UID="you";
export SETUP_USER_PWD='memorabletrumpism';

# The passphrase for 'hab' user SSH key.
export HABITAT_USER_SSH_PASS_PHRASE="memorablegobbledygook";

# The sudoer password to give the 'hab' user account when it is created
export HABITAT_USER_PWD="memorablecacaphony";

# The passphrase for this virtual hosts SSL certificate.
export VHOST_CERT_PASSPHRASE="memorablegibberish";

# The name of the 'PostgreSQL' database.
export PG_DB="todos";

# The user and password with which 'Meteor' will access 'PostgreSQL'.
export PG_UID="meteor";
export PG_PWD="memorablehieroglyphs";
export PGRESQL_PWD="${PG_PWD}";

# The server where 'Meteor' will find 'PostgreSQL'.
export PG_HST="localhost"; 

# The URL of a database backup to intialize 'PostgreSQL'.
export PG_BKP="http://bit.ly/mmks170317G";

# The password the Meteor app will use to connect to a localhost MongoDB
export MONGODB_PWD="memorablehieroglyphs";


# The domain and API key for 'MailGun'.
export MAILGUN_DOMAIN="iridium.blue";
export MAILGUN_KEY="key-f8eed2_FIXME_8218528eff7bfa50fa1";

# The SUBdomain and API key for 'Loggly'.
export LOGGLY_SUBDOMAIN="yourwork";
export LOGGLY_TOKEN="c771fa0f-_FIXME_d6-9660-5e23-c85a9f5";
