import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';

class TasksWidget extends StatefulWidget {
  const TasksWidget({Key? key}) : super(key: key);

  @override
  State<TasksWidget> createState() => _TasksWidgetState();
}

class _TasksWidgetState extends State<TasksWidget> {
  final TextEditingController _newItemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: FutureBuilder(
        future: Provider.of<TaskProvider>(context, listen: false).getTasks,
        builder: (ctx, snapshot) => snapshot.connectionState ==
                ConnectionState.waiting
            ? const Center(child: CircularProgressIndicator())
            : Consumer<TaskProvider>(
                child: Center(
                  heightFactor: MediaQuery.of(context).size.height * 0.03,
                  child: Text(
                    'You have no tasks.',
                    style: GoogleFonts.montserrat(
                        color: Colors.black12, fontSize: 20),
                  ),
                ),
                builder: (ctx, taskProvider, child) => taskProvider
                        .items.isEmpty
                    ? child as Widget
                    : Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: taskProvider.items.length + 1,
                            itemBuilder: (ctx, i) => Padding(
                              key: Key('$i'),
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: i == taskProvider.items.length
                                  ? ListTile(
                                      key: Key('$i'),
                                      leading: const Checkbox(
                                          value: false,
                                          shape: CircleBorder(),
                                          onChanged: null),
                                      title: TextFormField(
                                        controller: _newItemController,
                                        decoration: const InputDecoration(
                                          labelText: 'New item',
                                          border: OutlineInputBorder(),
                                        ),
                                        style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontSize: 15,
                                        ),
                                      ),
                                      trailing: IconButton(
                                          onPressed: () {
                                            Provider.of<TaskProvider>(context,
                                                    listen: false)
                                                .addTask(
                                                    _newItemController.text);
                                            _newItemController.clear();
                                          },
                                          icon: const Icon(Icons.add)))
                                  : ReorderableDragStartListener(
                                      key: Key('$i'),
                                      index: i,
                                      child: ListTile(
                                        leading: Checkbox(
                                            checkColor: Colors.black,
                                            activeColor: Colors.blueAccent,
                                            value: taskProvider
                                                .items[i].isExecuted,
                                            shape: const CircleBorder(),
                                            onChanged: (newValue) {
                                              Provider.of<TaskProvider>(context,
                                                      listen: false)
                                                  .executeTask(
                                                      taskProvider.items[i].id);
                                            }),
                                        title: Text(
                                          taskProvider.items[i].name,
                                          style: GoogleFonts.montserrat(
                                              color: Colors.black,
                                              fontSize: 15,
                                              decoration: taskProvider
                                                      .items[i].isExecuted
                                                  ? TextDecoration.lineThrough
                                                  : null),
                                        ),
                                        trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              Provider.of<TaskProvider>(context,
                                                      listen: false)
                                                  .deleteTask(
                                                      taskProvider.items[i].id);
                                            }),
                                        onTap: () {},
                                      )),
                            ),
                            onReorder: (int oldIndex, int newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final itemList = taskProvider.items;
                                final item = itemList.removeAt(oldIndex);
                                itemList.insert(newIndex, item);
                                Provider.of<TaskProvider>(context,
                                        listen: false)
                                    .updateTasksIds(itemList);
                              });
                            },
                          ),
                        ),
                      ),
              ),
      ),
    );
  }
}
