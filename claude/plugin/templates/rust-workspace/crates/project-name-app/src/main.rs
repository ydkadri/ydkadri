//! Binary entry point: tracing setup, argument handling and output only.

mod compose;
mod output;

use anyhow::Context;
use tracing::debug;
use tracing_subscriber::{
    EnvFilter, Layer, filter::LevelFilter, layer::SubscriberExt, util::SubscriberInitExt,
};

/// Install the global tracing subscriber, honouring `RUST_LOG`.
fn init_tracing() -> anyhow::Result<()> {
    let filter = EnvFilter::builder()
        .with_default_directive(LevelFilter::INFO.into())
        .from_env_lossy();
    let fmt_layer = tracing_subscriber::fmt::layer()
        .with_writer(std::io::stderr)
        .with_filter(filter);
    tracing_subscriber::registry()
        .with(fmt_layer)
        .try_init()
        .context("failed to initialise tracing")
}

fn main() -> anyhow::Result<()> {
    init_tracing()?;
    let title = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "first note".to_owned());
    debug!(%title, "adding note");
    for line in compose::run(&title)? {
        output::line(&line);
    }
    Ok(())
}
