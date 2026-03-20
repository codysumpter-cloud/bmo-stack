# Step-by-Step Setup

This guide is written for someone who is brand new.

## Before you begin

You need these things installed on your computer:
- **Git** (used to download project files from GitHub)
- **Docker** (used to run helper services)
- **OpenClaw** (used to run the assistant)

If you do not have them yet, stop here and install them first.
If you are not sure what they are, read `docs/GLOSSARY.md`.

## Step 1: Download this project

Open a terminal and run:

```bash
git clone https://github.com/codysumpter-cloud/bmo-stack.git
cd bmo-stack
```

### What this does
It downloads the project files from GitHub to your computer.

### What success looks like
You should now be inside a folder named `bmo-stack`.

## Step 2: Copy the example settings file

Run:

```bash
cp .env.example .env
```

### What this does
It creates your own private settings file.

### Important
Do **not** upload `.env` to GitHub.
That file may contain secret keys later.

## Step 3: Add your API key

Open `.env` in a text editor and fill in the values you need.
At minimum, you will usually need your NVIDIA API key.

### What success looks like
Your `.env` file is saved and no longer contains only placeholder values.

## Step 4: Start the helper services (optional)

Run:

```bash
make up
```

### What this does
It starts optional helper services, such as PostgreSQL, if you want them.

### What success looks like
Docker starts the services without an error.

## Step 5: Check your setup

Run:

```bash
make doctor
```

### What this does
It checks whether important parts of your setup exist.

### What success looks like
You see checks passing, or you get a short list of what is missing.

## Step 6: Create your context folder

Your assistant uses a host folder for important context:

```bash
mkdir -p ~/bmo-context
```

### What this does
It creates the folder where important memory and runtime notes live.

## Step 7: Sync context if needed

Run:

```bash
make sync-context
```

### What this does
It syncs the repo's `context/` folder with your host `~/bmo-context` folder.

## Step 8: Start OpenClaw on the host

Run:

```bash
make openclaw-start
```

Then check it with:

```bash
make openclaw-status
```

### What success looks like
OpenClaw shows as running.

## Step 9: Create the worker sandbox (optional)

Run:

```bash
make worker-create
```

Then upload config:

```bash
make worker-upload-config
```

Then connect when needed:

```bash
make worker-connect
```

### What this does
This creates the optional isolated worker called `bmo-tron`.

## Step 10: Recover your session later if needed

If your session restarts or Docker updates, run:

```bash
make recover-session
```

### What this does
It checks your context files, task state, work in progress, and repo status so you can safely resume.

## If something breaks

Go to:
- `docs/TROUBLESHOOTING.md`
- `docs/WHAT_EACH_PART_DOES.md`
- `README_ADVANCED.md`
