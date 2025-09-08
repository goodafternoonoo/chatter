import 'package:flutter/material.dart';
import 'room_list_screen.dart';
import 'profile_screen.dart';

/// 앱의 메인 화면으로, 하단 내비게이션 바를 통해 여러 페이지를 전환하는 역할을 합니다.
///
/// 현재는 `RoomListScreen`과 `ProfileScreen` 두 개의 페이지를 포함합니다.
/// `IndexedStack`을 사용하여 페이지 간 전환 시 각 페이지의 상태를 보존합니다.
class MainPage extends StatefulWidget {
  /// {@template main_page}
  /// `MainPage` 위젯을 생성합니다.
  /// {@endtemplate}
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  /// 현재 선택된 페이지의 인덱스입니다.
  int _selectedIndex = 0;

  /// 하단 내비게이션 바에 의해 표시될 페이지 목록입니다.
  final List<Widget> _pages = [
    const RoomListScreen(),
    const ProfileScreen(),
  ];

  /// 하단 내비게이션 바의 아이템이 탭되었을 때 호출됩니다.
  ///
  /// [index] 탭된 아이템의 인덱스입니다.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '채팅방',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
