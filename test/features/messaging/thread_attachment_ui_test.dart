import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/messaging/domain/constants/chat_attachment_limits.dart';
import 'package:carzon/features/messaging/domain/entities/chat_attachment.dart';
import 'package:carzon/features/messaging/domain/entities/chat_attachment_upload.dart';
import 'package:carzon/features/messaging/domain/entities/chat_message.dart';
import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/conversation_thread_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/conversation_thread_state.dart';
import 'package:carzon/features/messaging/presentation/utils/conversation_display_copy.dart';
import 'package:carzon/features/messaging/presentation/utils/thread_camera_capture_normalizer.dart';
import 'package:carzon/features/messaging/presentation/widgets/chat_image_message_bubble.dart';
import 'package:carzon/features/messaging/presentation/widgets/chat_message_bubble.dart';
import 'package:carzon/features/messaging/presentation/widgets/thread_composer_bar.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockMessagingRepository extends Mock implements MessagingRepository {}

const _kTinyPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  late _MockMessagingRepository repository;
  final l10n = ruStrings();
  final t0 = DateTime.utc(2026, 5, 1, 12);

  final conversation = Conversation(
    id: 'c1',
    listingId: 'l1',
    buyerId: 'b1',
    sellerId: 's1',
    createdAt: t0,
    updatedAt: t0,
  );

  final attachment = ChatAttachment(
    id: 'a1',
    messageId: 'm-img',
    conversationId: 'c1',
    storageBucket: 'chat-attachments',
    storagePath: 'conversations/c1/u1/photo.png',
    mimeType: 'image/png',
    sizeBytes: 64,
    createdAt: t0,
  );

  setUp(() {
    repository = _MockMessagingRepository();
    when(
      () => repository.markConversationRead(any()),
    ).thenAnswer((_) async => const Success(true));
  });

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(
      ChatAttachmentUpload(
        conversationId: 'c1',
        bytes: Uint8List(0),
        mimeType: 'image/png',
      ),
    );
  });

  Widget wrapComposer({
    required ConversationThreadCubit cubit,
    required TextEditingController controller,
    ThreadImagePicker? imagePicker,
    ThreadCameraCapture? cameraCapture,
    ThreadCameraCaptureNormalizerFn? cameraNormalizer,
  }) {
    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: ThreadComposerBar(
            conversationId: 'c1',
            textController: controller,
            onSendSucceeded: () => controller.clear(),
            imagePicker: imagePicker,
            cameraCapture: cameraCapture,
            cameraNormalizer: cameraNormalizer,
          ),
        ),
      ),
    );
  }

  ConversationThreadCubit readyCubit() {
    when(
      () => repository.getConversation('c1'),
    ).thenAnswer((_) async => Success(conversation));
    when(
      () => repository.getMessages('c1'),
    ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));
    return ConversationThreadCubit(
      repository: repository,
      conversationId: 'c1',
    );
  }

  test('conversationMessagePreviewLine maps [photo] to localized text', () {
    expect(
      conversationMessagePreviewLine('[photo]', l10n),
      l10n.messagingAttachmentPhotoPreview,
    );
    expect(
      conversationMessagePreviewLine('Hello', l10n),
      'Hello',
    );
  });

  blocTest<ConversationThreadCubit, ConversationThreadState>(
    'sendMessageWithAttachment calls repository and reloads',
    build: () {
      when(
        () => repository.getConversation('c1'),
      ).thenAnswer((_) async => Success(conversation));
      when(
        () => repository.getMessages('c1'),
      ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));
      when(
        () => repository.sendMessageWithAttachment(any()),
      ).thenAnswer((_) async => const Success<String>('m2'));
      return ConversationThreadCubit(
        repository: repository,
        conversationId: 'c1',
      );
    },
    act: (c) async {
      await c.load();
      await c.sendMessageWithAttachment(
        ChatAttachmentUpload(
          conversationId: 'c1',
          bytes: Uint8List.fromList(_kTinyPng),
          mimeType: 'image/png',
          caption: 'caption',
        ),
      );
    },
    verify: (_) {
      verify(() => repository.sendMessageWithAttachment(any())).called(1);
      verify(() => repository.getConversation('c1')).called(2);
      verify(() => repository.getMessages('c1')).called(2);
    },
  );

  testWidgets('composer send stays disabled for empty text without image', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrapComposer(cubit: cubit, controller: controller));
    await cubit.load();
    await tester.pumpAndSettle();

    final sendButton = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);
  });

  testWidgets('selected image preview appears and can be removed', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        imagePicker:
            ({
              required source,
              maxWidth,
              imageQuality,
            }) async => XFile.fromData(
              Uint8List.fromList(_kTinyPng),
              name: 'photo.png',
              mimeType: 'image/png',
            ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentGallery));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);

    await tester.tap(find.text(l10n.messagingAttachmentRemove));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets('attachment send calls repository with optional caption', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    when(
      () => repository.sendMessageWithAttachment(any()),
    ).thenAnswer((_) async => const Success<String>('m2'));

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        imagePicker:
            ({
              required source,
              maxWidth,
              imageQuality,
            }) async => XFile.fromData(
              Uint8List.fromList(_kTinyPng),
              name: 'photo.png',
              mimeType: 'image/png',
            ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentGallery));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'caption');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final captured = verify(
      () => repository.sendMessageWithAttachment(captureAny()),
    ).captured.single as ChatAttachmentUpload;
    expect(captured.caption, 'caption');
    expect(captured.mimeType, 'image/png');
  });

  testWidgets('failed attachment send keeps selected image for retry', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    when(() => repository.sendMessageWithAttachment(any())).thenAnswer(
      (_) async => const FailureResult<String>(ServerFailure('offline')),
    );

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        imagePicker:
            ({
              required source,
              maxWidth,
              imageQuality,
            }) async => XFile.fromData(
              Uint8List.fromList(_kTinyPng),
              name: 'photo.png',
              mimeType: 'image/png',
            ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentGallery));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(controller.text, isEmpty);
  });

  testWidgets('unsupported image type shows localized snackbar', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        imagePicker:
            ({
              required source,
              maxWidth,
              imageQuality,
            }) async => XFile.fromData(
              Uint8List.fromList(_kTinyPng),
              name: 'photo.gif',
              mimeType: 'image/gif',
            ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentGallery));
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingAttachmentUnsupportedType), findsOneWidget);
  });

  testWidgets('image-only message renders without empty text bubble', (
    tester,
  ) async {
    final message = ChatMessage(
      id: 'm-img',
      conversationId: 'c1',
      senderId: 'b1',
      body: '',
      createdAt: t0,
      attachments: [attachment],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatImageMessageBubble(
            message: message,
            attachment: attachment,
            isOutgoing: true,
            timeLabel: '12:00',
            loadFailedLabel: l10n.messagingAttachmentLoadFailed,
            loadBytes: (_) async => Uint8List.fromList(_kTinyPng),
            onOpenFullscreen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('image with caption renders both', (tester) async {
    final message = ChatMessage(
      id: 'm-img-cap',
      conversationId: 'c1',
      senderId: 'b1',
      body: 'Look at this',
      createdAt: t0,
      attachments: [attachment],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatImageMessageBubble(
            message: message,
            attachment: attachment,
            isOutgoing: false,
            timeLabel: '12:05',
            loadFailedLabel: l10n.messagingAttachmentLoadFailed,
            loadBytes: (_) async => Uint8List.fromList(_kTinyPng),
            onOpenFullscreen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Look at this'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('outgoing image caption aligns text to start', (tester) async {
    final message = ChatMessage(
      id: 'm-img-cap-out',
      conversationId: 'c1',
      senderId: 'b1',
      body: 'Look at this',
      createdAt: t0,
      attachments: [attachment],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatImageMessageBubble(
            message: message,
            attachment: attachment,
            isOutgoing: true,
            timeLabel: '12:05',
            loadFailedLabel: l10n.messagingAttachmentLoadFailed,
            loadBytes: (_) async => Uint8List.fromList(_kTinyPng),
            onOpenFullscreen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final caption = tester.widget<Text>(find.text('Look at this'));
    expect(caption.textAlign, TextAlign.start);

    final bubbleAlign = tester.widget<Align>(
      find.descendant(
        of: find.byType(ChatImageMessageBubble),
        matching: find.byType(Align),
      ).first,
    );
    expect(bubbleAlign.alignment, Alignment.centerRight);
  });

  testWidgets('outgoing text bubble aligns body to start', (tester) async {
    final message = ChatMessage(
      id: 'm-text-out',
      conversationId: 'c1',
      senderId: 'b1',
      body: 'Plain text',
      createdAt: t0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: message,
            isOutgoing: true,
            timeLabel: '12:10',
          ),
        ),
      ),
    );

    final body = tester.widget<Text>(find.text('Plain text'));
    expect(body.textAlign, TextAlign.start);
  });

  testWidgets('download failure shows placeholder not blank bubble', (
    tester,
  ) async {
    final message = ChatMessage(
      id: 'm-img',
      conversationId: 'c1',
      senderId: 'b1',
      body: '',
      createdAt: t0,
      attachments: [attachment],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatImageMessageBubble(
            message: message,
            attachment: attachment,
            isOutgoing: true,
            timeLabel: '12:00',
            loadFailedLabel: l10n.messagingAttachmentLoadFailed,
            loadBytes: (_) async => null,
            onOpenFullscreen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingAttachmentLoadFailed), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('text-only message bubble still renders body', (tester) async {
    final message = ChatMessage(
      id: 'm-text',
      conversationId: 'c1',
      senderId: 'b1',
      body: 'Plain text',
      createdAt: t0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: message,
            isOutgoing: true,
            timeLabel: '12:10',
          ),
        ),
      ),
    );

    expect(find.text('Plain text'), findsOneWidget);
  });

  testWidgets('oversized image shows localized snackbar', (tester) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    final huge = Uint8List(ChatAttachmentLimits.maxBytes + 1);

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        imagePicker:
            ({
              required source,
              maxWidth,
              imageQuality,
            }) async => XFile.fromData(
              huge,
              name: 'big.png',
              mimeType: 'image/png',
            ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentGallery));
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingAttachmentTooLarge), findsOneWidget);
  });

  testWidgets('source picker shows title and gallery/camera actions', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrapComposer(cubit: cubit, controller: controller));
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingAttachmentSourceTitle), findsOneWidget);
    expect(find.text(l10n.messagingAttachmentGallery), findsOneWidget);
    expect(find.text(l10n.messagingAttachmentCamera), findsOneWidget);
  });

  testWidgets('source picker dismiss does not mutate draft or show error', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrapComposer(cubit: cubit, controller: controller));
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ModalBarrier).last);
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.text(l10n.imagePickerLoadFailed), findsNothing);
  });

  testWidgets('attach button disabled while send is in flight', (tester) async {
    final gate = Completer<void>();
    when(
      () => repository.sendMessageWithAttachment(any()),
    ).thenAnswer((_) async {
      await gate.future;
      return const Success<String>('m2');
    });

    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        imagePicker:
            ({
              required source,
              maxWidth,
              imageQuality,
            }) async => XFile.fromData(
              Uint8List.fromList(_kTinyPng),
              name: 'photo.png',
              mimeType: 'image/png',
            ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentGallery));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final attachButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byTooltip(l10n.messagingAttachImage),
        matching: find.byType(IconButton),
      ),
    );
    expect(attachButton.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('gallery source uses image_picker gallery path only', (tester) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    ImageSource? pickedSource;
    var pickerCalls = 0;

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        imagePicker:
            ({
              required source,
              maxWidth,
              imageQuality,
            }) async {
              pickerCalls++;
              pickedSource = source;
              return XFile.fromData(
                Uint8List.fromList(_kTinyPng),
                name: 'photo.png',
                mimeType: 'image/png',
              );
            },
        cameraCapture: (_) async {
          fail('camera capture should not run for gallery selection');
        },
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentGallery));
    await tester.pumpAndSettle();

    expect(pickerCalls, 1);
    expect(pickedSource, ImageSource.gallery);
  });

  testWidgets('camera source uses injected capture path and shows preview', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var pickerCalls = 0;
    var cameraCalls = 0;

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        imagePicker:
            ({
              required source,
              maxWidth,
              imageQuality,
            }) async {
              pickerCalls++;
              return null;
            },
        cameraCapture: (_) async {
          cameraCalls++;
          return XFile.fromData(
            Uint8List.fromList(_kTinyPng),
            name: 'capture.jpg',
            mimeType: 'image/jpeg',
          );
        },
        cameraNormalizer: (file) async {
          final bytes = await file.readAsBytes();
          return ThreadCameraCaptureNormalized(
            bytes: bytes,
            mimeType: 'image/jpeg',
            filename: 'chat_camera_test.jpg',
          );
        },
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentCamera));
    await tester.pumpAndSettle();

    expect(pickerCalls, 0);
    expect(cameraCalls, 1);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('cancelled camera capture leaves composer without attachment draft', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        cameraCapture: (_) async => null,
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentCamera));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('oversize camera result shows localized oversize snackbar', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        cameraCapture: (_) async => XFile.fromData(
          Uint8List.fromList(_kTinyPng),
          name: 'capture.jpg',
          mimeType: 'image/jpeg',
        ),
        cameraNormalizer: (_) async => ThreadCameraCaptureNormalized(
          bytes: Uint8List(ChatAttachmentLimits.maxBytes + 1),
          mimeType: 'image/jpeg',
          filename: 'chat_camera_big.jpg',
        ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentCamera));
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingAttachmentTooLarge), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('send after camera capture uses ChatAttachmentUpload path', (
    tester,
  ) async {
    final cubit = readyCubit();
    addTearDown(cubit.close);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    when(
      () => repository.sendMessageWithAttachment(any()),
    ).thenAnswer((_) async => const Success<String>('m2'));

    await tester.pumpWidget(
      wrapComposer(
        cubit: cubit,
        controller: controller,
        cameraCapture: (_) async => XFile.fromData(
          Uint8List.fromList(_kTinyPng),
          name: 'capture.jpg',
          mimeType: 'image/jpeg',
        ),
        cameraNormalizer: (file) async {
          final bytes = await file.readAsBytes();
          return ThreadCameraCaptureNormalized(
            bytes: bytes,
            mimeType: 'image/jpeg',
            filename: 'chat_camera_test.jpg',
          );
        },
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.messagingAttachImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.messagingAttachmentCamera));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final captured = verify(
      () => repository.sendMessageWithAttachment(captureAny()),
    ).captured.single as ChatAttachmentUpload;
    expect(captured.mimeType, 'image/jpeg');
    expect(captured.filename, 'chat_camera_test.jpg');
  });
}
