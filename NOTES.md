NOTES
=====

TODO
----

Steps to Master:

* [ ] files/run functional
* [ ] files/log/run functional
* [ ] install.sh functional

Install
-------

Either `./install.sh` or `make install` (`make install` can call `./install.sh`)
`./install.sh -i` for interactive interview (things like eula)

`./install.sh [options] </path/to/install>`

* target directory
* `-j|--jar` path to server.jar (search for it ???) (symlink to actual jar)
* `-J|--java` path to java (default: whatever is in $PATH)
* `-p|--port` port to run on (default: minecraft default (25565))
* `-I|--ip` IP to bind to (default: minecraft default (0.0.0.0))
* `-w|--world` level name (default: minecraft default (world))
* `--eula=yes` eula (default: blank) https://account.mojang.com/documents/minecraft_eula
* `-m|--motd` motd (default: minecraft default (A Minecraft Server))
* `-r|--ram` initial / maximum ram (default: minecraft default (512kB? i dunno))
  [idea: default 1 GB; sounds reasonable]
* `-f|--force` override checks for existing directory, existant java and server.jar

Dependencies
------------

* daemontools
* java
* minecraft server.jar

Logs
----

* keeping 999999 logs, currently.
* gzip then when rotating? Minecraft itself does this
* logs are duplicated. Is this a real problem?

Readproctitle
-------------

* Display players in ps ?

envdir
------

`env - envdir envdir env` will display all the environmental variables defined in envdir

Problem: any empty file removes the variable; any file with an initial blank
line prints var=; neither of which are suitable for passing a "server" or
"nogui" option.

* `JAVA=` as path to java executable
* `SERVER=` as path to minecraft.jar (instead of symlink ?)
* `JAVA_OPTS=` as additional opstions (nogui, server, -d64, etc)
* `RAM=` allocated RAM (-Xms and -Xmx)

server.properties
-----------------

Testing shows that missing items in `server.properties` will get added when the
server starts. This means we can pre-supply certain information and everything
else will get filled in with (reasonable) defaults.