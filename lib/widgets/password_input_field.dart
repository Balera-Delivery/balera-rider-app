import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool isOutlined;

  const PasswordInputField({
    super.key,
    required this.controller,
    this.hintText = 'Enter your password',
    this.labelText,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.isOutlined = false,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _clearText() {
    widget.controller.clear();
    _focusNode.requestFocus();
    if (widget.onChanged != null) {
      widget.onChanged!('');
    }
    setState(() {});
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
    // Keep focus attached to the input field so typing continues seamlessly on Web
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    final suffixActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasText)
          IconButton(
            icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textMuted),
            onPressed: _clearText,
            tooltip: 'Clear password',
            splashRadius: 18,
          ),
        IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          onPressed: _toggleObscure,
          tooltip: _obscureText ? 'Show password' : 'Hide password',
          splashRadius: 18,
        ),
      ],
    );

    if (widget.isOutlined) {
      return TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _obscureText,
        keyboardType: TextInputType.visiblePassword,
        maxLines: 1,
        enableInteractiveSelection: true,
        enableSuggestions: false,
        autocorrect: false,
        cursorColor: AppColors.primary,
        cursorWidth: 2.0,
        textInputAction: TextInputAction.done,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        onTap: () {
          // If tapped and cursor is at position 0 with existing text, move cursor to the end
          if (widget.controller.text.isNotEmpty &&
              widget.controller.selection.baseOffset <= 0) {
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller.text.length),
            );
          }
        },
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: suffixActions,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNode.hasFocus ? AppColors.primary : AppColors.border,
          width: _focusNode.hasFocus ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _obscureText,
        keyboardType: TextInputType.visiblePassword,
        maxLines: 1,
        enableInteractiveSelection: true,
        enableSuggestions: false,
        autocorrect: false,
        cursorColor: AppColors.primary,
        cursorWidth: 2.0,
        textInputAction: TextInputAction.done,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        onTap: () {
          // If tapped and cursor is at position 0 with existing text, move cursor to the end
          if (widget.controller.text.isNotEmpty &&
              widget.controller.selection.baseOffset <= 0) {
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller.text.length),
            );
          }
        },
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
          suffixIcon: suffixActions,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
