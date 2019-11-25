import 'dart:ui';

import 'package:flutter/material.dart';

class ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path(); // the starting point is the 0,0 position of the widget.
    path.quadraticBezierTo(size.width - 150, size.height / 2, 0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close(); // this closes the loop from current position to the starting point of widget
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
