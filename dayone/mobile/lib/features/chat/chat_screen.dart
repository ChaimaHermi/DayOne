import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import 'chat_controller.dart';
import 'chat_models.dart';
import 'chat_store.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatController? _chat;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<List<ConnectivityResult>>? _network;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final session = AuthScope.of(context).session;
    if (session == null) return;
    final chat = ChatController(
      midwifeId: session.id,
      firstName: session.firstName,
      store: SqliteChatStore(),
    );
    _chat = chat;
    chat.addListener(_follow);
    chat.init();
    _network = Connectivity().onConnectivityChanged.listen((results) {
      chat.setRealOnline(_isOnline(results));
    });
    Connectivity().checkConnectivity().then((results) {
      if (mounted) chat.setRealOnline(_isOnline(results));
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  void _follow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _network?.cancel();
    _chat?.removeListener(_follow);
    _chat?.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  final _picker = ImagePicker();

  Future<List<String>> _copyImages(List<XFile> files) async {
    if (files.isEmpty) return [];
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'pages'));
    await folder.create(recursive: true);
    final paths = <String>[];
    for (final file in files) {
      final dest = p.join(folder.path, '${const Uuid().v4()}.jpg');
      await File(file.path).copy(dest);
      paths.add(dest);
    }
    return paths;
  }

  Future<void> _addFromGallery() async {
    final chat = _chat;
    if (chat == null) return;
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 2000);
      final paths = await _copyImages(files);
      if (paths.isNotEmpty) chat.addDrafts(paths);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible d’ouvrir les images. $error')));
    }
  }

  Future<void> _addFromCamera() async {
    final chat = _chat;
    if (chat == null) return;
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
      if (file == null) return;
      final paths = await _copyImages([file]);
      if (paths.isNotEmpty) chat.addDrafts(paths);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible d’ouvrir l’appareil photo. $error')));
    }
  }

  Future<void> _retakeAll() async {
    final chat = _chat;
    if (chat == null || chat.drafts.isEmpty) return;
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
      if (file == null) return;
      final paths = await _copyImages([file]);
      if (paths.isEmpty) return;
      chat.cancelAll();
      chat.addDrafts(paths);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de reprendre la photo. $error')));
    }
  }

  void _showAttachSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DayOneColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 42, height: 5, decoration: BoxDecoration(color: DayOneColors.border, borderRadius: BorderRadius.circular(99))),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Ajouter des pages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DayOneColors.text)),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: DayOneColors.primary),
                  title: const Text('Galerie', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Plusieurs images à la fois'),
                  onTap: () {
                    Navigator.pop(context);
                    _addFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: DayOneColors.primary),
                  title: const Text('Appareil photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Une photo, puis vous pouvez en ajouter d’autres'),
                  onTap: () {
                    Navigator.pop(context);
                    _addFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.layers_outlined, color: DayOneColors.primary),
                  title: const Text('File d’attente', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(context);
                    _showQueue();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onAction(ChatMessage message, ChatAction action) async {
    final chat = _chat;
    if (chat == null) return;
    switch (action.id) {
      case 'takePhoto':
        await _addFromCamera();
        break;
      case 'retake':
        final docId = message.docId;
        if (docId == null) return;
        final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
        if (file == null) return;
        final paths = await _copyImages([file]);
        if (paths.isNotEmpty) await chat.replacePhoto(docId, paths.first);
        break;
      case 'openQueue':
        _showQueue();
        break;
      default:
        await chat.act(message.id, action.id);
    }
  }

  Future<void> _logout() async {
    await AuthScope.of(context).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _showQueue() {
    final chat = _chat;
    if (chat == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DayOneColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return ListenableBuilder(
          listenable: chat,
          builder: (context, _) {
            final docs = [...chat.docs]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(color: DayOneColors.border, borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('File d’attente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DayOneColors.text)),
                    const SizedBox(height: 4),
                    Text(
                      chat.online ? 'En ligne : traitement puis synchronisation.' : 'Hors ligne : les pages restent sur le téléphone.',
                      style: const TextStyle(color: DayOneColors.muted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    if (docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Aucune page pour le moment.', style: TextStyle(color: DayOneColors.muted))),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: docs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: const Color(0xFFFBF4F7), borderRadius: BorderRadius.circular(18)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(doc.code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                                        const SizedBox(height: 4),
                                        Text(
                                          doc.failureNote.isEmpty ? 'Page capturée' : doc.failureNote,
                                          style: const TextStyle(color: DayOneColors.muted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatePill(state: doc.state),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    if (chat == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: DayOneColors.chatBg,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  online: chat.online,
                  pending: chat.pendingCount,
                  onToggle: chat.reallyOnline || chat.simulateOffline ? () => chat.toggleNetwork() : null,
                  onQueue: _showQueue,
                  onLogout: _logout,
                ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    children: [
                      const _Notice(),
                      const SizedBox(height: 12),
                      for (final message in chat.messages) ...[
                        _MessageTile(message: message, chat: chat, onAction: _onAction),
                        const SizedBox(height: 10),
                      ],
                      if (chat.typing) const _Typing(),
                    ],
                  ),
                ),
                _Composer(
                  controller: _input,
                  drafts: chat.drafts,
                  onRemove: chat.removeDraft,
                  onConfirm: chat.confirmAll,
                  onCancel: chat.cancelAll,
                  onRetake: _retakeAll,
                  onSend: () {
                    final text = _input.text;
                    _input.clear();
                    chat.sendText(text);
                  },
                  onCamera: _addFromCamera,
                  onAttach: _showAttachSheet,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.online,
    required this.pending,
    required this.onToggle,
    required this.onQueue,
    required this.onLogout,
  });

  final bool online;
  final int pending;
  final VoidCallback? onToggle;
  final VoidCallback onQueue;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: const BoxDecoration(gradient: DayOneColors.gradient),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.local_florist_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DayOne', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  online ? 'en ligne' : 'hors ligne : tout reste sur le téléphone',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 11.5),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Icon(online ? Icons.wifi_rounded : Icons.wifi_off_rounded, color: Colors.white, size: 15),
                    const SizedBox(width: 4),
                    Text(online ? 'En ligne' : 'Hors ligne', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onQueue,
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.layers_rounded, color: Colors.white),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') onLogout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Se déconnecter')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFFFF6D9), borderRadius: BorderRadius.circular(14)),
      child: const Text(
        'Photos et lectures restent sur ce téléphone tant que vous n’avez pas confirmé, puis synchronisées au retour du réseau.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF7A5B12), fontSize: 11.5, height: 1.35),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, required this.chat, required this.onAction});

  final ChatMessage message;
  final ChatController chat;
  final Future<void> Function(ChatMessage message, ChatAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final doc = chat.docById(message.docId);
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.84),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: message.mine ? DayOneColors.bubbleMine : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(message.mine ? 18 : 4),
          bottomRight: Radius.circular(message.mine ? 4 : 18),
        ),
        boxShadow: const [BoxShadow(color: Color(0x1A3C0A1E), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.type == 'image' && message.imagePath != null) _Photo(path: message.imagePath!),
          if (message.type == 'extraction')
            _Extraction(message: message, doc: doc)
          else
            Text(message.text, style: const TextStyle(color: DayOneColors.text, fontSize: 14.5, height: 1.35)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _time(message.at),
              style: const TextStyle(color: DayOneColors.muted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: message.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        if (!message.mine && message.actions.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final action in message.actions) ...[
            _ActionButton(action: action, message: message, onAction: onAction),
            const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }

  String _time(DateTime at) {
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _Extraction extends StatelessWidget {
  const _Extraction({required this.message, required this.doc});

  final ChatMessage message;
  final RegisterDoc? doc;

  @override
  Widget build(BuildContext context) {
    if (doc == null) {
      return const Text('Ce registre a été annulé.', style: TextStyle(color: DayOneColors.muted));
    }
    final doubts = doc!.fields.where((field) => field.doubtful).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registre ${doc!.code}', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6, color: DayOneColors.primaryDark)),
        const SizedBox(height: 6),
        Text(message.text, style: const TextStyle(color: DayOneColors.text, fontSize: 13.5, height: 1.35)),
        const SizedBox(height: 8),
        for (final field in doc!.fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    field.label,
                    style: const TextStyle(color: DayOneColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  field.value.isEmpty ? _statusLabel(field.status) : '${field.value}${field.unit.isEmpty ? '' : ' ${field.unit}'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: field.doubtful ? DayOneColors.warning : DayOneColors.text,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (doubts.isNotEmpty)
          const Text(
            'Photo déjà confirmée. Ces champs restent signalés.',
            style: TextStyle(color: DayOneColors.warning, fontWeight: FontWeight.w700, fontSize: 12),
          ),
      ],
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'ILLISIBLE' => 'Illisible',
    'INCONNU' => 'Inconnu',
    'NON_FOURNI' => 'Non fourni',
    'NON_APPLICABLE' => 'Non applicable',
    _ => status,
  };
}

class _Photo extends StatelessWidget {
  const _Photo({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: file.existsSync()
          ? Image.file(file, height: 180, width: 150, fit: BoxFit.cover)
          : Container(
              height: 140,
              width: 150,
              color: DayOneColors.primarySoft,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined, color: DayOneColors.primary),
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.message, required this.onAction});

  final ChatAction action;
  final ChatMessage message;
  final Future<void> Function(ChatMessage message, ChatAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final chosen = message.answered == action.id;
    final locked = message.answered != null && !chosen;
    final background = chosen ? DayOneColors.primary : Colors.white;
    final foreground = chosen ? Colors.white : (locked ? const Color(0xFFCDB7C2) : DayOneColors.primary);
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.78,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: locked ? null : () => onAction(message, action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: action.primary && message.answered == null ? DayOneColors.primary : Colors.transparent, width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (chosen) ...[const Icon(Icons.check_rounded, size: 16, color: Colors.white), const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
        ),
        child: const Text('lit la page…', style: TextStyle(color: DayOneColors.muted, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.drafts,
    required this.onRemove,
    required this.onConfirm,
    required this.onCancel,
    required this.onRetake,
    required this.onSend,
    required this.onCamera,
    required this.onAttach,
  });

  final TextEditingController controller;
  final List<PhotoDraft> drafts;
  final ValueChanged<String> onRemove;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onRetake;
  final VoidCallback onSend;
  final VoidCallback onCamera;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final pendingLabel = drafts.length > 1 ? 'Ces photos ne sont pas encore enregistrées.' : 'Cette photo n’est pas encore enregistrée.';
    return Container(
      color: DayOneColors.chatBg,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        children: [
          if (drafts.isNotEmpty) ...[
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: drafts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final draft = drafts[index];
                  return SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(draft.path), width: 72, height: 72, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: const Color(0xFF1F1F1F),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onRemove(draft.id),
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pendingLabel,
              style: const TextStyle(color: DayOneColors.muted, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _MiniAction(label: 'Confirmer', filled: true, onTap: onConfirm)),
                const SizedBox(width: 6),
                Expanded(child: _MiniAction(label: 'Reprendre', onTap: onRetake)),
                const SizedBox(width: 6),
                Expanded(child: _MiniAction(label: 'Annuler', onTap: onCancel)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: DayOneColors.shadow),
                  child: Row(
                    children: [
                      IconButton(onPressed: onAttach, icon: const Icon(Icons.add_rounded, color: DayOneColors.muted)),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      IconButton(onPressed: onCamera, icon: const Icon(Icons.photo_camera_outlined, color: DayOneColors.muted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSend,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: DayOneColors.gradient),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? DayOneColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: DayOneColors.primary),
          ),
          child: Text(
            label,
            style: TextStyle(color: filled ? Colors.white : DayOneColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final failure = DocState.isFailure(state);
    final synced = state == DocState.synced;
    final color = failure ? DayOneColors.danger : synced ? DayOneColors.success : DayOneColors.primaryDark;
    final bg = failure ? DayOneColors.dangerSoft : synced ? DayOneColors.successSoft : DayOneColors.primarySoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(DocState.labels[state] ?? state, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }
}
