# BMO Stack

BMO Stack helps you set up a helpful AI assistant system on your own computer.

This beginner draft is written for someone who knows **nothing** about:
- AI
- Docker
- GitHub
- terminals
- OpenClaw
- NemoClaw

That is okay.
You do not need to be an expert to get started.

## What this project does

This project gives you a starting point for running:
- a main assistant that talks to you
- an optional worker area for more isolated tasks
- memory and context files so the assistant can recover after restarts
- optional GitHub helpers that can watch and maintain a repo

## The easiest way to start

If you are brand new, read these files in this order:

1. `docs/START_HERE.md`
2. `docs/WHAT_EACH_PART_DOES.md`
3. `docs/STEP_BY_STEP_SETUP.md`
4. `docs/TROUBLESHOOTING.md`
5. `docs/GLOSSARY.md`

## What you need before you start

You will need:
- a computer
- a GitHub account
- Git installed
- Docker installed
- OpenClaw installed
- a little patience the first time

## What success looks like

When setup is working, you should have:
- this repo downloaded to your computer
- a `.env` file with your private settings
- a `~/bmo-context` folder for important context
- OpenClaw running on your host machine
- the option to create and use the `bmo-tron` worker sandbox

## Important truth

This project is not magic.
Some parts are automated.
Some parts are still manual.
You still need to install tools, add keys, and review changes.

## If you are more technical

Use `README_ADVANCED.md` and `RUNBOOK.md`.

## Words you will see a lot

- **BMO** = the assistant that talks to you
- **bmo-tron** = the worker sandbox
- **host** = your main computer environment
- **worker** = the isolated helper environment
- **context files** = files that help the assistant recover after restarts
