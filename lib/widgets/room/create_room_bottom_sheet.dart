import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class CreateRoomBottomSheet extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCreate;

  const CreateRoomBottomSheet({
    super.key,
    required this.controller,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: UIConstants.paddingMedium,
        right: UIConstants.paddingMedium,
        top: UIConstants.paddingMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '새 채팅방 이름',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              onCreate();
              context.pop();
            },
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              onCreate();
              context.pop();
            },
            child: const Text('채팅방 생성'),
          ),
        ],
      ),
    );
  }
}
