# Importar las dependencias de Flask
from flask import Flask, render_template, session, flash, redirect, url_for
from functools import wraps
import pymongo

# Crear una instancia de la aplicación Flask
app = Flask(__name__)

app.secret_key = b'\xb7\x16\xd9\x99o\x95\x85\x87\t\xd49\xd4\xd6[<\xd0'
"""
#database connection
#client = pymongo.MongoClient("mongodb+srv://danielito:password@clusterdanielrincon.ka0ke9e.mongodb.net/Aplicacion_Flask")
client = pymongo.MongoClient("mongodb+srv://admin:admin123123@cluster0.v9kflej.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")


db = client.Prueba

#Decorador para definir una ruta

def login_required(f):
    @wraps(f)
    def wrap(*args, **kwargs):
        if 'logged_in' in session:
            return f(*args,**kwargs)
        else:
            flash('You need to login first')
            return redirect('/')
    return wrap
"""

#routes
from extensions import db, login_required
#from user import routes
from user.routes import user_bp
app.register_blueprint(user_bp)

# Definir una ruta de inicio
@app.route('/')
def home():
    return render_template('login.html')


@app.route('/register/')
def register():
    return render_template('register.html')


@app.route('/perfil/')
@login_required
def perfil():
    return render_template('perfil.html')


# ... (todo el código existente) ...

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000) # Especifica host='0.0.0.0' y port=5000


#docker-compose up --build