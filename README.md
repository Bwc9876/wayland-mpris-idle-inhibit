# wayland-mpris-idle-inhibit

Uses the
[idle-inhibit-unstable-v1](https://wayland.app/protocols/idle-inhibit-unstable-v1)
Wayland protocol in order to inhibit the idle behavior of the compositor when a
media player is playing.

## Usage

1. Add the flake to your flake inputs (other packaging formats just uh build it
   yourself idk)
2. Add the package to your environment.systemPackages
3. Call the command, once you know which options you like best (see below), you
   can add it to your compositor's config.

Ex for Hyprland:

```
exec-once = "wayland-mpris-idle-inhibit"
```

Now whenever a player is playing media the program will inhibit the compositor's
idle (e.g. hypridle), and will resume idle when the player is stopped or paused.

### Note for KDE Connect

You probably still want your PC to fall asleep if your phone is playing media,
so you can add these two options to the command call to make it ignore
kdeconnect when scanning for active players:

```
--ignore=kdeconnect --ignore=playerctld
```

The `playerctld` part is because for some reason playing media through
kdeconnect registers _two_ players, one with the right name and one with
playerctld.

## Options

- `--poll-interval <interval>`: The interval in seconds at which the program
  will poll MPRIS for player information, default is `10`
- `--ignore <name>`: A player name to ignore. This name is the part of the
  `org.mpris.MediaPlayer2` interface name after the `org.mpris.MediaPlayer2.`
  prefix. For example, for `org.mpris.MediaPlayer2.vlc`, the name is `vlc`. This
  option can be specified multiple times.
- `--verbose`: Verbosity of output, can be 0 = silent, 1 = info, 2 = debug
  (defaults to 1)
- `--help`: Print help message
- `--version`: Print version information

## Inspiration

This project was inspired by
[wayland-pipewire-idle-inhibit](https://github.com/rafaelrc7/wayland-pipewire-idle-inhibit).
Which does the same thing but for PipeWire audio streams. It is also a lot more
feature rich than this project.
