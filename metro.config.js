const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

// Only the React Native screen is bundled; keep Metro out of the web app,
// the Flutter build output and the native projects. Patterns are anchored to
// this folder so they never match inside node_modules.
const escape = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const ignored = ['react_src', 'build', 'android', 'ios', 'assets'].map(
  (dir) => new RegExp('^' + escape(path.join(__dirname, dir) + path.sep) + '.*'),
);

module.exports = mergeConfig(getDefaultConfig(__dirname), {
  resolver: { blockList: ignored },
});
