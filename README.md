# HabitatForMeteor
## A Habitat packager for Meteor DevOps

Until, now there have been two main choices for deploying Meteor applications :

1. `Galaxy`, is an option for those with the money and a direct say in infrastructure decisions.
1. `mup`, is a single purpose hack for small budget operations.

HabitatForMeteor is for everyone else.

If you take DevOps seriously, you know about [Chef](https://www.chef.io/chef), and very likely automate your infrastructure with it already.

[Chef Habitat](https://www.habitat.sh/) is their new product, dedicated to standardizing deployment of any and all server-side applications.

Building on that, HabitatForMeteor...

1. Sets up your development machine with the tools to wrap you Meteor application into a Habitat deployment package.
2. Sets up a remote host with the Habitat deployment environment.
3. Provides a single command to build a deployment package and publish it to a Habitat Depot.
4. Provides a single command to pull a deployment package from a depot and deploy it to your remote host, *along with MongoDB, NodeJS, Nginx and the necessary connections between them*.

## Caution

This is an alpha stage project, and Habitat itself is early beta, so please expect some teething pains.

So far, HabitatForMeteor has only been developed and tested on pairs of Xubuntu Xenial Xerus virtual machines.  In the spirit of "release early, release often", the focus has been on ensuring easy accessibility for anyone willing to set up such an environment and give it a whirl.

Also, this is a "feeler" project to see if there is much community interest.  I have used BASH shell scripting throughout.  If there is broader interest, (among Windows server users, particularly, for example), I'd rewrite in a more accessible language.  Since this is a Meteor project, using Node on the client might make sense.  For the server-side Python would be the most accessible, while Rust would be the coolest, and compatible with Habitat itself.

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

#### The first steps

1. Prepare two Xubuntu Xenial Xerus virtual machines and give them distinct names that suggest developer machine and target server (`dev` & `srv`).  Set up their hosts files so the developer (`dev`) machine can address the server (`srv`) machine by name. After a while, you should be able to use the Xubuntu desktop on the developer VM only, without turning to the server machine desktop, such that the target VM can be an Ubuntu server install rather than Xubuntu.

1. Ensure that both machines are fully SSH enabled, including being able to SSH & SCP from dev machine without password.

1. Fork the Meteor sample project, [todos](https://github.com/meteor/todos), and clone it into you machine into, for example, ${HOME}/projects.

1. Fork this repo [HabitatForMeteor](https://github.com/your0rg/HabitatForMeteor) into, for example, ${HOME}/tools.

1. Run `Update_or_Install_H4M_into_Meteor_App.sh ${ path of your app };`, for first time use, and if there are updates. This script will insert HabitatForMeteor into a hidden directory `.habitat` in your project, with suitable `.gitignore` files.  Only a few files will need to be added under version control.

1. Switch to the root of your app ( same level as the `.meteor` dir ) and run `./.habitat/scripts/Update_or_Install_Dependencies.sh;`  This script will perform some sanity checks on the `.habitat` directory of your app, updating &/or installing as necessary:  ensures non-varying files are ignored by `git`, adds the varying files to your git repo, reminds that a Meteor installation is required ( this won't be automated ), installs Habitat and installs dependencies like `jq`and `semver`.  The script prompts for several constants that need to be set in order that you get the correct version of Habitat. It records these values in `${HOME}/.userVars.sh`.  One required constant is a GitHub token, to be used to interact with Habitat's package depot.  The token gives visibility only to GitHub email addresses. ( Refer to, [Setting up hab to authenticate to the depot](https://www.habitat.sh/docs/share-packages-overview/) )


### Contributing

The main contribution we look for at the mopment is alpha testing.  Spin up a pair of Ubuntu 16.04 flavored machines and follow the instructions.  Post an issue if you hit a snag or ambiguity in the instructions.

#### Stuff missing

1. *Staging*: We need a way to structure pushing to different servers.  Right now it is development direct to production.

1. *Continuous Integration*: In any project, with or without HabitatFor Meteor, each normal commit should fire off a rebuild in a CI server.  Commits which add a new release note should activate HabitatForMeteor to build and test in a staging server.
2. 