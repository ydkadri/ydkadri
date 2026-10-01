//! Port contract: behaviour every `StoresNotes` adapter must satisfy.

use project_name_adapters::InMemoryNotes;
use project_name_core::{CoreError, StoresNotes, add_note};

#[test]
fn stored_notes_can_be_listed() {
    let mut store = InMemoryNotes::new();
    add_note(&mut store, "  shopping  list ", "milk").unwrap();
    let notes = store.all().unwrap();
    assert_eq!(notes.len(), 1);
    assert_eq!(notes[0].title(), "shopping list");
}

#[test]
fn blank_titles_are_rejected_before_storage() {
    let mut store = InMemoryNotes::new();
    assert_eq!(add_note(&mut store, " ", "x"), Err(CoreError::EmptyTitle));
    assert!(store.all().unwrap().is_empty());
}
