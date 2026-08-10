DEVICE ?= 00008110-000A18802E03801E

.PHONY: run run-release build-ios build-apk build-aab clean

## Run in debug mode
run:
	flutter run -d $(DEVICE)

## Run in release mode
run-release:
	flutter run -d $(DEVICE) --release

## Build iOS release
build-ios:
	flutter build ios --release

## Build Android APK
build-apk:
	flutter build apk --release

## Build Android App Bundle
build-aab:
	flutter build appbundle --release

clean:
	flutter clean
