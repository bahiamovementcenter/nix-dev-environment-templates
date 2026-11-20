//! An app configured in Nickel: it evaluates config.ncl (or the file given as
//! its first argument), whose contracts validate it, into a Rust struct, and
//! prints the greetings it would serve. It runs natively (`cargo run`) and as
//! WebAssembly under wasmtime (`cargo run --target wasm32-wasip2`).

use std::collections::BTreeMap;
use std::process::ExitCode;

use nickel_embed::{Program, Source};
use serde::Deserialize;

/// Mirrors schema.ncl.
#[derive(Deserialize)]
struct Config {
    name: String,
    port: u16,
    greetings: BTreeMap<String, String>,
}

fn load_config(path: &str) -> Result<Config, Box<dyn std::error::Error>> {
    // Imports in a file source resolve from that file's folder.
    let mut program = Program::builder().source(Source::file(path)).build()?;
    Ok(program.eval_deep()?.to_serde()?)
}

fn main() -> ExitCode {
    let path = std::env::args().nth(1).unwrap_or_else(|| "config.ncl".into());
    match load_config(&path) {
        Ok(config) => {
            println!("{} would listen on port {} and serve:", config.name, config.port);
            for (code, greeting) in &config.greetings {
                println!("  /{code}: {greeting}");
            }
            ExitCode::SUCCESS
        }
        Err(e) => {
            eprintln!("{e}");
            ExitCode::FAILURE
        }
    }
}
