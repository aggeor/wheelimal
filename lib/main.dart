import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wheelimal/providers.dart';
import 'package:wheelimal/spin_wheel_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const Wheelimal(),
    ),
  );
}

class Wheelimal extends StatelessWidget {
  const Wheelimal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wheelimal',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      themeMode: ThemeMode.system,
      home: const SpinWheelPage(),
    );
  }
}
