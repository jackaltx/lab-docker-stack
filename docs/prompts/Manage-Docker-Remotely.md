# These are a collection of thoughts

We are still in the building phase. Because this is a "template in place" built for developers
I will need to be carefull to not "pollute" the repo.  The .env.global file is the glue to deployment (for now)

Because I am using "dns" to expose services behind traefik and creating isolated virtual networks, the traefik
config is going to need some "templating". I think best to pull all the "access" names in the DOMAIN and put them
in .env.global for the "sync-env" step.  

# When I ask you to install another docker compose unit  

Use the Project, Stacks and Secrets folders under a root.  User neets to specify that root.
This is about managing docker. if the user needs other folders, that is up to them after the docker compose
environment is created.

Ask if I (user) want use a remote host.  if yes, then ask how should you connect and what the how you can edit.  

## Remote host methods

There models I use, we will build these over time

1. I mount the drive on a development machine as a share and you edit locally.  then you can ssh in with a 'docker' user or passwordless-sudo. Truenas is an example where I need the apps:apps id's for the Project and Stacks (initialy)

2. Everything is remote and accessable via ssh with a docker user. Test if it is passwordless-sudo user.

3. TMUX panes.  You will be running in one pane and the other will be on the target host.

## Considerations for remote

1. permissions can be tricky on remote and we all make mistakes.  Ensure a shared vision of ID usage.

# Steps to creation

1. Look for the official containers and an example compose file. Try to use the latest version.
2. offer to create a Secrets env file with.

# Steps to deployment

1. review for any required Stack folders and create them
2. remote deploys can go poorly due to permission
3. inspect containers status and logs.
3. if it comes up good
    - Create a terse Build document outlining what was done.
    - If aske to audit create a terse audit docment
4. if bad, ask before fixing. make sure to keep history so we can backup.

# Things to audit

1. remote file permissions in the deployment stack after startup.  If the container changes ownership of the stack, document it.
2. bad thing in log.
