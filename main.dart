import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = "0";
  String _result = "";
  List<String> _history = [];
  bool _isNewEquation = true;
  int _bracketCount = 0;

  final Map<String, IconData> operatorIcons = {
    '+': Icons.add,
    '-': Icons.remove,
    '×': Icons.close,
    '÷': Icons.horizontal_split, // Using a horizontal split icon for division
    '%': Icons.percent,
  };

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (_isNewEquation &&
          !isOperator(buttonText) &&
          buttonText != 'C' &&
          buttonText != '⌫' &&
          buttonText != '( )') {
        _expression = buttonText;
        _isNewEquation = false;
      } else {
        switch (buttonText) {
          case 'C':
            _expression = "0";
            _result = "";
            _isNewEquation = true;
            _bracketCount = 0;
            break;
          case '⌫':
            if (_expression.length > 1) {
              if (_expression[_expression.length - 1] == '(') {
                _bracketCount--;
              } else if (_expression[_expression.length - 1] == ')') {
                _bracketCount++;
              }
              _expression = _expression.substring(0, _expression.length - 1);
            } else {
              _expression = "0";
              _isNewEquation = true;
            }
            break;
          case '( )':
            if (_expression == "0") {
              _expression = "(";
              _bracketCount++;
              _isNewEquation = false;
            } else if (_bracketCount > 0 &&
                !endsWithOperator(_expression) &&
                !_expression.endsWith('(')) {
              _expression += ")";
              _bracketCount--;
            } else {
              _expression += "(";
              _bracketCount++;
            }
            break;
          case '=':
            try {
              // Close any open brackets before calculating
              String tempExpr = _expression;
              for (int i = 0; i < _bracketCount; i++) {
                tempExpr += ")";
              }
              String result = calculateResult(tempExpr);
              if (result != "Error") {
                _history.add("$_expression = $result");
                _expression = result;
                _result = "";
                _isNewEquation = true;
                _bracketCount = 0;
              } else {
                _result = "Error";
              }
            } catch (e) {
              _result = "Error";
            }
            break;
          case '.':
            if (_canAddDecimal()) {
              _expression += buttonText;
            }
            break;
          default:
            if (isOperator(buttonText)) {
              if (!endsWithOperator(_expression)) {
                _expression += buttonText;
                _isNewEquation = false;
              } else if (buttonText == '-' && _canAddNegative()) {
                _expression += buttonText;
              }
            } else {
              if (_isNewEquation) {
                _expression = buttonText;
                _isNewEquation = false;
              } else {
                _expression += buttonText;
              }
            }
        }
      }
      if (buttonText != '=' && _expression != "0") {
        try {
          _result = calculateResult(_expression);
        } catch (e) {
          _result = "";
        }
      }
    });
  }

  bool _canAddDecimal() {
    String lastNumber = _getLastNumber();
    return !lastNumber.contains('.');
  }

  String _getLastNumber() {
    List<String> numbers = _expression.split(RegExp(r'[+\-×÷%()]'));
    return numbers.isEmpty ? "" : numbers.last;
  }

  bool _canAddNegative() {
    if (_expression.isEmpty) return true;
    String lastChar = _expression[_expression.length - 1];
    return lastChar == '×' || lastChar == '÷' || lastChar == '(';
  }

  bool isOperator(String text) {
    return ['+', '-', '×', '÷', '%'].contains(text);
  }

  bool endsWithOperator(String text) {
    return text.isNotEmpty && isOperator(text[text.length - 1]);
  }

  String calculateResult(String expr) {
    try {
      // Handle empty or simple cases
      if (expr.isEmpty || expr == "0") return "0";

      // Handle percentages
      expr = _handlePercentages(expr);

      // Convert operators to calculable format
      expr = expr.replaceAll('×', '*').replaceAll('÷', '/');

      // Evaluate the expression
      double result = _evaluateExpression(expr);

      // Format the result
      if (result == result.roundToDouble()) {
        return result.round().toString();
      } else {
        return result
            .toStringAsFixed(8)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
    } catch (e) {
      return "Error";
    }
  }

  String _handlePercentages(String expr) {
    while (expr.contains('%')) {
      int index = expr.indexOf('%');
      int start = index - 1;
      while (start >= 0 &&
          (RegExp(r'[0-9.]').hasMatch(expr[start]) ||
              (start == 0 && expr[start] == '-'))) {
        start--;
      }
      start++;
      String number = expr.substring(start, index);
      double percentage = double.parse(number) / 100;
      expr = expr.replaceRange(start, index + 1, percentage.toString());
    }
    return expr;
  }

  double _evaluateExpression(String expr) {
    List<String> tokens = _tokenize(expr);
    List<String> postfix = _infixToPostfix(tokens);
    return _evaluatePostfix(postfix);
  }

  List<String> _tokenize(String expr) {
    List<String> tokens = [];
    String number = '';
    bool isNegative = false;

    for (int i = 0; i < expr.length; i++) {
      String char = expr[i];
      if (char == '-' && (i == 0 || '*/+-'.contains(expr[i - 1]))) {
        isNegative = true;
      } else if ('0123456789.'.contains(char)) {
        number += char;
      } else if ('*/+-'.contains(char)) {
        if (number.isNotEmpty) {
          tokens.add(isNegative ? '-$number' : number);
          number = '';
          isNegative = false;
        }
        tokens.add(char);
      }
    }
    if (number.isNotEmpty) {
      tokens.add(isNegative ? '-$number' : number);
    }
    return tokens;
  }

  List<String> _infixToPostfix(List<String> tokens) {
    List<String> output = [];
    List<String> operators = [];

    for (String token in tokens) {
      if (!isOperator(token.replaceAll('*', '×').replaceAll('/', '÷'))) {
        output.add(token);
      } else {
        while (operators.isNotEmpty &&
            _getPrecedence(operators.last) >= _getPrecedence(token)) {
          output.add(operators.removeLast());
        }
        operators.add(token);
      }
    }

    while (operators.isNotEmpty) {
      output.add(operators.removeLast());
    }

    return output;
  }

  int _getPrecedence(String operator) {
    switch (operator) {
      case '*':
      case '/':
        return 2;
      case '+':
      case '-':
        return 1;
      default:
        return 0;
    }
  }

  double _evaluatePostfix(List<String> postfix) {
    List<double> stack = [];

    for (String token in postfix) {
      if (!isOperator(token.replaceAll('*', '×').replaceAll('/', '÷'))) {
        stack.add(double.parse(token));
      } else {
        double b = stack.removeLast();
        double a = stack.removeLast();
        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) throw Exception('Division by zero');
            stack.add(a / b);
            break;
        }
      }
    }

    return stack.first;
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _history.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _history[index],
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton(String text, {Color? color, IconData? icon}) {
    // Use operator icons if available
    if (operatorIcons.containsKey(text)) {
      icon = operatorIcons[text];
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: color ?? Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _onButtonPressed(text),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 24)
                    : Text(
                        text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: _showHistory,
                          iconSize: 28,
                        ),
                        Expanded(
                          child: Text(
                            _expression,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    if (_result.isNotEmpty && _result != "Error")
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "= $_result",
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("C",
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.2)),
                          _buildButton("( )",
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2)),
                          _buildButton("%"),
                          _buildButton("÷", icon: Icons.horizontal_split),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("7"),
                          _buildButton("8"),
                          _buildButton("9"),
                          _buildButton("×"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("4"),
                          _buildButton("5"),
                          _buildButton("6"),
                          _buildButton("-"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("1"),
                          _buildButton("2"),
                          _buildButton("3"),
                          _buildButton("+"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton("0"),
                          _buildButton("."),
                          _buildButton("⌫", icon: Icons.backspace_outlined),
                          _buildButton("=",
                              color: Theme.of(context).primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
