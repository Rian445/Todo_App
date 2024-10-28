import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoListScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const TodoListScreen({super.key, required this.isDarkMode, required this.toggleTheme});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Load tasks from shared preferences
  void _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedTasks = prefs.getStringList('tasks');
    if (storedTasks != null) {
      setState(() {
        tasks.clear();
        for (var task in storedTasks) {
          final taskData = task.split('|');
          DateTime? taskDate;
          if (taskData.length > 2 && taskData[2].isNotEmpty) {
            taskDate = DateTime.parse(taskData[2]);
          }
          tasks.add({
            'title': taskData[0],
            'note': taskData[1],
            'date': taskDate,
            'priority': taskData.length > 3 ? taskData[3] : 'Medium',
          });
        }
      });
    }
  }

  // Save tasks to shared preferences
  void _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> taskList = tasks.map((task) {
      String taskDate = task['date'] != null ? task['date'].toIso8601String() : '';
      return '${task['title']}|${task['note']}|$taskDate|${task['priority']}';
    }).toList();
    prefs.setStringList('tasks', taskList);
  }

  // Add new task
  void _addTask() {
    String newTask = '';
    String taskNote = '';
    DateTime? selectedDate;
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  newTask = value;
                },
                decoration: const InputDecoration(labelText: 'Task Name'),
              ),
              TextField(
                onChanged: (value) {
                  taskNote = value;
                },
                decoration: const InputDecoration(labelText: 'Task Note'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Due Date: '),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Text(selectedDate == null
                        ? 'Select Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: priority,
                items: ['Low', 'Medium', 'High'].map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    priority = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newTask.isNotEmpty) {
                  setState(() {
                    tasks.add({
                      'title': newTask,
                      'note': taskNote,
                      'date': selectedDate,
                      'priority': priority,
                    });
                  });
                  _saveTasks(); // Save tasks to shared preferences
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Edit an existing task
  void _editTask(int index) {
    String updatedTask = tasks[index]['title'];
    String updatedNote = tasks[index]['note'];
    DateTime? updatedDate = tasks[index]['date'];
    String updatedPriority = tasks[index]['priority'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  updatedTask = value;
                },
                controller: TextEditingController(text: updatedTask),
                decoration: const InputDecoration(labelText: 'Task Name'),
              ),
              TextField(
                onChanged: (value) {
                  updatedNote = value;
                },
                controller: TextEditingController(text: updatedNote),
                decoration: const InputDecoration(labelText: 'Task Note'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Due Date: '),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: updatedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          updatedDate = pickedDate;
                        });
                      }
                    },
                    child: Text(updatedDate == null
                        ? 'Select Date'
                        : '${updatedDate!.day}/${updatedDate!.month}/${updatedDate!.year}'),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: updatedPriority,
                items: ['Low', 'Medium', 'High'].map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    updatedPriority = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (updatedTask.isNotEmpty) {
                  setState(() {
                    tasks[index] = {
                      'title': updatedTask,
                      'note': updatedNote,
                      'date': updatedDate,
                      'priority': updatedPriority,
                    };
                  });
                  _saveTasks(); // Save tasks to shared preferences
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Delete task
  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      _saveTasks(); // Save tasks after deletion
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks added yet'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPriorityColor(tasks[index]['priority']),
                        child: const Icon(Icons.task, color: Colors.white),
                      ),
                      title: Text(tasks[index]['title'], style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tasks[index]['note'], style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                          Text(
                            tasks[index]['date'] != null
                                ? 'Due: ${tasks[index]['date'].day}/${tasks[index]['date'].month}/${tasks[index]['date'].year}'
                                : 'No Due Date',
                            style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editTask(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteTask(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: widget.isDarkMode ? Colors.blueGrey : Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'Low':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }
}
