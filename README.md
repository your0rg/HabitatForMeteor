# HabitatForMeteor

#### TL;DR

Use [Habitat by Chef](https://www.habitat.sh/) for [Meteor](www.meteor.com) app deployment.  Bundle up your app with all the necessary installation and configuration instructions, get similar bundles for MongoDB and NGinx, define them as a single logical unit with their connections parameters and then launch the unit automatically at boot-time as a single entity.  Manage remotely using Habitat's supervisory tools.

## A Habitat packager for Meteor DevOps

Until, now there have been two main choices for deploying Meteor applications :

1. `Galaxy`, is an option for those with the money and a direct say in infrastructure decisions.
1. `mup`, is a ([now unsupported](https://voice.kadira.io/its-time-thank-you-bye-meteor-115dd649a8#.yymuveqzg)) single purpose hack for small budget operations.

HabitatForMeteor is for everyone else.

If you take DevOps seriously, you know about [Chef](https://www.chef.io/chef), and very likely automate your infrastructure with it already.

[Habitat by Chef](https://www.habitat.sh/) is their new product, dedicated to standardizing deployment of any and all server-side applications.  Habitat understands very large installations and offers powerful capabilities for managing multiple logical groupings of services.  One specialized supervisor is the `Director` which permits launching a logical group of services, in a single machine, as though they are a single unit.

Production Meteor applications need MongoDB, NodeJS and NGinx in order to run.  By using Habitat, we can bundle up the Node package of our application with all the instructions necessary to run it in NodeJS and connect it to MongoDB.  Habitat makes available similar bundles for MongoDB and NGinx.  We can define an outer "Director" bundle that includes all three together as a logical unit that launches at boot-time via `systemd` and can be reconfigured remotely using Habitat's management tools.

Controlling your live applications' infrastructure begins to look a lot like, and not much harder, than the package management you do within your Meteor apps.

Briefly, HabitatForMeteor...

1. Sets up your development machine with the tools to wrap your Meteor application into a Habitat deployment package.
2. Sets up a remote host with the Habitat deployment environment.
3. Provides a single command to build a deployment package and publish it to a Habitat Depot.
4. Provides a single command to pull a deployment package from a depot and deploy it to your remote host, *along with MongoDB, NodeJS, Nginx and the necessary connections between them*.

## Caution

This is an alpha stage project, and Habitat itself is early beta, so please expect some teething pains.

So far, HabitatForMeteor has only been developed and tested on pairs of Xubuntu Xenial Xerus virtual machines.  In the spirit of "release early, release often", the focus has been on ensuring easy accessibility for anyone willing to set up such an environment and give it a whirl.

Also, this is a "feeler" project to see if there is much community interest.  We have used BASH shell scripting throughout.  If there is broader interest, (among Windows server users, particularly, for example), we'd rewrite in a more accessible language.  Since this is a Meteor project, using Node on the client might make sense.  For the server-side Python would be the most accessible, while Rust would be the coolest, and compatible with Habitat itself.

### Complexity

Habitat4Meteor has a lot of moving parts because it interacts with a number of different services :

* pulls Habitat and installs it on your development machine if necessary
* builds your Meteor applications
* assembles your Meteor Node packages into Habitat packages
* adjusts your applications' version numbering and creates releases in GitHub
* connects by RPC to your remote host to prepare Habitat with its own user 'sudoer' account
* connects by RPC to your remote host to create a `systemd` unit file for boot-time &/or manual launch of your application

Initial set up may be a bit of a pain, and can take some time, but the end result is single click deploy **and** release management:  ready for inclusion in serious continuous deployment systems.

![Habitat For Meteor](https://docs.google.com/drawings/d/19HVhiUMscFOl4vGXtzgbcbGn8rcltuxkBuRa6YrxiZk/pub?w=960&h=720)

### Getting started

#### Client side preparations

1. *Prepare Virtual Machines* :: Prepare two Xubuntu Xenial Xerus virtual machines with at least 12G disk space and give them distinct names that suggest developer machine and target server (eg; `dev` & `srv`).  Set up their `hosts` files so the developer (`dev`) machine can address the server (`srv`) machine by name. After gaining confidence in HabitatForMeteor, you should be able to use the Xubuntu desktop on the developer VM only, going to the server machine via SSH, such that the target VM can be a server install with no GUI needed.

1. *Prepare Secure Shell* :: Ensure that both machines are fully SSH enabled, including being able to SSH & SCP from `dev` machine to `srv` machine without password.

1. *Install Meteor* :: Find the latest correct installation command in the Meteor documentation page [Install](https://www.meteor.com/install), although realistically it's unlikely to change.  At last look it was :
    ```
    curl https://install.meteor.com/ | sh;
    ```


1. *Get Example Project* :: Fork the Meteor sample project, [todos](https://github.com/meteor/todos), and clone it into your machine as, for example, `${HOME}/projects/todos`.

1. Decide whether you want to run with the latest version of the `todos` project, the latest release of Meteor, or Meteor version `1.4.2.3`, against which this project was tested. *Note that*, if you run ```meteor version``` while in the top-level directory of the `todos` project, then `meteor` will download the version specified in `.meteor/release`  and report **that** as the current installed version of Meteor.  On the other hand if you run ```meteor version``` from outside any Meteor project directory it will tell you the version of Meteor that you most recemtly used.  This generates the text that you would need to put into `.meteor/release` if you choose to use your installed Meteor version :

    ```
    MV=$(meteor --version);MV=${MV/#Meteor /METEOR@}; echo ${MV};
    ```

Again . . . **don't** run that in a Meteor application directory.

1. Make sure you get to the point of having an issues free build and execute, locally.  Recently, (Oct 2016), for Meteor 1.4.2, I had to do :
    ```
    #
    # Optimize file change responsivity
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p;
    #
    # Install all NodeJS packages dependencies
    meteor npm install
    #
    # Also install the one that change since the last release of 'meteor/todos'
    meteor npm install --save bcrypt;
    #
    # Start it up, look for any other issues and test on URL :: http://localhost:3000/.
    meteor;
    ```


1. *Get Habitat For Meteor* :: Fork the [HabitatForMeteor](https://github.com/your0rg/HabitatForMeteor) repo as, for example...
    ```
    ${HOME}/tools/HabitatForMeteor
    ```

1. *Prepare Example Project* :: Run `Update_or_Install_H4M_into_Meteor_App.sh`, for first time use, or if there are updates.
Eg;
    ```
    ./Update_or_Install_H4M_into_Meteor_App.sh ../../projects/todos;
    ```
It will insert HabitatForMeteor into a hidden directory `.habitat` in your project, with suitable `.gitignore` files.  It will `git add` a few files to your version control, but not commit them.

1. *Prepare Habitat package build configuration in the file `./.habitat/plan.sh`* :: Switch to the root of your app ( same level as the `.meteor` dir ), then save the file `./.habitat/plan.sh.example` as `./.habitat/plan.sh`. Edit `./.habitat/plan.sh` establishing these five settings :

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

1. *Initialize Example Project* :: This is a one time install, with occasional repetitions in the future for the purpose of keeping up to  date.  Run the script `./.habitat/scripts/Update_or_Install_Dependencies.sh;`  It will perform some sanity checks on the `.habitat` directory of your app, updating &/or installing as necessary:  ensures non-varying files are ignored by `git`, adds the varying files to your git repo, reminds that a Meteor installation is required ( Meteor installation won't be automated ), installs Habitat and installs dependencies like `jq`and `semver`.  The script prompts for several constants that need to be set in order that you get the correct version of Habitat, including the *GitHub Personal Token*, mentioned above. It records these values in `${HOME}/.userVars.sh`.

1. *Tag Example Project Version* :: Ease of deployment is the point Habitat, but deployment needs to be a controlled process.  There are several places where the current project version number is specified and **they must all agree**.  The next step will fail if their is disagreement or if somehow downstream ( git repo ) version numbers are greater than the current version.  Additional, intentionally redundant, meta information is also required.  The complete list is:
    - `./package.json` - must have four additional fields not supplied in the repo `meteor/todos` :
        ```
          "name": "todos",
          "version": "0.1.4",
          "license": "MIT",
          "repository": "https://github.com/yourse1f-yourorg/todos",
        ```

    - `./habitat/plan.sh` - must indicate the same version in its field
        -    pkg_version=**0.1.4**

    - `./habitat/release_notes/`**0.1.4**`_note.txt` - is identified by file name only, you can put what you want in it. (_GitHub flavored markup makes it look like there is a space in that file path.  There should not be_)

    - `the argument to the script in the next step` - The same version number as in the previous 3 places must also be supplied as an argument to the script, `./.habitat/BuildAndUpload.sh`  **0.1.4**

    - `latest release number in the local git repo` - must be less than or equal to the one being built

    - `latest release number in GitHub` - must be less than or equal to the one in the local repo

    - `latest version in the Habitat Depot` - must be less than or equal to the one in GitHub

1. *Commit & Push Example Project* :: Finally you must commit your project entirely.  That is: no files remaining to add, no files remaining to commit. Files that need to be in your project, but not under version control must be ignored explicitly by reference in a `.gitignore` file.


1. *Install Habitat Origin Keys* :: There are three possibilities here :

    1. If you have never created any keys then do :

    ```
    sudo hab setup;
    ```

    1. If you have keys stored elsewhere and need to install them :

    ```
    cat ${somewhere}/yourse1f-yourorg-yyyymmddhhmmss.pub | sudo hab origin key import; echo ;
    cat ${somewhere}/yourse1f-yourorg-yyyymmddhhmmss.sig.key | sudo hab origin key import; echo ;
    ```

    1. If you need to replace the keys you got with `sudo hab setup` :

    ```
    STMP=$(hab origin key generate yourse1f-yourorg | tail -n 1);
    export STMP=${STMP%.};
    export TRY="* Generated origin key pair yourse1f-yourorg-";
    export KEY_STAMP=${STMP#${TRY}};
    cat /home/you/.hab/cache/keys/yourse1f-yourorg-${KEY_STAMP}.pub | hab origin key import; echo ;
    cat /home/you/.hab/cache/keys/yourse1f-yourorg-${KEY_STAMP}.sig.key | hab origin key import; echo ;
    ```

1. *Cleanly commit and push the project* :: The next step will balk at continuing if there are any "loose" files in your project directory.  You must have explicitly ignored &/or added, committed **and** pushed, each and every file.

1. *Build Example Project* :: In the root of your app (as before), run `BuildAndUpload.sh`.  For example...
    ```
    ./.habitat/BuildAndUpload.sh 0.1.4
    ```
This step first attempts to catch any lapses in the discipline described in the preceding step, collecting all the discrepancies it can find, listing them on screen with individual explanations and then quitting. Only if everything seems correct will it display a message prompt like this :

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

1. *Upload Example Project* :: If you type `y<enter>` at this point HabitatForMeteor will proceed with the indicated actions.  When it completes, you will find : 
    - a new release created on GitHub : ( eg; Similar to [the releases page of Habitat](https://github.com/habitat-sh/habitat/releases) )
    - a new package published on the Habitat Depot : ( eg; Similar to [this package page of MongoDB](https://app.habitat.sh/#/pkgs/core/mongodb) )

#### Server side operations

With your Meteor application bundled up as a Habitat package and available for download from the Habitat Depot, you are now ready to prepare a server for Habitat supervised deployments.

There are a number of considerations.

The first is that the initialization script will create a new user named `hab` that has ´sudoer´ privileges.  This is done for security reasons, basically to keep it distinct from the user account used by the client.  That account will need to be given an SSH public key for use from its `${HOME}/.ssh/authorized_keys` file.  The `sudo` password for the initial user account will be used once over RPC.  On the other hand, the `sudo` password for the habitat user account will be kept available for future deployments.  For security it will be stored as an `SUDO_ASK_PASS` script in the `hab` user's `${HOME}/.ssh` directory and executable by `hab` exclusively. Passwords are verified to have minimum 8 chars.

1. *Install Remote Host For Habitat* :: The script, `PushInstallerScriptsToTarget.sh` only needs run once, fortunately, because it must be supplied with quite a few arguments. Eg;
    ```
    export TARGET_HOST="meteor_server";
    export TARGET_USER="yourself";
    export SOURCE_SECRETS_FILE="/home/you/projects/todos/.habitat/scripts/target/secrets.sh";
    ./.habitat/scripts/PushInstallerScriptsToTarget.sh ${TARGET_HOST} ${TARGET_USER} ${SOURCE_SECRETS_FILE};
    ```
The required arguments are :

    - TARGET_HOST is the host where the project will be installed.
    - TARGET_USER is a previously prepared 'sudoer' account on '${TARGET_HOST}'. This account will only be used for initial set up, during whicha new account called ´hab´ will be created for all subsequently access.
    - SOURCE_SECRETS_FILE holds user and connections secrets to be installed server side. An example secrets file can be found at [HabitatForMeteor / habitat / scripts / target /secrets.sh.example](https://github.com/your0rg/HabitatForMeteor/blob/master/habitat/scripts/target/secrets.sh.example)

1. ** ::

### Contributing

The main contribution we look for at the moment is alpha testing.  Spin up a pair of Ubuntu 16.04 flavored machines and follow the instructions.  Post an issue if you hit a snag or ambiguity in the instructions.

#### Stuff missing

1. *Staging*: We need a way to structure pushing to different servers.  Right now it is development direct to production.

1. *Continuous Integration*: In any project, with or without HabitatFor Meteor, each normal commit should fire off a rebuild in a CI server.  Commits which add a new release note should activate HabitatForMeteor to build and test in a staging server.


#### Typical development REPL loop ( my usage ) 

##### Tools Directory

    cd ~/tools/HabitatForMeteor/
    ./Update_or_Install_H4M_into_Meteor_App.sh ../../projects/todos/
    ./run_on_save.sh ./habitat/BuildAndUpload.sh ./Update_or_Install_H4M_into_Meteor_App.sh ../../projects/todos


##### Application Directory

    cd ~/projects/todos
    ./.habitat/scripts/Update_or_Install_Dependencies.sh;
    ../../tools/HabitatForMeteor/run_on_save.sh .habitat/BuildAndUpload.sh .habitat/BuildAndUpload.sh 

