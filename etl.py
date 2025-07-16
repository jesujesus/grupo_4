import pymongo
import pandas as pd
from datetime import datetime

# 1. Conexión a MongoDB Atlas
client = pymongo.MongoClient("mongodb+srv://admin:admin123123@cluster0.v9kflej.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")

# 2. Base de datos origen y destino
db_origen = client.Prueba
db_destino = client.ETL_Destino

# 3. Cargar CSV actual a la base de datos origen
df = pd.read_csv('postulantes_2024-2_2025-1.csv')
data = df.to_dict(orient='records')
db_origen.postulantes.insert_many(data)
print("✅ Datos cargados en base de datos origen (Prueba.postulantes)")

# 4. Transformación de datos
for d in data:
    # Mayúsculas
    d['COLEGIO'] = d.get('COLEGIO', '').upper()
    d['ESPECIALIDAD'] = d.get('ESPECIALIDAD', '').upper()
    d['MODALIDAD'] = d.get('MODALIDAD', '').upper()
    d['COLEGIO_PAIS'] = d.get('COLEGIO_PAIS', '').upper()
    d['NACIMIENTO_PAIS'] = d.get('NACIMIENTO_PAIS', '').upper()

    # Capitalización de ubicaciones
    d['COLEGIO_DEPA'] = d.get('COLEGIO_DEPA', '').title()
    d['COLEGIO_PROV'] = d.get('COLEGIO_PROV', '').title()
    d['COLEGIO_DIST'] = d.get('COLEGIO_DIST', '').title()
    d['DOMICILIO_DEPA'] = d.get('DOMICILIO_DEPA', '').title()
    d['DOMICILIO_PROV'] = d.get('DOMICILIO_PROV', '').title()
    d['DOMICILIO_DIST'] = d.get('DOMICILIO_DIST', '').title()
    d['NACIMIENTO_DEPA'] = d.get('NACIMIENTO_DEPA', '').title()
    d['NACIMIENTO_PROV'] = d.get('NACIMIENTO_PROV', '').title()
    d['NACIMIENTO_DIST'] = d.get('NACIMIENTO_DIST', '').title()

    # Sexo
    sexo = d.get('SEXO', '').upper()
    d['SEXO'] = 'MASCULINO' if sexo == 'M' else 'FEMENINO' if sexo == 'F' else sexo

    # Ingreso
    ingreso = d.get('INGRESO', '')
    d['INGRESO'] = True if ingreso == 'Sí' else False if ingreso == 'No' else ingreso

    # Nota (calificación final)
    try:
        d['CALIF_FINAL'] = round(float(d.get('CALIF_FINAL', 0)), 2)
    except:
        d['CALIF_FINAL'] = 0.0

    # Año de egreso, postulación, nacimiento
    try:
        d['COLEGIO_ANIO_EGRESO'] = int(d.get('COLEGIO_ANIO_EGRESO', 0))
        d['ANIO_POSTULA'] = int(d.get('ANIO_POSTULA', 0))
        d['ANIO_NACIMIENTO'] = int(d.get('ANIO_NACIMIENTO', 0))
    except:
        pass

    # Fecha de corte
    try:
        d['FECHA_DE_CORTE'] = datetime.strptime(d['FECHA_DE_CORTE'], "%Y-%m-%d")
    except:
        d['FECHA_DE_CORTE'] = None

    # Proceso y fecha de carga
    d['PROCESO'] = '2024-2 a 2025-1'
    d['FECHA_REGISTRO'] = datetime.now()

# 5. Insertar transformados en destino
db_destino.postulantes_transformados.insert_many(data)
print(f"✅ {len(data)} registros transformados cargados en ETL_Destino.postulantes_transformados")
