import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:wheelimal/providers.dart';

class SpinWheelPage extends StatefulWidget {
  const SpinWheelPage({super.key});
  @override
  State<SpinWheelPage> createState() => _SpinWheelPageState();
}

class _SpinWheelPageState extends State<SpinWheelPage> {
  final selectedItem = BehaviorSubject<int>();
  final options = ['1', '2', '3', '4', '5'];
  String result = '';
  final newOptionController = TextEditingController();
  Map<int, TextEditingController> controllers = {};

  @override
  void initState() {
    updateControllers();
    super.initState();
  }

  @override
  void dispose() {
    selectedItem.close();
    super.dispose();
  }

  void updateControllers() {
    controllers.clear();
    for (var i = 0; i < options.length; i++) {
      controllers[i] = TextEditingController(text: options[i]);
    }
  }

  void addOption() {
    setState(() {
      if (options.contains(newOptionController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The option already exists. Add a new one.')));
        return;
      }
      options.add(newOptionController.text);
      controllers.addAll({
        options.length - 1:
            TextEditingController(text: newOptionController.text)
      });
      newOptionController.clear();
    });
  }

  void editOption(int index) {
    TextEditingController? controller = controllers[index];
    if (controller != null) {
      controller.addListener(
        () {
          setState(
            () {
              options[index] = controllers[index]?.text ?? '';
            },
          );
        },
      );
    }
  }

  void deleteOption(index) {
    setState(() {
      if (options.length > 2) {
        options.removeWhere((item) => options.indexOf(item) == index);
        controllers.remove(index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('There must be at least 2 options.')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wheelimal',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context)
                .themeData
                .colorScheme
                .primary,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: const Icon(Icons.dark_mode),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Spin the wheel!',
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context)
                    .themeData
                    .colorScheme
                    .primary,
                fontWeight: FontWeight.normal,
                fontSize: 20,
              ),
            ),
            result != ''
                ? Text(
                    result,
                    style: TextStyle(
                      color: Provider.of<ThemeProvider>(context)
                          .themeData
                          .colorScheme
                          .primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 50,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox(
                    height: 3,
                  ),
            SizedBox(
              height: 300,
              child: FortuneWheel(
                selected: selectedItem.stream,
                animateFirst: false,
                items: [
                  ...options.map(
                    (option) => FortuneItem(
                      child: Text(option),
                    ),
                  ),
                ],
                onAnimationEnd: () {
                  setState(() {
                    result = options[selectedItem.value];
                  });
                },
                onFling: () {
                  setState(() {
                    selectedItem.add(Fortune.randomInt(0, options.length));
                  });
                },
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Expanded(
                child: ListView(
              children: [
                ListTile(
                  title: TextField(
                    controller: newOptionController,
                    decoration: const InputDecoration.collapsed(
                        hintText: 'Add new option'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: addOption,
                  ),
                ),
                ...options.map(
                  (option) => ListTile(
                    title: TextField(
                      controller: controllers[options.indexOf(option)],
                      onTap: () {
                        editOption(options.indexOf(option));
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        deleteOption(options.indexOf(option));
                        updateControllers();
                      },
                    ),
                  ),
                )
              ],
            )),
          ],
        ),
      ),
    );
  }
}
