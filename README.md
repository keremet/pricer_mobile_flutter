Приложение для сканирования чеков

Для подписывания APK
1. создать ключ
```
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```
2. создать файл android/key.properties
```
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=key
storeFile=<location of the key store file, such as /Users/<user name>/key.jks>
```

Подробнее: https://flutter.dev/docs/deployment/android

Сборка
```
flutter build apk --split-per-abi --release
flutter build apk --target-platform android-arm64 --release
```
