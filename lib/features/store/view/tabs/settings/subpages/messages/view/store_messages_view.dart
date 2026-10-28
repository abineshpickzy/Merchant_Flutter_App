import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/store_messages_controller.dart';
import 'widgets/message_thread_card.dart';
import 'widgets/messages_skeleton.dart';

/// Store Messages List View matching Android MessagesFragment.java
class StoreMessagesView extends ConsumerStatefulWidget {
  final StoreModel store;

  const StoreMessagesView({
    super.key,
    required this.store,
  });

  @override
  ConsumerState<StoreMessagesView> createState() => _StoreMessagesViewState();
}

class _StoreMessagesViewState extends ConsumerState<StoreMessagesView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeMessagesControllerProvider(widget.store));
    final controller = ref.read(storeMessagesControllerProvider(widget.store).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: StoreTabAppBar(
        title: 'Messages',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF616161)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadMessages(isRefresh: true),
        color: const Color(0xFF2196F3),
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.messages.isEmpty) {
              return const MessagesSkeleton();
            }

            if (state.messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 54,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No records found!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final message = state.messages[index];
                return MessageThreadCard(
                  message: message,
                  onTap: () {
                    _showChatDetailSheet(message);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showChatDetailSheet(dynamic message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat - ${message.customerName}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('Order ID: ${message.orderId}'),
              if (message.lastMessage.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Last Message: ${message.lastMessage}'),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
