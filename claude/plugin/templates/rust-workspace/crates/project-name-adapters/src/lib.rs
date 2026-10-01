//! Adapters: implementations of the ports defined in `project-name-core`.
//!
//! Depends on core only. The in-memory adapter doubles as the fake for tests.

#![warn(missing_docs)]

mod memory;

pub use memory::InMemoryNotes;
