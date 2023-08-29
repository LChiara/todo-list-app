import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/task_item.dart';

Logger logger = Logger('TODOAppLogger');

class TaskProvider with ChangeNotifier {
  List<TaskItem> _items = [];
  //final url = 'http://todo-list-app-env-dev.eu-central-1.elasticbeanstalk.com';
  final url = 'http://localhost:5000';

  List<TaskItem> get items {
    return [..._items];
  }

  Future<void> addTask(String newTaskName) async {
    if (newTaskName.isEmpty) {
      return;
    }
    // Get the max task ID and increment it for the new task
    final newTaskId = _items.reduce((a, b) => a.id > b.id ? a : b).id + 1;
    Map<String, dynamic> request = {
      "name": newTaskName,
      "is_executed": false,
      "id": newTaskId,
    };
    final headers = {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Accept': '*/*'
    };
    final response = await http.post(Uri.parse("$url/add"),
        headers: headers, body: json.encode(request));
    Map<String, dynamic> responsePayload = json.decode(response.body);
    // Check response from add procedure
    if (!responsePayload["success"]) {
      logger.severe("ADD /status=False");
      return;
    }

    final todo = TaskItem(id: newTaskId, name: newTaskName, isExecuted: false);
    _items.add(todo);
    logger.info("ADD /status=True");
    notifyListeners();
  }

  Future<void> get getTasks async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Accept': '*/*',
        "Access-Control-Allow-Headers":
            "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
      };
      final response = await http.get(Uri.parse("$url/list"), headers: headers);
      Map<String, dynamic> responsePayload = json.decode(response.body);
      _items = createItemsList(responsePayload);
      logger.info("GET /status=True");
    } catch (e) {
      logger.severe(e);
    }

    notifyListeners();
  }

  Future<void> deleteTask(int todoId) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final response =
          await http.delete(Uri.parse("$url/delete/$todoId"), headers: headers);
      final responsePayload = json.decode(response.body);
      _items.removeWhere((element) => element.id == responsePayload["id"]);
      logger.info("DELETE /status=True");
    } catch (e) {
      logger.severe(e);
    }
    notifyListeners();
  }

  Future<void> executeTask(int todoId) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final response =
          await http.patch(Uri.parse("$url/update/$todoId"), headers: headers);
      // Get response
      Map<String, dynamic> responsePayload = json.decode(response.body);
      _items.forEach((element) => {
            if (element.id == responsePayload["id"])
              {element.isExecuted = responsePayload["is_executed"]}
          });
      logger.info("UPDATE id=todoId /status=True");
    } catch (e) {
      logger.severe(e);
    }
    notifyListeners();
  }

  Future<void> updateTasksIds(List tasks) async {
    try {
      // Create request body
      final List request = [];
      for (var i = 0; i < tasks.length; i++) {
        request.add({"name": tasks[i].name, "id": i});
      }
      // Create http patch request
      final headers = {'Content-Type': 'application/json'};
      final response = await http.patch(Uri.parse("$url/update"),
          headers: headers, body: json.encode(request));
      // Get response
      Map<String, dynamic> responsePayload = json.decode(response.body);
      _items = createItemsList(responsePayload);
      logger.info("UPDATE /status=True");
    } catch (e) {
      logger.severe(e);
    }

    notifyListeners();
  }
}

List<TaskItem> createItemsList(Map<String, dynamic> responseBody) {
  final orderedBody = Map.fromEntries(responseBody.entries.toList()
    ..sort((e1, e2) => e1.value["id"].compareTo(e2.value["id"])));
  List<TaskItem> itemList = [];
  orderedBody.forEach((k, v) => itemList.add(
      TaskItem(id: v['id'], name: v["name"], isExecuted: v['is_executed'])));
  return itemList;
}
