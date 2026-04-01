import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Domain enums ──────────────────────────────────────────────────────────────

enum ViceType { sloth, pride, greed, anger, envy }

enum SaintType { francis, dominic, joan, thomas, therese }

// ── Vice component ─────────────────────────────────────────────────────────────

class ViceComponent extends PositionComponent with HasGameRef<SaintDefenderGame> {
  ViceComponent({required this.viceType, required this.row})
      : super(size: Vector2(44, 44));

  final ViceType viceType;
  final int row;
  late double _speed;
  double _hp = 0;
  double _maxHp = 0;
  double _zigzagTimer = 0;
  double _splitTimer = 0;
  bool _hasSplit = false;
  final Paint _paint = Paint();
  final Paint _hpPaint = Paint()..color = Colors.red;
  final Paint _hpBgPaint = Paint()..color = Colors.black26;

  void configure() {
    _speed = switch (viceType) {
      ViceType.sloth => 28,
      ViceType.pride => 42,
      ViceType.greed => 60,
      ViceType.anger => 45,
      ViceType.envy => 38,
    };
    _maxHp = switch (viceType) {
      ViceType.sloth => 80,
      ViceType.pride => 160,
      ViceType.greed => 60,
      ViceType.anger => 90,
      ViceType.envy => 70,
    };
    _hp = _maxHp;
    _paint.color = switch (viceType) {
      ViceType.sloth => const Color(0xFF7F8C8D),
      ViceType.pride => const Color(0xFF8E44AD),
      ViceType.greed => const Color(0xFFF39C12),
      ViceType.anger => const Color(0xFFE74C3C),
      ViceType.envy => const Color(0xFF27AE60),
    };
  }

  bool get isDead => _hp <= 0;

  void takeDamage(double damage) {
    _hp = (_hp - damage).clamp(0, _maxHp);
  }

  /// Applies a slow effect for [duration] seconds.
  void applySlow(double factor, double duration) {
    _speed = (_speed * factor).clamp(5, 999);
    Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
      if (!isDead) {
        _speed = switch (viceType) {
          ViceType.sloth => 28,
          ViceType.pride => 42,
          ViceType.greed => 60,
          ViceType.anger => 45,
          ViceType.envy => 38,
        };
      }
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Base movement: left to right across the path
    position.x += _speed * dt;

    // Anger vice zigzags vertically within the row band
    if (viceType == ViceType.anger) {
      _zigzagTimer += dt;
      position.y += math.sin(_zigzagTimer * 4) * 1.5;
    }

    // Envy splits into two when at half HP
    if (viceType == ViceType.envy && !_hasSplit && _hp < _maxHp * 0.5) {
      _hasSplit = true;
      gameRef.spawnSplitVice(this);
    }

    // Remove when past the end of the path
    if (position.x > gameRef.size.x + 60) {
      gameRef.onViceReachedEnd();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      ),
      _paint,
    );

    // Vice symbol
    const textStyle = TextStyle(color: Colors.white, fontSize: 22);
    final symbol = switch (viceType) {
      ViceType.sloth => '😴',
      ViceType.pride => '👑',
      ViceType.greed => '💰',
      ViceType.anger => '😡',
      ViceType.envy => '🟢',
    };
    final tp = TextPainter(
      text: TextSpan(text: symbol, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));

    // HP bar
    final hpFrac = (_hp / _maxHp).clamp(0.0, 1.0);
    final barY = size.y + 3;
    canvas.drawRect(Rect.fromLTWH(0, barY, size.x, 5), _hpBgPaint);
    canvas.drawRect(Rect.fromLTWH(0, barY, size.x * hpFrac, 5), _hpPaint);
  }
}

// ── Saint tower component ──────────────────────────────────────────────────────

class SaintTowerComponent extends PositionComponent
    with HasGameRef<SaintDefenderGame> {
  SaintTowerComponent({required this.saintType, required Vector2 tilePosition})
      : super(position: tilePosition, size: Vector2(52, 52));

  final SaintType saintType;
  double _attackCooldown = 0;
  double _attackRate = 0;
  double _damage = 0;
  double _range = 0;
  final Paint _basePaint = Paint();

  void configure() {
    _attackRate = switch (saintType) {
      SaintType.francis => 2.5, // area, slow
      SaintType.dominic => 1.5, // chain
      SaintType.joan => 0.8, // fast sword
      SaintType.thomas => 3.0, // stun
      SaintType.therese => 1.2, // DoT
    };
    _damage = switch (saintType) {
      SaintType.francis => 20,
      SaintType.dominic => 30,
      SaintType.joan => 45,
      SaintType.thomas => 25,
      SaintType.therese => 15,
    };
    _range = switch (saintType) {
      SaintType.francis => 160, // wide area
      SaintType.dominic => 120,
      SaintType.joan => 90,
      SaintType.thomas => 100,
      SaintType.therese => 110,
    };
    _basePaint.color = switch (saintType) {
      SaintType.francis => const Color(0xFF8B6914),
      SaintType.dominic => const Color(0xFF1A1A1A),
      SaintType.joan => const Color(0xFF2980B9),
      SaintType.thomas => const Color(0xFF6C3483),
      SaintType.therese => const Color(0xFFE91E63),
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    _attackCooldown -= dt;
    if (_attackCooldown <= 0) {
      _tryAttack();
      _attackCooldown = _attackRate;
    }
  }

  void _tryAttack() {
    final vices = gameRef.activeVices;
    if (vices.isEmpty) return;

    final centre = position + size / 2;

    switch (saintType) {
      case SaintType.francis:
        // Area prayer: slow + damage all in range
        for (final vice in List.from(vices)) {
          final viceCentre = vice.position + vice.size / 2;
          if ((viceCentre - centre).length <= _range) {
            vice.takeDamage(_damage);
            vice.applySlow(0.5, 2.0);
          }
        }
        gameRef.spawnParticle(centre, const Color(0xFF8B6914));

      case SaintType.dominic:
        // Chain rosary: hits first target, then chains to nearest
        ViceComponent? first = _nearestVice(vices, centre);
        if (first == null) return;
        final hit = <ViceComponent>{first};
        first.takeDamage(_damage);
        // Chain up to 3 vices
        for (int i = 0; i < 2; i++) {
          final next = _nearestViceExcluding(vices, first!.position + first.size / 2, hit);
          if (next == null) break;
          next.takeDamage(_damage * 0.7);
          hit.add(next);
          first = next;
        }
        gameRef.spawnParticle(centre, Colors.white);

      case SaintType.joan:
        // Sword: high damage to single nearest
        final target = _nearestVice(vices, centre);
        if (target != null && (target.position + target.size / 2 - centre).length <= _range) {
          target.takeDamage(_damage);
          gameRef.spawnParticle(centre, const Color(0xFF2980B9));
        }

      case SaintType.thomas:
        // Wisdom blast: stuns nearest vice
        final target = _nearestVice(vices, centre);
        if (target != null && (target.position + target.size / 2 - centre).length <= _range) {
          target.takeDamage(_damage);
          target.applySlow(0.1, 2.0); // stun = very slow
          gameRef.spawnParticle(centre, const Color(0xFF6C3483));
        }

      case SaintType.therese:
        // Flower shower DoT: applies repeating damage to all in range
        for (final vice in List.from(vices)) {
          final viceCentre = vice.position + vice.size / 2;
          if ((viceCentre - centre).length <= _range) {
            vice.takeDamage(_damage * 0.5);
          }
        }
        gameRef.spawnParticle(centre, const Color(0xFFE91E63));
    }
  }

  ViceComponent? _nearestVice(List<ViceComponent> vices, Vector2 from) {
    ViceComponent? nearest;
    double minDist = double.infinity;
    for (final v in vices) {
      final d = (v.position + v.size / 2 - from).length;
      if (d < minDist) {
        minDist = d;
        nearest = v;
      }
    }
    return nearest;
  }

  ViceComponent? _nearestViceExcluding(
    List<ViceComponent> vices,
    Vector2 from,
    Set<ViceComponent> excluded,
  ) {
    ViceComponent? nearest;
    double minDist = double.infinity;
    for (final v in vices) {
      if (excluded.contains(v)) continue;
      final d = (v.position + v.size / 2 - from).length;
      if (d < minDist) {
        minDist = d;
        nearest = v;
      }
    }
    return nearest;
  }

  @override
  void render(Canvas canvas) {
    // Base platform
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(10),
      ),
      _basePaint,
    );

    // Saint emoji
    final symbol = switch (saintType) {
      SaintType.francis => '🕊️',
      SaintType.dominic => '📿',
      SaintType.joan => '⚔️',
      SaintType.thomas => '📖',
      SaintType.therese => '🌸',
    };
    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: const TextStyle(fontSize: 26),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2),
    );
  }
}

// ── Particle component ─────────────────────────────────────────────────────────

class _ParticleComponent extends PositionComponent {
  _ParticleComponent({required Vector2 pos, required this.color})
      : super(position: pos, size: Vector2(20, 20));

  final Color color;
  double _life = 0.6;

  @override
  void update(double dt) {
    _life -= dt;
    position.y -= 40 * dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      10 * (_life / 0.6),
      Paint()..color = color.withOpacity((_life / 0.6).clamp(0, 1)),
    );
  }
}

// ── Flame Game ────────────────────────────────────────────────────────────────

class SaintDefenderGame extends FlameGame with TapCallbacks {
  SaintDefenderGame({required this.onGameOver, required this.onWaveComplete});

  final void Function(int holyPoints, int wavesCompleted) onGameOver;
  final void Function(int wave) onWaveComplete;

  // Game state
  int _currentWave = 0;
  int _currentLevel = 1;
  int _grace = 100;
  int _holyPoints = 0;
  int _lives = 5;
  bool _gameOver = false;
  bool _waveInProgress = false;

  // Costs
  static const Map<SaintType, int> _saintCosts = {
    SaintType.francis: 30,
    SaintType.dominic: 25,
    SaintType.joan: 20,
    SaintType.thomas: 35,
    SaintType.therese: 15,
  };

  SaintType _selectedSaint = SaintType.joan;

  List<ViceComponent> get activeVices =>
      children.whereType<ViceComponent>().where((v) => !v.isDead).toList();

  final math.Random _rng = math.Random();

  // Path row y-positions (5 rows × 1 path)
  static const double _pathY = 200;

  @override
  Color backgroundColor() => const Color(0xFF0D1B2A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _startNextWave();
  }

  // ── Wave management ───────────────────────────────────────────────────────────

  void _startNextWave() {
    _currentWave++;
    if (_currentWave > 5) {
      _onLevelComplete();
      return;
    }
    _waveInProgress = true;
    _spawnWave(_currentWave);
  }

  Future<void> _spawnWave(int wave) async {
    final count = 3 + wave * 2;
    final interval = Duration(milliseconds: 1200 - wave * 100);

    for (int i = 0; i < count && !_gameOver; i++) {
      if (i > 0) await Future<void>.delayed(interval);
      _spawnVice();
    }
  }

  void _spawnVice() {
    final viceTypes = ViceType.values;
    final type = viceTypes[_rng.nextInt(viceTypes.length)];
    final vice = ViceComponent(viceType: type, row: 0)
      ..position = Vector2(-50, _pathY);
    vice.configure();
    add(vice);
  }

  void spawnSplitVice(ViceComponent parent) {
    final child = ViceComponent(viceType: ViceType.envy, row: parent.row)
      ..position = parent.position.clone() + Vector2(0, -20);
    child.configure();
    add(child);
  }

  // ── Tower placement ───────────────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    if (_gameOver) return;
    final cost = _saintCosts[_selectedSaint]!;
    if (_grace < cost) return;

    // Only allow placement on side rows (not the path row)
    final tapY = event.canvasPosition.y;
    if ((tapY - _pathY).abs() < 40) return; // too close to path

    // Check no existing tower at tap position
    final tapPos = event.canvasPosition - Vector2(26, 26);
    for (final tower in children.whereType<SaintTowerComponent>()) {
      if ((tower.position - tapPos).length < 60) return;
    }

    _grace -= cost;
    final tower = SaintTowerComponent(
      saintType: _selectedSaint,
      tilePosition: tapPos,
    )..configure();
    add(tower);
  }

  // ── Game events ───────────────────────────────────────────────────────────────

  void onViceReachedEnd() {
    _lives--;
    if (_lives <= 0 && !_gameOver) {
      _triggerGameOver();
    }
  }

  void _onLevelComplete() {
    _currentLevel++;
    _currentWave = 0;
    _grace += 50;
    _holyPoints += 100 * _currentLevel;
    onWaveComplete(_currentLevel - 1);

    if (_currentLevel > 3) {
      _triggerGameOver(); // Victory
    } else {
      _startNextWave();
    }
  }

  void _triggerGameOver() {
    _gameOver = true;
    onGameOver(_holyPoints, (_currentLevel - 1) * 5 + (_currentWave - 1));
  }

  void spawnParticle(Vector2 position, Color color) {
    add(_ParticleComponent(pos: position, color: color));
  }

  // ── Wave check loop ───────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    // Remove dead vices
    for (final vice in children.whereType<ViceComponent>().toList()) {
      if (vice.isDead) {
        _holyPoints += 10;
        _grace += 5;
        vice.removeFromParent();
      }
    }

    // Check wave clear
    if (_waveInProgress && activeVices.isEmpty) {
      _waveInProgress = false;
      onWaveComplete(_currentWave);
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!_gameOver) _startNextWave();
      });
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Path background
    final pathPaint = Paint()..color = const Color(0xFF1A3A1A);
    canvas.drawRect(
      Rect.fromLTWH(0, _pathY - 26, size.x, 52),
      pathPaint,
    );

    // Path direction arrows
    final arrowPaint = Paint()..color = Colors.white12;
    for (double x = 30; x < size.x; x += 80) {
      canvas.drawPath(
        Path()
          ..moveTo(x, _pathY)
          ..lineTo(x + 20, _pathY - 10)
          ..lineTo(x + 20, _pathY + 10)
          ..close(),
        arrowPaint,
      );
    }

    // HUD
    _renderHud(canvas);
  }

  void _renderHud(Canvas canvas) {
    final hudPaint = Paint()..color = const Color(0xCC0D1B2A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 60), hudPaint);

    void drawText(String text, double x, double y, {Color color = Colors.white}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }

    drawText('Wave $_currentWave/5', 12, 12, color: const Color(0xFFFFD700));
    drawText('Level $_currentLevel/3', 12, 32, color: Colors.white70);
    drawText('Grace: $_grace', size.x / 2 - 40, 12, color: const Color(0xFF27AE60));
    drawText('Holy Pts: $_holyPoints', size.x / 2 - 40, 32, color: const Color(0xFF9B59B6));
    drawText('♥ $_lives', size.x - 70, 12, color: Colors.redAccent);
  }
}

// ── Flutter wrapper screen ────────────────────────────────────────────────────

class SaintDefenderGameScreen extends ConsumerStatefulWidget {
  const SaintDefenderGameScreen({super.key});

  @override
  ConsumerState<SaintDefenderGameScreen> createState() => _SaintDefenderGameScreenState();
}

class _SaintDefenderGameScreenState extends ConsumerState<SaintDefenderGameScreen> {
  late final SaintDefenderGame _game;
  bool _gameOver = false;
  int _finalHolyPoints = 0;
  int _wavesCompleted = 0;
  int _currentWaveDisplay = 1;
  SaintType _selectedSaint = SaintType.joan;

  static const _saintCosts = {
    SaintType.francis: 30,
    SaintType.dominic: 25,
    SaintType.joan: 20,
    SaintType.thomas: 35,
    SaintType.therese: 15,
  };

  @override
  void initState() {
    super.initState();
    _game = SaintDefenderGame(
      onGameOver: (hp, waves) {
        setState(() {
          _gameOver = true;
          _finalHolyPoints = hp;
          _wavesCompleted = waves;
        });
      },
      onWaveComplete: (wave) {
        setState(() => _currentWaveDisplay = wave + 1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
          GameWidget(game: _game),

          // ── Saint selector ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              color: const Color(0xCC0D1B2A),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                children: SaintType.values.map((saint) {
                  final isSelected = _selectedSaint == saint;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSaint = saint);
                      _game._selectedSaint = saint;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFD700).withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD700)
                              : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            switch (saint) {
                              SaintType.francis => '🕊️',
                              SaintType.dominic => '📿',
                              SaintType.joan => '⚔️',
                              SaintType.thomas => '📖',
                              SaintType.therese => '🌸',
                            },
                            style: const TextStyle(fontSize: 22),
                          ),
                          Text(
                            '${_saintCosts[saint]} Grace',
                            style: const TextStyle(
                              color: Color(0xFF27AE60),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Back button ───────────────────────────────────────────────────
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // ── Game over overlay ─────────────────────────────────────────────
          if (_gameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Game Over!',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontFamily: 'Cinzel',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Waves Survived: $_wavesCompleted / 15',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      'Holy Points Earned: $_finalHolyPoints',
                      style: const TextStyle(color: Color(0xFF9B59B6), fontSize: 18),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: const Color(0xFF1A0A2E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Back to Games',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
