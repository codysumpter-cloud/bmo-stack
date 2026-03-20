# Start Here

Hi! This guide is for people who are brand new to this project.

You do **not** need to know what AI, Docker, OpenClaw, NemoClaw, or a “repo” is yet.
We will explain the basics in plain English.

## What this project is

BMO Stack is a setup that helps you run a helpful AI assistant with:
- a **main helper** that talks to you
- an **optional worker** that can do riskier or more isolated tasks
- a **memory folder** so the assistant can remember important project information after restarts

Think of it like this:
- **BMO** = the helper that talks to you
- **bmo-tron** = the workshop where risky or isolated jobs can happen
- **GitHub** = the place where the project files live online

## What you need before starting

You need:
1. A computer running macOS, Linux, or Windows with WSL2
2. A GitHub account
3. Docker installed
4. OpenClaw installed on your computer
5. About 30–60 minutes the first time

If one of those names means nothing to you, that is okay. See `docs/GLOSSARY.md`.

## The easiest path

1. Read `docs/WHAT_EACH_PART_DOES.md`
2. Follow `docs/STEP_BY_STEP_SETUP.md`
3. If something breaks, open `docs/TROUBLESHOOTING.md`

## What success looks like

At the end of setup, you should have:
- this repo downloaded to your computer
- OpenClaw running on your computer
- a context folder at `~/bmo-context`
- optional helper services running if you chose to enable them
- the ability to create or connect to the worker sandbox when needed

## Important truth

This project is **partly automated** and **partly manual**.
It does not magically do everything for you.
You still need to:
- install prerequisites
- fill in secrets like API keys
- start some services the first time
- review changes before accepting them

That is normal.

## Where to go next

- Beginner setup: `docs/STEP_BY_STEP_SETUP.md`
- Plain-English architecture: `docs/WHAT_EACH_PART_DOES.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`
- Word meanings: `docs/GLOSSARY.md`
- Advanced/operator view: `README_ADVANCED.md`
