import 'dart:typed_data';

import 'package:flutter/material.dart';

class DraftPhoto extends StatelessWidget {
  const DraftPhoto({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.memory(
      bytes,
      height: 210,
      width: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: 'Selected issue photo',
      errorBuilder: (_, error, stack) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Unable to display this photo. Please replace it.'),
      ),
    ),
  );
}
