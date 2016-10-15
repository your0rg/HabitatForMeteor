# HabitatForMeteor
A Habitat packager for Meteor DevOps

Until, now there have been two main choices for deploying Meteor applications :

1. `Galaxy`, is an option for those with the money and a direct say in infrastructure decisions.
1. `mup` is a single purpose hack for small budget operations.

HabitatForMeteor is for everyone else.

If you take DevOps seriously, you know about [Chef](https://www.chef.io/chef), and very likely automate your infrastructure with it already.

[Chef Habitat](https://www.habitat.sh/) is their new product, dedicated to standardizing deployment of any and all server-side applications.

Building on that, HabitatForMeteor...

1. Sets up your development machine with the tools to wrap you Meteor application into a Habitat deployment package.
2. Sets up a remote host with the Habitat deployment environment.
3. Provides a single command to build a deployment package and publish it to a Habitat Depot.
4. Provides a single command to pull a deployment package from a depot and deploy it to your remote host, **along with MongoDB, NodeJS, Nginx and the necessary connections between them**.

This is an alpha stage project, and Habitat itself is early beta, so please expect some teething pains.

So far, HabitatForMeteor has only been developed and tested on pairs of Xubuntu Xenial Xerus virtual machines.  In the spirit of "release early, release often", the focus has been on ensuring easy accessibility for anyone willing to set up such an environment and give it a whirl.

### Complexity

Habitat4Meteor has a lot of moving parts because it interacts with a number of different services :

* pulls Habitat and Meteor and installs them on your development machine if necessary
* builds your Meteor applications
* assembles your Meteor Node packages into Habitat packages
* adjusts your applications' version numbering and creates releases in GitHub
* connects by RPC to your remote host to prepare Habitat with its own user 'sudoer' account
* connects by RPC to your remote host to create a `systemd` unit file for boot-time &/or manual launch of your application

![Habitat For Meteor](https://docs.google.com/drawings/d/19HVhiUMscFOl4vGXtzgbcbGn8rcltuxkBuRa6YrxiZk/edit?usp=sharing)

### Getting started

#### The first steps

1. Prepare two Xubuntu Xenial Xerus virtual machines and give them distinct names that suggest developer machine and target server (`dev` & `srv`).  Set up their hosts files so the developer (`dev`) machine can address the server (`srv`) machine by name. After a while, you should be able to use the Xubuntu desktop on the developer VM only, without turning to the server machine desktop, such that the target VM can be an Ubuntu server install rather than Xubuntu.

2. Ensure that both machines are fully SSH enabled, including being able to SSH & SCP from dev machine without password. 

3. Fork the Meteor sample project, [todos](https://github.com/meteor/todos), and clone it into you machine.

4. Fork this repo [HabitatForMeteor](https://github.com/your0rg/HabitatForMeteor)
