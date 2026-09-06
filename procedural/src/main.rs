use std::{
    fs,
    io::{Read, Write},
};
fn run() -> Result<(), String> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 3 {
        return Err("Usage: scene-forge <recipe.json> <scene.json>".into());
    }
    let mut text = String::new();
    fs::File::open(&args[1])
        .map_err(|e| e.to_string())?
        .take(16 * 1024 * 1024 + 1)
        .read_to_string(&mut text)
        .map_err(|e| e.to_string())?;
    let output = scene_forge::compile_json(&text)?;
    // create_new protects existing authoring/output data; callers choose a fresh job path.
    let mut file = fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&args[2])
        .map_err(|e| e.to_string())?;
    file.write_all(output.as_bytes())
        .map_err(|e| e.to_string())?;
    println!("Compiled {} bytes", output.len());
    Ok(())
}
fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(1)
    }
}
