// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'chat_models.dart';
import 'chat_store.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required this.midwifeId,
    required this.firstName,
    required ChatStore store,
    bool online = true,
    this.processDelay = const Duration(milliseconds: 900),
    this.syncDelay = const Duration(milliseconds: 700),
  })  : _store = store,
        _realOnline = online;

  final String midwifeId;
  final String firstName;
  final ChatStore _store;
  final Duration processDelay;
  final Duration syncDelay;

  final List<ChatMessage> messages = [];
  final List<RegisterDoc> docs = [];
  final List<PhotoDraft> drafts = [];

  bool ready = false;
  bool typing = false;
  bool _realOnline;
  bool simulateOffline = false;
  bool _alive = true;
  _Undo? _undo;

  bool get online => _realOnline && !simulateOffline;
  bool get reallyOnline => _realOnline;
  bool get canUndo => _undo != null;
  String? get undoLabel => _undo?.label;
  int get pendingCount => docs.where((doc) => doc.state != DocState.synced).length;

  RegisterDoc? docById(String? id) {
    if (id == null) return null;
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  Future<void> init() async {
    docs.addAll(await _store.loadDocs(midwifeId));
    messages.addAll(await _store.loadMessages(midwifeId));
    docs.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    if (messages.isEmpty) {
      await _say(
        'Bonjour $firstName. Envoyez-moi la photo d’une page du registre. Je lis les champs, je vous dis quand je doute, et vous gardez le dernier mot.',
        actions: const [ChatAction(id: 'takePhoto', label: 'Photographier une page', primary: true)],
      );
    }
    ready = true;
    if (_alive) notifyListeners();
    if (online) await drain();
  }

  Future<void> setRealOnline(bool value) async {
    if (_realOnline == value) return;
    _realOnline = value;
    _touch();
    if (online) await drain();
  }

  Future<void> setSimulateOffline(bool value) async {
    if (!_realOnline && !value) return;
    if (simulateOffline == value) return;
    simulateOffline = value;
    _touch();
    if (online) await drain();
  }

  Future<void> toggleNetwork() => setSimulateOffline(!simulateOffline);

  void addDrafts(List<String> paths) {
    for (final path in paths) {
      if (path.isEmpty) continue;
      final draft = PhotoDraft(id: _id('ph'), path: path);
      drafts.add(draft);
    }
    _touch();
  }

  void removeDraft(String id) {
    drafts.removeWhere((draft) => draft.id == id);
    _touch();
  }

  void cancelAll() {
    if (drafts.isEmpty) return;
    drafts.clear();
    _touch();
  }

  Future<void> confirmAll() async {
    if (drafts.isEmpty) return;
    final paths = [for (final draft in drafts) draft.path];
    drafts.clear();
    _touch();
    for (final path in paths) {
      await captureImage(path);
    }
  }

  Future<void> captureImage(String path) async {
    final now = DateTime.now();
    final doc = RegisterDoc(
      id: _id('DOC'),
      code: _code(),
      state: DocState.captured,
      imagePath: path,
      capturedAt: now,
      history: [StateEvent(state: DocState.captured, at: now)],
    );
    docs.insert(0, doc);
    await _store.saveDoc(midwifeId, doc);
    await _mine('Photo du registre ${doc.code}', type: 'image', docId: doc.id, imagePath: path);
    if (!online) {
      await _move(doc, DocState.waitingAi);
      await _say(
        'Vous êtes hors ligne. La page ${doc.code} est chiffrée sur le téléphone, en file « En attente de traitement ». Je la lis dès le retour du réseau.',
        docId: doc.id,
        actions: const [ChatAction(id: 'openQueue', label: 'Voir la file d’attente')],
      );
      return;
    }
    await _process(doc.id);
  }

  Future<void> replacePhoto(String docId, String path) async {
    final doc = docById(docId);
    if (doc == null) return;
    _lockOpen(docId, 'retake');
    doc.imagePath = path;
    doc.fields.clear();
    doc.failureNote = '';
    await _move(doc, DocState.captured, note: 'Photo reprise');
    await _mine('Nouvelle photo du registre ${doc.code}', type: 'image', docId: doc.id, imagePath: path);
    _undo = null;
    if (!online) {
      await _move(doc, DocState.waitingAi);
      await _say('Nouvelle photo reçue. Hors ligne : elle attend dans la file.', docId: doc.id);
      return;
    }
    await _process(doc.id);
  }

  Future<void> act(String messageId, String actionId) async {
    final message = _message(messageId);
    if (message == null || message.answered != null) return;
    message.answered = actionId;
    await _store.saveMessage(midwifeId, message);
    final doc = docById(message.docId);
    await _mine(_labelOf(message, actionId), docId: message.docId);

    switch (actionId) {
      case 'confirm':
        if (doc == null) return;
        final previous = doc.state;
        await _move(doc, DocState.validated);
        await _move(doc, DocState.saved);
        _undo = _Undo(docId: doc.id, previousState: previous, label: 'la confirmation du registre ${doc.code}');
        await _say('Lecture du registre ${doc.code} confirmée. Rien n’est envoyé tant que vous n’avez pas validé : c’est fait.', docId: doc.id);
        if (!online) {
          await _say('Le dossier reste sur le téléphone. Il sera synchronisé au retour du réseau.', docId: doc.id);
          break;
        }
        await _sync(doc.id);
        break;
      case 'cancel':
        await _say(
          'Annuler le registre ${doc?.code ?? ''} ? La photo et la lecture seront retirées du téléphone. Le papier reste votre référence.',
          docId: message.docId,
          actions: const [
            ChatAction(id: 'cancelYes', label: 'Oui, annuler le registre'),
            ChatAction(id: 'cancelNo', label: 'Non, continuer', primary: true),
          ],
        );
        break;
      case 'cancelYes':
        if (doc != null) {
          docs.remove(doc);
          await _store.deleteDoc(midwifeId, doc.id);
          if (_undo?.docId == doc.id) _undo = null;
        }
        await _say('Registre annulé. Rien n’a été envoyé.', actions: const [
          ChatAction(id: 'takePhoto', label: 'Photographier une page', primary: true),
        ]);
        break;
      case 'cancelNo':
        await _askReview(doc);
        break;
      default:
        break;
    }
  }

  Future<void> undoLast() async {
    final entry = _undo;
    if (entry == null) return;
    final doc = docById(entry.docId);
    _undo = null;
    if (doc == null) {
      _touch();
      return;
    }
    await _mine('Annuler ma dernière réponse');
    doc.failureNote = '';
    await _move(doc, entry.previousState, note: 'Confirmation annulée');
    await _say('Réponse annulée pour ${entry.label}. Je repose la question.', docId: doc.id);
    await _askReview(doc);
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _mine(trimmed);
    if (RegExp(r'aide|help|comment', caseSensitive: false).hasMatch(trimmed)) {
      await _say(
        'Photographiez la page. Je propose une lecture. Vous confirmez, vous reprenez la photo, ou vous annulez le registre. Hors ligne, tout reste sur le téléphone.',
        actions: const [ChatAction(id: 'takePhoto', label: 'Photographier une page', primary: true)],
      );
      return;
    }
    await _say(
      'Je suis là pour lire le registre. Envoyez la photo d’une page.',
      actions: const [ChatAction(id: 'takePhoto', label: 'Photographier une page', primary: true)],
    );
  }

  Future<void> drain() async {
    if (!online) return;
    final waiting = docs.where((doc) => doc.state == DocState.waitingAi).toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final alreadySaved = docs.where((doc) => doc.state == DocState.saved || doc.state == DocState.syncFailed).length;
    if (waiting.isEmpty && alreadySaved == 0) return;
    await _say(
      'Connexion rétablie. ${waiting.isEmpty ? 'Aucun registre en attente de lecture' : 'Je lis ${waiting.length} page${waiting.length > 1 ? 's' : ''} en attente'}, puis j’envoie les dossiers enregistrés.',
    );
    for (final doc in waiting) {
      await _process(doc.id);
    }
    final toSync = docs.where((doc) => doc.state == DocState.saved || doc.state == DocState.syncFailed).toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    for (final doc in toSync) {
      await _sync(doc.id);
    }
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  Future<void> _process(String docId) async {
    final doc = docById(docId);
    if (doc == null) return;
    typing = true;
    _touch();
    await Future.delayed(processDelay);
    typing = false;
    if (!_alive || docById(docId) == null) return;
    if (!online) {
      await _move(doc, DocState.waitingAi, note: 'Connexion perdue pendant la lecture');
      await _say('La connexion est tombée pendant la lecture du registre ${doc.code}. Il reste en file : rien n’est perdu.', docId: doc.id);
      return;
    }
    doc.fields
      ..clear()
      ..addAll(_readingFor(doc.code));
    await _move(doc, DocState.processed);
    final doubts = doc.fields.where((field) => field.doubtful).toList();
    if (doubts.isNotEmpty) await _move(doc, DocState.review);
    final doubtText = doubts.isEmpty
        ? 'Tous les champs sont lus avec assurance.'
        : 'Je doute sur ${doubts.map((field) => field.label.toLowerCase()).join(', ')}. La photo a déjà été confirmée par vous.';
    await _say('Lecture du registre ${doc.code}. $doubtText', type: 'extraction', docId: doc.id);
    await _move(doc, DocState.validated);
    await _move(doc, DocState.saved);
    if (!online) {
      await _say('Le dossier ${doc.code} est enregistré sur le téléphone. Il sera synchronisé au retour du réseau.', docId: doc.id, actions: const [
        ChatAction(id: 'openQueue', label: 'Voir la file d’attente'),
      ]);
      return;
    }
    await _sync(doc.id);
  }

  Future<void> _sync(String docId) async {
    final doc = docById(docId);
    if (doc == null) return;
    if (doc.state != DocState.saved && doc.state != DocState.syncFailed) return;
    await Future.delayed(syncDelay);
    if (!_alive || docById(docId) == null) return;
    if (doc.state != DocState.saved && doc.state != DocState.syncFailed) return;
    if (!online) {
      await _move(doc, DocState.syncFailed, note: 'Connexion perdue pendant l’envoi');
      await _say('L’envoi du dossier ${doc.code} a été coupé. Il reste sur le téléphone, je réessaierai.', docId: doc.id);
      return;
    }
    doc.failureNote = '';
    await _move(doc, DocState.synced);
    await _say('Dossier ${doc.code} synchronisé.', docId: doc.id);
  }

  Future<void> _askReview(RegisterDoc? doc) async {
    if (doc == null) return;
    final doubts = doc.fields.where((field) => field.doubtful).toList();
    final doubtText = doubts.isEmpty
        ? 'Tous les champs sont lus avec assurance.'
        : 'Je doute sur ${doubts.map((field) => field.label.toLowerCase()).join(', ')}.';
    await _say(
      'Lecture du registre ${doc.code}. $doubtText Confirmez, reprenez la photo, ou annulez.',
      type: 'extraction',
      docId: doc.id,
      actions: const [
        ChatAction(id: 'confirm', label: 'Confirmer', primary: true),
        ChatAction(id: 'retake', label: 'Reprendre la photo'),
        ChatAction(id: 'cancel', label: 'Annuler'),
      ],
    );
  }

  Future<void> _move(RegisterDoc doc, String state, {String note = ''}) async {
    doc.state = state;
    doc.failureNote = DocState.isFailure(state) ? note : '';
    doc.history.add(StateEvent(state: state, at: DateTime.now(), note: note));
    await _store.saveDoc(midwifeId, doc);
    _touch();
  }

  Future<void> _say(
    String text, {
    String type = 'text',
    String? docId,
    List<ChatAction> actions = const [],
  }) async {
    final message = ChatMessage(
      id: _id('m'),
      from: 'agent',
      type: type,
      text: text,
      at: DateTime.now(),
      docId: docId,
      actions: actions,
    );
    messages.add(message);
    await _store.saveMessage(midwifeId, message);
    _touch();
  }

  Future<void> _mine(String text, {String type = 'text', String? docId, String? imagePath}) async {
    final message = ChatMessage(
      id: _id('m'),
      from: 'me',
      type: type,
      text: text,
      at: DateTime.now(),
      docId: docId,
      imagePath: imagePath,
    );
    messages.add(message);
    await _store.saveMessage(midwifeId, message);
    _touch();
  }

  void _lockOpen(String docId, String actionId) {
    for (final message in messages) {
      if (message.docId == docId && message.answered == null && message.actions.isNotEmpty) {
        message.answered = actionId;
        _store.saveMessage(midwifeId, message);
      }
    }
  }

  ChatMessage? _message(String id) {
    for (final message in messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  String _labelOf(ChatMessage message, String actionId) {
    for (final action in message.actions) {
      if (action.id == actionId) return action.label;
    }
    return actionId;
  }

  List<ExtractedField> _readingFor(String code) {
    final templates = <List<ExtractedField>>[
      [
        const ExtractedField(label: 'Âge', value: '24', unit: 'ans', status: 'CONNU', confidence: 0.96),
        const ExtractedField(label: 'Poids', value: '62', unit: 'kg', status: 'CONNU', confidence: 0.71),
        const ExtractedField(label: 'Tension artérielle', value: '118/74', unit: 'mmHg', status: 'CONNU', confidence: 0.93),
        const ExtractedField(label: 'Température', value: '36.8', unit: '°C', status: 'CONNU', confidence: 0.9),
      ],
      [
        const ExtractedField(label: 'Âge gestationnel', value: '28', unit: 'SA', status: 'CONNU', confidence: 0.91),
        const ExtractedField(label: 'Cœur fœtal', value: '146', unit: 'bpm', status: 'CONNU', confidence: 0.88),
        const ExtractedField(label: 'Tension artérielle', value: '150/95', unit: 'mmHg', status: 'CONNU', confidence: 0.58),
        const ExtractedField(label: 'Mouvements fœtaux', value: 'Oui', unit: '', status: 'CONNU', confidence: 0.9),
      ],
      [
        const ExtractedField(label: 'Date de la visite', value: '03/10/2026', unit: '', status: 'CONNU', confidence: 0.94),
        const ExtractedField(label: 'Syphilis', value: '', unit: '', status: 'ILLISIBLE', confidence: 0.8),
        const ExtractedField(label: 'VIH', value: 'Négatif', unit: '', status: 'CONNU', confidence: 0.92),
        const ExtractedField(label: 'Traitement', value: 'Fer + acide folique', unit: '', status: 'CONNU', confidence: 0.86),
      ],
    ];
    final index = code.codeUnits.fold<int>(0, (sum, unit) => sum + unit) % templates.length;
    return templates[index].map((field) => ExtractedField(
          label: field.label,
          value: field.value,
          unit: field.unit,
          status: field.status,
          confidence: field.confidence,
        )).toList();
  }

  void _touch() {
    if (_alive) notifyListeners();
  }

  String _id(String prefix) => '$prefix-${const Uuid().v4().substring(0, 8)}';

  String _code() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

class PhotoDraft {
  PhotoDraft({required this.id, required this.path});

  final String id;
  String path;
}

class _Undo {
  const _Undo({required this.docId, required this.previousState, required this.label});

  final String docId;
  final String previousState;
  final String label;
}
