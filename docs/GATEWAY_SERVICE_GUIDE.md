# Gateway Service Guide

This guide explains why the OpenClaw gateway may stop working when you close a terminal, and how to avoid that.

## The short version

There are two common ways to run the gateway:

1. **Foreground mode**
   - The gateway is attached to the terminal you started it from.
   - If you close the terminal, the gateway stops.

2. **Service or daemon mode**
   - The gateway is managed in the background by your operating system.
   - It can keep running after the terminal closes.

## Why people get confused

It is easy to start the gateway in a terminal and think it is now "running," but that does not always mean it is being managed as a background service.

If your gateway stops when you close the terminal, it was probably running in foreground mode.

## What to use for normal daily operation

For normal use, prefer the service-managed commands:

```bash
openclaw gateway status
openclaw gateway install
openclaw gateway start
openclaw gateway restart
```

## How to check the gateway

Run:

```bash
openclaw gateway status
```

What you want:
- the gateway should report that it is installed and running
- the probe should succeed

## If the gateway is not installed

Run:

```bash
openclaw gateway install
openclaw gateway start
```

Then check again:

```bash
openclaw gateway status
```

## Linux note

On Linux, the gateway may use a systemd user service such as:

```bash
systemctl --user status openclaw-gateway.service
```

## Important reminder

Docker helper services are not the same thing as the OpenClaw gateway.
This repo uses Docker mainly for optional helper services.
The main gateway should be managed as an OpenClaw service on the host.

## What success looks like

- you can close the terminal
- the gateway keeps running
- `openclaw gateway status` still shows a healthy service

## If it still breaks

Use:
- `make doctor`
- `make recover-session`
- `make audit-runtime`

Then read the output slowly and fix one thing at a time.
