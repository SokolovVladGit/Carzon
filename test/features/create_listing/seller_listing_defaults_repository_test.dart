import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/data/datasources/seller_listing_defaults_remote_datasource.dart';
import 'package:carzon/features/create_listing/data/repositories/seller_listing_defaults_repository_impl.dart';
import 'package:carzon/features/create_listing/domain/entities/seller_listing_defaults.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock
    implements SellerListingDefaultsRemoteDataSource {}

void main() {
  group('parseSellerListingDefaultsResponse', () {
    test('empty / missing row is a stable empty defaults object', () {
      expect(
        parseSellerListingDefaultsResponse(null),
        const SellerListingDefaults.empty(),
      );
      expect(
        parseSellerListingDefaultsResponse(<dynamic>[]),
        const SellerListingDefaults.empty(),
      );
      expect(
        parseSellerListingDefaultsResponse([
          {
            'contact_phone': null,
            'telegram_username': null,
            'whatsapp_enabled': false,
            'market_region': null,
            'city': null,
          },
        ]),
        const SellerListingDefaults.empty(),
      );
    });

    test('parses a populated defaults row', () {
      final parsed = parseSellerListingDefaultsResponse([
        {
          'contact_phone': '  +373 690 00001  ',
          'telegram_username': 'seller_md',
          'whatsapp_enabled': true,
          'market_region': 'moldova',
          'city': 'Chișinău',
        },
      ]);
      expect(parsed.contactPhone, '+373 690 00001');
      expect(parsed.telegramUsername, 'seller_md');
      expect(parsed.whatsappEnabled, isTrue);
      expect(parsed.marketRegion, MarketRegion.moldova);
      expect(parsed.city, 'Chișinău');
    });

    test('defensive malformed parsing does not throw', () {
      expect(
        parseSellerListingDefaultsResponse('nope'),
        const SellerListingDefaults.empty(),
      );
      expect(
        parseSellerListingDefaultsResponse([
          {
            'contact_phone': 12345,
            'telegram_username': <String, Object?>{},
            'whatsapp_enabled': 'true',
            'market_region': 'mars',
            'city': 'Tiraspol',
          },
        ]),
        const SellerListingDefaults.empty(),
      );
      expect(
        parseSellerListingDefaultsResponse({
          'contact_phone': '',
          'whatsapp_enabled': false,
          'market_region': 'transnistria',
          'city': '  ',
        }),
        const SellerListingDefaults(marketRegion: MarketRegion.transnistria),
      );
    });
  });

  group('sellerListingDefaultsToUpsertParams', () {
    test('maps domain fields onto RPC parameter names', () {
      expect(
        sellerListingDefaultsToUpsertParams(
          const SellerListingDefaults(
            contactPhone: '+373 690 00001',
            telegramUsername: 'seller_md',
            whatsappEnabled: true,
            marketRegion: MarketRegion.moldova,
            city: 'Chișinău',
          ),
        ),
        {
          'p_contact_phone': '+373 690 00001',
          'p_telegram_username': 'seller_md',
          'p_whatsapp_enabled': true,
          'p_market_region': 'moldova',
          'p_city': 'Chișinău',
        },
      );
    });
  });

  group('SellerListingDefaultsRepositoryImpl', () {
    late _MockRemote remote;
    late SellerListingDefaultsRepositoryImpl repo;

    setUpAll(() {
      registerFallbackValue(const SellerListingDefaults.empty());
    });

    setUp(() {
      remote = _MockRemote();
      repo = SellerListingDefaultsRepositoryImpl(remote);
    });

    test('read failure becomes a safe empty defaults result', () async {
      when(
        () => remote.getMyListingDefaults(),
      ).thenThrow(ServerException('rpc down'));

      final result = await repo.getMyListingDefaults();
      expect(result, isA<Success<SellerListingDefaults>>());
      expect(
        (result as Success<SellerListingDefaults>).value,
        const SellerListingDefaults.empty(),
      );
    });

    test('save RPC is forwarded to the remote upsert', () async {
      const saved = SellerListingDefaults(
        contactPhone: '+373 690 00001',
        marketRegion: MarketRegion.transnistria,
        city: 'Tiraspol',
      );
      when(
        () => remote.upsertMyListingDefaults(saved),
      ).thenAnswer((_) async => saved);

      final result = await repo.saveMyListingDefaults(saved);
      expect((result as Success<SellerListingDefaults>).value, saved);
      verify(() => remote.upsertMyListingDefaults(saved)).called(1);
    });

    test('save failure is returned as FailureResult', () async {
      when(
        () => remote.upsertMyListingDefaults(any()),
      ).thenThrow(ServerException('denied'));

      final result = await repo.saveMyListingDefaults(
        const SellerListingDefaults.empty(),
      );
      expect(result, isA<FailureResult<SellerListingDefaults>>());
      expect(
        (result as FailureResult<SellerListingDefaults>).failure,
        isA<ServerFailure>(),
      );
    });
  });
}
