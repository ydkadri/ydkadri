//! End-to-end tests of the `project-name` binary.

use std::process::Command;

fn bin() -> Command {
    Command::new(env!("CARGO_BIN_EXE_project-name"))
}

#[test]
fn prints_the_added_note() {
    let out = bin().arg("Ada").output().unwrap();
    assert!(out.status.success());
    assert_eq!(
        String::from_utf8_lossy(&out.stdout),
        "Ada: created by the composition root\n"
    );
}

#[test]
fn blank_title_fails() {
    let out = bin().arg(" ").output().unwrap();
    assert!(!out.status.success());
}
