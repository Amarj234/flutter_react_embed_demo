// Where the React Native CLI finds the host app's native projects. Autolinking
// and the React Native Gradle plugin need the Android package name.
module.exports = {
  project: {
    android: {
      sourceDir: './android',
      packageName: 'com.amarj234.react_embed_demo',
    },
    ios: {
      sourceDir: './ios',
    },
  },
};
