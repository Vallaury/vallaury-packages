#!/usr/bin/env bash
# Builds the signed apt and dnf/yum repositories from the .deb and .rpm files of one release.
# Usage: build-site.sh <dir with the release .deb/.rpm files> <output dir>
# Needs: apt-utils, createrepo-c, rpm (rpmsign), gnupg. The signing key must be in the default GnuPG home.
set -euo pipefail

in=$(realpath "$1")
out=$(realpath -m "$2")
root=$(cd "$(dirname "$0")/.." && pwd)
key="Vallaury Packages <packages@vallaury.it>"

rm -rf "$out"
mkdir -p "$out/apt/pool/main" "$out/rpm/x86_64" "$out/rpm/aarch64"

# apt
cp "$in"/*.deb "$out/apt/pool/main/"
(
  cd "$out/apt"
  for arch in amd64 arm64; do
    mkdir -p "dists/stable/main/binary-$arch"
    # one paragraph per package; keep those built for this architecture
    apt-ftparchive packages pool/main \
      | awk -v RS= -v ORS='\n\n' -v want="Architecture: $arch" '$0 ~ ("(^|\n)" want "(\n|$)")' \
      > "dists/stable/main/binary-$arch/Packages"
    gzip -9kn "dists/stable/main/binary-$arch/Packages"
    xz -9k "dists/stable/main/binary-$arch/Packages"
  done
  apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=Vallaury \
    -o APT::FTPArchive::Release::Label=Vallaury \
    -o APT::FTPArchive::Release::Suite=stable \
    -o APT::FTPArchive::Release::Codename=stable \
    -o APT::FTPArchive::Release::Architectures="amd64 arm64" \
    -o APT::FTPArchive::Release::Components=main \
    release dists/stable > dists/stable/Release
  gpg --batch --yes --local-user "$key" --armor --detach-sign -o dists/stable/Release.gpg dists/stable/Release
  gpg --batch --yes --local-user "$key" --clearsign -o dists/stable/InRelease dists/stable/Release
)

# dnf / yum / zypper
echo "%_gpg_name $key" > "$HOME/.rpmmacros"
for arch in x86_64 aarch64; do
  cp "$in"/*"-$arch.rpm" "$out/rpm/$arch/"
  rpmsign --addsign "$out/rpm/$arch/"*.rpm
  createrepo_c --quiet "$out/rpm/$arch"
  gpg --batch --yes --local-user "$key" --armor --detach-sign -o "$out/rpm/$arch/repodata/repomd.xml.asc" "$out/rpm/$arch/repodata/repomd.xml"
done

# public key, repo definition, page
cp "$root/vallaury.gpg" "$root/vallaury.asc" "$out/"
cp "$root/site/"* "$out/"
touch "$out/.nojekyll"
