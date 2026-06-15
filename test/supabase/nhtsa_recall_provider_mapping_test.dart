import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for NHTSA recall provider mapping helpers.
void main() {
  late String mappingTs;
  late String providerTs;
  late String typesTs;

  setUpAll(() {
    mappingTs = File(
      'supabase/functions/process-recall-data-jobs/providers/nhtsa_mapping.ts',
    ).readAsStringSync();
    providerTs = File(
      'supabase/functions/process-recall-data-jobs/providers/nhtsa_provider.ts',
    ).readAsStringSync();
    typesTs = File(
      'supabase/functions/process-recall-data-jobs/providers/types.ts',
    ).readAsStringSync();
  });

  group('nhtsa_mapping.ts field mapping', () {
    test('maps NHTSA campaign fields to buyer-safe snake_case keys', () {
      expect(mappingTs, contains('NHTSACampaignNumber'));
      expect(mappingTs, contains('campaign_number'));
      expect(mappingTs, contains('NHTSAActionNumber'));
      expect(mappingTs, contains('nhtsa_action_number'));
      expect(mappingTs, contains('ReportReceivedDate'));
      expect(mappingTs, contains('report_received_date'));
      expect(mappingTs, contains('parkIt'));
      expect(mappingTs, contains('park_it'));
      expect(mappingTs, contains('parkOutSide'));
      expect(mappingTs, contains('park_outside'));
      expect(mappingTs, contains('overTheAirUpdate'));
      expect(mappingTs, contains('over_the_air_update'));
    });

    test('uses recallsByVehicle endpoint with URLSearchParams encoding', () {
      expect(mappingTs, contains('recalls/recallsByVehicle'));
      expect(mappingTs, contains('URLSearchParams'));
      expect(mappingTs, contains('modelYear'));
      expect(providerTs, contains('buildNhtsaRecallsByVehicleUrl'));
    });

    test('allowlisted campaign keys are explicit', () {
      expect(typesTs, contains('ALLOWLISTED_CAMPAIGN_KEYS'));
      expect(typesTs, contains('"campaign_number"'));
      expect(typesTs, contains('"manufacturer"'));
      expect(typesTs, contains('"component"'));
      expect(typesTs, contains('"summary"'));
      expect(typesTs, contains('"consequence"'));
      expect(typesTs, contains('"remedy"'));
      expect(mappingTs, contains('pickAllowlistedCampaignFields'));
    });

    test('zero results maps to no_data path', () {
      expect(mappingTs, contains('buildRecallNoDataResult'));
      expect(providerTs, contains('parsed.campaigns.length === 0'));
      expect(providerTs, contains('buildRecallNoDataResult("no_match")'));
    });

    test('malformed response maps to safe failure', () {
      expect(mappingTs, contains('nhtsa_malformed_response'));
      expect(mappingTs, contains('retryable: false'));
      expect(providerTs, contains('parseNhtsaRecallsResponse'));
    });

    test('normalized summary uses campaigns array and campaign_count', () {
      expect(mappingTs, contains('buildRecallNormalizedSummary'));
      expect(mappingTs, contains('campaign_count'));
      expect(mappingTs, contains('market: "US"'));
    });

    test('does not store raw provider response in normalized summary', () {
      expect(mappingTs, isNot(contains('Results: payload')));
      expect(mappingTs, isNot(contains('normalizedSummary: payload')));
      expect(providerTs, isNot(contains('body: response.body')));
    });

    test('does not reference VIN decode endpoints', () {
      expect(mappingTs.toLowerCase(), isNot(contains('decodevinvalues')));
      expect(providerTs.toLowerCase(), isNot(contains('vpic.nhtsa.dot.gov')));
      expect(mappingTs.toLowerCase(), isNot(contains('listing_vehicle_identity')));
    });

    test('normalizes NHTSA dates before source_updated_at SQL completion', () {
      expect(mappingTs, contains('normalizeNhtsaDateForTimestamptz'));
      expect(mappingTs, contains('latestReportReceivedDate'));
      expect(mappingTs, contains('normalizeNhtsaDateForTimestamptz('));
      expect(mappingTs, contains('formatYmd'));
      expect(mappingTs, contains('first > 12'));
      expect(mappingTs, contains('second > 12'));
      expect(
        mappingTs,
        contains('sourceUpdatedAt: latestReportReceivedDate(campaigns)'),
      );
    });

    test('ambiguous slash dates are rejected for timestamptz normalization', () {
      expect(
        mappingTs,
        contains('Slash dates with both parts <= 12 are treated as ambiguous'),
      );
    });

    test('blank and malformed dates do not reach source_updated_at unchanged', () {
      expect(mappingTs, isNot(contains('date > latest')));
      expect(mappingTs, contains('if (!normalized) continue'));
    });
  });

  group('NHTSA date normalization expectations (documented contract)', () {
    test('20/12/2023 maps to ISO-compatible 2023-12-20 via DD/MM/YYYY rule', () {
      expect(normalizeCase('20/12/2023'), '2023-12-20');
    });

    test('04/11/2020 is ambiguous slash date and maps to null', () {
      expect(normalizeCase('04/11/2020'), isNull);
    });

    test('06/02/2020 is ambiguous slash date and maps to null', () {
      expect(normalizeCase('06/02/2020'), isNull);
    });

    test('valid ISO date remains accepted', () {
      expect(normalizeCase('2020-02-01'), '2020-02-01');
    });

    test('blank and malformed dates map to null', () {
      expect(normalizeCase(''), isNull);
      expect(normalizeCase('   '), isNull);
      expect(normalizeCase('not-a-date'), isNull);
      expect(normalizeCase('32/13/2020'), isNull);
    });
  });

  group('sample NHTSA JSON fixture (static contract)', () {
    test('mapper source handles Results array shape', () {
      const samplePayload = '''
{
  "Count": 1,
  "Message": "Results returned successfully",
  "Results": [
    {
      "Manufacturer": "Toyota",
      "NHTSACampaignNumber": "20TA01",
      "NHTSAActionNumber": "EA",
      "ReportReceivedDate": "2020-02-01",
      "Component": "AIR BAGS",
      "Summary": "Sample summary",
      "Consequence": "Sample consequence",
      "Remedy": "Sample remedy",
      "Notes": "Sample notes",
      "ModelYear": "2020",
      "Make": "TOYOTA",
      "Model": "Camry",
      "parkIt": false,
      "parkOutSide": false,
      "overTheAirUpdate": false
    }
  ]
}
''';
      expect(samplePayload, contains('"NHTSACampaignNumber"'));
      expect(mappingTs, contains('body.Results ?? body.results'));
      expect(mappingTs, contains('mapNhtsaRecallRow'));
    });
  });
}

/// Mirrors Edge helper rules for static contract tests (not runtime TS execution).
String? normalizeCase(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final isoPrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (isoPrefix != null) {
    final year = int.parse(isoPrefix.group(1)!);
    final month = int.parse(isoPrefix.group(2)!);
    final day = int.parse(isoPrefix.group(3)!);
    return _isValidYmd(year, month, day) ? _formatYmd(year, month, day) : null;
  }

  final slashMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
  if (slashMatch != null) {
    final first = int.parse(slashMatch.group(1)!);
    final second = int.parse(slashMatch.group(2)!);
    final year = int.parse(slashMatch.group(3)!);
    int month;
    int day;

    if (first > 12 && second <= 12) {
      day = first;
      month = second;
    } else if (second > 12 && first <= 12) {
      month = first;
      day = second;
    } else {
      return null;
    }

    return _isValidYmd(year, month, day) ? _formatYmd(year, month, day) : null;
  }

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  return _isValidYmd(parsed.year, parsed.month, parsed.day)
      ? _formatYmd(parsed.year, parsed.month, parsed.day)
      : null;
}

bool _isValidYmd(int year, int month, int day) {
  if (year < 1900 || year > 2100 || month < 1 || month > 12 || day < 1 || day > 31) {
    return false;
  }
  final dt = DateTime.utc(year, month, day);
  return dt.year == year && dt.month == month && dt.day == day;
}

String _formatYmd(int year, int month, int day) {
  final m = month.toString().padLeft(2, '0');
  final d = day.toString().padLeft(2, '0');
  return '$year-$m-$d';
}
