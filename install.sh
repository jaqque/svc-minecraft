#!/bin/bash

# Install the Minecraft server supervision scripts to the
# requested location, and set up reasonable defaults

# The lazy can just run out of the "files" directory. Symlink "server.jar" to
# the actual Minecraft server jar (or copy it in), cd files, ./run

# defaults
force=0;   # check for errors
quiet=0;   # display warnings
verbose=0; # supress excessive verbiage

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

if [[ $1 ]]; then
   echo
   echo "E: $*"
fi

}

if [ -z "$1" ]; then
   help
   exit 1
fi

# looks like passing "option=" will pass validation, but likely
# cause problems later. Caveat emptor.
while [[ "$1" == -* ]]; do
   case "$1" in

      -h|--help) help; exit 0 ;;
      -f|--force) force=1; shift; ;;
      -i|--interactive) interactive=1; shift ;;
      -q|--quiet) verbose=0; quiet=1; shift ;;
      -v|--verbose) verbose=1; quiet=0; shift ;;

      -I|--ip) if [[ -z $2 ]]; then help "$1 requires an address (eg: 0.0.0.0)"; exit 1; fi
        ip=$2; shift 2 ;;
      --ip=*) ip=${1#*=}; shift ;;

      -j|--java) if [[ -z $2 ]]; then help "$1 requires a path to java (eg: /usr/bin/java)"; exit 1; fi
         java=$2; shift 2 ;;
      --java=*) java=${1#*=}; shift ;;

      -m|--motd) if [[ -z $2 ]]; then help "$1 requires an argument (eg: \"A Minecraft Server\")"; exit 1; fi
         motd=$2; shift 2 ;;
      --motd=*) motd=${1#*=}; shift ;;

      -P|--png) if [[ -z $2 ]]; then help "$1 requires an argument (eg: server-icon.png)"; exit 1; fi
         png=$2; shift 2 ;;
      --png=*) png=${1#*=}; shift ;;

      -p|--port) if [[ -z $2 ]]; then help "$1 requires a port (eg: 25565)"; exit 1; fi
         port=$2; shift 2 ;;
      --port=*) port=${1#*=}; shift ;;

      -r|--ram) if [[ -z $2 ]]; then help "$1 requires a size (eg: 1024M)"; exit 1; fi
         ram=$2; shift 2 ;;
      --ram=*) ram=${1#*=}; shift ;;

      -u|--user) if [[ -z $2 ]]; then help "$1 requires an account (eg: minecraft)"; exit 1; fi
         user=$2; shift 2 ;;
      --user=*) user=${1#*=}; shift ;;

      -w|--world) if [[ -z $2 ]]; then help "$1 requires an argument (eg: world)"; exit 1; fi
         world=$2; shift 2 ;;
      --world=*) world=${1#*=}; shift ;;

      --) shift; break ;;
      *) help "$1: unrecognized option"; exit 1 ;;
   esac
done

