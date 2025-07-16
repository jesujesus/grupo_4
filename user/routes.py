# Importa las bibliotecas y clases necesarias
from bson import ObjectId
from flask import Blueprint, render_template, redirect, url_for, request, jsonify, session
from werkzeug.security import generate_password_hash, check_password_hash

from user.models import User, Task
from extensions import db, login_required

user_bp = Blueprint('user', __name__)

@user_bp.route('/user/signup', methods=['POST'])
def signup():
    return User().signup()
    
@user_bp.route('/user/signout')
def signout():
    return User().signout()

@user_bp.route('/user/login', methods=['POST'])
def login():
    return User().login()

@user_bp.route('/add_task', methods=['POST'])
def add_task():
    result = Task().add_task()
    return jsonify({"message": "Task added successfully"}), 200

@user_bp.route('/dashboard/tasks', methods=['GET'])
@login_required
def get_user_tasks():
    tasks = Task().get_user_tasks()
    return jsonify([{"nombre": task["nombre"], "detalles": task["detalles"], "fecha_entrega": task["fecha_entrega"]} for task in tasks])


@user_bp.route('/delete_task', methods=['POST'])
def delete_task():
    task_id = request.form.get('task_id')
    Task().delete_task(task_id)
    return jsonify({"message": "Task deleted successfully"}), 200


@user_bp.route('/registrar_postulante', methods=['POST'])
def registrar_postulante():
    datos = dict(request.form)
    print(datos)  # Verifica en la terminal que los datos llegan
    db.postulantes.insert_one(datos)
    return redirect('/dashboard')

@user_bp.route('/dashboard')
def dashboard():
    postulantes = list(db.postulantes.find())
    return render_template('dashboard.html', postulantes=postulantes)

@user_bp.route('/editar_tarea/<string:task_id>')
@login_required
def editar_tarea(task_id):
    task = Task().get_task_by_id(task_id)
    return render_template('editar_tarea.html', task=task)

@user_bp.route('/edit_task/<string:task_id>', methods=['POST'])
def edit_task(task_id):
    user_id = session['user']['_id']
    nombre = request.form['nombre']
    detalles = request.form['detalles']
    fecha_entrega = request.form['fecha_entrega']

    task_model = Task()
    if task_model.edit_task(task_id, nombre, detalles, fecha_entrega):
        return redirect('/dashboard')
    else:
        return jsonify({"error": "Task not found or user does not have permission to edit"}), 404
