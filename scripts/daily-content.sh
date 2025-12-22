#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository." >&2
  exit 1
fi

ts="$(date -u +"%Y%m%d")"
date_label="$(date -u +"%Y-%m-%d")"
day_of_year="$(date -u +"%j")"

themes=(dns securite stockage performance conteneurs kubernetes depannage commandes)
theme_index=$((10#$day_of_year % ${#themes[@]}))
theme="${themes[$theme_index]}"

section_class="section"
if (( day_of_year % 2 == 0 )); then
  section_class="section alt"
fi

title="Mise a jour quotidienne"
subtitle="Ajout du $date_label"
content_title="Focus $theme"
body="Cette section est ajoutee automatiquement et vise un public confirme."
list_items=""
code_block=""

case "$theme" in
  dns)
    content_title="DNS: resolution fiable et debug"
    list_items=$'              <li>Verifier la chaine avec dig +trace</li>\n              <li>Observer resolvectl et cache local</li>\n              <li>Documenter les resolvers critiques</li>'
    code_block=$'dig +trace debian.org\nresolvectl status\nsudo systemctl restart systemd-resolved'
    ;;
  securite)
    content_title="Audit securite rapide"
    list_items=$'              <li>Inventorier les ports exposes</li>\n              <li>Verifier les comptes privilegiés</li>\n              <li>Controler les binaires SUID</li>'
    code_block=$'ss -tulpen\nsudo awk -F: \'$3==0 {print $1}\' /etc/passwd\nsudo find / -perm -4000 -type f 2>/dev/null'
    ;;
  stockage)
    content_title="Btrfs/ZFS: integrite et snapshots"
    list_items=$'              <li>Verifier l etat des pools</li>\n              <li>Lancer un scrub regulier</li>\n              <li>Creer des snapshots horodates</li>'
    code_block=$'sudo btrfs scrub start -Bd /\nsudo zpool status\nsudo zfs snapshot tank/data@daily'
    ;;
  performance)
    content_title="Observabilite avancee"
    list_items=$'              <li>Mesurer CPU, memoire, I/O</li>\n              <li>Identifier les hotspots avec perf</li>\n              <li>Tracer les appels systeme critiques</li>'
    code_block=$'htop\nsudo perf top\nsudo strace -fp 1234'
    ;;
  conteneurs)
    content_title="Conteneurs: hygiene de prod"
    list_items=$'              <li>Isoler reseaux internes</li>\n              <li>Executer en non-root</li>\n              <li>Limiter les capabilities</li>'
    code_block=$'docker ps -a\ndocker run --read-only --cap-drop ALL app:latest\ndocker network ls'
    ;;
  kubernetes)
    content_title="Kubernetes poste dev"
    list_items=$'              <li>Cluster local via kind ou minikube</li>\n              <li>Namespaces par projet</li>\n              <li>Monitoring via metrics-server</li>'
    code_block=$'kind create cluster --name dev\nkubectl get nodes\nkubectl top pods -A'
    ;;
  depannage)
    content_title="Depannage: check rapide"
    list_items=$'              <li>Lire journalctl en priorite</li>\n              <li>Verifier systemctl --failed</li>\n              <li>Identifier les saturations disque</li>'
    code_block=$'journalctl -p err -S \"today\"\nsystemctl --failed\ndf -hT'
    ;;
  commandes)
    content_title="Commandes utiles"
    list_items=$'              <li>Chaines pipeline claires</li>\n              <li>Utiliser awk pour les rapports</li>\n              <li>Preferer rg pour les recherches</li>'
    code_block=$'rg -n \"error\" /var/log\nps aux | awk \'{print $1,$2,$11}\' | head\nsort | uniq -c | sort -nr'
    ;;
esac

section=$(cat <<EOF
      <section id="auto-$ts-$theme" class="$section_class">
        <div class="section-title">
          <p>$title</p>
          <h2>$subtitle</h2>
        </div>
        <div class="grid two">
          <article class="card">
            <h3>$content_title</h3>
            <p>
              $body
            </p>
            <ul>
$list_items
            </ul>
          </article>
          <article class="card">
            <h3>Commandes</h3>
            <div class="code-block">
              <pre><code>$code_block</code></pre>
            </div>
          </article>
        </div>
      </section>
EOF
)

for file in *.html; do
  if ! grep -q "</main>" "$file"; then
    echo "Missing </main> in $file" >&2
    exit 1
  fi
  if grep -q "auto-$ts-$theme" "$file"; then
    continue
  fi
  perl -0777 -i -pe "s#</main>#$section\n    </main>#s" "$file"
done

git add *.html
if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

git commit -m "Daily content $date_label ($theme)"
git push
