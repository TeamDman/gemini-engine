use ignore::WalkBuilder;
use std::path::PathBuf;
use std::env;
use std::process;

fn main() {
    // Get the first command line argument as a PathBuf
    // defaulting to the current directory if none is provided
    let args: Vec<String> = env::args().collect();
    let path = args.get(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| env::current_dir().unwrap_or_else(|err| {
            eprintln!("Error getting current directory: {}", err);
            process::exit(1);
        }));

    for result in WalkBuilder::new(path.clone()).build() {
        if let Ok(entry) = result {
            if entry.file_type().map_or(false, |ft| ft.is_file())
            {
                // let relative_path = entry.path().strip_prefix(&path).unwrap_or(entry.path());
                println!("{}", entry.path().display());
            }
        }
    }
}
