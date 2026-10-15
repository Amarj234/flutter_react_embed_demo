/*
 * React Native screen embedded in the Flutter demo through flutter_react_embed.
 *
 * Bundled into Flutter assets with `npm run bundle` (assets/rn/). Flutter shows
 * it with ReactViewConfiguration.native(componentName: 'DemoNative').
 *
 * Bridge API, mirroring the web dashboard where it makes sense:
 *   JS methods Dart can call:  getInfo() -> {screen, platform, theme, taps}
 *   events JS sends to Dart:   hello (bridge ready), mounted, tapped, toastShown,
 *                              propsApplied, flutterInfo
 *   events Dart sends to JS:   toast {message}, askFlutter (JS then calls Dart)
 *   Dart method JS calls:      getFlutterInfo() -> {platform, theme}
 */
import React, { useEffect, useRef, useState } from 'react';
import { AppRegistry, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { useFlutterBridge } from './fre-bridge-native';

const PALETTES = {
  light: { bg: '#F4F8FC', card: '#FFFFFF', text: '#14202E', muted: '#5B6B80', accent: '#0288D1', border: '#DCE5EF' },
  dark: { bg: '#0F1722', card: '#172232', text: '#EAF1FA', muted: '#95A6BD', accent: '#4FC3F7', border: '#26354A' },
};

function DemoNative(props) {
  const theme = props.theme === 'dark' ? 'dark' : 'light';
  const colors = PALETTES[theme];
  const [taps, setTaps] = useState(0);
  const [toast, setToast] = useState(null);
  const [flutterInfo, setFlutterInfo] = useState(null);
  const tapsRef = useRef(0);
  tapsRef.current = taps;

  const bridge = useFlutterBridge(props.__fre, {
    getInfo: () => ({ screen: 'react-native', platform: Platform.OS, theme, taps: tapsRef.current }),
  });

  const askFlutter = async () => {
    try {
      const info = await bridge.call('getFlutterInfo');
      setFlutterInfo(info);
      bridge.emit('flutterInfo', info);
    } catch (error) {
      setFlutterInfo({ error: String(error.message || error) });
      bridge.emit('flutterInfo', { error: String(error.message || error) });
    }
  };

  useEffect(
    () =>
      bridge.onEvent((name, data) => {
        if (name === 'toast') {
          setToast(String(data && data.message));
          bridge.emit('toastShown', { message: data && data.message });
        } else if (name === 'askFlutter') {
          // Lets Flutter (and its tests) trigger the JS -> Dart call.
          askFlutter();
        }
      }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [bridge],
  );

  const viewId = props.__fre ? props.__fre.viewId : null;
  useEffect(() => {
    bridge.emit('mounted', { viewId, screen: 'react-native' });
  }, [bridge, viewId]);

  useEffect(() => {
    bridge.emit('propsApplied', { theme });
  }, [bridge, theme]);

  const onTap = () => {
    const next = taps + 1;
    setTaps(next);
    bridge.emit('tapped', { taps: next });
  };

  return (
    <View style={[styles.root, { backgroundColor: colors.bg }]} testID="demo-native">
      <Text style={[styles.kicker, { color: colors.muted }]}>REACT NATIVE · {Platform.OS.toUpperCase()}</Text>
      <Text style={[styles.title, { color: colors.text }]}>Native screen inside Flutter</Text>
      <Text style={[styles.body, { color: colors.muted }]}>
        Rendered by React Native (ReactHost, New Architecture). Theme comes from Flutter as a prop: {theme}.
      </Text>

      <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <Text style={[styles.counter, { color: colors.text }]}>{taps}</Text>
        <Text style={[styles.body, { color: colors.muted }]}>taps sent to Flutter as `tapped` events</Text>
        <Pressable
          accessibilityRole="button"
          onPress={onTap}
          style={({ pressed }) => [styles.button, { backgroundColor: colors.accent, opacity: pressed ? 0.8 : 1 }]}>
          <Text style={styles.buttonText}>Tap me</Text>
        </Pressable>
        <Pressable
          accessibilityRole="button"
          onPress={askFlutter}
          style={({ pressed }) => [styles.outline, { borderColor: colors.accent, opacity: pressed ? 0.8 : 1 }]}>
          <Text style={[styles.outlineText, { color: colors.accent }]}>Ask Flutter for its info</Text>
        </Pressable>
        {flutterInfo ? (
          <Text style={[styles.mono, { color: colors.text }]}>{JSON.stringify(flutterInfo)}</Text>
        ) : null}
      </View>

      {toast ? (
        <View style={[styles.toast, { backgroundColor: colors.accent }]}>
          <Text style={styles.toastText}>{toast}</Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, padding: 20 },
  kicker: { fontSize: 12, fontWeight: '700', letterSpacing: 1.2 },
  title: { fontSize: 24, fontWeight: '800', marginTop: 6 },
  body: { fontSize: 14, lineHeight: 20, marginTop: 6 },
  card: { marginTop: 18, padding: 18, borderRadius: 14, borderWidth: 1, alignItems: 'center' },
  counter: { fontSize: 44, fontWeight: '800' },
  button: { marginTop: 14, paddingVertical: 12, paddingHorizontal: 28, borderRadius: 10 },
  buttonText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
  outline: { marginTop: 10, paddingVertical: 10, paddingHorizontal: 20, borderRadius: 10, borderWidth: 1.5 },
  outlineText: { fontSize: 14, fontWeight: '700' },
  mono: { marginTop: 10, fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace', fontSize: 12 },
  toast: { marginTop: 18, padding: 14, borderRadius: 12 },
  toastText: { color: '#FFFFFF', fontSize: 15, fontWeight: '600', textAlign: 'center' },
});

AppRegistry.registerComponent('DemoNative', () => DemoNative);
