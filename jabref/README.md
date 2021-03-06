# JabRef <-> remote sync

## Requirements:

* Remote storage 
* inotify-tools [https://github.com/inotify-tools/inotify-tools/wiki](https://github.com/inotify-tools/inotify-tools/wiki)
* rclone ([https://rclone.org/](https://rclone.org/)) configured to use said remote storage

Script achieves the following:

* synchronises local JabRef data with remote storage
* so that your iPad/iOS table/device which you're primarily using as an eReader with:
    - a Bib(la)Tex reference manager app
* isn't missing any data between your \*nix desktop and iPad/iOS tablet/device.

Yes, this is only a problem because you (I) are step-toe'ing around the actual problem of using a \*nix desktop which isn't MacOS and Apple not allowing synchronisation between the two because of their business model. You get what you pay for...

* Place it in your `~/.local/bin` & `chmod +x` that sht. You know what you're doing.
* Setup the Systemd service:
    - update the home/user path in the service unit file to reflect yours
    - `systemctl --user enable /path/to/where/you/have/jabrefremotesync.service`
    - `systemctl --user start jabrefremotesync.service`
    - test all is working: `journalctl --user -f -u jabrefremotesync.service`

## References:

1. [inotifywait](https://linux.die.net/man/1/inotifywait)
2. [inotify](https://www.kernel.org/doc/html/latest/filesystems/inotify.html)
