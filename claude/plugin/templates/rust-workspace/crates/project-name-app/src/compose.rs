//! Composition root: the one place that picks concrete adapters for ports.

use anyhow::Context;
use project_name_adapters::InMemoryNotes;
use project_name_core::{StoresNotes, add_note};

/// Wire the in-memory adapter into the core, add one note and render the store.
pub(crate) fn run(title: &str) -> anyhow::Result<Vec<String>> {
    let mut store = InMemoryNotes::new();
    add_note(&mut store, title, "created by the composition root").context("could not add note")?;
    let notes = store.all().context("could not list notes")?;
    Ok(notes
        .iter()
        .map(|n| format!("{}: {}", n.title(), n.body()))
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn renders_the_added_note() {
        let lines = run("  Hello  world ").unwrap();
        assert_eq!(lines, ["Hello world: created by the composition root"]);
    }

    #[test]
    fn blank_title_is_an_error() {
        assert!(run("").is_err());
    }
}
