import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'chat_conversation_mobile_view.dart';
export '../../models/chat_offer_stage.dart';
import '../../models/chat_offer_stage.dart';

class ChatConversationView extends StatelessWidget {
  const ChatConversationView({
    super.key,
    this.stage = ChatOfferStage.conversation,
  });
  final ChatOfferStage stage;
  @override
  Widget build(BuildContext context) =>
      TResponsiveLayout(mobile: ChatConversationMobileView(stage: stage));
}
