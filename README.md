# wayland-mpris-idle-inhibit

Uses the [idle-inhibit-unstable-v1](https://wayland.app/protocols/idle-inhibit-unstable-v1) Wayland protocol in order
to inhibit the idle behavior of the compositor when a media player is playing.

## Options

- `--poll-interval <interval>`: The interval in seconds at which the program will poll MPRIS for player information
- `--ignore <name>`: A player name to ignore. This name is the part of the
  `org.mpris.MediaPlayer2` interface name after the `org.mpris.MediaPlayer2.` prefix. For example, for
  `org.mpris.MediaPlayer2.vlc`, the name is `vlc`. This option can be specified multiple times.
- `--verbose`: Verbosity of output, can be 0 = silent, 1 = info, 2 = debug (defaults to 1)
- `--help`: Print help message
- `--version`: Print version information

## Inspiration

This project was inspired by [wayland-pipewire-idle-inhibit](https://github.com/rafaelrc7/wayland-pipewire-idle-inhibit). Which does the same thing but for PipeWire audio streams. It is also a lot more feature rich than this project.
