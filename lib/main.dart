import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_react_embed/flutter_react_embed.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'React Embed Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF02A9F4), useMaterial3: true),
      home: const HomeShell(),
    );
  }
}

/// Switches between the React web dashboard and the React Native screen.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // One surface at a time: switching tabs disposes the other React view.
      body: _index == 0 ? const DashboardPage() : const NativeScreenPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) => setState(() => _index = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.web), label: 'React Web'),
          NavigationDestination(icon: Icon(Icons.phone_android), label: 'React Native'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  ReactViewController? _controller;
  String _theme = 'light';
  final List<String> _log = <String>[];

  void _addLog(String line) {
    setState(() {
      _log.insert(0, line);
      if (_log.length > 50) _log.removeLast();
    });
  }

  void _onViewCreated(ReactViewController controller) {
    _controller = controller;
    _addLog('✅ React view ready');

    // React -> Flutter events.
    controller.events().listen((ReactBridgeEvent event) {
      _addLog('📩 ${event.name}: ${jsonEncode(event.data)}');
    });

    // Lets React call Dart: FlutterBridge.call('getFlutterInfo')
    controller.registerHandler('getFlutterInfo', (_) => <String, Object?>{
      'platform': defaultTargetPlatform.name,
      'theme': _theme,
    });
  }

  Future<void> _getInfo() async {
    try {
      final Map<String, Object?> info = await _controller!.invoke<Map<String, Object?>>('getInfo');
      _addLog('↩️ getInfo: ${info['hash']} · ${info['screen']}');
    } on ReactEmbedException catch (e) {
      _addLog('❌ $e');
    }
  }

  Future<void> _navigate(String hash) async {
    try {
      await _controller!.invoke<Object?>('navigate', params: <String, Object?>{'hash': hash});
      _addLog('🧭 navigate → $hash');
    } on ReactEmbedException catch (e) {
      _addLog('❌ $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _controller != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('React inside Flutter'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Toggle React theme (props)',
            icon: Icon(_theme == 'light' ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => setState(() => _theme = _theme == 'light' ? 'dark' : 'light'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ReactView(
              configuration: ReactViewConfiguration(
                engine: const ReactEngineConfig(
                  engine: ReactEngineKind.web,
                  bundle: 'assets/react_app/',
                  enableDebugging: kDebugMode,
                ),
                moduleName: '#/dashboard',
                initialProps: <String, Object?>{'theme': _theme},
              ),
              onViewCreated: _onViewCreated,
              onError: (ReactEmbedException error, StackTrace stackTrace) => _addLog('❌ $error'),
              placeholderBuilder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
              errorBuilder: (BuildContext context, ReactEmbedException error, VoidCallback retry) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Could not load React app:\n$error', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: retry, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _ControlPanel(
            enabled: ready,
            log: _log,
            onGetInfo: _getInfo,
            onNavigate: _navigate,
            onToast: () => _controller?.emit('toast', <String, Object?>{'message': 'Hello from Flutter 👋'}),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.enabled,
    required this.log,
    required this.onGetInfo,
    required this.onNavigate,
    required this.onToast,
  });

  final bool enabled;
  final List<String> log;
  final VoidCallback onGetInfo;
  final ValueChanged<String> onNavigate;
  final VoidCallback onToast;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: <Widget>[
                  _chip('Get info', Icons.info_outline, enabled ? onGetInfo : null),
                  _chip('Dashboard', Icons.dashboard, enabled ? () => onNavigate('#/dashboard') : null),
                  _chip('Charts', Icons.bar_chart, enabled ? () => onNavigate('#/charts') : null),
                  _chip('Buttons', Icons.smart_button, enabled ? () => onNavigate('#/components/buttons') : null),
                  _chip('Send toast', Icons.campaign, enabled ? onToast : null),
                ],
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: log.length,
                itemBuilder: (BuildContext context, int i) => Text(
                  log[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: onPressed),
    );
  }
}

/// A React Native screen (react_native/index.js), bundled into assets/rn/.
class NativeScreenPage extends StatefulWidget {
  const NativeScreenPage({super.key});

  @override
  State<NativeScreenPage> createState() => _NativeScreenPageState();
}

class _NativeScreenPageState extends State<NativeScreenPage> {
  ReactViewController? _controller;
  String _theme = 'light';
  final List<String> _log = <String>[];

  void _addLog(String line) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, line);
      if (_log.length > 50) _log.removeLast();
    });
  }

  void _onViewCreated(ReactViewController controller) {
    _controller = controller;
    _addLog('✅ React Native view ready');

    // React Native -> Flutter events.
    controller.events().listen((ReactBridgeEvent event) {
      _addLog('📩 ${event.name}: ${jsonEncode(event.data)}');
    });

    // Lets React Native call Dart: bridge.call('getFlutterInfo')
    controller.registerHandler('getFlutterInfo', (_) => <String, Object?>{
      'platform': defaultTargetPlatform.name,
      'theme': _theme,
    });
  }

  Future<void> _getInfo() async {
    try {
      final Map<String, Object?> info = await _controller!.invoke<Map<String, Object?>>('getInfo');
      _addLog('↩️ getInfo: ${info['screen']} · ${info['platform']} · taps ${info['taps']}');
    } on ReactEmbedException catch (e) {
      _addLog('❌ $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _controller != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('React Native inside Flutter'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Toggle React Native theme (props)',
            icon: Icon(_theme == 'light' ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => setState(() => _theme = _theme == 'light' ? 'dark' : 'light'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ReactView(
              configuration: ReactViewConfiguration.native(
                bundleName: 'assets/rn/index.android.bundle',
                iosBundleName: 'assets/rn/main.jsbundle',
                componentName: 'DemoNative',
                initialProps: <String, Object?>{'theme': _theme},
              ),
              onViewCreated: _onViewCreated,
              onError: (ReactEmbedException error, StackTrace stackTrace) => _addLog('❌ $error'),
              placeholderBuilder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
              errorBuilder: (BuildContext context, ReactEmbedException error, VoidCallback retry) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Could not load React Native screen:\n$error', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: retry, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _NativeControlPanel(
            enabled: ready,
            log: _log,
            onGetInfo: _getInfo,
            onToast: () => _controller?.emit('toast', <String, Object?>{'message': 'Hello from Flutter 👋'}),
            onAskFlutter: () => _controller?.emit('askFlutter'),
          ),
        ],
      ),
    );
  }
}

class _NativeControlPanel extends StatelessWidget {
  const _NativeControlPanel({
    required this.enabled,
    required this.log,
    required this.onGetInfo,
    required this.onToast,
    required this.onAskFlutter,
  });

  final bool enabled;
  final List<String> log;
  final VoidCallback onGetInfo;
  final VoidCallback onToast;
  final VoidCallback onAskFlutter;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: <Widget>[
                _chip('Get info', Icons.info_outline, enabled ? onGetInfo : null),
                _chip('Send toast', Icons.campaign, enabled ? onToast : null),
                _chip('JS → Dart call', Icons.call_received, enabled ? onAskFlutter : null),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: log.length,
              itemBuilder: (BuildContext context, int i) => Text(
                log[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: onPressed),
    );
  }
}
