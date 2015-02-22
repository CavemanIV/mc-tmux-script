# mc-tmux-script
My generic minecraft server management script

Surely you can use start-stop-daemon or supervisord to provide process monitor/restart functionality, but I use centos and I'd like to run some command through tmux.

TODO:
* Add user() function to make it a usable init.d rather than simple script
* Add Crontab
** Add poke for check and start
** Add Crantab
* Make it a generic tmux wrapper for daemon management
