import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = '';
  String _result = '0';
  bool _scientific = false;
  final List<String> _history = [];

  void _press(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expression = '';
          _result = '0';
          break;
        case '⌫':
          if (_expression.isNotEmpty) _expression = _expression.substring(0, _expression.length - 1);
          break;
        case '=':
          _evaluate();
          break;
        default:
          _expression += key;
      }
    });
  }

  void _evaluate() {
    try {
      final value = _Evaluator(_expression).parse();
      final formatted = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
      _result = formatted;
      _history.insert(0, '$_expression = $formatted');
      _expression = formatted;
    } catch (_) {
      _result = 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final basicKeys = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '.', '=', ''],
    ];
    final sciKeys = ['sin(', 'cos(', 'tan(', 'log(', 'ln(', '√(', '^', 'π', '(', ')'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Text('Calculator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Switch(value: _scientific, activeThumbColor: AppColors.accent, onChanged: (v) => setState(() => _scientific = v)),
              const Text('Scientific', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.bottomRight,
                          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppColors.border)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_expression, style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
                              Text(_result, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_scientific)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: sciKeys.map((k) => _KeyButton(label: k, onTap: () => _press(k), accent: false)).toList(),
                        ),
                      const SizedBox(height: 8),
                      ...basicKeys.map((row) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: row.map((k) => k.isEmpty ? const Spacer() : Expanded(child: _KeyButton(label: k, onTap: () => _press(k), accent: k == '='))).toList(),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.all(12), child: Text('History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Text(_history[i], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool accent;
  const _KeyButton({required this.label, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: accent ? AppColors.accent : AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(fontSize: 15, color: accent ? Colors.white : AppColors.textPrimary)),
          ),
        ),
      ),
    );
  }
}

/// Small recursive-descent expression evaluator — no need to pull in a
/// full math-expression package for basic + scientific calculator ops.
class _Evaluator {
  final String src;
  int pos = 0;
  _Evaluator(String input) : src = input.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-').replaceAll('π', math.pi.toString());

  double parse() {
    final v = _parseExpr();
    return v;
  }

  double _parseExpr() {
    var value = _parseTerm();
    while (pos < src.length && (src[pos] == '+' || src[pos] == '-')) {
      final op = src[pos++];
      final rhs = _parseTerm();
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  double _parseTerm() {
    var value = _parsePow();
    while (pos < src.length && (src[pos] == '*' || src[pos] == '/' || src[pos] == '%')) {
      final op = src[pos++];
      final rhs = _parsePow();
      if (op == '*') value *= rhs;
      if (op == '/') value /= rhs;
      if (op == '%') value %= rhs;
    }
    return value;
  }

  double _parsePow() {
    var value = _parseUnary();
    if (pos < src.length && src[pos] == '^') {
      pos++;
      final rhs = _parsePow();
      value = math.pow(value, rhs).toDouble();
    }
    return value;
  }

  double _parseUnary() {
    if (pos < src.length && src[pos] == '-') {
      pos++;
      return -_parseUnary();
    }
    return _parseAtom();
  }

  double _parseAtom() {
    if (pos < src.length && src[pos] == '(') {
      pos++;
      final v = _parseExpr();
      if (pos < src.length && src[pos] == ')') pos++;
      return v;
    }
    for (final fn in ['sin', 'cos', 'tan', 'log', 'ln', 'sqrt', '√']) {
      if (src.startsWith(fn, pos)) {
        pos += fn.length;
        if (pos < src.length && src[pos] == '(') pos++;
        final arg = _parseExpr();
        if (pos < src.length && src[pos] == ')') pos++;
        switch (fn) {
          case 'sin':
            return math.sin(arg);
          case 'cos':
            return math.cos(arg);
          case 'tan':
            return math.tan(arg);
          case 'log':
            return math.log(arg) / math.ln10;
          case 'ln':
            return math.log(arg);
          default:
            return math.sqrt(arg);
        }
      }
    }
    final start = pos;
    while (pos < src.length && (RegExp(r'[0-9.]').hasMatch(src[pos]))) {
      pos++;
    }
    if (start == pos) throw const FormatException('bad expr');
    return double.parse(src.substring(start, pos));
  }
}
