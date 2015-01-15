#!/bin/sh

# Install the Minecraft server supervision scripts to the
# requested location, and set up reasonable defaults

# The lazy can just run out of the "files" directory. Symlink "server.jar" to
# the actual Minecraft server jar (or copy it in), cd files, ./run


help() {
   # this format loosely based upon GNU coreutils 8.23 --help format

   cat <<EOF
Usage: install.sh [OPTION]... DIRECTORY
Installs the Minecraft server supervision files to DIRECTORY

Mandatory arguments to long options are mandatory for short options too.

  -f, --force         Overrides sanity checks
  -h, --help          This help
  -i, --interactive   Uses question/answer to install
  -I, --ip=IP         Binds Minecraft server to IP
  -j, --jar=SERVER    Uses SERVER as server.jar 
  -J, --java=JVM      Use JVM
  -m, --motd=MOTD     Assigns MOTD to motd
  -P, --png=IMAGE     Symlinks IMAGE to server-icon.png
  -p, --port=PORT     Binds Minecraft server to PORT
  -q, --quiet         Supresses warnings
  -r, --RAM=SIZE      Allocats SIZE to server at start
  -u, --user=ACCOUNT  Changes to ACCOUNT prior to installing / starting
  -w, --world=WORLD   Assigns WORLD to level-name
  -v, --verbose       Increases verbosity
  --eula=yes          Accept the EULA
                        https://account.mojang.com/documents/minecraft_eula
EOF
}

if [ -z "$1" ]; then
   help
   exit 1
fi
