import 'package:flutter/widgets.dart';
import 'package:restore/modules/ai/bloc/ai_assistant_cubit.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';

/// Cửa sổ chat nổi ở góc phải dưới trên web desktop.
enum DesktopChatPane { none, conversation, assistant }

/// Trạng thái cửa sổ chat nổi: đóng / mở, đang xem cuộc trò chuyện nào
/// hoặc ReStore AI. Mỗi lúc chỉ có một cửa sổ để góc màn hình gọn.
class DesktopChatController extends ChangeNotifier {
  DesktopChatController({this.assistantFactory});

  /// Cubit ReStore AI dùng chung với trang /ai-assistant (giữ hội thoại)
  final AiAssistantCubit Function()? assistantFactory;
  AiAssistantCubit? _ownAssistant;

  AiAssistantCubit assistantCubit() =>
      assistantFactory?.call() ?? (_ownAssistant ??= AiAssistantCubit());

  @override
  void dispose() {
    _ownAssistant?.close();
    super.dispose();
  }

  bool _open = false;
  DesktopChatPane _pane = DesktopChatPane.none;
  String? _conversationId;

  bool get isOpen => _open;
  DesktopChatPane get pane => _pane;
  String? get conversationId => _conversationId;

  void openList() {
    _open = true;
    notifyListeners();
  }

  void openConversation(String id) {
    _open = true;
    _pane = DesktopChatPane.conversation;
    _conversationId = id;
    notifyListeners();
  }

  void openAssistant() {
    _open = true;
    _pane = DesktopChatPane.assistant;
    _conversationId = null;
    notifyListeners();
  }

  /// Quay về danh sách (bỏ chọn cuộc trò chuyện)
  void clearSelection() {
    _pane = DesktopChatPane.none;
    _conversationId = null;
    notifyListeners();
  }

  void toggle() {
    _open = !_open;
    notifyListeners();
  }

  void close() {
    if (!_open) return;
    _open = false;
    notifyListeners();
  }
}

/// Đưa [DesktopChatController] xuống cây widget của khung desktop
class DesktopChatScope extends InheritedNotifier<DesktopChatController> {
  const DesktopChatScope({
    super.key,
    required DesktopChatController controller,
    required super.child,
  }) : super(notifier: controller);

  static DesktopChatController? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<DesktopChatScope>()
      ?.notifier;
}

/// Trên desktop mở cuộc trò chuyện [conversationId] (hoặc ReStore AI khi
/// [assistant]) trong cửa sổ chat nổi thay vì chuyển trang. Trả về false
/// khi đang ở bố cục điện thoại / máy tính bảng để nơi gọi tự chuyển trang.
bool openDesktopChat(
  BuildContext context, {
  String? conversationId,
  bool assistant = false,
}) {
  if (!isDesktopLayout(context)) return false;
  final chat = DesktopChatScope.maybeOf(context);
  if (chat == null) return false;
  if (assistant) {
    chat.openAssistant();
  } else if (conversationId != null) {
    chat.openConversation(conversationId);
  } else {
    chat.openList();
  }
  return true;
}
