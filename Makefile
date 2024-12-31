pre-release:
	flutter pub get

gen-code:
	flutter pub run build_runner build --delete-conflicting-outputs

gen-watch:
	flutter pub run build_runner watch --delete-conflicting-outputs

archive-mac:
	flutter_distributor package --platform macos --targets dmg