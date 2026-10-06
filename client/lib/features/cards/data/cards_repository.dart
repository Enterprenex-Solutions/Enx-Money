import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../auth/data/auth_repository.dart';
import '../models/card_model.dart';

class CardsRepository {
  static final CardsRepository _instance = CardsRepository._internal();
  factory CardsRepository() => _instance;
  CardsRepository._internal();

  final ApiClient _apiClient = ApiClient();
  final AuthRepository _authRepo = AuthRepository();

  /// Fetches cards belonging strictly to the currently authenticated user
  Future<List<UserCard>> getCards() async {
    final response = await _apiClient.get(ApiConfig.myCards);
    final data = response['data'] as Map<String, dynamic>?;
    if (data != null && data['cards'] is List) {
      final cardsList = data['cards'] as List<dynamic>;
      return cardsList.map((c) => UserCard.fromJson(c as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Issues a new card for the authenticated user
  Future<UserCard> createCard({
    String cardTier = 'Black Metal',
    String network = 'Visa',
    double limit = 500000.0,
    double balance = 150000.0,
  }) async {
    final user = _authRepo.currentUser ?? await _authRepo.getLocalUser();
    final holderName = user?.fullName.toUpperCase() ?? 'ENX MEMBER';

    final response = await _apiClient.post(
      ApiConfig.cards,
      body: {
        'cardTier': cardTier,
        'network': network,
        'limit': limit,
        'balance': balance,
        'cardHolderName': holderName,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final cardJson = data['card'] as Map<String, dynamic>;
    return UserCard.fromJson(cardJson);
  }

  /// Toggles freeze status for a user card
  Future<UserCard> toggleFreezeCard(String cardId) async {
    try {
      final response = await _apiClient.patch('${ApiConfig.cards}/$cardId/freeze');
      final data = response['data'] as Map<String, dynamic>;
      final cardJson = data['card'] as Map<String, dynamic>;
      return UserCard.fromJson(cardJson);
    } catch (e) {
      debugPrint('[CardsRepository] Error toggling freeze: $e');
      rethrow;
    }
  }

  /// Updates contactless and international controls
  Future<UserCard> updateCardControls(
    String cardId, {
    bool? isContactlessActive,
    bool? isInternationalActive,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.cards}/$cardId/controls',
        body: {
          if (isContactlessActive != null) 'isContactlessActive': isContactlessActive,
          if (isInternationalActive != null) 'isInternationalActive': isInternationalActive,
        },
      );
      final data = response['data'] as Map<String, dynamic>;
      final cardJson = data['card'] as Map<String, dynamic>;
      return UserCard.fromJson(cardJson);
    } catch (e) {
      debugPrint('[CardsRepository] Error updating card controls: $e');
      rethrow;
    }
  }
}
