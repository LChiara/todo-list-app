# app.py

from flask import Flask, request, jsonify
from firebase_admin import credentials, db, initialize_app

# Initialize Flask App
app = Flask(__name__) 

# Initialize Firestore Realtime DB
cred = credentials.Certificate('key.json')

# DATABASE_NAME.REGION.firebasedatabase.app (for databases in all other locations)
default_app = initialize_app(cred, {
    'databaseURL': 'https://todo-list-flask-flutter-default-rtdb.europe-west1.firebasedatabase.app'
    })

ref = db.reference("/tasks")

### APIs ###
@app.route('/add', methods=['POST'])
def add_task():
    try:
        ref.push().set(request.json)
        return jsonify({"success": True}), 200
    except Exception as e:
        return f"An Error Occured: {e}"
    
@app.route('/list', methods=["GET"])
def get_tasks():
    try:
        tasks = ref.get()
        ordered_tasks = dict(sorted(tasks.items(), key = lambda x: x[1]["id"]))
        return jsonify(ordered_tasks), 200
    except Exception as e:
        return f"An Error Occured: {e}"
    
@app.route('/update/<id>', methods=["PATCH", "POST", "PUT"])
def update_task(id):
    task_id = int(id)
    try:
        tasks = ref.get()
        item = {"id": -1}
        for key, value in tasks.items():
            if value["id"] == task_id:
                item["id"] = task_id
                item["is_executed"] = not value["is_executed"]
                task_to_update_ref = ref.child(key)
                task_to_update_ref.update({"is_executed": not value["is_executed"]})
                break
        item["success"] = True
        return jsonify(item), 200
    except Exception as e:
        return f"An Error Occured: {e}"
    
    
@app.route('/delete/<id>', methods=["GET", "DELETE"])
def delete_task(id):
    task_id = int(id)
    try:
        tasks = ref.get()
        item = {"id": -1}
        for key, value in tasks.items():
            if value["id"] == task_id:
                item["id"] = task_id
                task_to_delete_ref = ref.child(key)
                task_to_delete_ref.delete()
                break
        item["success"] = True
        return jsonify(item), 200
    except Exception as e:
        return f"An Error Occured: {e}"


if __name__ == '__main__':
    app.run()