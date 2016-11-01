# HabitatForMeteor

#### TL;DR

Use Chef Habitat for Meteor app deployment.  Bundle up your app with all the necessary installation and configuration instructions, get similar bundles for MongoDB and NGinx, define them as a single logical unit with their connections parameters and then launch the unit automatically at boot-time as a single entity.  Manage remotely using Habitat's supervisory tools.

## A Habitat packager for Meteor DevOps

Until, now there have been two main choices for deploying Meteor applications :

1. `Galaxy`, is an option for those with the money and a direct say in infrastructure decisions.
1. `mup`, is a single purpose hack for small budget operations.

HabitatForMeteor is for everyone else.

If you take DevOps seriously, you know about [Chef](https://www.chef.io/chef), and very likely automate your infrastructure with it already.

[Chef Habitat](https://www.habitat.sh/) is their new product, dedicated to standardizing deployment of any and all server-side applications.  Habitat understands very large installations and offers powerful capabilities for managing multiple logical groupings of services.  One specialized supervisor is the `Director` which permits launching a logical group of services, in a single machine, as though they are a single unit.

Production Meteor applications need MongoDB, NodeJS and NGinx in order to run.  By using Habitat, we can bundle up the Node package of our application with all the instructions necessary to run it in NodeJS and connect it to MongoDB.  Habitat makes available similar bundles for MongoDB and NGinx.  We can define an outer "Director" bundle that includes all three together as a logical unit that launches at boot-time via `systemd` and can be reconfigured remotely using Habitat's management tools.

Controlling your live applications' infrastructure begins to look a lot like, and not much harder, than the package management you do within your Meteor apps.

Briefly, HabitatForMeteor...

1. Sets up your development machine with the tools to wrap you Meteor application into a Habitat deployment package.
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

![Habitat For Meteor](https://docs.google.com/drawings/d/19HVhiUMscFOl4vGXtzgbcbGn8rcltuxkBuRa6YrxiZk/pub?w=960&h=720)

### Getting started

#### Client side preparations

1. *Prepare Virtual Machines* :: Prepare two Xubuntu Xenial Xerus virtual machines with at least 12G disk space and give them distinct names that suggest developer machine and target server (eg; `dev` & `srv`).  Set up their `hosts` files so the developer (`dev`) machine can address the server (`srv`) machine by name. After a while, you should be able to use the Xubuntu desktop on the developer VM only, without turning to the server machine desktop, such that the target VM can be an Ubuntu server install rather than Xubuntu.

1. *Prepare Secure Shell* :: Ensure that both machines are fully SSH enabled, including being able to SSH & SCP from dev machine without password.

1. *Get Example Project* :: Fork the Meteor sample project, [todos](https://github.com/meteor/todos), and clone it into your machine as, for example, `${HOME}/projects/todos`.  Make sure you get to the point of having an issues free build and local execution.  Recently, (Meteor 1.4.2, Oct 2016) I had to do : 

    #
    # Optimize file chnage responsivity
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    #
    # Install all NodeJS packages dependencies
    meteor npm install
    #
    # Also install the one that change since the last release of 'meteor/todos'
    meteor npm install --save bcrypt
    #
    # Start it up, look for any other issues and test on URL :: [localhost:3000](http://localhost:3000/).
    meteor

1. *Get Habitat For Meteor* :: Fork this repo [HabitatForMeteor](https://github.com/your0rg/HabitatForMeteor) as, for example, `${HOME}/tools/HabitatForMeteor`.

1. *Prepare Example Project* :: Run `Update_or_Install_H4M_into_Meteor_App.sh`, for first time use, or if there are updates.
Eg; ```./Update_or_Install_H4M_into_Meteor_App.sh ../../projects/todos;```
This script will insert HabitatForMeteor into a hidden directory `.habitat` in your project, with suitable `.gitignore` files.  It will `git add` a few files to your version control, but not commit them.

1. *Initialize Example Project* :: Switch to the root of your app ( same level as the `.meteor` dir ) and run `./.habitat/scripts/Update_or_Install_Dependencies.sh;`  This script will perform some sanity checks on the `.habitat` directory of your app, updating &/or installing as necessary:  ensures non-varying files are ignored by `git`, adds the varying files to your git repo, reminds that a Meteor installation is required ( this won't be automated ), installs Habitat and installs dependencies like `jq`and `semver`.  The script prompts for several constants that need to be set in order that you get the correct version of Habitat. It records these values in `${HOME}/.userVars.sh`.  One required constant is a GitHub token, to be used to interact with Habitat's package depot.  The token gives visibility only to GitHub email addresses. ( Refer to, [Setting up hab to authenticate to the depot](https://www.habitat.sh/docs/share-packages-overview/) )

1. *Tag Example Project Version* :: The point of using Habitat is ease of deployment, but deployment needs to be a controlled process.  There are several places where the version number is specified and they must all agree.  The next step will fail if their is disagreement or if somehow downstream ( git repo ) version numbers are greater than the current release.  Additional, intentionally redundant meta information is also required.  The complete list is:
    - `./package.json` - must have four additional fields not Supplied by MDG :
        -   "name": "todos",
        -   "version": "**0.1.4**",
        -   "license": "MIT",
        -   "repository": "https://github.com/yourOrg/todos",

    - `./habitat/plan.sh` - must indicate the same version in
        -    pkg_version=**0.1.4**

    - `./habitat/release_notes/`**0.1.4**`_note.txt` - is identified by file name only, you can put what you want in it. (_GitHub flavored markup makes it look like there is a space in that file path.  There should not be_)

    - `the argument to the script in the next step` - The same version number as in the previous 3 places must also be supplied as an argument to the script, `./.habitat/BuildAndUpload.sh`  **0.1.4**

    - `latest release number in the local git repo` - must be less than or equal to the one being built

    - `latest release number in GitHub` - must be less than or equal to the one in the local repo

    - `latest version in the Habitat Depot` - must be less than or equal to the one in the GitHub (BUG : verifying that one is not implemented yet)

1. *Commit & Push Example Project* :: Finally you must commit your project entirely.  That is: no files remaining to add, no files remaining to commit. Files that need to be in your project, but not under version control must be ignored explicitly by reference in a `.gitignore` file.


1. *Build Example Project* :: In the root of your app (as before), run `BuildAndUpload.sh`.
Eg; `./.habitat/BuildAndUpload.sh 0.1.4`
This step first attempts to catch any lapses in the discipline described in the preceding step.  It collects all the discrepancies it can find, lists them on screen with individual explanations and then quits. If everything seems correct it will display a message prompt like this :

    ```
            *** Please confirm the following ***

       -->  Previous deployed application revision tag : 0.1.4
       -->          Most recent previous local Git tag : 0.1.3-1-g5457468
       -->         Most recent previous remote Git tag : 0.1.3
       -->                   Specified new release tag : 0.1.4

            *** If you proceed now, you will ***
      1) Set Habitat package plan revision number to 0.1.4
      2) Push the Habitat package to the Habitat public depot as :
               yourOrg / todos
               0.1.4 / 20161017111516
      3) Set the project metadata revision number to 0.1.4
      4) Commit all uncommitted app changes (not including untracked files!)
      5) Tag the commit and push all to the remote repository

      Proceed? [y/N]
    ```

1. *Upload Example Project* :: If you type `y<enter>` at this point HabitatForMeteor will proceed with the indicated actions.  When it completes, you will find : 
    - a new release created on GitHub : ( eg; Similar to [the releases page of Habitat](https://github.com/habitat-sh/habitat/releases) )
    - a new package published on the Habitat Depot : ( eg; Similar to [the package page of MongoDB](https://app.habitat.sh/#/pkgs/core/mongodb) )

#### Server side operations

With your Meteor application bundled up as a Habitat package and available for download from the Habitat Depot, you are now ready to prepare a server for Habitat supervised deployments.

There are a number of considerations.

The first is that the initialization script will create a new user named `hab` that has ´sudoer´ privileges.  This is done for security reasons, basically to keep it distinct from the user account used by the client.  That account will need to be given an SSH public key for use from its `${HOME}/.ssh/authorized_keys` file.  The `sudo` password for the initial user account will be used once over RPC.  On the other hand, the `sudo` password for the habitat user account will be kept available for future deployments.  For security it will be stored as an `SUDO_ASK_PASS` script in the `hab` user's `${HOME}/.ssh` directory and executable by `hab` exclusively. Passwords are verified to have minimum 8 chars.

1. *Install Remote Host For Habitat* :: The script, `PushInstallerScriptsToTarget.sh` only needs run once, fortunately, because it must be supplied with quite a few arguments. Eg;
```./.habitat/scripts/PushInstallerScriptsToTarget.sh habtrg yourself yourpassword ${HOME}/.ssh/habitat/habpwdfile ${HOME}/.ssh/id_rsa.pub``` The required arguments are :

    - TARGET_SERVER is the host where the project will be installed.
    - TARGET_USER is a previously prepared 'sudoer' account on '${TARGET_HOST}'. This account will only be used for initial set up, during whicha new account called ´hab´ will be created for all subsequently access.
    - TARGET_USER_PWD is required for 'sudo' operations by '${TARGET_USER}' account. This is the password the aforementioned user must supply before performing `sudo` operations.
    - HABITAT_USER_PWD_FILE_PATH points to a file containing the password for the Habitat user, which will be created,
    - HABITAT_USER_SSH_KEY_PATH  points to a file containing a SSH key to be used for future deployments.
    - RELEASE_TAG is the release to be installed on ${TARGET_HOST}.


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

