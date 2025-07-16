# ----------------------------------------------------
# 1. Configuración del Proveedor de MongoDB Atlas
# ----------------------------------------------------
# Le dice a Terraform qué proveedor de la nube (MongoDB Atlas) debe usar
# y qué versión es requerida.
terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.13.1" # IMPORTANTE: Puedes verificar la última versión compatible aquí:
                        # https://registry.terraform.io/providers/mongodb/mongodbatlas/latest
    }
  }
}

# Configura el proveedor de MongoDB Atlas usando las claves API
# que se cargarán desde el archivo 'terraform.tfvars'.
provider "mongodbatlas" {
  public_key  = var.atlas_public_key
  private_key = var.atlas_private_key
}

# ----------------------------------------------------
# 2. Definición de Variables
# ----------------------------------------------------
# Estas variables son los marcadores de posición para tus credenciales
# y el ID de tu organización. Los valores reales irán en terraform.tfvars.
variable "atlas_public_key" {
  description = "Tu clave pública de la API de MongoDB Atlas."
  type        = string
  sensitive   = true # Evita que el valor se muestre en los logs de Terraform
}

variable "atlas_private_key" {
  description = "Tu clave privada de la API de MongoDB Atlas."
  type        = string
  sensitive   = true # Evita que el valor se muestre en los logs de Terraform
}

variable "atlas_organization_id" {
  description = "Tu ID de Organización de MongoDB Atlas."
  type        = string
}

# Variable para la IP de acceso, ya que 0.0.0.0/0 no está permitido
variable "my_ip_address" {
  description = "Tu dirección IP pública actual para la lista de acceso de Atlas."
  type        = string
  # Puedes poner tu IP aquí como un valor por defecto si es fija,
  # o dejarlo en blanco para que te lo pida, o usar el tfvars.
  # default = "TU_IP_PUBLICA_AQUI"
}

# ----------------------------------------------------
# 3. Recurso: Proyecto de MongoDB Atlas
# ----------------------------------------------------
# Define un nuevo proyecto en tu organización de MongoDB Atlas.
# Si ya tienes un proyecto y quieres usarlo, tendrías que usar un "data" block
# en lugar de un "resource" y omitir la creación de un nuevo proyecto.
resource "mongodbatlas_project" "mi_proyecto_clase" {
  org_id = var.atlas_organization_id # Usa el ID de tu organización
  name   = "Proyecto-Clase-ETL"      # Nombre del proyecto en Atlas

  # Opcional: Define equipos si los tienes configurados
  # teams {
  #   team_id    = "id_del_equipo_existente_en_atlas"
  #   role_names = ["GROUP_OWNER"]
  # }
}

# Output: Muestra el ID del proyecto una vez creado.
output "project_id_created" {
  value = mongodbatlas_project.mi_proyecto_clase.id
  description = "El ID del proyecto de MongoDB Atlas creado."
}

# ----------------------------------------------------
# 4. Recurso: Clúster de MongoDB Atlas (M0 Gratuito)
# ----------------------------------------------------
# Define un clúster M0 (gratuito).
# ¡Advertencia para M0s! Son solo para desarrollo y tienen limitaciones
# de disponibilidad por región en Atlas. Podría fallar si la región está saturada.
resource "mongodbatlas_cluster" "mi_cluster_demo" {
  project_id                  = mongodbatlas_project.mi_proyecto_clase.id # Asocia al proyecto creado
  name                        = "cluster-demo-iaC"                        # Nombre del clúster
  cluster_type                = "REPLICASET" # Tipo de clúster (M0 es siempre replicaset)


  # Configuración del proveedor de la nube
  provider_name               = "Azure"             # Puedes cambiar a GCP o AZURE
  provider_region_name        = "AZURE_EASTUS2" # O si prefieres, "EU_WEST_1"       # Región del proveedor. Elige una cercana a ti.
                                                  # Ejemplos: "US_EAST_1" (N. Virginia), "EU_WEST_1" (Irlanda)
                                                  # Para GCP: "GOOGLE_NORTH_AMERICA_NORTHEAST1"
                                                  # Para Azure: "AZURE_EASTUS2"
  provider_instance_size_name = "M0"              # Tipo de instancia (M0 es gratis)
  

  # Versión de MongoDB
  #mongo_db_major_version      = "6.0"             # Versión de MongoDB. Ajusta a la que necesites.
                                                  # Ej. "6.0", "5.0". Asegúrate que el proveedor
                                                  # y el tipo de instancia la soporten.

  # Opcional: Configuración avanzada (descomentar si la necesitas)
  # advanced_configuration {
  #   javascript_enabled = true
  # }
}

# Output: Muestra la cadena de conexión SRV del clúster.
output "cluster_connection_string_srv" {
  value = mongodbatlas_cluster.mi_cluster_demo.connection_strings[0].standard_srv
  description = "Cadena de conexión SRV para el clúster de MongoDB Atlas."
  sensitive   = true # Contiene información sensible
}

# ----------------------------------------------------
# 5. Recurso: Usuario de Base de Datos para el Clúster
# ----------------------------------------------------
# Crea un usuario para acceder a la base de datos de tu clúster.
# ¡IMPORTANTE! Genera una contraseña segura y no la pongas directamente aquí.
# Usaremos una variable.
resource "mongodbatlas_database_user" "mi_usuario_db" {
  project_id           = mongodbatlas_project.mi_proyecto_clase.id
  username             = "usuario_etl" # El nombre de usuario que usarás para conectar a la DB
  password             = var.db_user_password # La contraseña se define en terraform.tfvars
  auth_database_name   = "admin" # Generalmente es 'admin' o el nombre de tu base de datos principal

  # Roles del usuario
  roles {
    database_name = "admin"
    role_name     = "readWriteAnyDatabase" # Permite leer y escribir en cualquier DB
  }
  # Si quieres acceso solo a una base de datos específica:
  # roles {
  #   database_name = "nombre_de_tu_db_especifica"
  #   role_name     = "readWrite"
  # }
}

# Output: Muestra el nombre de usuario de la base de datos.
output "db_username" {
  value = mongodbatlas_database_user.mi_usuario_db.username
  description = "El nombre de usuario de la base de datos de MongoDB Atlas."
}

# ----------------------------------------------------
# 6. Recurso: Lista de Acceso IP para el Proyecto/Clúster
# ----------------------------------------------------
# Define qué direcciones IP pueden conectarse al clúster de MongoDB Atlas.
# Recuerda que 0.0.0.0/0 ya no está permitido para API keys,
# pero para la lista de acceso al clúster, sí suele ser posible.
# Sin embargo, es mejor especificar una IP o un rango.
resource "mongodbatlas_project_ip_access_list" "access_from_my_ip" {
  project_id  = mongodbatlas_project.mi_proyecto_clase.id
  ip_address  = var.my_ip_address # Tu IP pública
  comment     = "Acceso desde mi IP para desarrollo"
}

# Opcional: Si necesitas acceso desde cualquier lugar (menos seguro pero útil para demos rápidas)
# resource "mongodbatlas_project_ip_access_list" "access_anywhere" {
#   project_id  = mongodbatlas_project.mi_proyecto_clase.id
#   ip_address  = "0.0.0.0/0"
#   comment     = "Permitir acceso desde cualquier lugar (demo/testing)"
# }

# ----------------------------------------------------
# 7. Variable para la contraseña del usuario de la DB
# ----------------------------------------------------
variable "db_user_password" {
  description = "Contraseña para el usuario de la base de datos de MongoDB."
  type        = string
  sensitive   = true # ¡Muy importante para la seguridad!
}