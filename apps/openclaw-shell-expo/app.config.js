export default {
  expo: {
    name: 'OpenClaw Shell Expo',
    slug: 'openclaw-shell-expo',
    scheme: 'openclaw-shell-expo',
    version: '0.1.0',
    orientation: 'portrait',
    userInterfaceStyle: 'automatic',
    platforms: ['ios', 'android', 'web'],
    ios: {
      supportsTablet: false,
      bundleIdentifier: 'com.prismtek.openclawshellexpo'
    },
    android: {
      package: 'com.prismtek.openclawshellexpo'
    },
    web: {
      bundler: 'metro'
    }
  }
};
