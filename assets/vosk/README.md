# Herald offline voice pack

Place the unmodified Vosk archive at:

`assets/vosk/vosk-model-small-en-us-0.15.zip`

Do not unzip it into the Flutter assets directory. At first launch, Herald
unpacks it locally into the Android app documents directory:

`/data/user/0/com.example.herald/app_flutter/models/vosk-model-small-en-us-0.15/`

The archive is loaded only from the installed app; it is never downloaded at
runtime and microphone audio never leaves the device.
