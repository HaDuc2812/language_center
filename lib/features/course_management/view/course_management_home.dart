import 'package:flutter/material.dart';

import '../../auth/view/logout_button.dart';
import '../../auth/view_model/auth_view_model.dart';
import 'course_list_page.dart';
import 'classroom_list_page.dart';

// Lớp học đã có ở ClassesPage — import nếu muốn gộp

class CourseManagementHome extends StatefulWidget {
  const CourseManagementHome({required this.profile, super.key});
  final AuthorizedProfile profile;

  @override
  State<CourseManagementHome> createState() => _CourseManagementHomeState();
}

class _CourseManagementHomeState extends State<CourseManagementHome> {
  int _selectedIndex = 0;

  static const _pages = [
    CourseListPage(),
    ClassroomListPage(),
    // Có thể thêm ClassesPage() tại đây nếu muốn
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đào tạo • ${widget.profile.role}'),
        actions: const [LogoutButton()],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Khóa học',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Phòng học',
          ),
        ],
      ),
    );
  }
}
