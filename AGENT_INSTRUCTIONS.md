# Instrucciones para Agentes de IA (AI Agent Instructions)

Este archivo contiene reglas de comportamiento críticas y obligatorias que **todo agente de inteligencia artificial** debe leer, comprender y cumplir estrictamente al trabajar en este repositorio.

---

## 🚨 REGLAS CRÍTICAS DE TRABAJO

### 1. Pruebas Obligatorias en Dispositivo Móvil
* **Regla**: Cualquier cambio realizado en el código debe ser probado y verificado directamente en el dispositivo móvil conectado del usuario antes de sugerir que el cambio está completo.
* **Comando para instalación**:
  ```powershell
  flutter install
  ```

### 2. Regla de Oro para el Push a GitHub y APK de Producción
El proceso de subir cambios a GitHub y compilar el APK de producción está regulado bajo la siguiente lógica condicional:

```mermaid
graph TD
    A[El usuario autoriza subir cambios / hacer push] --> B{¿Hay cambios en el código?}
    B -- Sí -- > C[1. Compilar APK de producción]
    C --> D[2. Copiar APK a release/pagame.apk]
    D --> E[3. Realizar Git Commit y Push]
    B -- No *solo docs/readme* --> F[1. Realizar Git Commit y Push directamente]
```

* **Solo cuando el usuario indique explícitamente que se deben subir los cambios a GitHub**, el agente aplicará las siguientes reglas:
  
  * **CASO A: Si el push involucra cambios en el código** (modificaciones en archivos de lógica, interfaz, assets, paquetes, bases de datos como `lib/`, `android/`, `pubspec.yaml`, etc.):
    1. **Generar el APK de producción** de forma obligatoria ejecutando:
       ```powershell
       flutter build apk --release --no-tree-shake-icons
       ```
    2. **Copiar el APK compilado** al directorio específico de distribución:
       ```powershell
       Copy-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination "release\pagame.apk" -Force
       ```
    3. **Subir todos los cambios** (incluyendo el nuevo APK de producción) a GitHub.
  
  * **CASO B: Si el push NO involucra cambios en el código** (modificaciones puras en documentación, archivos de guías, `README.md`, reportes de cambios, planes de tareas, etc.):
    1. **NO generar el APK de producción** (para ahorrar tiempo, recursos y evitar desgaste innecesario).
    2. **Subir los cambios** directamente a GitHub usando comandos git.

---

## 🛠️ FLUJO DE TRABAJO DEL AGENTE

Sigue siempre esta secuencia cuando recibas una solicitud del usuario:

1. **Investigar y Planificar**: Analizar el codebase sin alterar nada. Proponer la solución.
2. **Implementar**: Aplicar los cambios de código localmente en el espacio de trabajo.
3. **Probar en Móvil**: Instalar en el dispositivo móvil (`flutter install`) y solicitar al usuario que lo pruebe.
4. **Validación de Push**:
   * Preguntar al usuario si está satisfecho y si autoriza subir a GitHub.
   * **NUNCA** hacer git push o commits automáticos sin su confirmación explícita.
5. **Ejecutar la Regla de Oro**: Una vez autorizado, aplicar el árbol de decisión anterior (Caso A o Caso B) según corresponda.

---

## 💾 REGLAS PARA BASE DE DATOS Y COPAS DE SEGURIDAD (ZIP)

Cuando realices modificaciones en la base de datos o añadas/elimines campos de tablas:

### 1. Migraciones de Esquema SQLite Limpias (Sin `DROP COLUMN` directo)
* **Regla**: Dado que muchos motores SQLite en dispositivos Android antiguos no soportan `ALTER TABLE DROP COLUMN`, **nunca** uses esa instrucción.
* **Procedimiento Seguro de Recreación**:
  1. Renombrar la tabla original a `nombre_tabla_old`.
  2. Crear la nueva tabla con el esquema limpio deseado.
  3. Copiar los registros con `INSERT INTO nombre_tabla SELECT ... FROM nombre_tabla_old`.
  4. Eliminar la tabla `nombre_tabla_old` (`DROP TABLE`).

### 2. Sanitización Obligatoria en Importador de Respaldos (ZIP)
* **Archivo afectado**: `lib/utils/backup_helper.dart` (método `importBackup()`).
* **Regla**: Al alterar campos de base de datos, debes actualizar obligatoriamente la sanitización de filas en el importador.
* **Lógica**: Al restaurar copias de seguridad de formatos JSON/ZIP antiguos, mapea y copia **únicamente** los campos válidos del esquema moderno y descarta los obsoletos. Si faltan columnas requeridas de esquemas antiguos, inyecta valores por defecto válidos. Esto previene excepciones fatales de inserción en SQLite al restaurar respaldos antiguos de hace meses.
