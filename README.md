# Vallaury packages

Signed apt and dnf/zypper repositories for the [Vallaury](https://vallaury.it) desktop app.
Install instructions: https://sappafrancesco.github.io/vallaury-packages/

The repositories are rebuilt from the latest release of
[vallaury-desktop](https://github.com/sappafrancesco/vallaury-desktop) by
`.github/workflows/publish.yml` (daily, or by hand), after checking every file against the
release's `SHA256SUMS`. `scripts/build-site.sh` makes the repositories and signs them with the
key in `vallaury.asc` (fingerprint `E1B5 5711 9138 0C27 C8C9 8381 C9D6 EB50 B55A 78C5`).
The private key is only a secret of this repository.

Licence of the scripts: GPL-3.0-only.
