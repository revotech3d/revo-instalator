#!/usr/bin/env bash
# =====================================================================
#  Revo OS – start instalacji na maszynie Revotech.
#  Repozytoria Revo OS są prywatne. Ten skrypt tworzy na maszynie klucze
#  tylko do odczytu, a gdy GitHub je zna, pobiera i uruchamia instalator.
#
#    bash <(curl -s https://raw.githubusercontent.com/revotech3d/revo-instalator/main/instaluj.sh) \
#         --id ID-MASZYNY --token rv_... --pin TWOJ-PIN
# =====================================================================
set -euo pipefail
H=$(hostname)
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/config && chmod 600 ~/.ssh/config
for r in agent config content; do
  [ -f ~/.ssh/revo_deploy_$r ] || ssh-keygen -q -t ed25519 -N "" -C "revo-$r@$H" -f ~/.ssh/revo_deploy_$r
  grep -q "Host github-revo-$r\$" ~/.ssh/config || printf "Host github-revo-%s\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/revo_deploy_%s\n  IdentitiesOnly yes\n\n" $r $r >> ~/.ssh/config
done
grep -q "^github.com ssh-ed25519" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null

brak=0
for r in agent config content; do
  if ! git ls-remote -q git@github-revo-$r:revotech3d/revo-$r.git HEAD >/dev/null 2>&1; then
    [ $brak = 0 ] && echo && echo "== Ta maszyna nie ma jeszcze dostępu do repozytoriów Revo OS."
    brak=1
    echo
    echo "   revo-$r → https://github.com/revotech3d/revo-$r/settings/keys/new"
    echo "   Title: $H     Allow write access: NIE"
    echo "   Key:   $(cat ~/.ssh/revo_deploy_$r.pub)"
  fi
done
if [ $brak = 1 ]; then
  echo
  echo "   Dodaj powyższe klucze w GitHubie (Deploy keys) i uruchom ten skrypt ponownie."
  exit 1
fi

if [ -d ~/revo-config/.git ]; then
  git -C ~/revo-config remote set-url origin git@github-revo-config:revotech3d/revo-config.git
  git -C ~/revo-config pull -q --ff-only || true
else
  git clone -q git@github-revo-config:revotech3d/revo-config.git ~/revo-config
fi
exec bash ~/revo-config/zainstaluj-revo-os.sh "$@"
