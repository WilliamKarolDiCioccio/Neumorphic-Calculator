import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:neumorphic_calculator/utils/enum.dart';
import 'package:neumorphic_calculator/utils/result_model.dart';
import 'dart:math' as math;

var logger = Logger(
  printer: PrettyPrinter(),
);

extension CalculatorExtension on String {
  String get input => this;

  ResultModel calculate({bool skipErrorChecking = false, Parser? parser}) {
    Parser p = parser ?? Parser();
    // TODO: check for mismatch parenthesis and fix it, use mapslitjoin to check every open parenthesis
    String finalInput =
        _replaceOperationSymbols.removeCommas.replaceAll('√', 'sqrt');
    bool hasDouble = finalInput.contains('.');
    try {
      Expression exp = p.parse(finalInput);
      ContextModel ctxModel = ContextModel();
      ctxModel.bindVariableName('π', Number(math.pi));
      double eval = exp.evaluate(EvaluationType.REAL, ctxModel);
      if (eval % 1 == 0 && !hasDouble) {
        return ResultModel(
            output: eval.toInt().toString(),
            expression: this,
            dateTime: DateTime.now());
      } else {
        return ResultModel(
            output: eval.toString(),
            expression: this,
            dateTime: DateTime.now());
      }
    } catch (e, stack) {
      logger.f(e.toString(), stackTrace: stack, error: e);
      if (skipErrorChecking) {
        return ResultModel.empty();
      } else {
        return ResultModel.formatError();
      }
    }
  }

  bool get isNumber =>
      double.tryParse(input) != null || int.tryParse(input) != null;
  bool get isDouble => double.tryParse(input) != null;
  bool get isInt => int.tryParse(input) != null;

  String get toFraction {
    if (!isDouble) return input;
    double number = double.tryParse(input.removeCommas)!;
    MixedFraction fraction = MixedFraction.fromDouble(number);
    return fraction.toString();
  }

  bool get canCalculate {
    if (input.isEmpty ||
        !input.containsAny([
          'x',
          '÷',
          '+',
          '-',
          ...ScientificButton.values
              .map((e) => e.value.replaceAll('(', '').replaceAll(')', ''))
        ])) {
      return false;
    }
    if (input.endsWithAny(['x', '÷', '+', '-'])) {
      return false;
    }
    return true;
  }

  int count(String countValue) {
    return input.characters.where((val) => val == countValue).length;
  }

  String formatExpression() {
    String expression = removeSpaces.removeCommas;
    String parts = expression.splitMapJoin(
      RegExp(r"[+\-x÷%()]"),
      onMatch: (m) => m.group(0) ?? '',
      onNonMatch: (n) {
        if (n.isEmpty) return '';
        // Prevent formatting number above 20 length
        // otherwise NumberFormat will throw an error
        if (n.length > 19) {
          return n.substring(0, 19).formatThousands();
        }
        return n.formatThousands();
      },
    );
    return parts;
  }

  String formatThousands() {
    try {
      // To avoid formatting the number if it contains an error
      if (input.toLowerCase().contains('error')) {
        return input;
      }
      //

      String number = input.removeCommas;
      if (number.removeSpaces.isEmpty) return number;
      String? trigonometry;
      // Remove sin, cos, tan, log and add them later
      if (number.containsAny(['sin', 'cos', 'tan', 'log', 'e', 'π'])) {
        // Remove all numbers and () from the string
        trigonometry = number.replaceAll(RegExp(r'[0-9()]'), '');
        number = number.replaceAll(RegExp(r'[a-zA-Zπ]'), '');
      }

      if (number.isEmpty) {
        return trigonometry ?? number;
      }

      if (!number.isNumber) {
        throw Exception('Not a number to format $number');
      }

      final isInt = !number.contains('.');
      String formattedString;
      if (isInt) {
        NumberFormat formatter = NumberFormat("#,###");
        formattedString = formatter.format(int.tryParse(number));
      } else {
        formattedString = number._formatDouble;
      }

      if (trigonometry == null) return formattedString;
      if (trigonometry.length > 1) {
        return '$trigonometry($formattedString)';
      } else {
        return '$trigonometry$formattedString';
      }
    } catch (e, stack) {
      logger.f(e.toString(), stackTrace: stack, error: e);
      return this;
    }
  }

  String get _replaceOperationSymbols {
    String finalInput = input;
    finalInput = finalInput
        .replaceAll('x', '*')
        .replaceAll('÷', '/')
        .replaceAll('%', '/100');
    return finalInput;
  }

  (String, int) insertScienticButton(ScientificButton value, int offset) {
    try {
      final firstPart = input.substring(0, offset);
      final lastPart = input.substring(offset);

      return (firstPart + value.value + lastPart, offset + value.value.length);
    } catch (e, stack) {
      logger.f(e.toString(), stackTrace: stack, error: e);
      return (input, offset);
    }
  }

  (String, int) insertText(String value, int offset,
      {bool skipFormatting = false}) {
    try {
      final firstPart = input.substring(0, offset);
      final lastPart = input.substring(offset);
      // To avoid adding multiple operators in a row
      if (firstPart.endsWithAny(['x', '÷', '+', '-', '%']) && !value.isNumber) {
        return (firstPart.substring(0, offset - 1) + value + lastPart, offset);
      } else if (lastPart.startsWithAny(['x', '÷', '+', '-', '%']) &&
          !value.isNumber) {
        return (firstPart + value + lastPart.substring(1), offset);
      } else {
        // insering a number
        String result;
        int difference;
        if (skipFormatting) {
          result = (firstPart + value + lastPart);
          difference = 0;
        } else {
          result = (firstPart + value + lastPart).formatExpression();
          // Calculate the difference because formatExpression can add ','
          // which will mess up the original offset
          difference = (result.length - input.length).abs();
        }

        return (result, offset + difference);
      }
    } catch (e, stack) {
      logger.f(e.toString(), stackTrace: stack, error: e);
      return (input, offset);
    }
  }

  String get removeLastChar => input.substring(0, input.length - 1);

  (String, int) removeCharAt(int offset) {
    try {
      final firstPartWithoutLastCharacter = input.substring(0, offset - 1);
      final lastPart = input.substring(offset);
      final oldOffset = offset;
      final updatedText = firstPartWithoutLastCharacter + lastPart;
      final formattedText = updatedText.formatExpression();
      final difference = (formattedText.length - input.length).abs();
      return (updatedText, oldOffset - difference);
    } catch (e, stack) {
      logger.f(e.toString(), stackTrace: stack);
      return (input, offset);
    }
  }

  String get _formatDouble {
    String number = this;
    bool shouldAddDecimal = number.characters.last == '.';

    // Remove trailing decimal point if there is more than one decimal point
    if (number.endsWith('.') &&
        number.substring(0, number.length - 1).contains('.')) {
      shouldAddDecimal = false;
      number = number.substring(0, number.length - 1);
    }
    final numOfDecimalPlaces =
        number.split('.').last == '0' ? 1 : number.split('.').last.length;
    NumberFormat formatter =
        NumberFormat.decimalPatternDigits(decimalDigits: numOfDecimalPlaces);
    return formatter.format(double.tryParse(number)) +
        (shouldAddDecimal ? '.' : '');
  }
}

extension StringExtension on String {
  String get capitilize => this[0].toUpperCase() + substring(1);

  String get removeSpaces => replaceAll(' ', '');

  bool endsWithAny(List<String> suffixes) {
    for (final suffix in suffixes) {
      if (endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }

  bool startsWithAny(List<String> prefixes) {
    for (final prefix in prefixes) {
      if (startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  bool containsAny(List<String> substrings) {
    for (final substring in substrings) {
      if (contains(substring)) {
        return true;
      }
    }
    return false;
  }

  String get removeCommas => input.replaceAll(',', '');
  int get commaCount => input.characters.where((val) => val == ',').length;
}
