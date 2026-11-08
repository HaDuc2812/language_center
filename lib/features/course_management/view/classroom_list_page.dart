import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/course_view_model.dart';
import 'classroom_form_page.dart';

class ClassroomListPage extends ConsumerWidget {
  const ClassroomListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classrooms = ref.watch(classroomListProvider);

    return Scaffold(
      body: classrooms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Lỗi: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có phòng học nào.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.status == 'active'
                        ? Colors.blue.shade100
                        : Colors.grey.shade300,
                    child: const Icon(Icons.meeting_room_outlined),
                  ),
                  title: Text(item.roomName),
                  subtitle: Text(
                    '${item.roomCode} • Sức chứa: ${item.capacity} • '
                    '${item.status == 'active' ? 'Hoạt động' : 'Ngưng'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ClassroomFormPage(classroom: item),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ClassroomFormPage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
