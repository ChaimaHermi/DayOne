import 'package:dayone/features/chat/chat_controller.dart';
import 'package:dayone/features/chat/chat_models.dart';
import 'package:dayone/features/chat/chat_store.dart';
import 'package:flutter_test/flutter_test.dart';

ChatController _chat({bool online = true}) {
  return ChatController(
    midwifeId: 'sf-test',
    firstName: 'Amina',
    store: MemoryChatStore(),
    online: online,
    processDelay: Duration.zero,
    syncDelay: Duration.zero,
  );
}

void main() {
  test('a photo stays out of the register until it is confirmed', () async {
    final chat = _chat();
    await chat.init();
    chat.addDrafts(['/tmp/a.jpg', '/tmp/b.jpg']);

    expect(chat.docs, isEmpty);
    expect(chat.drafts, hasLength(2));
  });

  test('the cross removes one photo and leaves the others', () async {
    final chat = _chat();
    await chat.init();
    chat.addDrafts(['/tmp/a.jpg', '/tmp/b.jpg']);
    chat.removeDraft(chat.drafts.first.id);

    expect(chat.drafts, hasLength(1));
    expect(chat.drafts.single.path, '/tmp/b.jpg');
    expect(chat.docs, isEmpty);
  });

  test('cancel removes every photo before anything is stored', () async {
    final chat = _chat();
    await chat.init();
    chat.addDrafts(['/tmp/a.jpg', '/tmp/b.jpg']);
    chat.cancelAll();

    expect(chat.drafts, isEmpty);
    expect(chat.docs, isEmpty);
  });

  test('confirm offline queues the page', () async {
    final chat = _chat(online: false);
    await chat.init();
    chat.addDrafts(['/tmp/page.jpg']);
    await chat.confirmAll();

    expect(chat.drafts, isEmpty);
    expect(chat.docs.single.state, DocState.waitingAi);
    expect(chat.pendingCount, 1);
  });

  test('confirm online reads the page then synchronizes it', () async {
    final chat = _chat();
    await chat.init();
    chat.addDrafts(['/tmp/page.jpg']);
    await chat.confirmAll();

    expect(chat.docs.single.state, DocState.synced);
    expect(chat.messages.any((message) => message.type == 'extraction'), isTrue);
  });

  test('network return reads the queue then synchronizes', () async {
    final chat = _chat(online: false);
    await chat.init();
    chat.addDrafts(['/tmp/page.jpg']);
    await chat.confirmAll();
    expect(chat.docs.single.state, DocState.waitingAi);

    await chat.setRealOnline(true);

    expect(chat.docs.single.state, DocState.synced);
  });

  test('confirm stores every pending photo', () async {
    final chat = _chat(online: false);
    await chat.init();
    chat.addDrafts(['/tmp/a.jpg', '/tmp/b.jpg']);
    await chat.confirmAll();

    expect(chat.drafts, isEmpty);
    expect(chat.docs, hasLength(2));
    expect(chat.docs.every((doc) => doc.state == DocState.waitingAi), isTrue);
  });
}
