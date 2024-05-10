mod wayland;

use anyhow::{Context, Result as _Result};
use clap::Parser;
use log::{debug, error, info};
use mpris::{FindingError, PlayerFinder};

use crate::wayland::WaylandClient;

type Result<T = ()> = _Result<T>;

#[derive(Parser)]
#[clap(
    name = "wayland-mpris-idle-inhibit",
    about = "Inhibit idle when MPRIS player is active",
    version,
    author
)]
struct Cli {
    #[clap(
        short,
        long,
        help = "Verbosity of output, can be 0 = silent, 1 = info, 2 = debug (defaults to 1)"
    )]
    verbose: Option<u64>,
    #[clap(
        short,
        long,
        help = "How many seconds to wait between checks (defaults to 10)"
    )]
    poll_interval: Option<u64>,
    #[clap(
        short,
        long,
        help = "List of player names to ignore, this is the name part of the player's bus name. e.g. 'org.mpris.MediaPlayer2.spotify' would be 'spotify'"
    )]
    ignore: Vec<String>,
}

const NO_PLAYER_TEXT: &str = "No player is being controlled by playerctld";

fn check_mpris(ignore_list: &[String]) -> Result<bool> {
    let finder = PlayerFinder::new().context("Couldn't open player finder")?;
    let active = match finder.find_all() {
        Ok(player) => Ok(Some(player)),
        Err(FindingError::NoPlayerFound) => Ok(None),
        Err(FindingError::DBusError(e)) => {
            if e.to_string().contains(NO_PLAYER_TEXT) {
                Ok(None)
            } else {
                Err(e)
            }
        }
    }
    .context("D-Bus error when trying to find active player")?;

    if let Some(players) = active {
        Ok(players.iter().any(|player| {
            let id = player.identity();
            match player.get_playback_status() {
                Ok(status) => {
                    let player_name = player.bus_name_player_name_part().to_string();
                    let is_playing = status == mpris::PlaybackStatus::Playing && !ignore_list.contains(&player_name);
                    debug!(
                        "Player \"{id}\":\nStatus: {status:?}\nBus name (player part): \"{player_name}\"\nConsidered playing: {is_playing}"
                    );
                    is_playing
                }
                Err(_) => {
                    error!("Error getting playback status for player \"{id}\", ignoring");
                    false
                }
            }
        }))
    } else {
        Ok(false)
    }
}

fn main() -> Result {
    let cli = Cli::parse();

    let log_level = match cli.verbose {
        Some(0) => log::LevelFilter::Off,
        Some(1) => log::LevelFilter::Info,
        Some(2) => log::LevelFilter::Debug,
        _ => {
            if cfg!(debug_assertions) {
                log::LevelFilter::Debug
            } else {
                log::LevelFilter::Info
            }
        }
    };

    colog::default_builder().filter_level(log_level).init();

    let poll_interval = cli.poll_interval.unwrap_or(10);

    debug!("Setting Up");

    let ignore = cli
        .ignore
        .into_iter()
        .map(|s| s.to_lowercase())
        .collect::<Vec<_>>();
    let mut wayland_client = WaylandClient::new().context("Failed to initialize Wayland client")?;

    info!("Watching for MPRIS Changes...");

    let mut current_status = false;

    loop {
        match check_mpris(&ignore) {
            Ok(playing) => {
                debug!("MPRIS status: {playing}");
                if playing != current_status {
                    info!("MPRIS status changed: {playing}");
                    wayland_client
                        .set_inhibit_idle(playing)
                        .context("Failed to set idle inhibitor status")?;
                    current_status = playing;
                }
            }
            Err(e) => error!("Error getting MPRIS status: {e:?}"),
        }

        std::thread::sleep(std::time::Duration::from_secs(poll_interval));
    }
}
