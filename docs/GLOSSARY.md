# Glossary

This page explains common words in simple language.

## AI
Short for **artificial intelligence**. In this project, it means software that can help answer questions, read files, and assist with tasks.

## Repo
Short for **repository**. A repo is a folder of project files stored on GitHub.

## GitHub
A website that stores project files online and tracks changes.

## Git
A tool that downloads project files from GitHub and tracks changes on your computer.

## Terminal
A text-based window where you can type commands.

## Command
Something you type into the terminal to tell the computer to do a task.

## Docker
A tool that runs software in small packaged environments.

## Container
A packaged environment used by Docker.
It helps software run more predictably.

## OpenClaw
The software in this project that runs the assistant on your computer.

## NemoClaw
A related part of the system that helps with the worker sandbox.

## OpenShell
The system used to manage the isolated worker sandbox.

## Host
Your main computer environment.
This is where the main assistant and stable context live.

## Worker
A helper environment used for more isolated or riskier tasks.

## Sandbox
A safer, more isolated place to run commands.
In this project, `bmo-tron` is the worker sandbox.

## Context
Important notes and state files that help the assistant recover after restarts.

## Context files
Files like:
- `BOOTSTRAP.md`
- `SESSION_STATE.md`
- `RUNBOOK.md`
- `TASK_STATE.md`
- `WORK_IN_PROGRESS.md`

These help the system remember what matters.

## Council
A set of named roles used to organize the assistant's responsibilities.
Some are real automated parts. Some are guidance roles.

## Prismo
The orchestrator role. Prismo routes tasks.

## BMO
The front-facing assistant role. BMO talks to the user.

## NEPTR
The verification role. NEPTR checks work before something is claimed complete.

## Cosmic Owl
The GitHub watcher role. Cosmic Owl watches for repo drift and maintenance needs.

## Moe
The repair worker role. Moe handles repo fixes and PR-style maintenance work.

## API key
A secret value that lets software use an online service.
Keep API keys private.

## Environment file (`.env`)
A private file that stores settings such as API keys.
This file should not be committed to GitHub.

## Makefile
A file that defines shortcut commands like `make up` and `make doctor`.

## `make doctor`
A project check that looks for missing tools or missing setup pieces.

## `make recover-session`
A command that helps check task state, work in progress, and repo status after a restart.
