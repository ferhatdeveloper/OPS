import 'package:flutter/material.dart';

class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({Key? key}) : super(key: key);

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  String _displayValue = '0';
  String _currentNumber = '';
  double _firstOperand = 0;
  String _operation = '';
  bool _resetDisplay = false;
  bool _hasDecimal = false;

  void _onDigitPressed(String digit) {
    setState(() {
      if (_resetDisplay) {
        _displayValue = digit;
        _resetDisplay = false;
        _currentNumber = digit;
      } else {
        // Eğer ekranda sadece 0 varsa, yeni rakamı ekrana yaz
        if (_displayValue == '0' && digit != '.') {
          _displayValue = digit;
          _currentNumber = digit;
        } else {
          // Ondalık kontrolü
          if (digit == '.' && _hasDecimal) {
            return; // Zaten ondalık var, tekrar eklemeye gerek yok
          }
          if (digit == '.') {
            _hasDecimal = true;
          }
          _displayValue = _displayValue + digit;
          _currentNumber = _currentNumber + digit;
        }
      }
    });
  }

  void _onOperationPressed(String operation) {
    setState(() {
      if (_operation.isNotEmpty && _currentNumber.isNotEmpty) {
        _calculateResult();
      }

      _firstOperand = double.parse(_displayValue);
      _operation = operation;
      _resetDisplay = true;
      _hasDecimal = false;
      _currentNumber = '';
    });
  }

  void _calculateResult() {
    if (_currentNumber.isEmpty) return;

    double secondOperand = double.parse(_currentNumber);
    double result = 0;

    switch (_operation) {
      case '+':
        result = _firstOperand + secondOperand;
        break;
      case '-':
        result = _firstOperand - secondOperand;
        break;
      case 'x':
        result = _firstOperand * secondOperand;
        break;
      case '÷':
        if (secondOperand != 0) {
          result = _firstOperand / secondOperand;
        } else {
          // Sıfıra bölme hatası
          setState(() {
            _displayValue = 'Hata';
            _resetDisplay = true;
            _operation = '';
            _firstOperand = 0;
            _currentNumber = '';
            _hasDecimal = false;
          });
          return;
        }
        break;
    }

    setState(() {
      // Sonuç tam sayı ise ondalık kısmı gösterme
      if (result == result.toInt()) {
        _displayValue = result.toInt().toString();
      } else {
        _displayValue = result.toString();
        // Çok uzun ondalık sayıları kısalt
        if (_displayValue.length > 10) {
          _displayValue = result.toStringAsFixed(8);
        }
      }

      _firstOperand = result;
      _operation = '';
      _resetDisplay = true;
      _currentNumber = '';
      _hasDecimal = _displayValue.contains('.');
    });
  }

  void _clearAll() {
    setState(() {
      _displayValue = '0';
      _firstOperand = 0;
      _operation = '';
      _resetDisplay = false;
      _currentNumber = '';
      _hasDecimal = false;
    });
  }

  void _clearEntry() {
    setState(() {
      _displayValue = '0';
      _currentNumber = '';
      _hasDecimal = false;
    });
  }

  void _negate() {
    setState(() {
      if (_displayValue.startsWith('-')) {
        _displayValue = _displayValue.substring(1);
      } else {
        _displayValue = '-$_displayValue';
      }
      _currentNumber = _displayValue;
    });
  }

  void _calculatePercentage() {
    setState(() {
      double value = double.parse(_displayValue);
      value = value / 100;

      if (value == value.toInt()) {
        _displayValue = value.toInt().toString();
      } else {
        _displayValue = value.toString();
      }

      _currentNumber = _displayValue;
      _hasDecimal = _displayValue.contains('.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Ekran
          Container(
            width: double.infinity,
            height: 70,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF23252F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _displayValue,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          // Tuş takımı
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 1.2,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // İlk satır
                _buildCalculatorButton('C', Colors.red[400]!, _clearAll),
                _buildCalculatorButton('CE', Colors.amber[700]!, _clearEntry),
                _buildCalculatorButton(
                  '%',
                  Colors.amber[700]!,
                  _calculatePercentage,
                ),
                _buildCalculatorButton(
                  '÷',
                  Colors.amber[700]!,
                  () => _onOperationPressed('÷'),
                ),

                // İkinci satır
                _buildCalculatorButton(
                  '7',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('7'),
                ),
                _buildCalculatorButton(
                  '8',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('8'),
                ),
                _buildCalculatorButton(
                  '9',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('9'),
                ),
                _buildCalculatorButton(
                  'x',
                  Colors.amber[700]!,
                  () => _onOperationPressed('x'),
                ),

                // Üçüncü satır
                _buildCalculatorButton(
                  '4',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('4'),
                ),
                _buildCalculatorButton(
                  '5',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('5'),
                ),
                _buildCalculatorButton(
                  '6',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('6'),
                ),
                _buildCalculatorButton(
                  '-',
                  Colors.amber[700]!,
                  () => _onOperationPressed('-'),
                ),

                // Dördüncü satır
                _buildCalculatorButton(
                  '1',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('1'),
                ),
                _buildCalculatorButton(
                  '2',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('2'),
                ),
                _buildCalculatorButton(
                  '3',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('3'),
                ),
                _buildCalculatorButton(
                  '+',
                  Colors.amber[700]!,
                  () => _onOperationPressed('+'),
                ),

                // Beşinci satır
                _buildCalculatorButton(
                  '=',
                  Colors.blue[600]!,
                  _calculateResult,
                ),
                _buildCalculatorButton(
                  '.',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('.'),
                ),
                _buildCalculatorButton(
                  '0',
                  const Color(0xFF3A3D4C),
                  () => _onDigitPressed('0'),
                ),
                _buildCalculatorButton('+/-', const Color(0xFF3A3D4C), _negate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorButton(
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
