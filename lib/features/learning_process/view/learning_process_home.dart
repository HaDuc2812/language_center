import 'package:flutter/material.dart';

import '../../auth/view/logout_button.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../student/view/students_page.dart';
import '../../teachers/views/teacher_list_view.dart';
import 'classes_page.dart';
import 'enrollments_page.dart';

import '../../course_management/view/course_list_page.dart';
import '../../course_management/view/classroom_list_page.dart';

class LearningProcessHome extends StatefulWidget {
  const LearningProcessHome({required this.profile, super.key});

  final AuthorizedProfile profile;

  @override
  State<LearningProcessHome> createState() => _LearningProcessHomeState();
}

class _LearningProcessHomeState extends State<LearningProcessHome> {
  int _selectedIndex = 0;
  static const _pages = [
    EnrollmentsPage(),
    ClassesPage(),
    StudentsPage(),
    StudentLookupPage(),
    TeacherListView(showAppBar: false),
    CourseListPage(), // ← MỚI
    ClassroomListPage(), // ← MỚI
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Language Center • ${widget.profile.role}'),
        actions: const [LogoutButton()],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
  NavigationDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    label: 'Tổng quan',
  ),
  NavigationDestination(
    icon: Icon(Icons.class_outlined),
    selectedIcon: Icon(Icons.class_),
    label: 'Lớp học',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_search_outlined),
    selectedIcon: Icon(Icons.person_search),
    label: 'Học viên',
  ),
  NavigationDestination(
    icon: Icon(Icons.school_outlined),
    selectedIcon: Icon(Icons.school),
    label: 'Giáo viên',
  ),
  NavigationDestination(
    icon: Icon(Icons.book_outlined),
    selectedIcon: Icon(Icons.book),
    label: 'Khóa học',
  ),
  NavigationDestination(
    icon: Icon(Icons.meeting_room_outlined),
    selectedIcon: Icon(Icons.meeting_room),
    label: 'Phòng',
  ),
],
      ),
    );
  }
}
