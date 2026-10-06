# Rastros

Aplicación móvil Flutter para ayudar a las mascotas y a sus familias.

## Pantallas iniciales

- **Ingreso:** captura y valida un número de celular.
- **Identificación OTP:** presenta seis casillas para el código y permite continuar.
- **Inicio:** incluye navegación inferior para Explorar, Mapa, Reportar, Seguimiento y Perfil.

Las imágenes de la carpeta `Assets/` están registradas en `pubspec.yaml`: `Foto login.png` se usa en ingreso, `logo.png` en las pantallas de OTP e inicio, y `Foto OTP.png` en la pantalla de verificación. Las huellitas decorativas y las ondas inferiores se dibujan en Flutter.

## Firebase Phone Authentication

La app inicializa Firebase y usa Firebase Authentication para enviar y verificar el código SMS. En Colombia, los números escritos sin prefijo se envían con `+57`; para otros países, escribe el número en formato internacional, empezando por `+` (por ejemplo, `+14155552671`).

En Firebase Console, selecciona el proyecto `rastros-app-cf11f`, registra una app Android cuyo ID de paquete sea exactamente `com.usc.rastros_app` y descarga su `google-services.json` en `android/app/google-services.json`. El archivo que se descargó inicialmente estaba registrado para `com.example.rastros`; ese archivo no corresponde a esta app y debe reemplazarse por el correcto.

Activa **Authentication → Sign-in method → Phone**. Para la verificación automática de Android y la configuración de seguridad, agrega las huellas SHA-1 y SHA-256 de la app en los ajustes de Firebase. Puedes consultar las huellas de debug con `cd android; .\gradlew signingReport`.

Para probar sin enviar SMS reales, agrega un número de prueba y su código en la configuración del proveedor Phone de Firebase Authentication. Para un número real, Firebase debe poder enviar SMS y pueden aplicar cuotas o límites.

## Ejecutar

```bash
flutter pub get
flutter run
```
