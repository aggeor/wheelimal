import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:wheelimal/color_picker.dart';
import 'package:wheelimal/providers.dart';

class SpinWheelPage extends StatefulWidget {
  const SpinWheelPage({super.key});
  @override
  State<SpinWheelPage> createState() => _SpinWheelPageState();
}

class _SpinWheelPageState extends State<SpinWheelPage> {
  // Reactive stream controller for wheel selection
  final BehaviorSubject<int> _selectedItem = BehaviorSubject<int>();

  // Wheel options management
  final List<String> _options = ['1', '2', '3', '4', '5'];
  final TextEditingController _newOptionController = TextEditingController();
  final Map<int, TextEditingController> _optionControllers = {};

  // Wheel state
  String _result = '';
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _selectedItem.close();
    _newOptionController.dispose();
    for (var controller in _optionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Initialize text controllers for options
  void _initializeControllers() {
    for (var i = 0; i < _options.length; i++) {
      _optionControllers[i] = TextEditingController(text: _options[i]);
      // Setup listener for each controller to handle text changes
      _setupControllerListener(i);
    }
  }

  // Setup listener for text controller changes
  void _setupControllerListener(int index) {
    _optionControllers[index]!.addListener(() {
      if (_options[index] != _optionControllers[index]!.text) {
        setState(() {
          _options[index] = _optionControllers[index]!.text;
        });
      }
    });
  }

  // Add new option to the wheel
  void _addOption() {
    setState(() {
      final newText = _newOptionController.text.trim();

      if (newText.isEmpty || _options.contains(newText)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The option already exists or is empty.'),
        ));
        return;
      }

      _options.add(newText);
      final newIndex = _options.length - 1;
      _optionControllers[newIndex] = TextEditingController(text: newText);
      _setupControllerListener(newIndex); // Add listener for the new controller
      _newOptionController.clear();
    });
  }

  // Delete an option from the wheel
  void _deleteOption(int index) {
    setState(() {
      if (_options.length > 2) {
        // Dispose the controller before removing it
        _optionControllers[index]!.dispose();
        _optionControllers.remove(index);
        _options.removeAt(index);

        // Reinitialize controllers to handle index changes
        _initializeControllers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('There must be at least 2 options.')),
        );
      }
    });
  }

  // Spin the wheel
  void _spinWheel() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _result = '';
      _selectedItem.add(Fortune.randomInt(0, _options.length));
    });
  }

  // Handle wheel animation completion
  void _handleWheelAnimationEnd() {
    setState(() {
      _result = _options[_selectedItem.value];
      _isSpinning = false;
    });
  }

  // Show color picker dialog
  void _showColorPickerDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    Color initialColor = themeProvider.seedColor;

    showDialog(
      context: context,
      builder: (context) => ColorWheelPickerDialog(initialColor: initialColor),
    );
  }

  // Calculate font size based on option text and count
  double _calculateFontSize(String option) {
    const double baseFontSize = 24;
    const int maxLength = 10;
    final int optionCount = _options.length;

    double fontSize = baseFontSize;

    // Adjust for text length
    if (option.length > maxLength) {
      fontSize -= (option.length - maxLength) * 0.8;
    }

    // Adjust for number of options
    if (optionCount > 6) {
      fontSize -= (optionCount - 6) * 1.0;
    }

    // Clamp between min and max
    return fontSize.clamp(10.0, baseFontSize);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).themeData;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
    );
  }

  // App bar component
  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
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
          onPressed: _showColorPickerDialog,
          icon: const Icon(Icons.palette),
          tooltip: 'Choose color',
        ),
        IconButton(
          onPressed: () =>
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
          icon: Icon(
            theme.brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
        ),
      ],
    );
  }

  // Main content body
  Widget _buildBody(ThemeData theme) {
    return LayoutBuilder(
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
                if (_result.isNotEmpty) _buildResultText(theme),
                _buildWheel(theme),
                const SizedBox(height: 12),
                _buildSpinButton(theme),
                const SizedBox(height: 12),
                _buildOptionsList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Result display text
  Widget _buildResultText(ThemeData theme) {
    return Text(
      _result,
      style: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 50,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  // Fortune wheel component
  Widget _buildWheel(ThemeData theme) {
    return SizedBox(
      height: 300,
      child: FortuneWheel(
        selected: _selectedItem.stream,
        animateFirst: false,
        items: _options.map((option) {
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
                  fontSize: _calculateFontSize(option),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
        onAnimationEnd: _handleWheelAnimationEnd,
        onFling: _spinWheel,
      ),
    );
  }

  // Spin button
  Widget _buildSpinButton(ThemeData theme) {
    return TextButton(
      onPressed: _isSpinning ? null : _spinWheel,
      style: TextButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      child: Text(
        'Spin the wheel!',
        style: TextStyle(
          color: theme.colorScheme.surface,
          fontWeight: FontWeight.normal,
          fontSize: 20,
        ),
      ),
    );
  }

  // Options list
  Widget _buildOptionsList() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      children: [
        _buildAddOptionTile(),
        ..._buildOptionTiles(),
      ],
    );
  }

  // Add new option tile
  Widget _buildAddOptionTile() {
    return ListTile(
      title: TextField(
        controller: _newOptionController,
        enabled: !_isSpinning,
        decoration: const InputDecoration.collapsed(
          hintText: 'Add new option',
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add),
        onPressed: _isSpinning ? null : _addOption,
      ),
    );
  }

  // List of option tiles
  List<Widget> _buildOptionTiles() {
    return List.generate(_options.length, (index) {
      return ListTile(
        title: TextField(
          controller: _optionControllers[index],
          enabled: !_isSpinning,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _isSpinning ? null : () => _deleteOption(index),
        ),
      );
    });
  }
}
