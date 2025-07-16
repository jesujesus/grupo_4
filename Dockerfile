# Usa una imagen base ligera de Python 11
FROM python:3.11-slim-buster

# Establece el directorio de trabajo dentro del contenedor
# Todo lo que se copie o ejecute después de esta línea estará en /app dentro del contenedor.
WORKDIR /app

# Copia el archivo requirements.txt desde el host al contenedor.
# Como requirements.txt está en el mismo directorio que el Dockerfile,
# simplemente copiamos el archivo al WORKDIR del contenedor.
COPY requirements.txt .

# Instala las dependencias de Python listadas en requirements.txt.
# --no-cache-dir evita que pip guarde una caché de paquetes, reduciendo el tamaño de la imagen.
RUN pip install --no-cache-dir -r requirements.txt

# Instala las dependencias de Python listadas en requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Limpia la caché de pip para reducir el tamaño de la imagen y evitar posibles corrupciones
RUN rm -rf /root/.cache/pip

# Copia todo el código de la aplicación desde el host al contenedor.
# El '.' en el origen (primer '.') significa "todo el contenido del directorio actual del host"
# (donde está el Dockerfile). El '.' en el destino (segundo '.') significa
# "al directorio de trabajo actual del contenedor" (que es /app).
# Esto copiará app.py, static/, templates/, user/, etl.py, etc., a /app.
COPY . .

# Expone el puerto en el que se ejecutará tu aplicación Flask (por ejemplo, 5000).
# Esto indica a Docker que la aplicación dentro del contenedor usará este puerto.
EXPOSE 5000

# Configura variables de entorno (si son necesarias para tu aplicación, por ejemplo, la URI de MongoDB).
# Es mejor pasar la MONGO_URI a través de docker-compose.yml o docker run con -e,
# para no "quemar" credenciales en la imagen.
# ENV MONGODB_URI="mongodb+srv://<usuario>:<contraseña>@<cluster>.mongodb.net/<nombre_db>?retryWrites=true&w=majority"

# Comando para ejecutar la aplicación Flask.
# Asumimos que tu archivo principal es app.py y que tu aplicación Flask se ejecuta directamente con Python.
CMD ["python", "app.py"]

# Si usas Gunicorn (recomendado para producción por su robustez y rendimiento):
# Descomenta la siguiente línea y comenta la anterior si decides usar Gunicorn.
# Asegúrate de haber instalado gunicorn en tu requirements.txt.
# CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
# -w 4: Inicia 4 procesos de trabajo de Gunicorn.
# -b 0.0.0.0:5000: Escucha en todas las interfaces de red en el puerto 5000.
# app:app: Asume que tu instancia de la aplicación Flask se llama 'app' dentro del archivo 'app.py'.