import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  GetCurrentUser(this._repository);
  final AuthRepository _repository;

  Future<Result<AuthUser?>> call() => _repository.getCurrentUser();
}
