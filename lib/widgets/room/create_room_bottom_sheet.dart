import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

/// 새로운 채팅방을 생성하기 위한 UI를 제공하는 바텀 시트(bottom sheet) 위젯입니다.
///
/// 사용자로부터 채팅방 이름을 입력받고, '생성' 버튼을 누르면 `onCreate` 콜백을 실행합니다.
class CreateRoomBottomSheet extends StatelessWidget {
  /// 채팅방 이름 입력을 제어하는 컨트롤러입니다.
  final TextEditingController controller;

  /// '채팅방 생성' 버튼을 눌렀을 때 호출될 콜백 함수입니다.
  final VoidCallback onCreate;

  /// {@template create_room_bottom_sheet}
  /// `CreateRoomBottomSheet` 위젯을 생성합니다.
  /// {@endtemplate}
  const CreateRoomBottomSheet({
    super.key,
    required this.controller,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    // 키보드가 올라왔을 때 UI가 가려지지 않도록 `viewInsets`를 사용합니다.
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
            // 키보드에서 '완료'를 눌러도 생성이 가능하도록 합니다.
            onSubmitted: (value) {
              onCreate();
              context.pop(); // 바텀 시트 닫기
            },
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              onCreate();
              context.pop(); // 바텀 시트 닫기
            },
            child: const Text('채팅방 생성'),
          ),
        ],
      ),
    );
  }
}
