import 'package:flutter/material.dart';

class DunotsHomeShell extends StatefulWidget {
  const DunotsHomeShell({super.key});

  @override
  State<DunotsHomeShell> createState() => _DunotsHomeShellState();
}

class _DunotsHomeShellState extends State<DunotsHomeShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Shell temporário')));
  }
}
