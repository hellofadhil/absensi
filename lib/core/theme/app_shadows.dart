import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const primary = <BoxShadow>[
    BoxShadow(color: Color(0x1F0A84FF), blurRadius: 18, offset: Offset(0, 7)),
  ];

  static const ai = <BoxShadow>[
    BoxShadow(color: Color(0x1A8B5CF6), blurRadius: 18, offset: Offset(0, 7)),
  ];
}
