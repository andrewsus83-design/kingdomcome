SUPABASE_URL := https://diyimabdmsjykvitomgd.supabase.co
SUPABASE_ANON_KEY := eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpeWltYWJkbXNqeWt2aXRvbWdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MDYyMDgsImV4cCI6MjA4NzA4MjIwOH0.YbDq_1zLli12RY10EFi6yihhlzSYc8oNcUvirN9qp-Q
AI_GATEWAY_URL := https://kingdom-come-ai-gateway.andrewsus83.workers.dev
BIBLE_API_URL   := https://kingdom-come-bible-api.andrewsus83.workers.dev

DART_DEFINES := \
	--dart-define=SUPABASE_URL=$(SUPABASE_URL) \
	--dart-define=SUPABASE_ANON_KEY=$(SUPABASE_ANON_KEY) \
	--dart-define=AI_GATEWAY_URL=$(AI_GATEWAY_URL) \
	--dart-define=BIBLE_API_URL=$(BIBLE_API_URL)

.PHONY: setup run run-ios run-android build-ios build-android gen clean

## First-time setup: fonts + placeholders + pub get + codegen
setup:
	bash scripts/setup.sh

## Run on connected device (debug)
run:
	flutter run $(DART_DEFINES)

## Run specifically on iOS Simulator
run-ios:
	flutter run -d "iPhone 16 Pro" $(DART_DEFINES)

## Run on Android emulator
run-android:
	flutter run -d "emulator-5554" $(DART_DEFINES)

## Re-run code generation only
gen:
	dart run build_runner build --delete-conflicting-outputs

## Clean build artifacts
clean:
	flutter clean
	dart run build_runner clean

## Build iOS release IPA
build-ios:
	flutter build ipa $(DART_DEFINES) --release

## Build Android release AAB
build-android:
	flutter build appbundle $(DART_DEFINES) --release
