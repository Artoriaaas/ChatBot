import 'package:flutter/material.dart';
import 'package:paper_chat/app/theme/app_theme.dart';
import 'package:paper_chat/features/auth/auth_screen.dart';
import 'package:paper_chat/features/auth/auth_view_model.dart';
import 'package:paper_chat/features/chat/chat_view_model.dart';
import 'package:paper_chat/features/library/library_view_model.dart';
import 'package:paper_chat/features/notes/notes_view_model.dart';
import 'package:paper_chat/features/projects/projects_view_model.dart';
import 'package:paper_chat/features/reader/reader_view_model.dart';
import 'package:paper_chat/features/settings/settings_view_model.dart';
import 'package:paper_chat/services/api_service.dart';
import 'package:paper_chat/services/api_paper_repository.dart';
import 'package:paper_chat/services/api_ai_service.dart';
import 'package:paper_chat/services/notes_repository.dart';
import 'package:paper_chat/services/project_repository.dart';
import 'package:paper_chat/services/settings_repository.dart';
import 'package:paper_chat/shared/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize repositories & API services
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();
  
  final notesRepo = NotesRepository();
  await notesRepo.init();

  final projectRepo = ProjectRepository();
  await projectRepo.init();
  
  final apiService = ApiService();
  final paperRepo = ApiPaperRepository(apiService);
  await paperRepo.fetchRemotePapers();

  final aiService = ApiAiService(apiService);
  
  // Create view models
  final authVM = AuthViewModel();
  // Xóa token cũ khi khởi động - bắt buộc đăng nhập lại mỗi phiên
  await authVM.clearSession();
  final settingsVM = SettingsViewModel(settingsRepo);
  final libraryVM = LibraryViewModel(paperRepo);
  final readerVM = ReaderViewModel();
  final chatVM = ChatViewModel(aiService);
  final notesVM = NotesViewModel(notesRepo);
  final projectsVM = ProjectsViewModel(projectRepo, paperRepo, aiService);
  
  runApp(PaperInkApp(
    authVM: authVM,
    settingsVM: settingsVM,
    libraryVM: libraryVM,
    readerVM: readerVM,
    chatVM: chatVM,
    notesVM: notesVM,
    projectsVM: projectsVM,
    notesRepo: notesRepo,
  ));
}

class PaperInkApp extends StatelessWidget {
  final AuthViewModel authVM;
  final SettingsViewModel settingsVM;
  final LibraryViewModel libraryVM;
  final ReaderViewModel readerVM;
  final ChatViewModel chatVM;
  final NotesViewModel notesVM;
  final ProjectsViewModel projectsVM;
  final NotesRepository notesRepo;
  
  const PaperInkApp({
    super.key,
    required this.authVM,
    required this.settingsVM,
    required this.libraryVM,
    required this.readerVM,
    required this.chatVM,
    required this.notesVM,
    required this.projectsVM,
    required this.notesRepo,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([settingsVM, authVM]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Paperdesk',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settingsVM.flutterThemeMode,
          themeAnimationDuration: const Duration(milliseconds: 220),
          themeAnimationCurve: Curves.easeOutCubic,
          home: authVM.isLoggedIn
              ? AppShell(
                  settingsVM: settingsVM,
                  libraryVM: libraryVM,
                  readerVM: readerVM,
                  chatVM: chatVM,
                  notesVM: notesVM,
                  projectsVM: projectsVM,
                  notesRepo: notesRepo,
                  authVM: authVM,
                )
              : AuthScreen(
                  authVM: authVM,
                  settingsVM: settingsVM,
                ),
        );
      },
    );
  }
}
