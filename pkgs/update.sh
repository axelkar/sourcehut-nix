#! /usr/bin/env nix-shell
#! nix-shell -i bash -p git mercurial common-updater-scripts
set -eux -o pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
#root=../../../..
#root=./..
root="$PWD"/..
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

default() {
  set -eux -o pipefail
  (cd "$root" && nix-instantiate --eval --strict -A "sourcehut.python.pkgs.$1.meta.position" | sed -re 's/^"(.*):[0-9]+"$/\1/')
}

version() {
  set -eux -o pipefail
  (cd "$root" && nix-instantiate --eval --strict -A "sourcehut.python.pkgs.$1.version" | tr -d '"')
}

src_url() {
  set -eux -o pipefail
  pwd >&2
  nix-instantiate --eval --strict --expr "with import $root {}; let src = sourcehut.python.pkgs.$1.drvAttrs.src; in src.meta.homepage" | tr -d '"'
  # Simplified version: nix-instantiate --eval --strict "$root" -A "sourcehut.python.pkgs.$1.drvAttrs.src.meta.homepage" | tr -d '"'
}

get_latest_version() {
  set -eux -o pipefail
  src="$(src_url "$1")"
  rm -rf "$tmp"
  if [ "$1" = "hgsrht" ]; then
    hg clone "$src" "$tmp" >/dev/null
    printf "%s" "$(cd "$tmp" && hg log --limit 1 --template '{latesttag}')"
  else
    git clone "$src" "$tmp" >/dev/null
    printf "%s" "$(cd "$tmp" && git describe "$(git rev-list --tags --max-count=1)")"
  fi
}

update_version() {
  set -eux -o pipefail
  default_nix="$(default "$1")"
  oldVersion="$(version "$1")"
  version="$(get_latest_version "$1")"

  (cd "$root" && update-source-version "sourcehut.python.pkgs.$1" "$version")

  return
  # Update vendorSha256 of Go modules
  retry=true
  while "$retry"; do
    retry=false;
    exec < <(exec nix -L build -f "$root" sourcehut.python.pkgs."$1" 2>&1)
    while IFS=' :' read -r origin hash; do
      case "$origin" in
        (expected|specified) oldHash="$hash";;
        (got) sed -i "s|$oldHash|$hash|" "$default_nix"; retry=true; break;;
        (*) printf >&2 "%s\n" "$origin${hash:+:$hash}"
      esac
    done
  done

  if [ "$oldVersion" != "$version" ]; then
    #git add "$default_nix"
    #git commit -m "sourcehut.$1: $oldVersion -> $version"
    echo COMMIT HERE
  fi
}

if [ $# -gt 0 ]; then
  services=("$@")
else
  # Get a full list with
  # (cd pkgs; attr=sourcehut.python.pkgs ; nix-instantiate --eval --strict -E "builtins.filter (name: builtins.match \"^.*srht$\" name == []) (builtins.attrNames (let tree = import ./.; in if builtins.isFunction tree then tree {} else tree).$attr)")

  # Beware that some packages must be updated before others,
  # eg. buildsrht must be updated before gitsrht,
  # otherwise this script would enter an infinite loop
  # because the reported $oldHash to be changed
  # may not actually be in $default_nix
  # but in the file of one of its dependencies.
  services=( "srht" "scmsrht" "buildsrht" "gitsrht" "hgsrht" "hubsrht" "listssrht" "mansrht"
             "metasrht" "pastesrht" "todosrht" )
  #           "metasrht" "pagessrht" "pastesrht" "todosrht" )
fi

for service in "${services[@]}"; do
  update_version "$service"
done
