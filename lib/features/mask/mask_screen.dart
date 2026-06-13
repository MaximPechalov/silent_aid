import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../emergency/emergency_screen.dart';
import '../../app/app_colors.dart';

class MaskScreen extends StatefulWidget {
  const MaskScreen({super.key});

  @override
  State<MaskScreen> createState() => _MaskScreenState();
}

class _MaskScreenState extends State<MaskScreen> {
  String _display = '0';
  double _firstNumber = 0;
  String _operator = '';
  bool _isNewNumber = true;
  String _codeBuffer = '';
  
  static const String _secretCode = '112';
  
  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
        _firstNumber = 0;
        _operator = '';
        _isNewNumber = true;
        _codeBuffer = '';
      }
      else if (key == '=') {
        _checkForSecretCode();
        _calculate();
      }
      else if (key == '+' || key == '-' || key == '×' || key == '÷') {
        _firstNumber = double.parse(_display);
        _operator = key;
        _isNewNumber = true;
      }
      else {
        if (_isNewNumber) {
          _display = key;
          _isNewNumber = false;
        } else {
          _display += key;
        }
        _codeBuffer += key;
        if (_codeBuffer.length > _secretCode.length) {
          _codeBuffer = _codeBuffer.substring(1);
        }
      }
    });
  }
  
  void _checkForSecretCode() {
    if (_codeBuffer == _secretCode) {
      _activateEmergency();
    }
  }
  
  void _calculate() {
    final double secondNumber = double.parse(_display);
    double result = 0;
    
    switch (_operator) {
      case '+':
        result = _firstNumber + secondNumber;
        break;
      case '-':
        result = _firstNumber - secondNumber;
        break;
      case '×':
        result = _firstNumber * secondNumber;
        break;
      case '÷':
        if (secondNumber != 0) {
          result = _firstNumber / secondNumber;
        }
        break;
      default:
        return;
    }
    
    _display = result.toString().endsWith('.0')
        ? result.toInt().toString()
        : result.toString();
    _operator = '';
    _isNewNumber = true;
  }
  
  void _activateEmergency() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmergencyScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calculatorBackground,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 64,
                  color: AppColors.calculatorDisplay,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _buildButtonRow(['C', '±', '%', '÷']),
                _buildButtonRow(['7', '8', '9', '×']),
                _buildButtonRow(['4', '5', '6', '-']),
                _buildButtonRow(['1', '2', '3', '+']),
                _buildButtonRow(['0', '.', '=']),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildButtonRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((key) => _buildButton(key)).toList(),
      ),
    );
  }
  
  Widget _buildButton(String key) {
    Color backgroundColor;
    Color textColor;
    
    if (key == 'C' || key == '±' || key == '%') {
      backgroundColor = AppColors.calculatorSpecial;
      textColor = Colors.black;
    } else if (key == '÷' || key == '×' || key == '-' || key == '+' || key == '=') {
      backgroundColor = AppColors.calculatorOperator;
      textColor = Colors.white;
    } else {
      backgroundColor = AppColors.calculatorNumber;
      textColor = Colors.white;
    }
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _onKeyPressed(key),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          child: Text(
            key,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}