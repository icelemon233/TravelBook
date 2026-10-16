import 'package:flutter/material.dart';

class ValueEditor extends StatefulWidget {
  const ValueEditor({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.suffix,
    this.numeric = true,
    this.maxLines = 1,
    this.maxLength,
  });
  final String label, value;
  final ValueChanged<String> onChanged;
  final String? error, suffix;
  final bool numeric;
  final int maxLines;
  final int? maxLength;
  @override
  State<ValueEditor> createState() => _ValueEditorState();
}

class _ValueEditorState extends State<ValueEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final _focus = FocusNode();
  final _scroll = ScrollController(keepScrollOffset: false);
  @override
  void didUpdateWidget(ValueEditor old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    onTapOutside: (_) => _focus.unfocus(),
    controller: _controller,
    focusNode: _focus,
    scrollController: _scroll,
    keyboardType: widget.numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : widget.maxLines > 1
        ? TextInputType.multiline
        : TextInputType.text,
    maxLines: widget.maxLines,
    minLines: widget.maxLines > 1 ? 2 : 1,
    maxLength: widget.maxLength,
    decoration: InputDecoration(
      labelText: widget.label,
      errorText: widget.error,
      suffixText: widget.suffix,
      alignLabelWithHint: widget.maxLines > 1,
    ),
    onChanged: widget.onChanged,
  );
}
