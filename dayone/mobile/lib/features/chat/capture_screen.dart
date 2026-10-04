import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../shared/dayone_widgets.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, this.title = 'Photographier une page'});

  final String title;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  String? _path;
  String _phase = 'aim';
  final Map<String, String> _checks = {};
  final List<Timer> _timers = [];

  static const _steps = [
    ('light', 'Lumière', Icons.wb_sunny_outlined),
    ('frame', 'Cadrage', Icons.crop_rounded),
    ('sharp', 'Netteté', Icons.center_focus_strong_outlined),
  ];

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 2000);
      if (picked == null || !mounted) return;
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'pages'));
      await folder.create(recursive: true);
      final dest = p.join(folder.path, '${const Uuid().v4()}.jpg');
      await File(picked.path).copy(dest);
      if (!mounted) return;
      setState(() {
        _path = dest;
        _phase = 'aim';
        _checks.clear();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ouvrir l’image. $error')),
      );
    }
  }

  void _shoot() {
    setState(() {
      _phase = 'checking';
      _checks.clear();
    });
    for (var i = 0; i < _steps.length; i++) {
      _timers.add(Timer(Duration(milliseconds: 350 + i * 380), () {
        if (!mounted) return;
        setState(() => _checks[_steps[i].$1] = 'ok');
      }));
    }
    _timers.add(Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _phase = 'ok');
    }));
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    return Scaffold(
      backgroundColor: DayOneColors.bg,
      appBar: AppBar(
        backgroundColor: DayOneColors.bg,
        elevation: 0,
        foregroundColor: DayOneColors.primaryDark,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: DayOneColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            height: 360,
            decoration: BoxDecoration(color: const Color(0xFF1F0E18), borderRadius: BorderRadius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: path == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'Placez toute la page dans le cadre, à la lumière, sans flash.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.4),
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(path), fit: BoxFit.cover),
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(999)),
                            child: Text(
                              _phase == 'ok'
                                  ? 'Photo acceptée'
                                  : _phase == 'checking'
                                      ? 'Contrôle de la qualité…'
                                      : 'Vérifiez la page',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final step in _steps) ...[
                Expanded(child: _CheckTile(label: step.$2, icon: step.$3, status: _checks[step.$1])),
                if (step != _steps.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (path == null) ...[
            DayOneButton(label: 'Prendre la photo', icon: Icons.photo_camera_rounded, onPressed: () => _pick(ImageSource.camera)),
            const SizedBox(height: 10),
            DayOneButton(
              label: 'Choisir une image',
              icon: Icons.photo_library_outlined,
              variant: DayOneButtonVariant.ghost,
              onPressed: () => _pick(ImageSource.gallery),
            ),
          ] else if (_phase == 'aim') ...[
            DayOneButton(label: 'Contrôler la photo', icon: Icons.center_focus_strong_rounded, onPressed: _shoot),
            const SizedBox(height: 10),
            DayOneButton(
              label: 'Reprendre la photo',
              icon: Icons.refresh_rounded,
              variant: DayOneButtonVariant.ghost,
              onPressed: () => setState(() {
                _path = null;
                _checks.clear();
              }),
            ),
          ] else if (_phase == 'checking')
            const DayOneButton(label: 'Contrôle de la qualité…', busy: true, onPressed: null)
          else ...[
            DayOneButton(
              label: 'Envoyer à DayOne',
              icon: Icons.send_rounded,
              onPressed: () => Navigator.of(context).pop(path),
            ),
            const SizedBox(height: 10),
            DayOneButton(
              label: 'Reprendre la photo',
              icon: Icons.photo_camera_rounded,
              variant: DayOneButtonVariant.ghost,
              onPressed: () => setState(() {
                _path = null;
                _phase = 'aim';
                _checks.clear();
              }),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'La photo d’origine reste sur le téléphone. Vous pourrez encore la confirmer, la reprendre ou annuler le registre dans la discussion.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DayOneColors.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.label, required this.icon, required this.status});

  final String label;
  final IconData icon;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final ok = status == 'ok';
    final color = ok ? DayOneColors.success : DayOneColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: ok ? DayOneColors.successSoft : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: DayOneColors.shadow,
      ),
      child: Column(
        children: [
          Icon(ok ? Icons.check_circle_rounded : icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}
