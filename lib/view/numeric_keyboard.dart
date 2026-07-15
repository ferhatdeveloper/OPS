import 'package:flutter/material.dart';

class NumericKeyboard extends StatefulWidget {
  final Function(String) onKeyPressed;
  final Function() onDone;
  final Function() onClear;
  final TextEditingController? controller;
  final String initialValue;

  const NumericKeyboard({
    Key? key,
    required this.onKeyPressed,
    required this.onDone,
    required this.onClear,
    this.controller,
    this.initialValue = '',
  }) : super(key: key);

  @override
  State<NumericKeyboard> createState() => _NumericKeyboardState();
}

class _NumericKeyboardState extends State<NumericKeyboard> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  void _handleKeyPress(String value) {
    setState(() {
      _currentValue += value;
    });
    widget.onKeyPressed(value);
    if (widget.controller != null) {
      // Update controller with the new value
      widget.controller!.text = _currentValue;
      // Position cursor at the end
      widget.controller!.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller!.text.length),
      );
    }
  }

  void _handleClear() {
    if (_currentValue.isNotEmpty) {
      setState(() {
        // Remove last character if there's text
        _currentValue = _currentValue.substring(0, _currentValue.length - 1);
      });

      if (widget.controller != null) {
        widget.controller!.text = _currentValue;
        // Position cursor at the end
        widget.controller!.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller!.text.length),
        );
      }
    } else {
      widget.onClear();
    }
  }

  Widget _buildKey(String text, VoidCallback onPressed, {Color? color}) {
    return Expanded(
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.white,
            foregroundColor:
                color == const Color(0xFFFF0000)
                    ? Colors.white
                    : Colors.black87,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: text == '✓' ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keyboard rows with wider buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1', () => _handleKeyPress('1')),
              _buildKey('2', () => _handleKeyPress('2')),
              _buildKey('3', () => _handleKeyPress('3')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4', () => _handleKeyPress('4')),
              _buildKey('5', () => _handleKeyPress('5')),
              _buildKey('6', () => _handleKeyPress('6')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7', () => _handleKeyPress('7')),
              _buildKey('8', () => _handleKeyPress('8')),
              _buildKey('9', () => _handleKeyPress('9')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('C', _handleClear, color: Colors.grey.shade200),
              _buildKey('0', () => _handleKeyPress('0')),
              _buildKey('✓', widget.onDone, color: const Color(0xFFFF0000)),
            ],
          ),
        ],
      ),
    );
  }
}
