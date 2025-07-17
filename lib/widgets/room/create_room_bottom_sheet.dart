import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        left: 16.0,
        right: 16.0,
        top: 16.0,
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
