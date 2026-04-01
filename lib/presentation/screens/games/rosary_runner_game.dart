import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Obstacle types ────────────────────────────────────────────────────────────

enum ObstacleType { phone, apple, cloud }

enum PowerUpType { maryGrace, bible, angel }

// ── Runner character ──────────────────────────────────────────────────────────

class RunnerComponent extends PositionComponent with HasGameRef<RosaryRunnerGame> {
  RunnerComponent() : super(size: Vector2(40, 52));

  double _velocityY = 0;
  bool _isOnGround = true;
  bool _isSliding = false;
  double _slideTimer = 0;
  bool _hasShield = false;
  bool _hasMagnet = false;
  bool _isFlying = false;
  double _powerUpTimer = 0;

  static const double _gravity = 800;
  static const double _jumpForce = -420;
  static const double _groundY = 0; // set in onMount

  final Paint _bodyPaint = Paint()..color = const Color(0xFF3498DB);
  final Paint _shieldPaint = Paint()
    ..color = const Color(0xFF9B59B6).withOpacity(0.4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  void jump() {
    if (_isOnGround && !_isSliding) {
      _velocityY = _jumpForce;
      _isOnGround = false;
    }
  }

  void slide() {
    if (_isOnGround && !_isSliding) {
      _isSliding = true;
      _slideTimer = 0.5;
    }
  }

  void activatePowerUp(PowerUpType type) {
    _powerUpTimer = 5.0;
    switch (type) {
      case PowerUpType.maryGrace:
        _hasShield = true;
      case PowerUpType.bible:
        _hasMagnet = true;
      case PowerUpType.angel:
        _isFlying = true;
    }
  }

  bool consumeShieldHit() {
    if (_hasShield) {
      _hasShield = false;
      return true; // absorbed
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Power-up timer
    if (_powerUpTimer > 0) {
      _powerUpTimer -= dt;
      if (_powerUpTimer <= 0) {
        _hasShield = false;
        _hasMagnet = false;
        _isFlying = false;
      }
    }

    // Slide
    if (_isSliding) {
      _slideTimer -= dt;
      if (_slideTimer <= 0) _isSliding = false;
    }

    // Gravity
    if (!_isOnGround && !_isFlying) {
      _velocityY += _gravity * dt;
    } else if (_isFlying) {
      _velocityY = -60; // gentle upward drift
    }

    position.y += _velocityY * dt;

    // Ground check
    final groundY = gameRef.groundY;
    if (position.y >= groundY) {
      position.y = groundY;
      _velocityY = 0;
      _isOnGround = true;
      _isFlying = false;
    }

    // Update hitbox size for sliding
    size = _isSliding ? Vector2(40, 26) : Vector2(40, 52);
  }

  @override
  void render(Canvas canvas) {
    // Body
    final bodyRect = _isSliding
        ? Rect.fromLTWH(0, size.y - 26, size.x, 26)
        : Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
      _bodyPaint,
    );

    // Character face
    const faceStyle = TextStyle(fontSize: 24);
    final emoji = _isFlying ? '😇' : _isSliding ? '🙏' : '🏃';
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: faceStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        (size.x - tp.width) / 2,
        _isSliding ? size.y - tp.height - 2 : (size.y - tp.height) / 2,
      ),
    );

    // Shield aura
    if (_hasShield) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x + 16,
          height: size.y + 16,
        ),
        _shieldPaint,
      );
    }

    // Magnet indicator
    if (_hasMagnet) {
      final magnetPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        80,
        magnetPaint,
      );
    }
  }
}

// ── Bead component ────────────────────────────────────────────────────────────

class BeadComponent extends PositionComponent with HasGameRef<RosaryRunnerGame> {
  BeadComponent({required Vector2 spawnPosition})
      : super(position: spawnPosition, size: Vector2(20, 20));

  final Paint _paint = Paint()..color = const Color(0xFF9B59B6);
  bool collected = false;

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= gameRef.scrollSpeed * dt;
    if (position.x < -30) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      10,
      _paint,
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      7,
      Paint()..color = const Color(0xFFD7BDE2),
    );
  }
}

// ── Obstacle component ────────────────────────────────────────────────────────

class ObstacleComponent extends PositionComponent with HasGameRef<RosaryRunnerGame> {
  ObstacleComponent({required this.obstacleType, required Vector2 spawnPos})
      : super(position: spawnPos, size: Vector2(44, 44));

  final ObstacleType obstacleType;

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= gameRef.scrollSpeed * dt;
    if (position.x < -50) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final emoji = switch (obstacleType) {
      ObstacleType.phone => '📱',
      ObstacleType.apple => '🍎',
      ObstacleType.cloud => '☁️',
    };
    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 32),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }
}

// ── Power-up component ────────────────────────────────────────────────────────

class PowerUpComponent extends PositionComponent with HasGameRef<RosaryRunnerGame> {
  PowerUpComponent({required this.powerType, required Vector2 spawnPos})
      : super(position: spawnPos, size: Vector2(40, 40));

  final PowerUpType powerType;
  bool collected = false;

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= gameRef.scrollSpeed * dt;
    if (position.x < -50) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final emoji = switch (powerType) {
      PowerUpType.maryGrace => '💙',
      PowerUpType.bible => '📖',
      PowerUpType.angel => '👼',
    };
    // Glowing background
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      22,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 26)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }
}

// ── Main Flame game ───────────────────────────────────────────────────────────

class RosaryRunnerGame extends FlameGame with TapCallbacks, HorizontalDragCallbacks {
  RosaryRunnerGame({
    required this.onGameOver,
    required this.onRosaryComplete,
    required this.onBeadCollected,
  });

  final void Function(int beads, int grace) onGameOver;
  final void Function() onRosaryComplete;
  final void Function(int totalBeads) onBeadCollected;

  late final RunnerComponent _runner;
  final math.Random _rng = math.Random();

  // Scroll
  double scrollSpeed = 180;

  // Path geometry
  double get groundY => size.y - 100;

  // Bead tracking
  int _beadsCollected = 0;
  static const int _beadsPerRosary = 50;

  // Timers
  double _beadSpawnTimer = 0;
  double _obstacleSpawnTimer = 0;
  double _powerUpSpawnTimer = 0;
  double _difficultyTimer = 0;

  bool _isGameOver = false;

  @override
  Color backgroundColor() => const Color(0xFF0D1B2A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _runner = RunnerComponent()
      ..position = Vector2(80, groundY);
    add(_runner);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;

    // Increase difficulty over time
    _difficultyTimer += dt;
    scrollSpeed = 180 + _difficultyTimer * 4;

    // Spawn beads
    _beadSpawnTimer += dt;
    if (_beadSpawnTimer > 0.6) {
      _beadSpawnTimer = 0;
      _spawnBead();
    }

    // Spawn obstacles
    _obstacleSpawnTimer += dt;
    if (_obstacleSpawnTimer > 1.8 - _difficultyTimer * 0.02) {
      _obstacleSpawnTimer = 0;
      _spawnObstacle();
    }

    // Spawn power-ups
    _powerUpSpawnTimer += dt;
    if (_powerUpSpawnTimer > 8.0) {
      _powerUpSpawnTimer = 0;
      _spawnPowerUp();
    }

    // Collision detection
    _checkCollisions();

    // Magnet: pull nearby beads
    if (_runner._hasMagnet) {
      for (final bead in children.whereType<BeadComponent>()) {
        final diff = _runner.position + _runner.size / 2 -
            (bead.position + bead.size / 2);
        if (diff.length < 90) {
          bead.position += diff.normalized() * 200 * dt;
        }
      }
    }
  }

  void _spawnBead() {
    final groundOffset = _rng.nextBool() ? 0.0 : -80.0;
    add(BeadComponent(
      spawnPosition: Vector2(
        size.x + 10,
        groundY + groundOffset,
      ),
    ));
  }

  void _spawnObstacle() {
    final type = ObstacleType.values[_rng.nextInt(ObstacleType.values.length)];
    final isHigh = type == ObstacleType.cloud;
    add(ObstacleComponent(
      obstacleType: type,
      spawnPos: Vector2(
        size.x + 10,
        isHigh ? groundY - 80 : groundY,
      ),
    ));
  }

  void _spawnPowerUp() {
    final type = PowerUpType.values[_rng.nextInt(PowerUpType.values.length)];
    add(PowerUpComponent(
      powerType: type,
      spawnPos: Vector2(size.x + 10, groundY - 60),
    ));
  }

  void _checkCollisions() {
    final runnerRect = Rect.fromLTWH(
      _runner.position.x + 4,
      _runner.position.y + 4,
      _runner.size.x - 8,
      _runner.size.y - 8,
    );

    // Collect beads
    for (final bead in children.whereType<BeadComponent>().toList()) {
      if (bead.collected) continue;
      final beadRect = Rect.fromLTWH(
        bead.position.x, bead.position.y, bead.size.x, bead.size.y,
      );
      if (runnerRect.overlaps(beadRect)) {
        bead.collected = true;
        bead.removeFromParent();
        _beadsCollected++;
        onBeadCollected(_beadsCollected);
        if (_beadsCollected >= _beadsPerRosary) {
          onRosaryComplete();
          _beadsCollected = 0;
        }
      }
    }

    // Hit obstacles
    for (final obs in children.whereType<ObstacleComponent>().toList()) {
      final obsRect = Rect.fromLTWH(
        obs.position.x + 6, obs.position.y + 6,
        obs.size.x - 12, obs.size.y - 12,
      );
      if (runnerRect.overlaps(obsRect)) {
        final absorbed = _runner.consumeShieldHit();
        obs.removeFromParent();
        if (!absorbed) {
          _triggerGameOver();
          return;
        }
      }
    }

    // Collect power-ups
    for (final pu in children.whereType<PowerUpComponent>().toList()) {
      if (pu.collected) continue;
      final puRect = Rect.fromLTWH(
        pu.position.x, pu.position.y, pu.size.x, pu.size.y,
      );
      if (runnerRect.overlaps(puRect)) {
        pu.collected = true;
        _runner.activatePowerUp(pu.powerType);
        pu.removeFromParent();
      }
    }
  }

  void _triggerGameOver() {
    _isGameOver = true;
    final graceEarned = (_beadsCollected ~/ 10) * 5;
    onGameOver(_beadsCollected, graceEarned);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isGameOver) return;
    if (event.canvasPosition.y > size.y / 2) {
      _runner.slide();
    } else {
      _runner.jump();
    }
  }

  @override
  void onHorizontalDragStart(HorizontalDragStartEvent event) {}

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderGround(canvas);
    _renderHud(canvas);
  }

  void _renderGround(Canvas canvas) {
    final groundPaint = Paint()..color = const Color(0xFF1A3A2A);
    canvas.drawRect(
      Rect.fromLTWH(0, groundY + 50, size.x, 50),
      groundPaint,
    );

    // Rosary path dots
    final dotPaint = Paint()..color = const Color(0xFF9B59B6).withOpacity(0.3);
    for (double x = 0; x < size.x; x += 30) {
      canvas.drawCircle(Offset(x, groundY + 60), 4, dotPaint);
    }
  }

  void _renderHud(Canvas canvas) {
    final hudPaint = Paint()..color = const Color(0xCC0D1B2A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 56), hudPaint);

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

    // Bead progress
    final decades = _beadsCollected ~/ 10;
    final beadsInDecade = _beadsCollected % 10;
    drawText('📿 Decade $_decades/5', 12, 10, color: const Color(0xFF9B59B6));
    drawText('Beads: $beadsInDecade/10', 12, 30, color: Colors.white70);

    // Speed
    drawText('🏃 ${scrollSpeed.toInt()} px/s', size.x / 2 - 40, 10, color: Colors.white70);

    // Power-up status
    final activeStr = _runner._hasShield
        ? '💙 Shield'
        : _runner._hasMagnet
            ? '📖 Magnet'
            : _runner._isFlying
                ? '👼 Flying'
                : '';
    if (activeStr.isNotEmpty) {
      drawText(activeStr, size.x - 110, 10, color: const Color(0xFFFFD700));
      drawText(
        '${_runner._powerUpTimer.toStringAsFixed(1)}s',
        size.x - 110,
        30,
        color: Colors.white54,
      );
    }
  }
}

// ── Flutter wrapper screen ────────────────────────────────────────────────────

class RosaryRunnerGameScreen extends ConsumerStatefulWidget {
  const RosaryRunnerGameScreen({super.key});

  @override
  ConsumerState<RosaryRunnerGameScreen> createState() =>
      _RosaryRunnerGameScreenState();
}

class _RosaryRunnerGameScreenState extends ConsumerState<RosaryRunnerGameScreen> {
  late final RosaryRunnerGame _game;
  bool _gameOver = false;
  bool _rosaryComplete = false;
  int _beadsCollected = 0;
  int _graceEarned = 0;

  @override
  void initState() {
    super.initState();
    _game = RosaryRunnerGame(
      onGameOver: (beads, grace) {
        setState(() {
          _gameOver = true;
          _beadsCollected = beads;
          _graceEarned = grace;
        });
      },
      onRosaryComplete: () {
        setState(() => _rosaryComplete = true);
      },
      onBeadCollected: (total) {
        setState(() => _beadsCollected = total);
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

          // Instructions
          if (!_gameOver && !_rosaryComplete)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap top half to JUMP • Tap bottom half to SLIDE',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ),
            ),

          // Back
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

          // Rosary complete banner
          if (_rosaryComplete && !_gameOver)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '🌟 Full Rosary Complete! +Grace Earned! 🌟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1A0A2E),
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Game over
          if (_gameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _beadsCollected >= 50
                          ? 'Rosary Complete!'
                          : 'Game Over!',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontFamily: 'Cinzel',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Beads Collected: $_beadsCollected / 50',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      'Decades: ${_beadsCollected ~/ 10} / 5',
                      style: const TextStyle(color: Color(0xFF9B59B6), fontSize: 16),
                    ),
                    Text(
                      'Grace Earned: $_graceEarned',
                      style: const TextStyle(color: Color(0xFF27AE60), fontSize: 18),
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
