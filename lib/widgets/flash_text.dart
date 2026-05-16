import 'package:flutter/material.dart';

enum FlashTextStyle {
  typewriter,
  fadeIn,
  slideUp,
  slideLeft,
  bounce,
  scale,
  glitch,
  wave,
}

class FlashText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final FlashTextStyle flashStyle;
  final Duration duration;
  final Duration delay;
  final bool autoPlay;
  final VoidCallback? onComplete;

  const FlashText({
    super.key,
    required this.text,
    this.style,
    this.flashStyle = FlashTextStyle.fadeIn,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.autoPlay = true,
    this.onComplete,
  });

  @override
  State<FlashText> createState() => _FlashTextState();
}

class _FlashTextState extends State<FlashText> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _displayedText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoPlay) {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.flashStyle == FlashTextStyle.typewriter) {
      _startTypewriter();
    } else {
      _controller.forward();
    }
  }

  void _startTypewriter() {
    if (!mounted) return;

    if (_currentIndex < widget.text.length) {
      setState(() {
        _displayedText = widget.text.substring(0, _currentIndex + 1);
        _currentIndex++;
      });

      Future.delayed(
        Duration(milliseconds: widget.duration.inMilliseconds ~/ widget.text.length),
        _startTypewriter,
      );
    } else {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.flashStyle) {
      case FlashTextStyle.typewriter:
        return _buildTypewriter();
      case FlashTextStyle.fadeIn:
        return _buildFadeIn();
      case FlashTextStyle.slideUp:
        return _buildSlideUp();
      case FlashTextStyle.slideLeft:
        return _buildSlideLeft();
      case FlashTextStyle.bounce:
        return _buildBounce();
      case FlashTextStyle.scale:
        return _buildScale();
      case FlashTextStyle.glitch:
        return _buildGlitch();
      case FlashTextStyle.wave:
        return _buildWave();
    }
  }

  Widget _buildTypewriter() {
    return Text(
      _displayedText,
      style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFadeIn() {
    return FadeTransition(
      opacity: _animation,
      child: Text(
        widget.text,
        style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSlideUp() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Text(
        widget.text,
        style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSlideLeft() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(50 * (1 - _animation.value), 0),
            child: child,
          ),
        );
      },
      child: Text(
        widget.text,
        style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBounce() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double scale = 0.0;
        if (_animation.value < 0.5) {
          scale = _animation.value * 2;
        } else {
          scale = 1.0 + (1 - _animation.value) * 0.2;
        }
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Text(
        widget.text,
        style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildScale() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Text(
        widget.text,
        style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGlitch() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double offset = (_animation.value * 10 - 5) * (1 - _animation.value);
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(offset, 0),
              child: Opacity(
                opacity: 0.8 * (1 - _animation.value),
                child: Text(
                  widget.text,
                  style: (widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                      .copyWith(color: Colors.red),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-offset, 0),
              child: Opacity(
                opacity: 0.8 * (1 - _animation.value),
                child: Text(
                  widget.text,
                  style: (widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                      .copyWith(color: Colors.blue),
                ),
              ),
            ),
            Opacity(
              opacity: _animation.value,
              child: child,
            ),
          ],
        );
      },
      child: Text(
        widget.text,
        style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWave() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.text.length, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index / widget.text.length;
            final double progress = ((_animation.value - delay) / (1 - delay)).clamp(0.0, 1.0);
            final double offset = (1 - progress) * 20;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Opacity(
                opacity: progress,
                child: child,
              ),
            );
          },
          child: Text(
            widget.text[index],
            style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }
}

class FlashTextSequence extends StatefulWidget {
  final List<String> texts;
  final List<TextStyle>? styles;
  final List<FlashTextStyle>? animations;
  final Duration interval;
  final bool repeat;
  final VoidCallback? onComplete;

  const FlashTextSequence({
    super.key,
    required this.texts,
    this.styles,
    this.animations,
    this.interval = const Duration(milliseconds: 200),
    this.repeat = false,
    this.onComplete,
  });

  @override
  State<FlashTextSequence> createState() => _FlashTextSequenceState();
}

class _FlashTextSequenceState extends State<FlashTextSequence> {
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    if (widget.texts.isNotEmpty) {
      _startSequence();
    }
  }

  void _startSequence() {
    if (_currentIndex < widget.texts.length) {
      setState(() {
        _isAnimating = true;
      });
    } else if (widget.repeat) {
      setState(() {
        _currentIndex = 0;
      });
      Future.delayed(widget.interval, _startSequence);
    } else {
      widget.onComplete?.call();
    }
  }

  void _onTextComplete() {
    Future.delayed(widget.interval, () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _isAnimating = false;
        });
        _startSequence();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.texts.length) {
      return const SizedBox.shrink();
    }

    return FlashText(
      key: ValueKey(_currentIndex),
      text: widget.texts[_currentIndex],
      style: widget.styles?[_currentIndex],
      flashStyle: widget.animations?[_currentIndex] ?? FlashTextStyle.fadeIn,
      autoPlay: true,
      onComplete: _onTextComplete,
    );
  }
}

class AnimatedLogoText extends StatefulWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color primaryColor;
  final Color secondaryColor;

  const AnimatedLogoText({
    super.key,
    required this.text,
    this.baseStyle,
    this.primaryColor = const Color(0xFF4C6FFF),
    this.secondaryColor = const Color(0xFF3557E5),
  });

  @override
  State<AnimatedLogoText> createState() => _AnimatedLogoTextState();
}

class _AnimatedLogoTextState extends State<AnimatedLogoText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.text.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      );
    }).toList();

    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.text.length, (index) {
        final bool isEven = index % 2 == 0;
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _animations[index].value,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: isEven
                        ? [widget.primaryColor, widget.secondaryColor]
                        : [widget.secondaryColor, widget.primaryColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds);
                },
                child: Text(
                  widget.text[index],
                  style: widget.baseStyle ??
                      const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class PulseText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const PulseText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseText> createState() => _PulseTextState();
}

class _PulseTextState extends State<PulseText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Text(
        widget.text,
        style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class RotatingText extends StatefulWidget {
  final List<String> texts;
  final TextStyle? style;
  final Duration duration;
  final Duration pauseDuration;

  const RotatingText({
    super.key,
    required this.texts,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<RotatingText> createState() => _RotatingTextState();
}

class _RotatingTextState extends State<RotatingText>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _startRotation();
  }

  void _startRotation() async {
    if (!mounted) return;

    _fadeController.forward();

    await Future.delayed(widget.pauseDuration);

    if (!mounted) return;

    _fadeController.reverse();

    await Future.delayed(widget.duration);

    if (!mounted) return;

    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.texts.length;
    });

    _startRotation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        widget.texts[_currentIndex],
        style: widget.style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class TypingCursor extends StatefulWidget {
  final Widget child;
  final Color cursorColor;
  final double cursorWidth;
  final Duration blinkDuration;

  const TypingCursor({
    super.key,
    required this.child,
    this.cursorColor = const Color(0xFF4C6FFF),
    this.cursorWidth = 2.0,
    this.blinkDuration = const Duration(milliseconds: 500),
  });

  @override
  State<TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<TypingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.blinkDuration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.child,
        FadeTransition(
          opacity: _animation,
          child: Container(
            width: widget.cursorWidth,
            height: (widget.child as Text?)?.style?.fontSize ?? 24,
            margin: const EdgeInsets.only(left: 2),
            color: widget.cursorColor,
          ),
        ),
      ],
    );
  }
}
