import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class ChatMessage {
  final String sender;
  final String text;
  final bool isUser;
  ChatMessage({required this.sender, required this.text, required this.isUser});
}

class AutonomousIntakeModule extends StatefulWidget {
  const AutonomousIntakeModule({super.key});
  @override
  State<AutonomousIntakeModule> createState() => _AutonomousIntakeModuleState();
}

class _AutonomousIntakeModuleState extends State<AutonomousIntakeModule> {
  final TextEditingController _msgCtrl = TextEditingController();

  final List<ChatMessage> _messages = [
    ChatMessage(sender: "Agent", text: "Elite Intake Agent Online. Tell me about the role and availability.", isUser: false),
  ];
  bool _isProcessing = false;

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.isEmpty || _isProcessing) return;
    final String userText = _msgCtrl.text;
    _msgCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(sender: "User", text: userText, isUser: true));
      _isProcessing = true;
    });
    try {
      // Calls the Supabase Edge Function 'intake-chat', which holds the
      // Gemini API key server-side. The key never ships inside the app.
      final response = await Supabase.instance.client.functions.invoke(
        'intake-chat',
        body: {'message': userText},
      );

      if (response.status != 200) {
        throw 'Server error (${response.status})';
      }

      final data = response.data as Map<String, dynamic>;
      final text = data['text'] as String? ?? "...";
      setState(() => _messages.add(ChatMessage(sender: "Agent", text: text, isUser: false)));
    } catch (e) {
      setState(() => _messages.add(ChatMessage(sender: "Agent", text: "Error: $e", isUser: false)));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.topLarge,
      ),
      child: Column(children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("AI INTAKE AGENT", style: AppTypography.sectionHeader),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: _messages.length,
            itemBuilder: (context, i) => _bubble(_messages[i]),
          ),
        ),
        Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: "Describe the role...",
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F766E), Colors.teal]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: IconButton(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isProcessing ? null : _sendMessage,
              ),
            )
          ]),
        )
      ]),
    );
  }

  Widget _bubble(ChatMessage msg) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.sender, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            SizedBox(height: AppSpacing.xs),
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: msg.isUser ? AppColors.secondary : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: AppBorderRadius.medium,
              ),
              child: Text(
                msg.text,
                style: AppTypography.bodySmall.copyWith(
                  color: msg.isUser ? AppColors.textLight : AppColors.textDark,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}
