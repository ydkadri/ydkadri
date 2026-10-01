//! Domain core: types, a pure function, and the driven port.
//!
//! This crate performs no I/O. Anything that touches the outside world is a
//! port (a trait named with a verb, such as [`StoresNotes`]) implemented in
//! the adapters crate.

#![warn(missing_docs)]

use thiserror::Error;

/// Failure reported by a [`StoresNotes`] implementation.
#[derive(Debug, Error, PartialEq, Eq)]
pub enum StoreError {
    /// The backing store could not be reached or written.
    #[error("note store unavailable: {reason}")]
    Unavailable {
        /// Human readable cause.
        reason: String,
    },
}

/// Failure of a core operation.
#[derive(Debug, Error, PartialEq, Eq)]
pub enum CoreError {
    /// The title was empty or only whitespace.
    #[error("note title must not be empty")]
    EmptyTitle,
    /// The store failed.
    #[error(transparent)]
    Store(#[from] StoreError),
}

/// A short note.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Note {
    title: String,
    body: String,
}

impl Note {
    /// The normalised title.
    pub fn title(&self) -> &str {
        &self.title
    }

    /// The body text.
    pub fn body(&self) -> &str {
        &self.body
    }
}

/// Driven port: somewhere notes can be stored and listed.
pub trait StoresNotes {
    /// Persist a note.
    ///
    /// # Errors
    ///
    /// Returns [`StoreError`] if the note cannot be stored.
    fn save(&mut self, note: Note) -> Result<(), StoreError>;

    /// List every stored note in insertion order.
    ///
    /// # Errors
    ///
    /// Returns [`StoreError`] if the notes cannot be read.
    fn all(&self) -> Result<Vec<Note>, StoreError>;
}

/// Trim a raw title and collapse inner whitespace runs to single spaces.
///
/// This is a pure function: no I/O, no clock, no randomness.
///
/// # Errors
///
/// Returns [`CoreError::EmptyTitle`] if nothing is left after trimming.
///
/// # Examples
///
/// ```
/// let title = project_name_core::normalise_title("  Buy   milk ")?;
/// assert_eq!(title, "Buy milk");
/// # Ok::<(), project_name_core::CoreError>(())
/// ```
pub fn normalise_title(raw: &str) -> Result<String, CoreError> {
    let title = raw.split_whitespace().collect::<Vec<_>>().join(" ");
    if title.is_empty() {
        return Err(CoreError::EmptyTitle);
    }
    Ok(title)
}

/// Use case: validate a note and hand it to the store.
///
/// # Errors
///
/// Returns [`CoreError::EmptyTitle`] for a blank title, or
/// [`CoreError::Store`] if the store fails.
pub fn add_note<S: StoresNotes>(store: &mut S, title: &str, body: &str) -> Result<(), CoreError> {
    let note = Note {
        title: normalise_title(title)?,
        body: body.to_owned(),
    };
    store.save(note)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Minimal fake used only to exercise the use case.
    struct Fake {
        fail: bool,
        saved: Vec<Note>,
    }

    impl StoresNotes for Fake {
        fn save(&mut self, note: Note) -> Result<(), StoreError> {
            if self.fail {
                return Err(StoreError::Unavailable {
                    reason: "down".to_owned(),
                });
            }
            self.saved.push(note);
            Ok(())
        }

        fn all(&self) -> Result<Vec<Note>, StoreError> {
            Ok(self.saved.clone())
        }
    }

    #[test]
    fn normalises_whitespace() {
        assert_eq!(normalise_title("  a   b ").unwrap(), "a b");
    }

    #[test]
    fn rejects_blank_title() {
        assert_eq!(normalise_title(" \t"), Err(CoreError::EmptyTitle));
    }

    #[test]
    fn add_note_saves_normalised_note() {
        let mut fake = Fake {
            fail: false,
            saved: vec![],
        };
        add_note(&mut fake, " Hi  there ", "body").unwrap();
        let notes = fake.all().unwrap();
        assert_eq!(notes[0].title(), "Hi there");
        assert_eq!(notes[0].body(), "body");
    }

    #[test]
    fn add_note_surfaces_store_errors() {
        let mut fake = Fake {
            fail: true,
            saved: vec![],
        };
        let err = add_note(&mut fake, "t", "b").unwrap_err();
        assert!(matches!(
            err,
            CoreError::Store(StoreError::Unavailable { .. })
        ));
    }
}
