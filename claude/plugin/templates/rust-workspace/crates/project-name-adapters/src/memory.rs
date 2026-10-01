//! In-memory [`StoresNotes`] adapter.

use project_name_core::{Note, StoreError, StoresNotes};

/// Keeps notes in a `Vec`. Lost when dropped.
#[derive(Debug, Default)]
pub struct InMemoryNotes {
    notes: Vec<Note>,
}

impl InMemoryNotes {
    /// Create an empty store.
    pub fn new() -> Self {
        Self::default()
    }
}

impl StoresNotes for InMemoryNotes {
    fn save(&mut self, note: Note) -> Result<(), StoreError> {
        self.notes.push(note);
        Ok(())
    }

    fn all(&self) -> Result<Vec<Note>, StoreError> {
        Ok(self.notes.clone())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use project_name_core::add_note;

    #[test]
    fn starts_empty() {
        assert!(InMemoryNotes::new().all().unwrap().is_empty());
    }

    #[test]
    fn keeps_insertion_order() {
        let mut store = InMemoryNotes::new();
        add_note(&mut store, "first", "").unwrap();
        add_note(&mut store, "second", "").unwrap();
        let titles: Vec<_> = store
            .all()
            .unwrap()
            .iter()
            .map(|n| n.title().to_owned())
            .collect();
        assert_eq!(titles, ["first", "second"]);
    }
}
