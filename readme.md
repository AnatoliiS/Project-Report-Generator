# Project Report Generator

A Bash script that generates a detailed report of your project's structure and text file contents, with customizable exclusions and optional ZIP archiving.

## Features

- Reports project structure and file contents
- Configurable via `.project_report_config`
- Custom exclusions for dirs/files
- Progress bar during processing
- Optional ZIP archive
- Auto-installs dependencies (needs sudo)

## Prerequisites

- Bash shell
- Optional: `tree` (structure), `zip` (archive)

The script offers to install missing tools.

## Usage

1. Clone: `git clone https://github.com/yourusername/project-report-generator.git && cd project-report-generator`
2. Make executable: `chmod +x generate_report.sh`
3. Run: `./generate_report.sh`
4. Follow prompts for name, email, exclusions, and ZIP option

## Output

- `complete_project_report.txt` with metadata, structure, and contents
- Optional ZIP (e.g., `project_report_20231115_143022.zip`)

## Configuration

Settings in `.project_report_config`:
- `DEV_NAME`: Your name
- `DEV_EMAIL`: Your email
- `EXCLUDED_DIRS`: Dirs to skip (comma-separated)
- `EXCLUDED_FILES`: Files to skip (comma-separated)
- `ADDITIONAL_INFO`: Notes

Skips `node_modules`, `.git`, `.jpg`, `.zip`, etc. by default.

## Example

Run `./generate_report.sh`, approve dependency install if needed, enter details (e.g., "Alice Smith", "alice@example.com", "temp, backups" to exclude), and choose ZIP option. Output: `complete_project_report.txt` and optional ZIP.

## Notes

- Skips itself, config, and output
- Needs write permissions
- May need sudo
- Large projects make big files

## Contributing

Submit issues/pull requests to improve!

## License

MIT License - see [LICENSE](LICENSE)