import 'dart:async';
import 'package:flutter/material.dart';
import 'package:odon_booking/core/api/api_service.dart';

/// Drop-in TextField for guest name with autocomplete suggestions backed by
/// the Guest database. Selecting a suggestion fills both the name and phone
/// controllers so the rest of the booking form keeps working unchanged.
class GuestNameAutocomplete extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String label;

  /// Decoration applied to the inner TextField. If null, a borderless
  /// labelled decoration is used.
  final InputDecoration? inputDecoration;

  /// Decoration applied to the Container wrapping the TextField. If null,
  /// a flat white card with shadow is used (matches room_selection_screen).
  final BoxDecoration? wrapperDecoration;

  /// Optional padding for the wrapping container.
  final EdgeInsetsGeometry wrapperPadding;

  const GuestNameAutocomplete({
    super.key,
    required this.nameController,
    required this.phoneController,
    this.label = 'Guest Name',
    this.inputDecoration,
    this.wrapperDecoration,
    this.wrapperPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  });

  @override
  State<GuestNameAutocomplete> createState() => _GuestNameAutocompleteState();
}

class _GuestNameAutocompleteState extends State<GuestNameAutocomplete> {
  final ApiService _api = ApiService();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<Iterable<Map<String, dynamic>>> _search(String input) async {
    final q = input.trim();
    if (q.length < 2) return const [];
    // Debounce: wait briefly, then bail if the user has kept typing.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (widget.nameController.text.trim() != q) return const [];
    try {
      return await _api.searchGuests(q);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: widget.nameController,
      focusNode: _focusNode,
      optionsBuilder: (v) => _search(v.text),
      displayStringForOption: (g) => (g['name'] ?? '').toString(),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        final field = TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: widget.inputDecoration ??
              InputDecoration(border: InputBorder.none, labelText: widget.label),
        );
        return Container(
          padding: widget.wrapperPadding,
          decoration: widget.wrapperDecoration ??
              BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
          child: field,
        );
      },
      onSelected: (guest) {
        final phone = (guest['phone'] ?? '').toString();
        if (phone.isNotEmpty) widget.phoneController.text = phone;
        FocusScope.of(context).unfocus();
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (ctx, i) {
                  final g = options.elementAt(i);
                  final name = (g['name'] ?? '').toString();
                  final phone = (g['phone'] ?? '').toString();
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.indigo, size: 18),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    onTap: () => onSelected(g),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
