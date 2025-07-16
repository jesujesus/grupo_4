import pymongo
from functools import wraps
from flask import session, flash, redirect

# Conexión a la base de datos
client = pymongo.MongoClient("mongodb+srv://admin:admin123123@cluster0.v9kflej.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
db = client.Prueba

# Decorador login_required
def login_required(f):
    @wraps(f)
    def wrap(*args, **kwargs):
        if 'logged_in' in session:
            return f(*args, **kwargs)
        else:
            flash('You need to login first')
            return redirect('/')
    return wrap