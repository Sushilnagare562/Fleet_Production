import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme.dart';

/// A form-field-style selector that, when tapped, opens a bottom sheet with a
/// search bar and a filtered list. Use it in place of a [DropdownButtonFormField]
/// when the list can grow long enough that scrolling to find an item is painful
/// (e.g. drivers, vehicles).
///
/// [itemLabel]/[itemSubtitle] control how each row is rendered, while
/// [searchText] provides the text that the search query is matched against
/// (so you can make an item findable by name, phone, plate number, etc.).
class SearchablePickerField<T> extends StatelessWidget {
  const SearchablePickerField({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.searchText,
    required this.onSelected,
    this.value,
    this.itemSubtitle,
    this.searchHint,
    this.emptyText = 'Nothing to show',
    this.leadingIcon,
  });

  final String label;
  final T? value;
  final List<T> items;

  /// Primary line shown for an item, both in the field and in the list.
  final String Function(T item) itemLabel;

  /// Optional secondary line shown under [itemLabel] in the list.
  final String Function(T item)? itemSubtitle;

  /// Text the typed query is matched against (case-insensitive, substring).
  final String Function(T item) searchText;

  final ValueChanged<T> onSelected;

  final String? searchHint;
  final String emptyText;
  final IconData? leadingIcon;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.fleet.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SearchPickerSheet<T>(
        title: label,
        items: items,
        itemLabel: itemLabel,
        itemSubtitle: itemSubtitle,
        searchText: searchText,
        searchHint: searchHint ?? 'Search $label'.trim(),
        emptyText: emptyText,
        selected: value,
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: leadingIcon != null ? Icon(leadingIcon, size: 20) : null,
          suffixIcon: const Icon(Icons.search, size: 20),
        ),
        isEmpty: !hasValue,
        child: hasValue
            ? Text(
                itemLabel(value as T),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.fleet.textPrimary),
              )
            : null,
      ),
    );
  }
}

class _SearchPickerSheet<T> extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.itemSubtitle,
    required this.searchText,
    required this.searchHint,
    required this.emptyText,
    required this.selected,
  });

  final String title;
  final List<T> items;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final String Function(T item) searchText;
  final String searchHint;
  final String emptyText;
  final T? selected;

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) => widget.searchText(item).toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Sit above the keyboard and cap the sheet a little below the top of screen.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    final results = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.fleet.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                      child: Center(
                        child: Text(
                          _query.isEmpty ? widget.emptyText : context.l10n.noResults,
                          style: TextStyle(color: context.fleet.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final isSelected = item == widget.selected;
                        return ListTile(
                          title: Text(widget.itemLabel(item)),
                          subtitle: widget.itemSubtitle != null ? Text(widget.itemSubtitle!(item)) : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
