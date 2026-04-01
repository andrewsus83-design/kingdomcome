#!/bin/bash
# Kingdom Come — First-time setup script
# Run once after cloning: bash scripts/setup.sh

set -e
cd "$(dirname "$0")/.."

echo "🏰 Kingdom Come Setup"
echo "====================="

# ── 1. Cinzel fonts from Google Fonts ──────────────────────────────────────
echo ""
echo "📥 Downloading Cinzel fonts..."

FONTS_DIR="assets/fonts"
mkdir -p "$FONTS_DIR"

# Cinzel Regular
curl -sL "https://fonts.gstatic.com/s/cinzel/v23/8vIU7ww63mVu7gt79mT_MkWSjgEBwMk3.ttf" \
  -o "$FONTS_DIR/Cinzel-Regular.ttf" && echo "  ✓ Cinzel-Regular.ttf"

# Cinzel Bold
curl -sL "https://fonts.gstatic.com/s/cinzel/v23/8vIU7ww63mVu7gt79mT_ugmSjgEBwMk3.ttf" \
  -o "$FONTS_DIR/Cinzel-Bold.ttf" && echo "  ✓ Cinzel-Bold.ttf"

# Use Bold as SemiBold (same weight tier — adjust URL if you have a specific SemiBold source)
curl -sL "https://fonts.gstatic.com/s/cinzel/v23/8vIU7ww63mVu7gt79mT_ugmSjgEBwMk3.ttf" \
  -o "$FONTS_DIR/Cinzel-SemiBold.ttf" && echo "  ✓ Cinzel-SemiBold.ttf (from Bold)"

# ── 2. Placeholder asset files ─────────────────────────────────────────────
echo ""
echo "📁 Creating placeholder assets..."

# Required directories from pubspec.yaml
for dir in \
  "assets/images/ui" \
  "assets/images/buildings" \
  "assets/images/saints" \
  "assets/images/map" \
  "assets/animations" \
  "assets/data"; do
  mkdir -p "$dir"
  touch "$dir/.gitkeep"
done

# Minimal placeholder JSON data files (so the app can boot without errors)
cat > assets/data/saints.json << 'EOF'
[]
EOF

cat > assets/data/prayers.json << 'EOF'
[]
EOF

cat > assets/data/liturgical_calendar.json << 'EOF'
{}
EOF

cat > assets/data/buildings.json << 'EOF'
[]
EOF

cat > assets/data/quests.json << 'EOF'
[]
EOF

cat > assets/data/bible_verses.json << 'EOF'
[]
EOF

echo "  ✓ placeholder JSON data files"

# ── 3. Flutter pub get ─────────────────────────────────────────────────────
echo ""
echo "📦 Running flutter pub get..."
flutter pub get

# ── 4. Code generation ─────────────────────────────────────────────────────
echo ""
echo "⚙️  Running build_runner (code generation)..."
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Setup complete!"
echo ""
echo "To run the app:"
echo "  flutter run \\"
echo "    --dart-define=SUPABASE_URL=https://diyimabdmsjykvitomgd.supabase.co \\"
echo "    --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpeWltYWJkbXNqeWt2aXRvbWdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MDYyMDgsImV4cCI6MjA4NzA4MjIwOH0.YbDq_1zLli12RY10EFi6yihhlzSYc8oNcUvirN9qp-Q \\"
echo "    --dart-define=AI_GATEWAY_URL=https://kingdom-come-ai-gateway.andrewsus83.workers.dev"
echo ""
echo "Or open in VS Code and press F5 (launch.json already configured)."
