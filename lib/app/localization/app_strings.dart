import 'package:paper_chat/services/settings_repository.dart';

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isVi => language == AppLanguage.vi;

  // App Shell & Navigation
  String get appTitle => 'Paperdesk';
  String get library => isVi ? 'Thư viện' : 'Library';
  String get recent => isVi ? 'Gần đây' : 'Recent';
  String get notes => isVi ? 'Ghi chú' : 'Notes';
  String get projectsSection => isVi ? 'DỰ ÁN' : 'PROJECTS';
  String get projects => isVi ? 'Dự án' : 'Projects';
  String get collections => isVi ? 'BỘ SƯU TẬP' : 'COLLECTIONS';
  String get currentlyOpen => isVi ? 'ĐANG MỞ' : 'CURRENTLY OPEN';
  String get settings => isVi ? 'Cài đặt' : 'Settings';
  String get searchDocuments => isVi ? 'Tìm tài liệu' : 'Search documents';
  String get openNewPaper => isVi ? 'Mở bài báo mới' : 'Open new paper';
  String get toggleSidebar => isVi ? 'Thu gọn / Mở rộng thanh bên' : 'Toggle sidebar';
  String get demoBadge => isVi ? 'Chế độ Demo' : 'Demo Mode';
  String get demoNotice => isVi ? 'Chế độ Demo - Chưa thể tải bài báo mới.' : 'Demo mode - paper import is currently unavailable.';

  // Projects Feature
  String get createProject => isVi ? 'Tạo dự án mới' : 'Create project';
  String get projectName => isVi ? 'Tên dự án' : 'Project name';
  String get projectNameHint => isVi ? 'Ví dụ: Nghiên cứu LLM, Multi-Doc RAG...' : 'e.g. LLM Research, RAG Papers...';
  String get projectDesc => isVi ? 'Mô tả dự án' : 'Description';
  String get projectDescHint => isVi ? 'Mô tả ngắn về mục tiêu nghiên cứu...' : 'Brief research goal...';
  String get selectInitialPapers => isVi ? 'Chọn bài báo đính kèm ban đầu:' : 'Select initial papers:';
  String get attachedPapers => isVi ? 'Tài liệu trong dự án' : 'Project documents';
  String get addFilesToProject => isVi ? 'Thêm tài liệu' : 'Add files';
  String get noProjectsYet => isVi ? 'Chưa có dự án nào. Bấm "+" để tạo dự án đầu tiên!' : 'No projects yet. Click "+" to create your first project!';
  String get projectChatScope => isVi ? 'Chat Dự án (Multi-Doc)' : 'Project Chat (Multi-Doc)';
  String get projectChatHint => isVi ? 'Hỏi AI bất kỳ điều gì dựa trên tất cả tài liệu trong dự án này...' : 'Ask AI anything based on all papers in this project...';
  String get deleteProjectQuestion => isVi ? 'Xóa dự án?' : 'Delete project?';
  String get confirmDeleteProject => isVi ? 'Bạn có chắc chắn muốn xóa dự án này không?' : 'Are you sure you want to delete this project?';
  String get openPaperInReader => isVi ? 'Đọc PDF' : 'Read PDF';
  String get removeFromProject => isVi ? 'Gỡ khỏi dự án' : 'Remove';
  String get addToProject => isVi ? 'Thêm vào dự án' : 'Add to project';
  String get saveChanges => isVi ? 'Lưu thay đổi' : 'Save changes';
  String get selectProjectToAddTo => isVi ? 'Chọn dự án muốn thêm bài báo:' : 'Select project to add paper to:';
  String get addedToProjectSuccess => isVi ? 'Đã thêm bài báo vào dự án!' : 'Paper added to project!';
  String get editProject => isVi ? 'Chỉnh sửa dự án' : 'Edit project';
  String get sourceFiles => isVi ? 'Tài liệu nguồn' : 'Source files';
  String get addFile => isVi ? 'Thêm tài liệu' : 'Add file';
  String get removeLocalProject => isVi ? 'Xóa dự án' : 'Remove local project';
  String get newProjectChat => isVi ? 'Đoạn chat mới bao phủ dự án' : 'New project chat';




  // Reader Toolbar & Controls
  String get tableOfContents => isVi ? 'Mục lục' : 'Contents';
  String get tocHeader => isVi ? 'Mục lục tài liệu' : 'Table of Contents';
  String get closeToc => isVi ? 'Đóng mục lục' : 'Close Contents';
  String get searchInPdf => isVi ? 'Tìm trong PDF' : 'Search in PDF';
  String get fitWidth => isVi ? 'Vừa chiều rộng' : 'Fit width';
  String get highlight => isVi ? 'Tô sáng' : 'Highlight';
  String get page => isVi ? 'trang' : 'page';
  String get pageAbbr => isVi ? 'tr.' : 'p.';
  String pageIndicator(int current, int total) => isVi ? 'Trang $current/$total' : 'Page $current/$total';
  String searchMatchIndicator(int current, int total) => isVi ? '$current/$total' : '$current/$total';

  // Text Selection Popup
  String get askAi => isVi ? 'Hỏi AI' : 'Ask AI';
  String get explain => isVi ? 'Giải thích' : 'Explain';
  String get summarize => isVi ? 'Tóm tắt' : 'Summarize';
  String get addNoteOption => isVi ? 'Ghi chú' : 'Note';

  // Note Editor
  String get newNoteTitle => isVi ? 'Ghi chú mới' : 'New note';
  String get noteTitleHint => isVi ? 'Tiêu đề ghi chú...' : 'Note title...';
  String get noteContentHint => isVi ? 'Viết nội dung ghi chú ở đây...' : 'Write note content here...';
  String get normalText => isVi ? 'Bình thường' : 'Normal';
  String get headingText => isVi ? 'Tiêu đề' : 'Heading';

  // Chat Panel & Messages
  String get chatTab => isVi ? 'Chat' : 'Chat';
  String get notesTab => isVi ? 'Ghi chú' : 'Notes';
  String get userRole => isVi ? 'Bạn' : 'You';
  String get assistantRole => isVi ? 'Trợ lý' : 'Assistant';
  String get entirePaperScope => isVi ? 'Chỉ tài liệu này' : 'Entire paper';
  String get selectionScope => isVi ? 'Đoạn văn chọn' : 'Selection';
  String get selectedScope => selectionScope;
  String get source => isVi ? 'Nguồn' : 'Source';
  String get copy => isVi ? 'Sao chép' : 'Copy';
  String get saveNote => isVi ? 'Lưu ghi chú' : 'Save note';
  String get savedToNotes => isVi ? 'Đã lưu vào Ghi chú' : 'Saved to Notes';
  String get copiedToClipboard => isVi ? 'Đã sao chép câu trả lời' : 'Copied to clipboard';
  String get retry => isVi ? 'Thử lại' : 'Retry';
  String get askAboutPaper => isVi ? 'Hỏi về bài báo này...' : 'Ask about this paper...';
  String get answersCrossReferenced => isVi ? 'Câu trả lời được đối chiếu với tài liệu' : 'Answers are cross-referenced with document';
  String get newMessages => isVi ? 'Tin nhắn mới ↓' : 'New messages ↓';
  String get createNote => isVi ? 'Tạo ghi chú' : 'Create note';
  String get addNoteTitle => isVi ? 'Thêm ghi chú' : 'Add note';
  String get paperNotesHeader => isVi ? 'Ghi chú cho tài liệu' : 'Notes for paper';
  String get noNotesYet => isVi ? 'Chưa có ghi chú nào' : 'No notes saved yet';
  String get noNotesHint => isVi ? 'Hãy chọn văn bản trong PDF hoặc bấm "Lưu ghi chú" từ Chat' : 'Select text in PDF or click "Save note" from Chat';
  String pageTag(int p) => isVi ? 'Trang $p' : 'Page $p';

  // Starter Prompts
  String get starterPromptTitle => isVi ? 'Hỏi AI về bài báo này' : 'Ask about this paper';
  String get promptSummarize => isVi ? 'Tóm tắt bài báo này' : 'Summarize this paper';
  String get promptContribution => isVi ? 'Đóng góp chính của bài báo là gì?' : 'What is the main contribution?';
  String get promptMethodology => isVi ? 'Giải thích phương pháp nghiên cứu' : 'Explain the methodology';
  String get promptFindings => isVi ? 'Các phát hiện quan trọng nhất là gì?' : 'What are the key findings?';

  // Library & Notes Screen
  String get searchTitleAuthors => isVi ? 'Tìm theo tiêu đề, tác giả, tóm tắt...' : 'Search title, authors, abstract, tags...';
  String get allPapers => isVi ? 'Tất cả bài báo' : 'All papers';
  String get importPaper => isVi ? 'Thêm bài báo' : 'Import paper';
  String get sortBy => isVi ? 'Sắp xếp' : 'Sort by';
  String get filterByTag => isVi ? 'Thẻ' : 'Tag';
  String get yearDesc => isVi ? 'Năm mới nhất' : 'Newest year';
  String get yearAsc => isVi ? 'Năm cũ nhất' : 'Oldest year';
  String get titleAsc => isVi ? 'Tiêu đề (A-Z)' : 'Title (A-Z)';
  String get titleDesc => isVi ? 'Tiêu đề (Z-A)' : 'Title (Z-A)';
  String get favoritesOnly => isVi ? 'Chỉ yêu thích' : 'Favorites only';
  String get noPapersFound => isVi ? 'Không tìm thấy bài báo nào' : 'No papers found';
  String get allNotes => isVi ? 'Tất cả ghi chú' : 'All notes';

  String get filterByCollection => isVi ? 'Lọc theo Bộ sưu tập' : 'Filter by Collection';
  String get allCollections => isVi ? 'Tất cả Bộ sưu tập' : 'All Collections';
  String get sortOptions => isVi ? 'Tùy chọn sắp xếp' : 'Sort Options';
  String get clearFilters => isVi ? 'Xóa bộ lọc' : 'Clear Filters';
  String get clear => isVi ? 'Xóa' : 'Clear';
  String get noResultsFound => isVi ? 'Không tìm thấy kết quả' : 'No results found';
  String get noPapersYet => isVi ? 'Chưa có bài báo nào' : 'No papers yet';
  String get tryAdjustingFilters => isVi ? 'Hãy thử điều chỉnh bộ lọc tìm kiếm' : 'Try adjusting your search filters';
  String get importPaperToStart => isVi ? 'Thêm bài báo để bắt đầu nghiên cứu' : 'Import a paper to get started';

  // Notes & Cards
  String get exportMarkdown => isVi ? 'Xuất ra Markdown' : 'Export as Markdown';
  String exportedTo(String path) => isVi ? 'Đã xuất ra $path' : 'Exported to $path';
  String get exportFailed => isVi ? 'Không thể xuất hoặc không có ghi chú' : 'Failed to export or no notes available';
  String get searchNotes => isVi ? 'Tìm kiếm ghi chú...' : 'Search notes...';
  String get deleteNoteQuestion => isVi ? 'Xóa ghi chú?' : 'Delete Note?';
  String get confirmDeleteNote => isVi ? 'Bạn có chắc chắn muốn xóa ghi chú này?' : 'Are you sure you want to delete this note?';
  String get cancel => isVi ? 'Hủy' : 'Cancel';
  String get delete => isVi ? 'Xóa' : 'Delete';
  String get editNote => isVi ? 'Sửa ghi chú' : 'Edit note';
  String get deleteNote => isVi ? 'Xóa ghi chú' : 'Delete note';
  String get save => isVi ? 'Lưu' : 'Save';
  String get justNow => isVi ? 'vừa xong' : 'just now';
  String minAgo(int m) => isVi ? '$m phút trước' : '$m min ago';
  String hoursAgo(int h) => isVi ? '$h giờ trước' : '$h hours ago';
  String get yesterday => isVi ? 'hôm qua' : 'yesterday';
  String daysAgo(int d) => isVi ? '$d ngày trước' : '$d days ago';

  // Settings Screen
  String get appearance => isVi ? 'Giao diện' : 'Appearance';
  String get themeLight => isVi ? 'Sáng' : 'Light';
  String get themeDark => isVi ? 'Tối' : 'Dark';
  String get themeSystem => isVi ? 'Theo hệ thống' : 'System';
  String get languageTitle => isVi ? 'Ngôn ngữ' : 'Language';
  String get languageVi => 'Tiếng Việt';
  String get languageEn => 'English';
  String get typography => isVi ? 'Kiểu chữ' : 'Typography';
  String get readerFontSizeLabel => isVi ? 'Kích thước chữ bài đọc' : 'Reader font size';
  String get chatFontSizeLabel => isVi ? 'Kích thước chữ Chat' : 'Chat font size';
  String get sampleTextPreview => isVi ? 'Văn bản xem thử mẫu' : 'Sample text preview';
  String get accessibility => isVi ? 'Khả năng truy cập' : 'Accessibility';
  String get reduceMotion => isVi ? 'Giảm chuyển động' : 'Reduce motion';
  String get reduceMotionSubtitle => isVi ? 'Giảm các hiệu ứng chuyển động trong app' : 'Reduces animations throughout the app';
  String get about => isVi ? 'Giới thiệu' : 'About';
  String get aboutContent => isVi 
      ? 'Phiên bản 0.1.0 (Demo)\nMôi trường đọc paper khoa học & tương tác với AI.' 
      : 'Version 0.1.0 (Demo)\nResearch paper reader with AI chat.';

  // Authentication Screen
  String get signInTitle => isVi ? 'Đăng nhập vào Paperdesk' : 'Sign in to Paperdesk';
  String get signUpTitle => isVi ? 'Tạo tài khoản mới' : 'Create an Account';
  String get authSubtitle => isVi ? 'Đọc báo khoa học & nghiên cứu thông minh cùng AI' : 'Smart scientific paper reader & AI research assistant';
  String get loginTab => isVi ? 'Đăng nhập' : 'Sign In';
  String get registerTab => isVi ? 'Đăng ký' : 'Sign Up';
  String get continueWithGoogle => isVi ? 'Tiếp tục với Google' : 'Continue with Google';
  String get orWithEmail => isVi ? 'HOẶC BẰNG EMAIL' : 'OR WITH EMAIL';
  String get emailLabel => isVi ? 'Địa chỉ Email' : 'Email Address';
  String get emailHint => isVi ? 'nhap.email@domain.com' : 'enter.email@domain.com';
  String get passwordLabel => isVi ? 'Mật khẩu' : 'Password';
  String get passwordHint => isVi ? 'Nhập mật khẩu (ít nhất 6 ký tự)' : 'Enter password (min 6 chars)';
  String get confirmPasswordLabel => isVi ? 'Xác nhận mật khẩu' : 'Confirm Password';
  String get confirmPasswordHint => isVi ? 'Nhập lại mật khẩu' : 'Re-enter password';
  String get fullNameLabel => isVi ? 'Họ và tên' : 'Full Name';
  String get fullNameHint => isVi ? 'Ví dụ: Nguyễn Văn A' : 'e.g., John Doe';
  String get forgotPassword => isVi ? 'Quên mật khẩu?' : 'Forgot password?';
  String get rememberMe => isVi ? 'Ghi nhớ đăng nhập' : 'Remember me';
  String get signInButton => isVi ? 'Đăng nhập' : 'Sign In';
  String get signUpButton => isVi ? 'Tạo tài khoản' : 'Create Account';
  String get dontHaveAccount => isVi ? 'Chưa có tài khoản?' : 'Don\'t have an account?';
  String get alreadyHaveAccount => isVi ? 'Đã có tài khoản?' : 'Already have an account?';
  String get signUpNow => isVi ? 'Đăng ký ngay' : 'Sign up now';
  String get signInNow => isVi ? 'Đăng nhập ngay' : 'Sign in now';
  String get logout => isVi ? 'Đăng xuất' : 'Logout';
  String get resetPasswordTitle => isVi ? 'Đặt lại mật khẩu' : 'Reset Password';
  String get resetPasswordStep1Subtitle => isVi
      ? 'Nhập địa chỉ email liên kết với tài khoản của bạn để nhận mã xác thực một lần (OTP).'
      : 'Enter your email address to receive a one-time verification code (OTP).';
  String get resetPasswordStep2Subtitle => isVi
      ? 'Nhập mã xác thực một lần và mật khẩu mới của bạn.'
      : 'Enter the one-time code and choose a new password.';
  String get sendOtpCode => isVi ? 'Gửi mã xác nhận' : 'Send Code';
  String get resendCode => isVi ? 'Gửi lại mã' : 'Resend Code';
  String get otpCodeLabel => isVi ? 'Mã xác thực một lần (OTP)' : 'One-Time Code (OTP)';
  String get otpCodeHint => isVi ? 'Nhập mã 6 chữ số (Mã thử nghiệm: 123456)' : 'Enter 6-digit code (Demo: 123456)';
  String get newPasswordLabel => isVi ? 'Mật khẩu mới' : 'New Password';
  String get newPasswordHint => isVi ? 'Nhập mật khẩu mới (ít nhất 6 ký tự)' : 'Enter new password (min 6 chars)';
  String get confirmNewPasswordLabel => isVi ? 'Xác nhận mật khẩu mới' : 'Confirm New Password';
  String get confirmNewPasswordHint => isVi ? 'Nhập lại mật khẩu mới' : 'Re-enter new password';
  String get resetPasswordButton => isVi ? 'Đặt lại mật khẩu' : 'Reset Password';
  String get resetPasswordSuccess => isVi
      ? 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.'
      : 'Password reset successfully! You can now sign in with your new password.';
  String get enterValidEmail => isVi ? 'Vui lòng nhập địa chỉ email hợp lệ' : 'Please enter a valid email address';
  String get enterValidOtp => isVi ? 'Vui lòng nhập mã xác thực gồm 6 chữ số' : 'Please enter the 6-digit code';
  String get back => isVi ? 'Quay lại' : 'Back';
  String get addNewPaperTitle => isVi ? 'Thêm bài báo mới' : 'Add New Paper';
  String get addNewPaperSubtitle => isVi
      ? 'Nhập thông tin nghiên cứu hoặc chọn nhanh các bài báo kinh điển có sẵn.'
      : 'Enter research paper details or quickly load benchmark papers.';
  String get paperTitleLabel => isVi ? 'Tiêu đề bài báo' : 'Paper Title';
  String get paperTitleHint => isVi ? 'vd: BERT: Pre-training of Deep Bidirectional Transformers...' : 'e.g., BERT: Pre-training of Deep Bidirectional Transformers...';
  String get authorsLabel => isVi ? 'Tác giả' : 'Authors';
  String get authorsHint => isVi ? 'Phân cách bằng dấu phẩy (vd: Jacob Devlin, Ming-Wei Chang)' : 'Separated by comma (e.g., Jacob Devlin, Ming-Wei Chang)';
  String get yearLabel => isVi ? 'Năm xuất bản' : 'Publication Year';
  String get collectionLabel => isVi ? 'Bộ sưu tập' : 'Collection';
  String get tagsLabel => isVi ? 'Thẻ (Tags)' : 'Tags';
  String get tagsHint => isVi ? 'vd: NLP, Transformer, Language Model' : 'e.g., NLP, Transformer, Language Model';
  String get abstractLabel => isVi ? 'Tóm tắt bài báo (Abstract)' : 'Abstract';
  String get abstractHint => isVi ? 'Tóm tắt nội dung chính và đóng góp khoa học của bài báo...' : 'Summary of key methodology and scientific contributions...';
  String get paperContentLabel => isVi ? 'Nội dung bài báo (Trang 1)' : 'Paper Content (Page 1)';
  String get paperContentHint => isVi ? 'Nhập nội dung chi tiết bài báo...' : 'Enter detailed paper content...';
  String get quickPresets => isVi ? 'Chọn mẫu nghiên cứu có sẵn' : 'Quick Presets';
  String get addPaperButton => isVi ? 'Thêm vào thư viện' : 'Add to Library';
  String get addPaperSuccess => isVi ? 'Đã thêm bài báo vào thư viện thành công!' : 'Paper successfully added to library!';
  String get titleRequired => isVi ? 'Vui lòng nhập tiêu đề bài báo' : 'Paper title is required';
}

