import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/services/settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsViewModel viewModel;

  const SettingsScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final strings = viewModel.strings;

        return Scaffold(
          backgroundColor: colors.appBackground,
          appBar: AppBar(
            title: Text(strings.settings),
            backgroundColor: colors.surface,
          ),
          body: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildSectionHeader(context, strings.appearance),
              _buildThemeSection(context, colors, viewModel),
              const SizedBox(height: 24),
              
              _buildSectionHeader(context, strings.languageTitle),
              _buildLanguageSection(context, colors, viewModel),
              const SizedBox(height: 24),

              _buildSectionHeader(context, strings.typography),
              _buildTypographySection(context, colors, viewModel),
              const SizedBox(height: 24),

              _buildSectionHeader(context, strings.accessibility),
              _buildAccessibilitySection(context, colors, viewModel),
              const SizedBox(height: 24),

              _buildSectionHeader(context, strings.about),
              _buildAboutSection(context, colors, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = AppColorsExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: colors.primary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, AppColorsExtension colors, SettingsViewModel vm) {
    final strings = vm.strings;
    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          RadioListTile<AppThemeMode>(
            title: Text(strings.themeLight),
            secondary: const Icon(Icons.light_mode_outlined, size: 20),
            value: AppThemeMode.light,
            groupValue: vm.themeMode,
            onChanged: (mode) {
              if (mode != null) vm.setThemeMode(mode);
            },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(strings.themeDark),
            secondary: const Icon(Icons.dark_mode_outlined, size: 20),
            value: AppThemeMode.dark,
            groupValue: vm.themeMode,
            onChanged: (mode) {
              if (mode != null) vm.setThemeMode(mode);
            },
          ),
          RadioListTile<AppThemeMode>(
            title: Text(strings.themeSystem),
            secondary: const Icon(Icons.brightness_auto, size: 20),
            value: AppThemeMode.system,
            groupValue: vm.themeMode,
            onChanged: (mode) {
              if (mode != null) vm.setThemeMode(mode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context, AppColorsExtension colors, SettingsViewModel vm) {
    final strings = vm.strings;
    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          RadioListTile<AppLanguage>(
            title: Text(strings.languageVi),
            secondary: const Icon(Icons.language, size: 20),
            value: AppLanguage.vi,
            groupValue: vm.language,
            onChanged: (lang) {
              if (lang != null) vm.setLanguage(lang);
            },
          ),
          RadioListTile<AppLanguage>(
            title: Text(strings.languageEn),
            secondary: const Icon(Icons.translate, size: 20),
            value: AppLanguage.en,
            groupValue: vm.language,
            onChanged: (lang) {
              if (lang != null) vm.setLanguage(lang);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypographySection(BuildContext context, AppColorsExtension colors, SettingsViewModel vm) {
    final strings = vm.strings;
    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          children: [
            ListTile(
              title: Text(strings.readerFontSizeLabel),
              subtitle: Text(
                strings.sampleTextPreview,
                style: TextStyle(fontSize: vm.readerFontSize),
              ),
              trailing: Text('${vm.readerFontSize.toInt()}'),
            ),
            Slider(
              value: vm.readerFontSize,
              min: 12,
              max: 22,
              divisions: 10,
              onChanged: vm.setReaderFontSize,
            ),
            const Divider(),
            ListTile(
              title: Text(strings.chatFontSizeLabel),
              subtitle: Text(
                strings.sampleTextPreview,
                style: TextStyle(fontSize: vm.chatFontSize),
              ),
              trailing: Text('${vm.chatFontSize.toInt()}'),
            ),
            Slider(
              value: vm.chatFontSize,
              min: 13,
              max: 20,
              divisions: 7,
              onChanged: vm.setChatFontSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilitySection(BuildContext context, AppColorsExtension colors, SettingsViewModel vm) {
    final strings = vm.strings;
    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SwitchListTile(
        title: Text(strings.reduceMotion),
        subtitle: Text(strings.reduceMotionSubtitle),
        value: vm.reduceMotion,
        onChanged: vm.setReduceMotion,
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, AppColorsExtension colors, SettingsViewModel vm) {
    final strings = vm.strings;
    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(strings.appTitle),
        subtitle: Text(strings.aboutContent),
        isThreeLine: true,
      ),
    );
  }
}
