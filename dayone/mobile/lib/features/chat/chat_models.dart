class DocState {
  DocState._();

  static const captured = 'CAPTURÉ';
  static const waitingAi = 'EN_ATTENTE_IA';
  static const processed = 'TRAITÉ_IA';
  static const review = 'À_RÉVISER';
  static const validated = 'VALIDÉ';
  static const saved = 'ENREGISTRÉ';
  static const synced = 'SYNCHRONISÉ';
  static const processFailed = 'ÉCHEC_TRAITEMENT';
  static const syncFailed = 'ÉCHEC_SYNCHRO';

  static const labels = {
    captured: 'Capturé',
    waitingAi: 'En attente de traitement',
    processed: 'Traité par l’agent',
    review: 'À réviser',
    validated: 'Validé',
    saved: 'Enregistré',
    synced: 'Synchronisé',
    processFailed: 'Échec du traitement',
    syncFailed: 'Échec de synchronisation',
  };

  static bool isFailure(String state) => state == processFailed || state == syncFailed;
}

class ExtractedField {
  const ExtractedField({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.confidence,
  });

  final String label;
  final String value;
  final String unit;
  final String status;
  final double confidence;

  bool get doubtful => status == 'ILLISIBLE' || status == 'À_RÉVISER' || confidence < 0.75;

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'unit': unit,
        'status': status,
        'confidence': confidence,
      };

  factory ExtractedField.fromJson(Map<String, dynamic> json) {
    return ExtractedField(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      status: json['status'] as String? ?? 'CONNU',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
    );
  }
}

class StateEvent {
  const StateEvent({required this.state, required this.at, this.note = ''});

  final String state;
  final DateTime at;
  final String note;

  Map<String, dynamic> toJson() => {'state': state, 'at': at.toIso8601String(), 'note': note};

  factory StateEvent.fromJson(Map<String, dynamic> json) {
    return StateEvent(
      state: json['state'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }
}

class RegisterDoc {
  RegisterDoc({
    required this.id,
    required this.code,
    required this.state,
    required this.imagePath,
    required this.capturedAt,
    this.failureNote = '',
    List<ExtractedField>? fields,
    List<StateEvent>? history,
  })  : fields = fields ?? [],
        history = history ?? [];

  final String id;
  String code;
  String state;
  String imagePath;
  final DateTime capturedAt;
  String failureNote;
  final List<ExtractedField> fields;
  final List<StateEvent> history;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'state': state,
        'imagePath': imagePath,
        'capturedAt': capturedAt.toIso8601String(),
        'failureNote': failureNote,
        'fields': fields.map((field) => field.toJson()).toList(),
        'history': history.map((event) => event.toJson()).toList(),
      };

  factory RegisterDoc.fromJson(Map<String, dynamic> json) {
    return RegisterDoc(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      state: json['state'] as String? ?? DocState.captured,
      imagePath: json['imagePath'] as String? ?? '',
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ?? DateTime.now(),
      failureNote: json['failureNote'] as String? ?? '',
      fields: [
        for (final item in (json['fields'] as List?) ?? [])
          if (item is Map<String, dynamic>) ExtractedField.fromJson(item),
      ],
      history: [
        for (final item in (json['history'] as List?) ?? [])
          if (item is Map<String, dynamic>) StateEvent.fromJson(item),
      ],
    );
  }
}

class ChatAction {
  const ChatAction({required this.id, required this.label, this.primary = false});

  final String id;
  final String label;
  final bool primary;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'primary': primary};

  factory ChatAction.fromJson(Map<String, dynamic> json) {
    return ChatAction(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      primary: json['primary'] as bool? ?? false,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.from,
    required this.type,
    required this.text,
    required this.at,
    this.docId,
    this.imagePath,
    List<ChatAction>? actions,
    this.answered,
  }) : actions = actions ?? [];

  final String id;
  final String from;
  final String type;
  final String text;
  final DateTime at;
  final String? docId;
  final String? imagePath;
  final List<ChatAction> actions;
  String? answered;

  bool get mine => from == 'me';

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'type': type,
        'text': text,
        'at': at.toIso8601String(),
        'docId': docId,
        'imagePath': imagePath,
        'actions': actions.map((action) => action.toJson()).toList(),
        'answered': answered,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      from: json['from'] as String? ?? 'agent',
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      docId: json['docId'] as String?,
      imagePath: json['imagePath'] as String?,
      actions: [
        for (final item in (json['actions'] as List?) ?? [])
          if (item is Map<String, dynamic>) ChatAction.fromJson(item),
      ],
      answered: json['answered'] as String?,
    );
  }
}
