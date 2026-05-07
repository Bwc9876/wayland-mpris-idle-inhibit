use crate::Result;
use anyhow::Context;
use log::warn;
use zbus::{blocking::Connection, proxy};

#[proxy(
    interface = "org.freedesktop.ScreenSaver",
    default_service = "org.freedesktop.ScreenSaver",
    default_path = "/ScreenSaver"
)]
trait ScreenSaver {
    fn Inhibit(&self, application_name: &str, reason_for_inhibit: &str) -> zbus::Result<u32>;

    #[zbus(no_reply)]
    fn UnInhibit(&self, cookie: u32) -> zbus::Result<()>;
}

pub struct DbusClient<'a> {
    _conn: Connection,
    proxy: ScreenSaverProxyBlocking<'a>,
    cookie: Option<u32>,
}

impl<'a> DbusClient<'a> {
    pub fn new() -> Result<Self> {
        let conn = Connection::session().context("While creating DBUS connection")?;
        let proxy = ScreenSaverProxyBlocking::new(&conn)
            .context("While initializing proxy to org.freedesktop.ScreenSaver")?;

        Ok(Self {
            _conn: conn,
            proxy,
            cookie: None,
        })
    }
}

impl DbusClient<'_> {
    pub fn toggle(&mut self, playing: bool) -> Result {
        if playing {
            if let Some(old_cookie) = self.cookie.take() {
                warn!("Trying to inhibit but still have an old cookie");
                if let Err(why) = self.proxy.UnInhibit(old_cookie) {
                    warn!("Failed to uninhibit with old cookie ({why:?}), ignoring...");
                }
            }
            let cookie = self
                .proxy
                .Inhibit(
                    "wayland-mpris-idle-inhibit",
                    "An MPRIS player is playing media",
                )
                .context("While inhibiting")?;
            self.cookie = Some(cookie);
            Ok(())
        } else if let Some(cookie) = self.cookie.take() {
            self.proxy.UnInhibit(cookie).context("While uninhibiting")
        } else {
            warn!("Tried to uninhibit but don't have an old cookie, ignoring...");
            Ok(())
        }
    }
}
