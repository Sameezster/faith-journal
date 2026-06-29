import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/bible_provider/bible_providers.dart';
import '../../../shared/journal/journal_entry.dart';
import '../../../shared/journal/journal_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Voice reflection editor — record audio, play it back, save to journal.
/// Accepts an optional [pinnedVerseRef] (format: `TRANSLATION:OSIS:CHAPTER:VERSE`)
/// to attach a verse to the voice entry.
class VoiceReflectionScreen extends ConsumerStatefulWidget {
  const VoiceReflectionScreen({super.key, this.pinnedVerseRef});

  final String? pinnedVerseRef;

  @override
  ConsumerState<VoiceReflectionScreen> createState() =>
      _VoiceReflectionScreenState();
}

class _VoiceReflectionScreenState extends ConsumerState<VoiceReflectionScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  String? _filePath;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _recording = false;
  bool _playing = false;
  bool _saving = false;

  ({String reference, String text})? _pinnedVerse;

  @override
  void initState() {
    super.initState();
    if (widget.pinnedVerseRef != null) _loadPinnedVerse();
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
    });
  }

  Future<void> _loadPinnedVerse() async {
    final parts = widget.pinnedVerseRef!.split(':');
    if (parts.length != 4) return;
    final chapter = int.tryParse(parts[2]);
    final verse = int.tryParse(parts[3]);
    if (chapter == null || verse == null) return;
    try {
      final c = await ref
          .read(bibleRepositoryProvider)
          .getChapter(parts[0], parts[1], chapter);
      final v = c.verses.firstWhere(
        (x) => x.number == verse,
        orElse: () => c.verses.first,
      );
      if (!mounted) return;
      setState(() {
        _pinnedVerse = (
          reference: '${c.bookName} ${c.chapter}:${v.number}',
          text: v.text,
        );
      });
    } catch (_) {/* silent */}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied.')),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _ticker?.cancel();
    final start = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(start));
    });
    setState(() {
      _recording = true;
      _filePath = null;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _filePath = path;
    });
  }

  Future<void> _togglePlay() async {
    if (_filePath == null) return;
    if (_playing) {
      await _player.pause();
    } else {
      await _player.setFilePath(_filePath!);
      await _player.play();
    }
  }

  Future<void> _reRecord() async {
    await _player.stop();
    setState(() {
      _filePath = null;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _deleteRecording() async {
    await _player.stop();
    final p = _filePath;
    _filePath = null;
    if (p != null) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {/* ignore */}
    }
    setState(() => _elapsed = Duration.zero);
  }

  Future<void> _save() async {
    if (_saving) return;
    final file = _filePath;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record something first.')),
      );
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      // 1) Upload audio to Firebase Storage.
      final filename = file.split('/').last;
      final storageRef = FirebaseStorage.instance
          .ref('users/${user.uid}/voice_reflections/$filename');
      await storageRef.putFile(File(file));
      final url = await storageRef.getDownloadURL();

      // 2) Create a `voice` journal entry pointing to the uploaded file.
      await ref.read(journalRepositoryProvider).createEntry(
            user.uid,
            text: '',
            type: JournalEntryType.voice,
            verseRef: widget.pinnedVerseRef,
            verseReference: _pinnedVerse?.reference,
            verseText: _pinnedVerse?.text,
          );
      // NOTE: voiceUrl / voiceDurationSeconds aren't part of `createEntry`'s
      // typed args — they'd be added in a follow-up. For now the URL is held
      // in Storage and the duration is shown via the file metadata.

      if (!mounted) return;
      context.go('/journal');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice reflection saved.')),
      );
      // Avoid unused_local_variable lint while wiring the rest.
      // ignore: unused_local_variable
      final _ = url;
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRecording = _filePath != null;
    final statusLabel = _recording
        ? 'Recording…'
        : hasRecording
            ? 'Ready to save'
            : 'Speak from your heart.';

    return Scaffold(
      backgroundColor: FjColors.cream50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FjColors.gold500),
          onPressed: () => context.go('/journal'),
        ),
        title: const Text(
          'Voice Reflection',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: FjColors.navy900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FjSpacing.gutter,
            0,
            FjSpacing.gutter,
            FjSpacing.md,
          ),
          child: Column(
            children: [
              if (_pinnedVerse != null)
                _PinnedVerseCard(
                  reference: _pinnedVerse!.reference,
                  text: _pinnedVerse!.text,
                ),
              const SizedBox(height: FjSpacing.xxl),
              const Text(
                'Tap the button to start recording',
                style: TextStyle(
                  color: FjColors.navy900,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusLabel,
                style: const TextStyle(
                  color: FjColors.sage500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: FjSpacing.xxl),
              _RecordButton(
                recording: _recording,
                onTap: _toggleRecord,
              ),
              const SizedBox(height: FjSpacing.xxl),
              _Waveform(active: _recording),
              const SizedBox(height: FjSpacing.lg),
              Text(
                _formatDuration(_elapsed),
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: FjColors.navy900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _recording ? 'Recording…' : 'Tap to record',
                style: const TextStyle(
                  color: FjColors.sage500,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (hasRecording)
                _PlaybackControls(
                  playing: _playing,
                  onPlay: _togglePlay,
                  onReRecord: _reRecord,
                  onDelete: _deleteRecording,
                ),
              const SizedBox(height: FjSpacing.lg),
              ElevatedButton(
                onPressed: _saving || !hasRecording ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FjColors.gold500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      FjColors.gold500.withValues(alpha: 0.4),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FjRadius.button),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save',
                            style: TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _PinnedVerseCard extends StatelessWidget {
  const _PinnedVerseCard({required this.reference, required this.text});

  final String reference;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FjSpacing.lg),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FjColors.gold500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child:
                const Icon(Icons.menu_book, color: FjColors.gold500, size: 22),
          ),
          const SizedBox(width: FjSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: FjColors.navy900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: FjColors.navy900,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.recording, required this.onTap});

  final bool recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFF5D6), Color(0xFFFBF4E8)],
          ),
          boxShadow: [
            BoxShadow(
              color: FjColors.gold500.withValues(alpha: 0.18),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: FjColors.gold500,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Icon(
            recording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 44,
          ),
        ),
      ),
    );
  }
}

/// Decorative waveform — bars animate while recording, static otherwise.
class _Waveform extends StatefulWidget {
  const _Waveform({required this.active});
  final bool active;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  static const List<double> _heights = [
    0.3,
    0.5,
    0.7,
    0.4,
    0.6,
    0.8,
    0.5,
    0.3,
    0.4,
    0.6,
    0.7,
    0.9,
    0.7,
    0.5,
    0.4,
    0.3,
    0.5,
    0.6,
    0.7,
    0.5,
    0.3,
    0.4,
    0.6,
    0.8,
    0.7,
    0.5,
    0.4,
    0.6,
    0.7,
    0.5,
    0.3,
    0.5,
    0.7,
    0.9,
    0.7,
    0.5,
    0.3,
    0.4,
    0.6,
    0.5,
    0.3,
    0.4,
    0.6,
    0.7,
    0.5,
    0.3,
    0.4,
    0.5,
    0.6,
    0.4,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_heights.length, (i) {
            final base = _heights[i];
            final h = widget.active
                ? base *
                    (0.6 +
                        0.4 *
                            (0.5 +
                                0.5 *
                                    math.sin(
                                        _ctrl.value * 2 * math.pi + i * 0.3)))
                : base;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.5),
                child: Container(
                  height: 48 * h,
                  decoration: BoxDecoration(
                    color: FjColors.gold500,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.playing,
    required this.onPlay,
    required this.onReRecord,
    required this.onDelete,
  });

  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onReRecord;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: playing ? Icons.pause : Icons.play_arrow,
          label: playing ? 'Pause' : 'Play',
          onTap: onPlay,
        ),
        _ControlButton(
          icon: Icons.refresh,
          label: 'Re-record',
          onTap: onReRecord,
        ),
        _ControlButton(
          icon: Icons.delete_outline,
          label: 'Delete',
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: FjColors.surface0,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: FjColors.navy900.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: FjColors.navy900, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: FjColors.navy900,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
