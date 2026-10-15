// Connects this page to flutter_react_embed. Does nothing in a normal browser.
(function () {
  var native = window.__freNative;
  var pending = {};   // JS → Dart calls waiting for an answer
  var handlers = {};  // functions Dart can call
  var nextId = 1;

  function send(message) {
    if (native) native.postMessage(JSON.stringify(message));
  }

  window.FlutterBridge = {
    // True when running inside the Flutter app.
    isAvailable: !!native,

    // Latest props sent by Flutter (initialProps in Dart).
    props: {},

    // Let Dart call a JavaScript function: controller.invoke('name', params: ...)
    handle: function (method, fn) { handlers[method] = fn; },

    // Send an event to Dart: controller.events(name: 'name')
    emit: function (name, data) {
      send({ jsonrpc: '2.0', method: name, params: data === undefined ? {} : data });
    },

    // Call a Dart function and get a Promise: controller.registerHandler('name', ...)
    call: function (method, params) {
      if (!native) return Promise.reject(new Error('Not running inside Flutter'));
      var id = 'js-' + nextId++;
      return new Promise(function (resolve, reject) {
        pending[id] = { resolve: resolve, reject: reject };
        send({ jsonrpc: '2.0', id: id, method: method, params: params === undefined ? {} : params });
      });
    },
  };

  if (!native) return; // Opened in a normal browser: nothing else to do.

  window.__freReceive = async function (frame) {
    var message = JSON.parse(frame);
    var params = message.params || {};

    // Flutter sent new props.
    if (message.method === '$/mount' || message.method === '$/updateProps') {
      window.FlutterBridge.props = params.props || {};
      window.dispatchEvent(new CustomEvent('flutter:props', { detail: window.FlutterBridge.props }));
      return;
    }
    if (message.method === '$/unmount' || message.method === '$/cancelRequest') return;

    // Dart answered one of our FlutterBridge.call(...) calls.
    if (message.method === undefined && pending[message.id]) {
      var p = pending[message.id];
      delete pending[message.id];
      if (message.error) p.reject(Object.assign(new Error(message.error.message), message.error));
      else p.resolve(message.result);
      return;
    }

    // Dart sent an event: controller.emit('name', data)
    if (message.id === undefined || message.id === null) {
      window.dispatchEvent(new CustomEvent('flutter:event', { detail: { name: message.method, data: params } }));
      return;
    }

    // Dart called a JavaScript function: controller.invoke('name')
    var handler = handlers[message.method];
    if (!handler) {
      send({ jsonrpc: '2.0', id: message.id, error: { code: -32601, message: 'No JS handler for ' + message.method } });
      return;
    }
    try {
      var result = await handler(message.params);
      send({ jsonrpc: '2.0', id: message.id, result: result === undefined ? null : result });
    } catch (error) {
      send({
        jsonrpc: '2.0',
        id: message.id,
        error: { code: -32000, message: String(error && error.message || error), data: { stack: String(error && error.stack || '') } },
      });
    }
  };

  // First message: tells Flutter the page is ready. Required!
  send({ jsonrpc: '2.0', method: 'hello', params: {} });
})();
