// Demo glue between the CoreUI dashboard and the Flutter app.
(function () {
  var bridge = window.FlutterBridge;
  if (!bridge || !bridge.isAvailable) return;

  function route() {
    return { hash: location.hash || '#/', title: document.title };
  }

  // Dart: controller.invoke('getInfo')
  bridge.handle('getInfo', function () {
    var info = route();
    info.userAgent = navigator.userAgent;
    info.screen = window.innerWidth + 'x' + window.innerHeight;
    return info;
  });

  // Dart: controller.invoke('navigate', params: {'hash': '#/charts'})
  bridge.handle('navigate', function (params) {
    location.hash = params.hash;
    return route();
  });

  // React -> Flutter events.
  window.addEventListener('hashchange', function () { bridge.emit('route', route()); });
  document.addEventListener('click', function (e) {
    var el = e.target.closest && e.target.closest('a, button');
    if (el) bridge.emit('click', { text: (el.innerText || '').trim().slice(0, 40) });
  }, true);

  // Flutter props -> dashboard theme.
  function applyProps(props) {
    if (props.theme) document.documentElement.setAttribute('data-coreui-theme', props.theme);
  }
  window.addEventListener('flutter:props', function (e) { applyProps(e.detail); });

  // Flutter -> React events.
  window.addEventListener('flutter:event', function (e) {
    if (e.detail.name === 'toast') alert(e.detail.data.message);
  });
})();
