import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../emergency/emergency_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/prefs_service.dart';

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
  String _secretCode = '112';
  bool _isLoaded = false;
  
  final Map<String, bool> _buttonPressed = {};
  
  @override
  void initState() {
    super.initState();
    _loadSecretCode();
  }
  
  Future<void> _loadSecretCode() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsService = PrefsService(prefs);
    setState(() {
      _secretCode = prefsService.getSecretCode();
      _isLoaded = true;
    });
  }
  
  void _onKeyPressed(String key) {
    setState(() {
      _buttonPressed[key] = true;
    });
    
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
    
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _buttonPressed[key] = false;
        });
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
    try {
      final bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 100);
      }
    } catch (_) {}
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmergencyScreen()),
      );
    }
  }
  
  void _openSettings() {
    debugPrint('=== ОТКРЫТИЕ НАСТРОЕК (долгое нажатие на %) ===');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
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
                  color: Colors.white,
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
    Color baseColor;
    Color pressedColor;
    Color textColor;
    
    if (key == 'C' || key == '±' || key == '%') {
      baseColor = const Color(0xFFD4D4D2);
      pressedColor = const Color(0xFFA8A8A6);
      textColor = Colors.black;
    } else if (key == '÷' || key == '×' || key == '-' || key == '+' || key == '=') {
      baseColor = const Color(0xFFFF9500);
      pressedColor = const Color(0xFFCC7700);
      textColor = Colors.white;
    } else {
      baseColor = const Color(0xFF505050);
      pressedColor = const Color(0xFF707070);
      textColor = Colors.white;
    }
    
    final bool isPressed = _buttonPressed[key] ?? false;
    final Color currentColor = isPressed ? pressedColor : baseColor;
    
    if (key == '%') {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: GestureDetector(
            onLongPress: _openSettings,
            onTapDown: (_) {
              setState(() {
                _buttonPressed[key] = true;
              });
            },
            onTapUp: (_) {
              setState(() {
                _buttonPressed[key] = false;
              });
              _onKeyPressed(key);
            },
            onTapCancel: () {
              setState(() {
                _buttonPressed[key] = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: GestureDetector(
          onTapDown: (_) {
            setState(() {
              _buttonPressed[key] = true;
            });
          },
          onTapUp: (_) {
            setState(() {
              _buttonPressed[key] = false;
            });
            _onKeyPressed(key);
          },
          onTapCancel: () {
            setState(() {
              _buttonPressed[key] = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
