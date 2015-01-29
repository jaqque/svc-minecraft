NOTES
=====

TODO
----

Steps to Master:

* [X] files/run functional
   * [X] read in ENV variables (envdir)
* [X] files/log/run functional
* [ ] install.sh functional
* [ ] installation documentation

### Optional, but Nice to Have

* [ ] Full Documentation
* [ ] Helper scripts (op, ban, jail, give items, etc)
* [ ] Ability to install to existing Minecraft server

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
* `--eula=yes` eula (default: blank)
   https://account.mojang.com/documents/minecraft_eula
* `-m|--motd` motd (default: minecraft default (A Minecraft Server))
* `-r|--ram` initial / maximum ram (default: minecraft default (512kB? i
   dunno)) [idea: default 1 GB; sounds reasonable]
* `-f|--force` override checks for existing directory, existant java and server.jar
* `-P|--png` path to image to use for server-icon.png (check/force dimenstions?)
* `-u|--user` user to install as (default: current, if UID != root; minecraft
   if UID = root)


If you really want Xms and Xmm to be different, specify the values in JAVA_OPTS and
ignore RAM.

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

Server on Demand
----------------

In order to have a server start only upon login instead of at ping, a
minimal server would have to be created. This is way beyond the scope
of this project at this time.

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
* `FIFO=` name of named pipe

server.properties
-----------------

Testing shows that missing items in `server.properties` will get added when the
server starts. This means we can pre-supply certain information and everything
else will get filled in with (reasonable) defaults.
