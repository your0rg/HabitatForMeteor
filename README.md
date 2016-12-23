# HabitatForMeteor

#### TL;DR

Future-proof your [Meteor](www.meteor.com) app deployments with [Habitat by Chef](https://www.habitat.sh/).  Bundle up your app with all the necessary installation and configuration instructions, get similar bundles for MongoDB, NGinx, PostgreSQL, etc, define them as a single logical unit with their connections parameters and then launch the unit automatically at boot-time as a single entity.  Manage remotely using Habitat's supervisory tools.

## A Habitat packager for Meteor DevOps

Until, now there have been two main choices for deploying Meteor applications :

1. `Galaxy`, is an option for those with a say in infrastructure decisions.
1. `mup`, is a ([now unsupported](https://voice.kadira.io/its-time-thank-you-bye-meteor-115dd649a8#.yymuveqzg)) single purpose hack for small budget operations.

HabitatForMeteor is for everyone else.

If you take DevOps seriously, you know about [Chef](https://www.chef.io/chef), and very likely automate your infrastructure with it already.

[Habitat by Chef](https://www.habitat.sh/) is their new product, dedicated to standardizing deployment of any and all server-side applications.  Habitat understands very large installations and offers powerful capabilities for managing multiple logical groupings of services.  One specialized supervisor is the `Director` which permits launching a logical group of services, in a single machine, as though they are a single unit.

Until recently, production Meteor applications only needed MongoDB, NodeJS and NGinx in order to run.  By using Habitat, we can bundle up the Node package of our application with all the instructions necessary to run it in NodeJS and connect it to MongoDB.  Habitat makes available similar bundles for MongoDB and NGinx.  We can define an outer `Director` bundle that includes all three together as a logical unit that launches at boot-time via `systemd` and can be reconfigured remotely using Habitat's management tools.

With Apollo, the spectrum of possible deployment requirements broadens dramatically.  MongoDB and NGinx will no longer be the the only ones.  The Habitat public "depot" offers an expanding ecosystem of generic standardized installers, eg [MySql](https://app.habitat.sh/#/pkgs/core/mysql/5.7.14/20160812153521), [PostgreSQL](https://app.habitat.sh/#/pkgs/core/postgresql/9.5.3/20161214235406), and they aren't difficult to create.  So, once you begin deploying with HabitatForMeteor your deployment tasks will be future-proof.  Controlling your live applications' infrastructure begins to look a lot like, and not much harder, than the package management you do within your Meteor apps.

Briefly, HabitatForMeteor...

1. Adds to your Meteor application the tools you need to wrap it into a Habitat deployment package.
1. Provides a single command to build a deployment package and publish it to a Habitat Depot.
1. Sets up a remote host with the Habitat deployment environment.
1. Provides a single command to pull a deployment package from a depot and deploy it to your remote host, *along with MongoDB, NodeJS, Nginx and the necessary connections between them*.


## Precautions

This is an alpha stage project, and Habitat itself is early beta, so please expect some teething pains.

So far, HabitatForMeteor has only been developed and tested on pairs of Xubuntu Xenial Xerus virtual machines.  In the spirit of "release early, release often", the focus has been on ensuring easy accessibility for anyone willing to set up such an environment and give it a whirl.

Also, this is a "feeler" project to see if there is much community interest.  We have used BASH shell scripting throughout.  If there is broader interest, (among Windows server users, particularly, for example), we'd rewrite in a more accessible language.  Since this is a Meteor project, using Node on the client might make sense.  For the server-side Python would be the most accessible, while Rust would be the coolest, and compatible with Habitat itself.

### Complexity

Habitat4Meteor has a lot of moving parts because it interacts with a number of different services and must manage quite a few of your deployment "secrets" :

* pulls Habitat and installs it on your development machine if necessary
* builds your Meteor applications
* assembles your Meteor Node packages into Habitat packages
* adjusts your applications' version numbering and creates releases in GitHub
* connects by RPC to your remote host to prepare Habitat with its own user 'sudoer' account
* connects by SCP to deliver installer scripts
* connects by RPC to your remote host to create a `systemd` unit file for boot-time &/or manual launch of your application

Initial set up may be a bit of a pain, and can take some time, but the end result is single click deploy **and** release management:  ready for inclusion in serious continuous deployment systems.

![Habitat For Meteor](https://docs.google.com/drawings/d/1YWjJnEXR4dmuE5R17owjhMdxg1ypBOGYlq3pUcQ0P6M/pub?w=480&h=360)

## Getting started

### Client side preparations

The steps below are designed to prepare everything in freshly installed Xubuntu virtual machines.

You will work exclusively in the client.  

You can cut'n paste the snippets unaltered and see the process unfold with no need to edit anything.  Those snippets can then form the basis of you own automation.  The steps depend on a set of shell variables, that you'll initialize immediately below. You will need to **be sure to re-source them** before trying any of the snippets below.

1. *Accounts* :: You need accounts on several remote services :
    1. [GitHub](https://github.com/) : You need user id and password, obviously.  You need an SSH key for commits. You'll also need a "GitHub Personal Token" to authenticate with the Habitat depot API; see below.
    2. [Habitat](https://app.habitat.sh/) : You can sign directly into Habitat with only your GitHub ID, **if** you already logged in to GitHub.  To interact with the Habitat depot API, you'll need a "GitHub Personal Token".
    3. [Loggly](https://www.loggly.com/) and [MailGun](https://www.mailgun.com/) : If you are building the Meteor Mantra Kickstarter you'll need access token for these two too.

1. *Prepare Virtual Machines* :: Prepare two Xubuntu Xenial Xerus virtual machines.  To quickly run through the *getting started* snippets below, cutting and pasting with no edits, you should name the machines `hab4metdev` & `hab4metsrv` (`${TARGET_SRVR}`).  Set up their `hosts` files so the developer (`hab4metdev`) machine can address the server (`hab4metsrv`) machine by name. The dev machine needs at least 12G disk space, while the server can be 8Gb.

1. *Prepare Secure Shell* :: Ensure that both machines are fully SSH enabled, including being able to SSH & SCP from `hab4metdev` machine to `hab4metsrv` machine without password.  The *getting started* scripts below expect the initial user on each machine to be called ´you´.

1.  Install keys for todos project user on GitHub

1.  Install Habitat Origin keys in '~/.ssh/hab_vault/habitat_user/'

1.  Define the virtual host domain in '/etd/hosts'.


### Install

To get started, fork HabitatForMeteor and clone it from to `${HABITA4METEOR_PARENT_DIR}/${HABITA4METEOR_FORK_NAME}`.

```
mkdir -p ${HABITA4METEOR_PARENT_DIR};
cd ${HABITA4METEOR_PARENT_DIR};
git clone git@github.com:${HABITA4METEOR_FORK_ORG}/${HABITA4METEOR_FORK_NAME};
cd ${HABITA4METEOR_FORK_NAME};
git checkout mmks_merger;

```


### Getting started "exerciser"

In order to make initial setup as easy as possible we have provided an [exerciser](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh) script with the functionality for every step of the process to deploy either the Meteor [Todos](https://github.com/meteor/todos) app or the [Meteor Mantra Kickstarter](https://github.com/warehouseman/meteor-mantra-kickstarter).  It's probably a good idea to fork HabitatForMeteor, rather than just clone it so you can immediately commit your preferred settings.

The script tries to be fully idempotent; you can repeat execution beginning at any of [the provided stages](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L6-L12) using the `${EXECUTION_STAGE}` variable. 


### Initial values

The first thing the script does is create a file of execution parameters, [${HOME}/.testVars.sh](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L23), **only if** there is not one already.

Some of the values in the file cannot be left as is.

You should edit `exerciser.sh` to provide suitable values for your setup. In the list below of sections of *required* project specifications the **[Obligatory]** flag indicates those you **must** alter.  After you have run the exerciser for the first time you should edit `${HOME}/.testVars.sh` to change settings.

 1. [Controlling exerciser execution](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L24-L29)
     * Specify whether the script should assume **no missing details**
     * Specify the execution stage you want to begin from

 1. [Locating public files within the developer VM](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L34-L47)
     * Location of developer tools
     * Location of projects
     * The SSH secrets directory 
     * The SSH keys of the current user, for ssh-add

 1. [Locating secrets within the developer VM](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L53-L60)
     * HabitatForMeteor secrets directory
     * HabitatForMeteor user secrets directory

 1. [Specifying your fork of HabitatForMeteor](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L66-L74)
     * Name of your HabitatForMeteorFork  
     * Organization of your HabitatForMeteorFork **[Obligatory]**
     * URI of your fork of HabitatForMeteor

 1. [Specifying your fork of a target project](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L80-L94)
     * Name of your fork of one the target projects
     * Your github organization for your fork of "todos" or "mmks"    **[Obligatory]**
     * The release tag you want to attach to the above project. It must be the newest release available anywhere, be it locally, on GitHub, or on apps.habitat.sh **[Obligatory]**

 1. [Specifying your public GitHub access](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L100-L108)
     * Your full name 
     * Your email address
     * Path to the SSH keys of the current user, for ssh-add

 1. [Specifying access parameters for your server VM](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L114-L126)
     * Domain name of the server where the project will be deployed
     * The 'habitat' admin account on the server
     * Parameters for creating a SSH key pair for the 'hab' user.

 1. [Specifying parameters for creating SSL certificates for your project domain](https://github.com/your0rg/HabitatForMeteor/blob/master/exerciser.sh#L132-L136)
     * Virtual host domain name
     * Virtual host certificate password







__________________________________________

#### Client side preparations

1. *Accounts* :: You need accounts on several remote services :
    1. [GitHub](https://github.com/) : You need user id and password, obviously.  You'll also need a personal token; see below.
    2. [Habitat](https://app.habitat.sh/) : You can sign directly into Habitat with only your GitHub ID, **if** you already logged in to GitHub.

1. *Prepare Virtual Machines* :: Prepare two Xubuntu Xenial Xerus virtual machines.  To quickly run through the *getting started* snippets below, cutting and pasting with no edits, you should name the machines `hab4metdev` & `hab4metsrv` (`${TARGET_SRVR}`).  Set up their `hosts` files so the developer (`hab4metdev`) machine can address the server (`hab4metsrv`) machine by name. The dev machine needs at least 12G disk space, while the server can be 8Gb.

1. *Prepare Secure Shell* :: Ensure that both machines are fully SSH enabled, including being able to SSH & SCP from `hab4metdev` machine to `hab4metsrv` machine without password.  The *getting started* snippets below expect the initial user on each machine to be called ´you´.

1.  Install keys for todos project user on GitHub

1.  Install Habitat Origin keys in '~/.ssh/hab_vault/habitat_user/'

1.  Define the virtual host domain in '/etd/hosts'

1. *Install Meteor* :: Find the latest correct installation command in the Meteor documentation page [Install](https://www.meteor.com/install), although realistically it's unlikely to change.  At last look it was :
    ```
    curl https://install.meteor.com/ | sh;
    ```


1. *Get Example Project* :: Fork the Meteor sample project, [todos](https://github.com/meteor/todos), and clone it into your machine as, for example, `${HOME}/projects/todos`.
    ```
    
    # Prepare directory
    mkdir -p ${TARGET_PROJECT_PARENT_DIR};
    pushd ${TARGET_PROJECT_PARENT_DIR};
    #
    # Install example project
    rm -fr ${TARGET_PROJECT_NAME};
    git clone git@github.com:${YOUR_ORG}/${TARGET_PROJECT_NAME}.git;
    popd;

    ```

1. Make sure you get to the point of having an issues free build and execute, locally.  Recently, (Dec 2016), for Meteor 1.4.2.3, I had to do :
    ```
    pushd ${TARGET_PROJECT_PARENT_DIR}/${TARGET_PROJECT_NAME};
    # Install all NodeJS packages dependencies
    meteor npm install
    #
    # Also install the one that change since the last release of 'meteor/todos'
    meteor npm install --save bcrypt;
    #
    # Start it up, look for any other issues and test on URL :: http://localhost:3000/.
    meteor;
    popd;

    ```
    Also, you'll see a recommendation to improve performance, with the following line ...
    ```
    # Optimize file change responsivity
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p;

    ```


1. *Prepare Example Project* :: Run `Update_or_Install_H4M_into_Meteor_App.sh`, for first time use, or if there are updates.
Eg;
    ```

    pushd ${HABITA4METEOR_PARENT_DIR}/${HABITA4METEOR_FORK_NAME};
    ./Update_or_Install_H4M_into_Meteor_App.sh ${TARGET_PROJECT_PARENT_DIR}/${TARGET_PROJECT_NAME};
    popd;


    ```
It will insert HabitatForMeteor into a hidden directory, `.habitat`, in your project, with suitable `.gitignore` files.  It will `git add` a few files to your version control, but not commit them.

1. *Prepare Habitat package build configuration in the file `./.habitat/plan.sh`* :: Switch to the root of your app ( same level as the `.meteor` dir ), then save the file `./.habitat/plan.sh.example` as `./.habitat/plan.sh`.
    ```
    pushd ${TARGET_PROJECT_PARENT_DIR}/${TARGET_PROJECT_NAME}/.habitat;
    cp plan.sh.example plan.sh;
    sed -i '/pkg_origin/c\pkg_origin=yourse1f-yourorg' plan.sh;
    popd;

    ```

    Edit `./.habitat/plan.sh` establishing these five settings :

    ```
    #               Name of Habitat origin.  E.g. --  pkg_origin=yourse1f-yourorg
    pkg_origin=
    #              Name of Habitat package.  E.g. --  pkg_name=todos
    pkg_name=
    #       Package formal release version.  E.g. --  pkg_version=0.1.1
    pkg_version=
    #        How you wish to be identified.  E.g. --  pkg_maintainer="Yourself <yourse1f.yourorg@gmail.com>"
    pkg_maintainer=
    # Where your source code is published..  E.g. --  pkg_upstream_url=https://github.com/yourse1f-yourorg/todos
    pkg_upstream_url=

    ```

1. *Obtain a GitHub Personal Token* :: To work with Habitat you need to warehouse your packages in a Habitat Depot.  You can build your own Depot if necessary.  Here we will use [Habitat's free public depot](https://app.habitat.sh/). To sign into a Depot web interface you simply need to authenticate via GitHub. Your package depository will be instantiated automatically.  To interact with a Depot via its API, you **must** use a *GitHub Personal Token*. The Depot only needs a token that exposes your GitHub email addresses. Following steps will guide you through using the token; for now, refer to, [Setting up hab to authenticate to the depot](https://www.habitat.sh/docs/share-packages-overview/), to learn how to get one.

1. *Initialize Example Project* :: This is a one time install, with occasional repetitions in the future for the purpose of keeping up to  date.  Run the script `./.habitat/scripts/Update_or_Install_Dependencies.sh;`
    ```
    pushd ${HOME}/projects/todos;
    ./.habitat/scripts/Update_or_Install_Dependencies.sh;
    popd;

    ```
    The script prompts for several constants that need to be set in order that you get the correct version of Habitat, including the *GitHub Personal Token*, mentioned above. It records these values in `${HOME}/.userVars.sh`.

    When finished, it will have performed some sanity checks on the `.habitat` directory of your app, updating &/or installing as necessary.
    * ensured non-varying files are ignored by `git`
    * added the varying files to your git repo
    * reminded that a Meteor installation is required ( if you haven't installed it )
    * installed Habitat
    * installed dependencies like `jq`,  `curl`,  `expect` and `semver`.


1. *Tag Example Project Version* :: Ease of deployment is the point of Habitat, but deployment needs to be a controlled process.  There are several places where the current project version number is specified and **they must all agree**.  The next step will fail if their is disagreement or if somehow downstream ( git repo ) version numbers are greater than the current version.  Additional, intentionally redundant, meta information is also required.  The complete list is:
    - `./package.json` - must have four additional fields not supplied in the repo `meteor/todos`, such that this ...
        ```
        {
          "scripts": {
            "start": "meteor",
            "pretest": "npm run lint --silent",
        ```
        ... should end up looking like this ...
        ```
        {
          "name": "todos",
          "version": "0.1.4",
          "license": "MIT",
          "repository": "https://github.com/yourse1f-yourorg/todos",
          "scripts": {
            "start": "meteor",
            "pretest": "npm run lint --silent",
        ```

    - `./habitat/plan.sh` - must indicate the same version in its field
        -    pkg_version=**0.1.4**

    - `./habitat/release_notes/`**0.1.4**`_note.txt` - is identified by file name only, you can put what you want in it. (_GitHub flavored markup makes it look like there is a space in that file path.  There should not be._) So do :
        ```
        pushd ${HOME}/projects/todos;
        cp .habitat/release_notes/0.0.0_note.txt.example .habitat/release_notes/0.1.4_note.txt;
        sed -i "s|0.0.0|0.1.4|g" .habitat/release_notes/0.1.4_note.txt
        git add .habitat/release_notes/0.1.4_note.txt;
        popd;

        ```

    - `the argument to the script in the next step` - The same version number as in the previous 3 places must also be supplied as an argument to the script, `./.habitat/BuildAndUpload.sh`  **0.1.4**

    - `latest release number in the local git repo` - must be less than or equal to the one being built

    - `latest release number in GitHub` - must be less than or equal to the one in the local repo

    - `latest version in the Habitat Depot` - must be less than or equal to the one in GitHub

1. *Commit & Push Example Project* :: Finally you must commit your project entirely.  That is: no files remaining to add, no files remaining to commit. Files that need to be in your project, but not under version control must be ignored explicitly by reference in a `.gitignore` file.


1. *Install Habitat Origin Keys* :: Origin keys are the way you prove ownership of artifacts produced by Habitat.  They have a public part, `yourse1f-yourorg-20161031014505.pub` and a private part, `yourse1f-yourorg-20161031014505.sig.key`, that look this ...
    ```
    SIG-PUB-1
    yourse1f-yourorg-20161031014505

    +df5kEByPZ+BrPotXBc3wuo34WS6e+uK/xcKP6A0yEE=
    ```
    ... and this ...
    ```
    SIG-SEC-1
    yourse1f-yourorg-20161031014505

    qDLpFRBhR+Ni5y9hUC447JXOSQVkzkEeyv6IglowsRH51/mQQHI9n4Gs+i1cFzfC6jfhZLp764r/Fwo/oDTIQQ==
    ```
    ... respectively.

    There are three possibilities here :

    1. If you have never created any keys then do :

    ```
    sudo hab setup;
    ```

    1. If you have keys stored elsewhere, ( eg; ${HOME}/.ssh ), and need to install them :

    ```
    cat ${HOME}/.ssh/hab_vault/habitat_user/yourse1f-yourorg-*.pub | sudo hab origin key import; echo ;
    cat ${HOME}/.ssh/hab_vault/habitat_user/yourse1f-yourorg-*.sig.key | sudo hab origin key import; echo ;
    ```

    1. If you need to replace the keys you got with `sudo hab setup` :

    ```
    STMP=$(hab origin key generate yourse1f-yourorg | tail -n 1);
    export STMP=${STMP%.};
    export TRY="* Generated origin key pair yourse1f-yourorg-";
    export KEY_STAMP=${STMP#${TRY}};
    cat ${HOME}/.hab/cache/keys/yourse1f-yourorg-${KEY_STAMP}.pub | hab origin key import; echo ;
    cat ${HOME}/.hab/cache/keys/yourse1f-yourorg-${KEY_STAMP}.sig.key | hab origin key import; echo ;
    ```

1. *Use ssh-agent* :: You **don't** need to have SSH continually nagging for your SSH key passphrase.  Do ...
    ```
    echo "$SSH_AUTH_SOCK";
    # if that returns nothing, then you'll need to start ssh-agent with ...
    eval $(ssh-agent);
    # either way, do ...
    ssh-add <path to yout private key>;
    # yeah, it's gonna want the password!
    ```

1. *Cleanly commit and push the project* :: The next step will balk at continuing if there are any "loose" files in your project directory.  You must have explicitly ignored &/or added, committed **and** pushed, each and every file.

1. *Build Example Project* :: In the root of your app (as before), run `BuildAndUpload.sh`.  For example...
    ```
    ./.habitat/BuildAndUpload.sh 0.1.4
    ```
This step first attempts to catch any lapses in the discipline described in the preceding step, collecting all the discrepancies it can find, listing them on screen with individual explanations and then quitting.

    If there's nothing you need to fix it will go ahead and start building.

    **Be warned** -- there are two disconcertingly long pauses...

        "Stripping unneeded symbols from binaries and libraries"

    ... and ...

        "Generating blake2b hashes of all files in the package"

    Both are valid and necessary tasks, so be patient and let it run.

    Only if everything seems correct will it display a message prompt like this :

    ```
            *** Please confirm the following ***

       -->  Previous deployed application revision tag : 0.1.4
       -->          Most recent previous local Git tag : 0.1.3-1-g5457468
       -->         Most recent previous remote Git tag : 0.1.3
       -->                   Specified new release tag : 0.1.4

            *** If you proceed now, you will ***
      1) Set Habitat package plan revision number to 0.1.4
      2) Push the Habitat package to the Habitat public depot as :
               yourse1f-yourorg / todos
               0.1.4 / 20161017111516
      3) Set the project metadata revision number to 0.1.4
      4) Commit all uncommitted app changes (not including untracked files!)
      5) Tag the commit and push all to the remote repository

      Proceed? [y/N]
    ```

1. *Upload Example Project* :: If you type `y<enter>` at this point HabitatForMeteor will proceed with the indicated actions.  When it has done everything, it ends with :
    ```
        Your package is published on the Habitat depot.   You can see it at:

            https://app.habitat.sh/#/pkgs/yourse1f-yourorg/todos

                                        - o 0 o -



            - Next Step * : Prepare your target host for deploying the package by
                 placing a Secure SHell Remote Procedure Call (SSH RPC) to it :

            cd /home/you/projects/mmks;
            ./.habitat/scripts/PushInstallerScriptsToTarget.sh ${TARGET_SRVR} ${SETUP_USER} ${METEOR_SETTINGS_FILE} ${SOURCE_SECRETS_FILE};

          Where :
            TARGET_SRVR is the host where the project will be installed.
            SETUP_USER is a previously prepared 'sudoer' account on '${TARGET_SRVR}'.
            METEOR_SETTINGS_FILE typically called 'settings.json', contains your app's internal settings,
            SOURCE_SECRETS_FILE is the path to a file of required passwords and keys for '${TARGET_SRVR}'.
                ( example file : /home/you/projects/mmks/.habitat/scripts/target/secrets.sh.example )


      .  .  .  .  .  .  .  .  .  .  .  .  .
    ```
    You will find :
    - a new release created on GitHub : ( eg; Similar to [our todos repo](https://github.com/yourse1f-yourorg/todos) )
    - a new package published on the Habitat Depot : ( eg; Similar to [our, embarrassingly numerous, publications](https://app.habitat.sh/#/pkgs/yourse1f-yourorg/todos) )

#### Server side operations

With your Meteor application bundled up as a Habitat package and available for download from the Habitat Depot, you are now ready to prepare a server for Habitat supervised deployments.

There are a number of considerations.

The first is that the initialization script will create a new user named `hab` that has "sudoer" privileges.  This is done for security reasons -- basically to keep it distinct from the user account used by the client.  That account will need to be given an SSH public key for use from its `${HOME}/.ssh/authorized_keys` file.  The `sudo` password for the initial user account will be used once over RPC, while the `sudo` password for the habitat user account will be used for all future deployments.  For security it will be stored as an `SUDO_ASK_PASS` script in the `hab` user's `${HOME}/.ssh` directory and executable by `hab` exclusively. Passwords are verified to have minimum 8 chars.

Next, you'll need to have ready an SSL certificate file set.  Digital Ocean [explains how to do this](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04) very well as usual.  If you need a "real" certificate from a certificate authority (CA), [StartSSL](https://www.startssl.com/), offers **free** 3 yr., Class 1 certificates that certify up to 10 domains.

The following steps assume you are simply working between two virtual machines with a self-signed certificate for an imaginary domain.

  **It is important to notice that these server-side preparations are done from the developer client machine, using SCP and RPC via SSH!  Unless, otherwise indicated, the provided command snippets are to be run in a terminal window on the client.** (Logging into individual machines just isn't *the DevOps way*.)

The **client side** steps to perform server side preparations are :

1. *Specify the target server in your hosts file* :: Find the IP address of your server, for example `192.168.122.123` and add the following line to the file `/etc/hosts`:
    ```
    192.168.122.123 hab4metsrv
    ```

1. *Specify the site domain name in your hosts file* :: For simplicity sake, we'll assume it's the same IP as the server: `192.168.122.123`, but it doesn't have to be.  Add the following line to the file `/etc/hosts`:
    ```
    192.168.122.123 moon.planet.sun
    ```

1. *Dependencies* :: Be sure you have `expect` installed.  Cut'n paste this line and supply your `sudoer` password as requested:
    ```
    sudo apt install -y expect;
    ```

1. *Prepare SSH keys* :: Paste the following lines at a command prompt.

    ```
    COMMENT="DevopsTeamLeader";
    SSHPPHRASE="memorablegobbledygook";
    HABITAT_USER_SSH_KEY_PATH="${HOME}/.ssh/hab_vault/habitat_user"
    #
    mkdir -p ${HABITAT_USER_SSH_KEY_PATH};
    rm -f ${HABITAT_USER_SSH_KEY_PATH}/id_rsa*;
    ssh-keygen \
      -t rsa \
      -C "${COMMENT}" \
      -f "${HABITAT_USER_SSH_KEY_PATH}/id_rsa" \
      -P "${SSHPPHRASE}" \
      && cat ${HABITAT_USER_SSH_KEY_PATH}/id_rsa.pub;
    chmod go-rwx ${HABITAT_USER_SSH_KEY_PATH}/id_rsa;
    chmod go-wx ${HABITAT_USER_SSH_KEY_PATH}/id_rsa.pub;
    chmod go-w ${HABITAT_USER_SSH_KEY_PATH};

    ```
    You'll also need to distinguish the `hab` user's keys from you own, by means of a SSH `config` file.  Paste the following lines at a command prompt.
    ```
    CURRENT_USER=$(whoami);
    TARGET_SRVR="hab4metsrv";
    CURRENT_USER_SSH_KEY_FILE="${HOME}/.ssh/id_rsa";
    #
    ping -c 4 ${TARGET_SRVR};
    #
    export PTRN="# ${CURRENT_USER} account on ${TARGET_SRVR}";
    export PTRNB="${PTRN} «begins»";
    export PTRNE="${PTRN} «ends»";
    #
    mkdir -p ${HOME}/.ssh;
    touch ${HOME}/.ssh/config;
    cp ${HOME}/.ssh/config ${HOME}/.ssh/config_BK;
    chmod ugo-w ${HOME}/.ssh/config_BK;
    sed -i "/${PTRNB}/,/${PTRNE}/d" ${HOME}/.ssh/config;
    #
    echo -e "
    ${PTRNB}
    Host ${TARGET_SRVR}
        HostName ${TARGET_SRVR}
        User ${CURRENT_USER}
        PreferredAuthentications publickey
        IdentityFile ${CURRENT_USER_SSH_KEY_FILE}
    ${PTRNE}
    " >> ${HOME}/.ssh/config

    HABITAT_USER="hab";
    HABITAT_USER_SSH_KEY_FILE="${HOME}/.ssh/hab_vault/habitat_user/id_rsa";
    #
    export PTRN="# ${HABITAT_USER} account on ${TARGET_SRVR}";
    export PTRNB="${PTRN} «begins»";
    export PTRNE="${PTRN} «ends»";
    #
    sed -i "/${PTRNB}/,/${PTRNE}/d" ${HOME}/.ssh/config;
    #
    echo -e "
    ${PTRNB}
    Host ${TARGET_SRVR}
        HostName ${TARGET_SRVR}
        User ${HABITAT_USER}
        PreferredAuthentications publickey
        IdentityFile ${HABITAT_USER_SSH_KEY_FILE}
    ${PTRNE}
    " >> ${HOME}/.ssh/config
    #
    sed -i "/^$/N;/^\n$/D" ${HOME}/.ssh/config
    ```


1. *Verify SSH to the server* :: Cut'n paste this snippet ...
    ```
    TARGET_SRVR="hab4metsrv";
    CURRENT_USER_SSH_KEY_FILE="${HOME}/.ssh/id_rsa";
    #
    eval $(ssh-agent);
    ssh-add ${CURRENT_USER_SSH_KEY_FILE}

    ```
    ... and then this one ...
    ```
    ssh -t -oStrictHostKeyChecking=no -oBatchMode=yes -l $(whoami) ${TARGET_SRVR} whoami;
    ```


1. *Prepare SSL certificate* :: Paste the following line at a command prompt.

    ```
    SSLPPHRASE="memorablegibberish";
    VHOST_DOMAIN="moon.planet.sun";
    SUBJ="/C=ZZ/ST=Planet/L=Moon/O=YouGuyz/CN=${VHOST_DOMAIN}";
    CERT_PATH="${HOME}/.ssh/hab_vault/${VHOST_DOMAIN}";
    #
    mkdir -p ${CERT_PATH};
    rm -f ${CERT_PATH}/*;
    echo ${SSLPPHRASE} > ${CERT_PATH}/server.pp;
    openssl req \
    -new \
    -newkey rsa:4096 \
    -days 1825 \
    -x509 \
    -subj "${SUBJ}" \
    -passout file:${CERT_PATH}/server.pp \
    -keyout ${CERT_PATH}/server.key \
    -out ${CERT_PATH}/server.crt

    ```

1. *Prepare your secrets file* :: The SOURCE_SECRETS_FILE holds user and connections secrets to be installed server side. There is an example secrets file at [HabitatForMeteor/habitat/scripts/target/secrets.sh.example](https://github.com/your0rg/HabitatForMeteor/blob/master/habitat/scripts/target/secrets.sh.example).  Needless to say, you'll want to do a good job of expunging this file after use, or keeping close care of it, same as you would with the server certificates.  The scripts snippets below expect you to store the file at `${HOME}/.ssh/hab_vault/secrets.sh`.  If you have been using the snippets unaltered, ´SETUP_USER_PWD´, is the only setting you'll need to change.  Give it the password of ´you´.

    1. Passwords: The script needs to know the password Meteor will use to connect to MongoDB, the sudoer password for the initial connection user,  and the sudoer password for the habitat user.  These three passwords are used internally in the server. Passwords are **not** used in the SSH and SCP connections.
    2. Habitat user key file: The path and filename, on the developer's (your) machine, of a copy of the `hab` user's SSH public key. Obviously the key pair will have to be safely recorded for future use.
    3. Certificates:  To install Nginx's SSL certificate, the script needs to be able to find the certificate, it's decryption key and the decryption key pass phrase.  Assuming a site name, `moon.planet.sun`, and a certificates storage location of, `/home/you/.ssh/hab_vault/` the exported shell variable must be **exactly** `export  MOON_PLANET_SUN_CERT_PATH="/home/you/.ssh/hab_vault/moon.planet.sun"`.  All three of the required certificate files must be in the specified subdirectory, `moon.planet.sun`, and must be named **exactly** "server.crt", "server.key", "server.pp" (for now).

        Finally, the shell variable, `ENABLE_GLOBAL_CERT_PASSWORD_FILE`, can be commented out to stop Nginx trying to load certificates' passwords. You'll still need an empty `server.pp` file, if you elect to go for a passwordless cert.

1. *Install Remote Host For Habitat* :: The script, `PushInstallerScriptsToTarget.sh` only needs run once, fortunately, because it must be supplied with quite a few arguments. Eg;
    ```
    export HABITAT_PROJ_DIR="${HOME}/tools/HabitatForMeteor";
    export TARGET_SRVR="hab4metsrv";
    export SETUP_USER="you";
    export METEOR_SETTINGS_FILE="${HOME}/.ssh/hab_vault/settings.json";
    export SOURCE_SECRETS_FILE="${HOME}/.ssh/hab_vault/secrets.sh";
    ${HABITAT_PROJ_DIR}/habitat/scripts/PushInstallerScriptsToTarget.sh ${TARGET_SRVR} ${SETUP_USER} ${METEOR_SETTINGS_FILE} ${SOURCE_SECRETS_FILE};
    ```
The required arguments are :

    - TARGET_SRVR is the host where the project will be installed.
    - SETUP_USER is a previously prepared 'sudoer' account on '${TARGET_SRVR}'. This account will only be used for initial set up, during whicha new account called ´hab´ will be created for all subsequently access.
    - METEOR_SETTINGS_FILE specifies the location of your [Meteor settings.json](http://galaxy-guide.meteor.com/environment-variables.html) file. It **must** exist, even if you leave it empty.
    - SOURCE_SECRETS_FILE holds user and connections secrets to be installed server side. An example secrets file can be found at [HabitatForMeteor / habitat / scripts / target /secrets.sh.example](https://github.com/your0rg/HabitatForMeteor/blob/master/habitat/scripts/target/secrets.sh.example)

    **early release note** While all these scripts and snippets are designed to be idempotent, (meaning that you can run them repeatedly without negative consequences), the current version of this script (PushInstallerScriptsToTarget.sh) tries to wipe out and recreate the 'hab' user each time.  It fails if the 'hab' user has files open or tasks running.

1. *Verify SSH to the 'hab' user now works* :: Cut'n paste the following :
    ```
    HABITAT_USER="hab";
    TARGET_SRVR="hab4metsrv";
    HABITAT_USER_SSH_KEY_FILE="/home/you/.ssh/hab_vault/habitat_user/id_rsa";
    HABITAT_USER_SSH_PASS="memorablegobbledygook";
    #
    eval $(ssh-agent);
    expect << EOF
      spawn ssh-add ${HABITAT_USER_SSH_KEY_FILE}
      expect "Enter passphrase"
      send "${HABITAT_USER_SSH_PASS}\r"
      expect eof
    EOF
    ssh -t -oStrictHostKeyChecking=no -oBatchMode=yes -l ${HABITAT_USER} ${TARGET_SRVR} whoami;

    ```


1. *Install Your SSL certificates* :: Use the script, `PushSiteCertificateToTarget.sh` to upload the SSL certificate you created earlier. Eg;
    ```
    export HABITAT_PROJ_DIR="${HOME}/tools/HabitatForMeteor";
    export TARGET_SRVR="hab4metsrv";
    export VIRTUAL_HOST_DOMAIN_NAME="moon.planet.sun";
    export SOURCE_SECRETS_FILE="${HOME}/.ssh/hab_vault/secrets.sh";
    export SOURCE_CERTS_DIR="${HOME}/.ssh/hab_vault";
    ${HABITAT_PROJ_DIR}/habitat/scripts/PushSiteCertificateToTarget.sh \
                   ${TARGET_SRVR} \
                   ${SOURCE_SECRETS_FILE} \
                   ${SOURCE_CERTS_DIR} \
                   ${VIRTUAL_HOST_DOMAIN_NAME}
    ```
The required arguments are :

    - TARGET_SRVR is the host where you installed the project.
    - SOURCE_SECRETS_FILE is the same one as described earlier.
    - SOURCE_CERTS_DIR is the path to a directory of certificates holding the one for '\${VIRTUAL_HOST_DOMAIN_NAME}'.
    - VIRTUAL_HOST_DOMAIN_NAME is the fully qualified domain name you specified in the certificate.


#### Deployment

With a server prepared as above, any machine possessing private keys to the ´hab´ account can deploy Nginx, MongoDB and your Meteor app, with this single command:

    ´´´
    export VIRTUAL_HOST_DOMAIN_NAME="moon.planet.sun";
    export YOUR_ORG='yourse1f-yourorg';
    export YOUR_PKG='todos';
    export semver='';    # An optional version number, eg; 0.1.8
    export timestamp=''; # An optional timestamp, eg; 20161231235959
    #
    ssh hab@hab4metsrv "~/HabitatPkgInstallerScripts/HabitatPackageRunner.sh ${VIRTUAL_HOST_DOMAIN_NAME} ${YOUR_ORG} ${YOUR_PKG} ${semver} ${timestamp}";

    ´´´

Use a browser to visit [https://moon.planet.sun/](https://moon.planet.sun/).  It will throw a hissy-fit about your "insecure" self-signed certifiacte. Take the necessary override steps and the Meteor `todos` application will load.

Reboot to verify that it relaunches without any hiccups.

#### No secrets

It's useful to understand at this point, that no secrets are transferred or exposed in the deployment step.  That task is handled by the script, PushInstallerScriptsToTarget.sh, documented above.

#### Management

To see how it's behaving you can log into the server with ...
```
ssh you@hab4metsrv
```
... and then use any of the following to control it:

Watch the Habitat logs with :
```
sudo journalctl -fb -u yourse1f-yourorg_todos.service
```

Examine the Habitat logs back to the last boot with :
```
sudo journalctl -fb --no-tail -u yourse1f-yourorg_todos.service
```

Disable and stop MongoDb, Meteor and Nginx as a unit with :
```
sudo systemctl disable yourse1f-yourorg_todos.service
sudo systemctl    stop yourse1f-yourorg_todos.service
```

Enable and start MongoDb, Meteor and Nginx as a unit with :
```
sudo systemctl enable yourse1f-yourorg_todos.service
sudo systemctl  start yourse1f-yourorg_todos.service
```

Watch the Nginx logs with ...
```
sudo tail -fn 50 /var/log/nginx/moon.planet.sun/access.log 
```
... and with ....
```
sudo tail -fn 50 /var/log/nginx/moon.planet.sun/error.log 
```



### Contributing

The main contribution we look for at the moment is alpha testing.  Spin up a pair of Ubuntu 16.04 flavored machines and follow the instructions.  Post an issue if you hit a snag or ambiguity in the instructions.

#### Stuff missing

1. *Staging*: We need a way to structure pushing to different servers.  Right now it is development direct to production.

1. *Continuous Integration*: In any project, with or without HabitatFor Meteor, each normal commit should fire off a rebuild in a CI server.  Commits which add a new release note should activate HabitatForMeteor to build and test in a staging server.

1. *Clustering*: We really do want Nginx fronting two or more Meteor servers, if only for zero-downtime deployment.


#### Typical development REPL loop ( my usage ) 

##### Tools Directory

    cd ${HOME}/tools/HabitatForMeteor/
    ./Update_or_Install_H4M_into_Meteor_App.sh ../../projects/todos/
    ./run_on_save.sh ./habitat/BuildAndUpload.sh ./Update_or_Install_H4M_into_Meteor_App.sh ../../projects/todos


##### Application Directory

    cd ${HOME}/projects/todos
    ./.habitat/scripts/Update_or_Install_Dependencies.sh;
    ../../tools/HabitatForMeteor/run_on_save.sh .habitat/BuildAndUpload.sh .habitat/BuildAndUpload.sh 

