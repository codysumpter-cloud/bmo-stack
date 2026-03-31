BMO host next steps

Goal
Move background work off the laptop and onto an always-on Linux host.

What is already in this branch
A heartbeat snapshot writer lives at scripts/bmo_write_heartbeat.py.
It writes memory/heartbeat-state.json with a timestamp, hostname, git SHA, and status note.

Recommended host layout
Use a Linux machine that stays on all the time.
Clone bmo-stack to the home directory as ~/bmo-stack.
Create a stable host root at ~/bmo-host for logs, state, temp files, and the GitHub runner bundle.

Recommended host prerequisites
Install git, python3, curl, tar, and GitHub CLI.
Install Docker only if you want the local runtime helpers on that machine.

Runner plan
Use GitHub-hosted CI for prismtek-site checks and builds.
Use a self-hosted runner on the always-on host only for jobs that need local files, Ollama, or persistent host state.

Heartbeat plan
Run scripts/bmo_write_heartbeat.py on a one minute schedule.
Treat that heartbeat file as a host-backed source, not a universally deployed source.

Truth rule
If a panel depends on host-local files or host-local APIs, label it as host-backed or local-only in Mission Control.
