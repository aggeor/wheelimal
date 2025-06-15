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
  bool isSpinning = false;

  @override
  void initState() {
    updateControllers();
    super.initState();
  }

  @override
  void dispose() {
    selectedItem.close();
    newOptionController.dispose();
    for (var controller in controllers.values) {
      controller.dispose();
    }
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
      final newText = newOptionController.text.trim();
      if (newText.isEmpty || options.contains(newText)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The option already exists or is empty.')));
        return;
      }
      options.add(newText);
      controllers[options.length - 1] = TextEditingController(text: newText);
      newOptionController.clear();
    });
  }

  void editOption(int index) {
    TextEditingController? controller = controllers[index];
    if (controller != null) {
      controller.addListener(() {
        setState(() {
          options[index] = controller.text;
        });
      });
    }
  }

  void deleteOption(int index) {
    setState(() {
      if (options.length > 2) {
        options.removeAt(index);
        controllers.remove(index);
        updateControllers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('There must be at least 2 options.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).themeData;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Wheelimal',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  if (result.isNotEmpty)
                    Text(
                      result,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 50,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(
                    height: 300,
                    child: FortuneWheel(
                      selected: selectedItem.stream,
                      animateFirst: false,
                      items: options.map((option) {
                        final int optionCount = options.length;
                        const double baseFontSize = 24;
                        const int maxLength = 10;

                        // Reduce font size based on number of options and text length
                        double adjustedFontSize = baseFontSize -
                            ((option.length > maxLength
                                    ? option.length - maxLength
                                    : 0) *
                                0.8) -
                            ((optionCount > 6 ? optionCount - 6 : 0) * 1.0);

                        // Clamp font size to avoid being too small or too big
                        adjustedFontSize =
                            adjustedFontSize.clamp(10.0, baseFontSize);

                        return FortuneItem(
                          child: SizedBox(
                            width: 80,
                            child: Text(
                              option,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: adjustedFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onAnimationEnd: () {
                        setState(() {
                          result = options[selectedItem.value];
                          isSpinning = false;
                        });
                      },
                      onFling: () {
                        if (isSpinning) return;
                        setState(() {
                          isSpinning = true;
                          result = '';
                          selectedItem
                              .add(Fortune.randomInt(0, options.length));
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isSpinning
                        ? null
                        : () {
                            if (isSpinning) return;
                            setState(() {
                              isSpinning = true;
                              result = '';
                              selectedItem
                                  .add(Fortune.randomInt(0, options.length));
                            });
                          },
                    style: TextButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      'Spin the wheel!',
                      style: TextStyle(
                        color: theme.colorScheme.surface,
                        fontWeight: FontWeight.normal,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    children: [
                      ListTile(
                        title: TextField(
                          controller: newOptionController,
                          enabled: !isSpinning,
                          decoration: const InputDecoration.collapsed(
                              hintText: 'Add new option'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: isSpinning ? null : addOption,
                        ),
                      ),
                      ...List.generate(options.length, (index) {
                        return ListTile(
                          title: TextField(
                            controller: controllers[index],
                            enabled: !isSpinning,
                            onTap: () => editOption(index),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed:
                                isSpinning ? null : () => deleteOption(index),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
