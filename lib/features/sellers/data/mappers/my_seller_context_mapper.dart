import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/my_seller_context.dart';
import '../../domain/entities/seller_type.dart';

MySellerContext mySellerContextFromRow(Map<String, dynamic> row) {
  return MySellerContext(
    sellerType: SellerType.fromWire(row['seller_type']),
    verifiedDealer: _parseBool(row['verified_dealer']),
  );
}

Map<String, dynamic> requireSellerContextRow(dynamic data, String rpc) {
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List && data.isNotEmpty && data.first is Map) {
    return Map<String, dynamic>.from(data.first as Map);
  }
  throw ServerException('Unexpected response from $rpc.');
}

bool _parseBool(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final key = raw?.toString().trim().toLowerCase();
  return key == 'true' || key == 't' || key == '1';
}
