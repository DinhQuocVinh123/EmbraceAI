import 'dart:js_interop';

@JS('window.location.href')
external JSString get _href;

@JS('window.history.replaceState')
external void _replaceState(JSAny? data, JSString unused, JSString url);

/// Bỏ [name] khỏi địa chỉ đang hiện mà không tải lại trang hay thêm một mục
/// vào lịch sử trình duyệt.
void removeQueryParameter(String name) {
  final uri = Uri.parse(_href.toDart);
  if (!uri.queryParameters.containsKey(name)) return;
  final rest = Map.of(uri.queryParameters)..remove(name);
  final clean = Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    queryParameters: rest.isEmpty ? null : rest,
    fragment: uri.hasFragment ? uri.fragment : null,
  );
  _replaceState(null, ''.toJS, clean.toString().toJS);
}
