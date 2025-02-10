import 'package:flutter/material.dart';

class SearchFilters extends StatelessWidget {
  final Map<String, bool> selectedFilters;
  final Function(String, bool) onFilterChanged;

  const SearchFilters({
    super.key,
    required this.selectedFilters,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            context,
            'Books',
            'books',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            'Poems',
            'poems',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            'Verses',
            'verses',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String filter,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selectedFilters[filter] ?? false,
      onSelected: (selected) => onFilterChanged(filter, selected),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}
