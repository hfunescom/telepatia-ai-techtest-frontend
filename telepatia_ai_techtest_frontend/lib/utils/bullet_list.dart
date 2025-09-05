import 'package:flutter/widgets.dart';

/// Recursively builds a bullet list widget for maps and lists.
Widget buildBulletList(dynamic data) {
  return _build(data);
}

Widget _build(dynamic data) {
  if (data is Map) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in data.entries)
          _bulletRow(
            (entry.value is Map || entry.value is List)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key}:'),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _build(entry.value),
                      ),
                    ],
                  )
                : Text('${entry.key}: ${entry.value}'),
          ),
      ],
    );
  } else if (data is List) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in data) _bulletRow(_build(item)),
      ],
    );
  } else {
    return Text(data.toString());
  }
}

Widget _bulletRow(Widget child) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('• '),
      Expanded(child: child),
    ],
  );
}
