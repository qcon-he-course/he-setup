# Finding your way in the code

- For Java code, use the Serena tools before grep and before reading whole files: `find_symbol` for where something is defined, `find_referencing_symbols` for who uses it, `get_symbols_overview` for what a file contains, and `find_implementations` for the classes behind an interface.
- Use grep or ripgrep for configuration, SQL, templates and other files that aren't Java.
