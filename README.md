https://github.com/VayeZaZa/RASTROS-APP-GRUPO/blob/main/README.md# Rastros

Aplicación móvil Flutter para ayudar a las mascotas y a sus familias.

## Pantallas iniciales

- **Ingreso:** captura y valida un número de celular.
- **Identificación OTP:** presenta seis casillas para el código y permite continuar.
- **Inicio:** incluye navegación inferior para Explorar, Mapa, Reportar, Seguimiento y Perfil.

Las imágenes de la carpeta `Assets/` están registradas en `pubspec.yaml`: `Foto login.png` se usa en ingreso, `logo.png` en las pantallas de OTP e inicio, y `Foto OTP.png` en la pantalla de verificación. Las huellitas decorativas y las ondas inferiores se dibujan en Flutter.

## Rama `modo-test`

Esta rama es solo para trabajar en la interfaz. El inicio muestra un botón **Continuar como modo tester**; desde allí se puede avanzar por OTP e Inicio sin ingresar un código.

La aplicación de esta rama no inicializa Firebase. El acceso telefónico, el envío de SMS y el guardado de perfiles no están disponibles aquí.

## Ejecutar

```bash
flutter pub get
flutter run
```
