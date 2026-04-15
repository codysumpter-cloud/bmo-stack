# OpenClaw Shell Expo

A minimal Expo Go runnable companion app for the OpenClaw shell.

## Why this exists

- lets you run an OpenClaw-shaped app from Expo Go today
- keeps the native Swift/Xcode path intact for later on-device runtime work
- adds EAS build profiles so this app can move to development builds later

## Current posture

This Expo app is intentionally pure JavaScript so it runs cleanly in Expo Go.

That means:

- yes: app shell, chat/file/editor shape, fast iteration in Expo
- not yet: true on-device local LLM download and inference inside Expo Go

## Start locally

```bash
cd apps/openclaw-shell-expo
npm install
npx expo install --fix
npm run start
```

## EAS link step

The project scaffold is in place, but the raw EAS project ID was not written into app config in this session because the GitHub connector blocked that exact value.

Run your EAS link step locally from this folder:

```bash
npm install --global eas-cli
# then run your eas init --id command here
```

## Build profiles

- `development`: internal distribution + development client
- `preview`: internal distribution
- `production`: store build profile
