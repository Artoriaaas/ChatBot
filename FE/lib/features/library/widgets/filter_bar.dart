import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/features/library/library_view_model.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';

class FilterBar extends StatelessWidget {
  final SettingsViewModel settingsVM;
  final LibraryViewModel viewModel;

  const FilterBar({
    super.key,
    required this.settingsVM,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: settingsVM,
      builder: (context, _) {
        final strings = settingsVM.strings;
        final hasFilters = viewModel.searchQuery.isNotEmpty || 
                           viewModel.selectedTag != null || 
                           viewModel.selectedCollection != null || 
                           viewModel.showFavoritesOnly ||
                           viewModel.sortMode != SortMode.yearDesc;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.sidebarBackground,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              PopupMenuButton<String?>(
                initialValue: viewModel.selectedCollection,
                tooltip: strings.filterByCollection,
                onSelected: (val) => viewModel.selectedCollection = val,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_outlined, size: 20, color: colors.textPrimary),
                    const SizedBox(width: 4),
                    Text(
                      viewModel.selectedCollection ?? strings.allCollections,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    Icon(Icons.arrow_drop_down, color: colors.textPrimary),
                  ],
                ),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(value: null, child: Text(strings.allCollections)),
                    ...viewModel.allCollections.map((c) => PopupMenuItem(value: c, child: Text(c))),
                  ];
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: viewModel.allTags.map((tag) {
                      final isSelected = viewModel.selectedTag == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            viewModel.selectedTag = selected ? tag : null;
                          },
                          backgroundColor: colors.surface,
                          selectedColor: colors.selectionBackground,
                          labelStyle: TextStyle(
                            color: isSelected ? colors.onSelection : colors.textPrimary,
                          ),
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : colors.divider,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  viewModel.showFavoritesOnly ? Icons.star : Icons.star_border,
                  color: viewModel.showFavoritesOnly ? Colors.amber : colors.textSecondary,
                ),
                tooltip: strings.favoritesOnly,
                onPressed: () => viewModel.showFavoritesOnly = !viewModel.showFavoritesOnly,
              ),
              PopupMenuButton<SortMode>(
                initialValue: viewModel.sortMode,
                tooltip: strings.sortOptions,
                icon: Icon(Icons.sort, color: colors.textSecondary),
                onSelected: (val) => viewModel.sortMode = val,
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(value: SortMode.yearDesc, child: Text(strings.yearDesc)),
                    PopupMenuItem(value: SortMode.yearAsc, child: Text(strings.yearAsc)),
                    PopupMenuItem(value: SortMode.titleAsc, child: Text(strings.titleAsc)),
                    PopupMenuItem(value: SortMode.titleDesc, child: Text(strings.titleDesc)),
                  ];
                },
              ),
              if (hasFilters) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text(strings.clear),
                  onPressed: viewModel.clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
