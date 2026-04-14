import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app.dart';
import '../app/router.dart';
import '../core/security/app_role_providers.dart';
import '../features/admin/data/admin_audit_repository.dart';
import '../features/admin/data/admin_analytics_repository.dart';
import '../features/admin/data/admin_business_submissions_repository.dart';
import '../features/admin/data/admin_businesses_repository.dart';
import '../features/admin/data/admin_claims_repository.dart';
import '../features/admin/data/admin_observability_repository.dart';
import '../features/admin/data/admin_price_suggestions_repository.dart';
import '../features/admin/data/admin_queue_repository.dart';
import '../features/admin/data/admin_receipt_submissions_repository.dart';
import '../features/admin/data/admin_repository.dart';
import '../features/admin/data/admin_reports_repository.dart';
import '../features/admin/data/admin_search_repository.dart';
import '../features/admin/domain/admin_access_provider.dart';
import '../features/admin/domain/admin_audit_models.dart';
import '../features/admin/domain/admin_growth_models.dart';
import '../features/admin/domain/admin_kpi_models.dart';
import '../features/admin/domain/admin_models.dart';
import '../features/admin/domain/admin_observability_models.dart';
import '../features/admin/domain/admin_offline_mutation_alert_settings.dart';
import '../features/admin/domain/admin_queue_models.dart';
import '../features/admin/domain/admin_realtime_lifecycle_provider.dart';
import '../features/admin/domain/admin_receipt_submission.dart';
import '../features/admin/domain/admin_search_models.dart';
import '../features/auth/domain/auth_providers.dart';
import '../data/repositories/business_amenities_repository.dart';
import '../data/repositories/business_meal_card_providers_repository.dart';
import '../data/repositories/owner_claim_repository.dart';
import '../features/owner_businesses/data/owner_business_repository.dart';
import '../features/owner_dashboard/domain/owner_growth_provider.dart';
import '../features/owner_dashboard/domain/owner_kpi_provider.dart';
import '../features/owner_dashboard/domain/owner_moat_provider.dart';
import '../features/owner_dashboard/domain/owner_quality_score_provider.dart';
import '../features/owner_dashboard/ui/owner_dashboard_sections.dart';
import '../features/owner_analytics/data/owner_analytics_repository.dart';
import '../features/owner_analytics/domain/owner_analytics_models.dart';
import '../features/owner_businesses/domain/owner_business_models.dart';
import '../features/owner_businesses/domain/owner_business_providers.dart';
import '../features/owner_businesses/domain/owner_business_state.dart';
import '../features/business/domain/business_amenity.dart';
import '../features/business/domain/meal_card_provider_option.dart';
import '../features/owner_menu_management/data/owner_menu_repository.dart';
import '../features/owner_menu_management/data/owner_menu_safety_repository.dart';
import '../features/owner_menu_management/domain/owner_menu_models.dart';
import '../features/owner_menu_management/domain/owner_menu_safety_models.dart';
import '../features/owner_onboarding/domain/owner_onboarding_models.dart';
import '../features/owner_onboarding/domain/owner_onboarding_providers.dart';
import '../features/owner_onboarding/data/owner_onboarding_repository.dart';
import '../features/owner_monetization/data/owner_monetization_repository.dart';
import '../features/owner_price_suggestions/data/owner_price_suggestions_repository.dart';
import '../features/owner_price_suggestions/domain/owner_price_suggestion_models.dart';
import '../features/owner_suspended/data/owner_suspended_repository.dart';
import '../features/owner_suspended/domain/owner_suspended_models.dart';
import '../features/owner_team/data/owner_team_repository.dart';
import '../features/owner_team/domain/owner_team_models.dart';
import '../features/group_requests/data/group_requests_repository.dart';
import '../features/group_requests/domain/group_request_models.dart';
import '../core/security/business_rbac.dart';
import '../domain/models/owner_claim.dart';

enum _SmokeAuthMode { admin, owner, none }

class PanelSmokeHarness extends StatelessWidget {
  const PanelSmokeHarness({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final session = _resolveSession(uri);
    final role = _resolveRole(uri);
    final smokeOnboardingRepository = _buildSmokeOwnerOnboardingRepository(uri);

    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(
            AuthState(AuthChangeEvent.initialSession, session),
          ),
        ),
        sessionProvider.overrideWith((ref) => session),
        appRoleProvider.overrideWith((ref) async => role),
        adminAccessProvider.overrideWith(
          (ref) async => role == AppRole.admin,
        ),
        adminRealtimeLifecycleProvider.overrideWith((ref) {}),
        hasBusinessPermissionProvider.overrideWith(
          (ref, request) async => request.$1 == _ownerBusinesses.first.businessId,
        ),
        selectedOwnerBusinessIdProvider.overrideWith(
          (ref) => _ownerBusinesses.first.businessId,
        ),
        ownerBusinessesProvider.overrideWith((ref) async => _ownerBusinesses),
        ownerKpiSummaryProvider.overrideWith(
          (ref, businessId) async => _matchesOwnerBusiness(businessId)
              ? const OwnerKpiSummary(
                  businessViews: 1280,
                  outboundClicks: 96,
                  directionsClicks: 34,
                  searchImpressions: 4120,
                )
              : null,
        ),
        ownerGrowthSummaryProvider.overrideWith(
          (ref, businessId) async => null,
        ),
        ownerQualityScoreProvider.overrideWith(
          (ref, businessId) async => _matchesOwnerBusiness(businessId)
              ? const OwnerQualityScore(
                  score: 86,
                  tips: <String>[
                    'Foto kanitlarini son fiyat degisiklikleriyle birlikte guncel tut.',
                  ],
                  breakdown: <String, dynamic>{
                    'menu_freshness': 92,
                    'price_accuracy': 81,
                  },
                )
              : null,
        ),
        ownerMoatSummaryProvider.overrideWith(
          (ref, businessId) async => _matchesOwnerBusiness(businessId)
              ? OwnerMoatSummary(
                  businessTrustScore: 88,
                  menuFreshnessScore: 90,
                  priceAccuracyScore: 82,
                  contributionTrustScore: 76,
                  uniqueValidators: 14,
                  lastPriceVerificationAt: DateTime(2026, 3, 8, 18, 30),
                  evidenceRate: 0.84,
                  contributionQualityRate: 0.78,
                  menuViewsToday: 41,
                  districtRank: 3,
                )
              : null,
        ),
        ownerAnalyticsRepositoryProvider.overrideWithValue(
          _SmokeOwnerAnalyticsRepository(),
        ),
        ownerSponsorshipCatalogProvider.overrideWith(
          (ref, businessId) async => _matchesOwnerBusiness(businessId)
              ? <OwnerSponsorshipCatalogItem>[
                  OwnerSponsorshipCatalogItem(
                    packageId: 'pkg-discovery-1',
                    packageName: 'Discovery Boost',
                    surface: 'discovery',
                    durationDays: 14,
                    priceDisplay: '7.500 TRY',
                    priceCents: 750000,
                    currencyCode: 'TRY',
                    inventoryLimit: 8,
                    surfaceLiveUnits: 5,
                    surfaceOpenSlots: 3,
                    businessLiveUnits: 0,
                    businessImpressions30d: 18200,
                    businessUniqueUsers30d: 4200,
                    latestLeadStatus: 'new',
                  ),
                ]
              : const <OwnerSponsorshipCatalogItem>[],
        ),
        ownerBusinessRepositoryProvider.overrideWithValue(
          _smokeOwnerBusinessRepository,
        ),
        ownerClaimRepositoryProvider.overrideWithValue(
          _SmokeOwnerClaimRepository(),
        ),
        businessAmenitiesRepositoryProvider.overrideWithValue(
          _SmokeBusinessAmenitiesRepository(),
        ),
        businessMealCardProvidersRepositoryProvider.overrideWithValue(
          _SmokeBusinessMealCardProvidersRepository(),
        ),
        ownerOnboardingRepositoryProvider.overrideWithValue(
          smokeOnboardingRepository,
        ),
        ownerTeamRepositoryProvider.overrideWithValue(_smokeOwnerTeamRepository),
        ownerPriceSuggestionsRepositoryProvider.overrideWithValue(
          _smokeOwnerPriceSuggestionsRepository,
        ),
        ownerMenuRepositoryProvider.overrideWithValue(
          _smokeOwnerMenuRepository,
        ),
        ownerMenuSafetyRepositoryProvider.overrideWithValue(
          _smokeOwnerMenuSafetyRepository,
        ),
        ownerSuspendedRepositoryProvider.overrideWithValue(
          _smokeOwnerSuspendedRepository,
        ),
        groupRequestsRepositoryProvider.overrideWithValue(
          _smokeGroupRequestsRepository,
        ),
        ownerMonetizationRepositoryProvider.overrideWithValue(
          _SmokeOwnerMonetizationRepository(),
        ),
        adminSearchRepositoryProvider.overrideWithValue(
          _SmokeAdminSearchRepository(),
        ),
        adminRepositoryProvider.overrideWithValue(_SmokeAdminRepository()),
        adminAnalyticsRepositoryProvider.overrideWithValue(
          _SmokeAdminAnalyticsRepository(),
        ),
        adminQueueRepositoryProvider.overrideWithValue(
          _SmokeAdminQueueRepository(),
        ),
        adminBusinessSubmissionsRepositoryProvider.overrideWithValue(
          _SmokeAdminBusinessSubmissionsRepository(),
        ),
        adminClaimsRepositoryProvider.overrideWithValue(
          _SmokeAdminClaimsRepository(),
        ),
        adminPriceSuggestionsRepositoryProvider.overrideWithValue(
          _SmokeAdminPriceSuggestionsRepository(),
        ),
        adminAuditRepositoryProvider.overrideWithValue(
          _SmokeAdminAuditRepository(),
        ),
        adminReportsRepositoryProvider.overrideWithValue(
          _SmokeAdminReportsRepository(),
        ),
        adminBusinessesRepositoryProvider.overrideWithValue(
          _SmokeAdminBusinessesRepository(),
        ),
        adminReceiptSubmissionsRepositoryProvider.overrideWithValue(
          _SmokeAdminReceiptSubmissionsRepository(),
        ),
        adminObservabilityRepositoryProvider.overrideWithValue(
          _SmokeAdminObservabilityRepository(),
        ),
        appRouterProvider.overrideWith(
          (ref) => buildAppRouter(ref, initialLocation: _initialLocation(uri)),
        ),
      ],
      child: const YeedoyApp(),
    );
  }
}

bool _matchesOwnerBusiness(String? businessId) =>
    businessId != null && businessId.trim() == _ownerBusinesses.first.businessId;

_SmokeOwnerOnboardingRepository _buildSmokeOwnerOnboardingRepository(Uri uri) {
  final isOnboardingRoute = uri.path == '/owner/onboarding';
  return _SmokeOwnerOnboardingRepository(
    initialStepCompleted: isOnboardingRoute ? 0 : 5,
  );
}

String _initialLocation(Uri uri) {
  final path = uri.path.trim().isEmpty ? '/' : uri.path;
  if (uri.hasQuery) {
    return '$path?${uri.query}';
  }
  return path;
}

Session? _resolveSession(Uri uri) {
  final mode = _resolveMode(uri);
  return switch (mode) {
    _SmokeAuthMode.admin => _fakeSession(
      email: 'admin@yeedoy.com',
      role: 'admin',
    ),
    _SmokeAuthMode.owner => _fakeSession(
      email: 'owner@yeedoy.com',
      role: 'owner',
    ),
    _SmokeAuthMode.none => null,
  };
}

AppRole _resolveRole(Uri uri) {
  final mode = _resolveMode(uri);
  return switch (mode) {
    _SmokeAuthMode.admin => AppRole.admin,
    _SmokeAuthMode.owner => AppRole.owner,
    _SmokeAuthMode.none => AppRole.user,
  };
}

_SmokeAuthMode _resolveMode(Uri uri) {
  final auth = (uri.queryParameters['auth'] ?? '').trim().toLowerCase();
  if (auth == 'admin') return _SmokeAuthMode.admin;
  if (auth == 'owner') return _SmokeAuthMode.owner;
  if (auth == 'none') return _SmokeAuthMode.none;

  final path = uri.path;
  if (path == '/isletme-giris' || path == '/login') {
    return _SmokeAuthMode.none;
  }
  if (path == '/admin' || path.startsWith('/admin/')) {
    return _SmokeAuthMode.admin;
  }
  return _SmokeAuthMode.owner;
}

Session _fakeSession({required String email, required String role}) {
  return Session(
    accessToken: 'smoke-access-token',
    tokenType: 'bearer',
    refreshToken: 'smoke-refresh-token',
    user: User(
      id: 'smoke-user-$role',
      appMetadata: {'role': role},
      userMetadata: {'role': role},
      aud: 'authenticated',
      email: email,
      role: role,
      createdAt: '2026-03-09T00:00:00.000Z',
      updatedAt: '2026-03-09T00:00:00.000Z',
      emailConfirmedAt: '2026-03-09T00:00:00.000Z',
    ),
  );
}

final List<OwnerBusiness> _ownerBusinesses = <OwnerBusiness>[
  OwnerBusiness(
    businessId: '11111111-1111-4111-8111-111111111111',
    businessName: 'Cafe Nova',
    city: 'Istanbul',
    district: 'Kadikoy',
    claimStatus: 'approved',
    claimedAt: DateTime(2026, 3, 9),
  ),
];

final _SmokeOwnerBusinessRepository _smokeOwnerBusinessRepository =
    _SmokeOwnerBusinessRepository();
final _SmokeOwnerTeamRepository _smokeOwnerTeamRepository =
    _SmokeOwnerTeamRepository();
final _SmokeOwnerPriceSuggestionsRepository _smokeOwnerPriceSuggestionsRepository =
    _SmokeOwnerPriceSuggestionsRepository();
final _SmokeOwnerMenuRepository _smokeOwnerMenuRepository =
    _SmokeOwnerMenuRepository();
final _SmokeOwnerMenuSafetyRepository _smokeOwnerMenuSafetyRepository =
    _SmokeOwnerMenuSafetyRepository();
final _SmokeOwnerSuspendedRepository _smokeOwnerSuspendedRepository =
    _SmokeOwnerSuspendedRepository();
final _SmokeGroupRequestsRepository _smokeGroupRequestsRepository =
    _SmokeGroupRequestsRepository();

class _SmokeOwnerBusinessRepository extends OwnerBusinessRepository {
  _SmokeOwnerBusinessRepository()
    : _submissions = <BusinessSubmission>[
        BusinessSubmission(
          id: 'submission-1',
          name: 'Cafe Nova Kadikoy',
          city: 'Istanbul',
          district: 'Kadikoy',
          category: 'Cafe',
          address: 'Moda Cad. 10',
          phone: '02120000000',
          website: 'https://cafenova.example',
          status: 'pending',
          adminNote: null,
          createdAt: DateTime(2026, 3, 9, 12),
        ),
      ],
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final List<BusinessSubmission> _submissions;

  @override
  Future<String> submitNewBusiness({
    required String name,
    required String city,
    required String district,
    required String category,
    required String address,
    String? phone,
    String? website,
  }) async {
    _submissions.insert(
      0,
      BusinessSubmission(
        id: 'submission-${_submissions.length + 1}',
        name: name,
        city: city,
        district: district,
        category: category,
        address: address,
        phone: phone,
        website: website,
        status: 'pending',
        adminNote: null,
        createdAt: DateTime(2026, 3, 10, 12),
      ),
    );
    return 'smoke-request-${_submissions.length}';
  }

  @override
  Future<List<BusinessSubmission>> listMySubmissions({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final filtered = (status == null || status.trim().isEmpty)
        ? _submissions
        : _submissions.where((item) => item.status == status).toList();
    final safeOffset = offset.clamp(0, filtered.length);
    final end = (safeOffset + limit).clamp(0, filtered.length);
    return filtered.sublist(safeOffset, end);
  }

  @override
  Future<void> updateCommerceLinks({
    required String businessId,
    String? reservationUrl,
    String? orderYemeksepetiUrl,
    String? orderTrendyolgoUrl,
    String? orderGetirUrl,
  }) async {}
}

class _SmokeOwnerClaimRepository extends OwnerClaimRepository {
  _SmokeOwnerClaimRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<List<OwnerClaim>> fetchMyClaims({int? limit, int? offset}) async {
    return <OwnerClaim>[
      OwnerClaim(
        id: 'claim-1',
        businessId: _ownerBusinesses.first.businessId,
        status: 'approved',
        createdAt: DateTime(2026, 3, 9, 8),
      ),
    ];
  }

  @override
  Future<Map<String, String>> fetchBusinessNamesByIds(List<String> ids) async {
    return <String, String>{
      _ownerBusinesses.first.businessId: _ownerBusinesses.first.businessName,
    };
  }
}

class _SmokeBusinessAmenitiesRepository extends BusinessAmenitiesRepository {
  _SmokeBusinessAmenitiesRepository()
    : _selectedKeys = <String>{'wifi', 'outdoor'},
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final Set<String> _selectedKeys;

  static final List<BusinessAmenity> _allAmenities = <BusinessAmenity>[
    BusinessAmenity(id: 'amenity-1', key: 'wifi', label: 'Wi-Fi', icon: 'wifi'),
    BusinessAmenity(
      id: 'amenity-2',
      key: 'outdoor',
      label: 'Açık Alan',
      icon: 'deck',
    ),
    BusinessAmenity(
      id: 'amenity-3',
      key: 'credit_card',
      label: 'Kart',
      icon: 'credit_card',
    ),
  ];

  @override
  Future<List<BusinessAmenity>> listAllAmenities() async {
    return _allAmenities;
  }

  @override
  Future<List<BusinessAmenity>> listBusinessAmenities(
    String businessId, {
    bool force = false,
  }) async {
    if (!_matchesOwnerBusiness(businessId)) return const <BusinessAmenity>[];
    return _allAmenities
        .where((item) => _selectedKeys.contains(item.key))
        .toList(growable: false);
  }

  @override
  Future<void> updateBusinessAmenities({
    required String businessId,
    required List<String> amenityKeys,
  }) async {
    _selectedKeys
      ..clear()
      ..addAll(amenityKeys);
  }
}

class _SmokeBusinessMealCardProvidersRepository
    extends BusinessMealCardProvidersRepository {
  _SmokeBusinessMealCardProvidersRepository()
    : _selectedKeys = <String>{'multinet', 'edenred'},
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final Set<String> _selectedKeys;

  static final List<MealCardProviderOption> _allProviders =
      <MealCardProviderOption>[
        MealCardProviderOption(
          id: 'meal-1',
          key: 'multinet',
          name: 'MultiNet',
          assetName: 'meal_card_multinet.png',
          sortOrder: 10,
        ),
        MealCardProviderOption(
          id: 'meal-2',
          key: 'edenred',
          name: 'Edenred',
          assetName: 'meal_card_edenred.png',
          sortOrder: 20,
        ),
        MealCardProviderOption(
          id: 'meal-3',
          key: 'pluxee',
          name: 'Pluxee',
          assetName: 'meal_card_pluxee.png',
          sortOrder: 30,
        ),
      ];

  @override
  Future<List<MealCardProviderOption>> listAllProviders() async {
    return _allProviders;
  }

  @override
  Future<List<MealCardProviderOption>> listBusinessProviders(
    String businessId, {
    bool force = false,
  }) async {
    if (!_matchesOwnerBusiness(businessId)) {
      return const <MealCardProviderOption>[];
    }
    return _allProviders
        .where((item) => _selectedKeys.contains(item.key))
        .toList(growable: false);
  }

  @override
  Future<void> updateBusinessProviders({
    required String businessId,
    required List<String> providerKeys,
  }) async {
    _selectedKeys
      ..clear()
      ..addAll(providerKeys);
  }
}

class _SmokeOwnerOnboardingRepository extends OwnerOnboardingRepository {
  _SmokeOwnerOnboardingRepository({required int initialStepCompleted})
    : _progress = OwnerOnboardingProgress(
        stepCompleted: initialStepCompleted,
        updatedAt: DateTime(2026, 3, 10, 12),
      ),
      _profile = const OwnerBusinessProfile(
        logoUrl: '',
        coverUrl: '',
      ),
      _hours = null,
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  OwnerOnboardingProgress _progress;
  OwnerBusinessProfile _profile;
  OwnerBusinessHours? _hours;

  @override
  Future<OwnerOnboardingProgress> fetchProgress(String businessId) async {
    return _progress;
  }

  @override
  Future<void> setProgress(String businessId, int stepCompleted) async {
    _progress = OwnerOnboardingProgress(
      stepCompleted: stepCompleted,
      updatedAt: DateTime(2026, 3, 10, 12),
    );
  }

  @override
  Future<OwnerBusinessProfile> fetchBusinessProfile(String businessId) async {
    return _profile;
  }

  @override
  Future<void> updateBusinessProfile({
    required String businessId,
    required String logoUrl,
    required String coverUrl,
  }) async {
    _profile = OwnerBusinessProfile(logoUrl: logoUrl, coverUrl: coverUrl);
  }

  @override
  Future<OwnerBusinessHours?> fetchBusinessHours(String businessId) async {
    return _hours;
  }

  @override
  Future<void> upsertBusinessHours({
    required String businessId,
    required String openTime,
    required String closeTime,
  }) async {
    _hours = OwnerBusinessHours(openTime: openTime, closeTime: closeTime);
  }

  @override
  Future<OwnerOnboardingMenuStatus> fetchMenuStatus(String businessId) async {
    return const OwnerOnboardingMenuStatus(
      menuCount: 1,
      sectionCount: 1,
      itemCount: 2,
      primaryMenuId: 'menu-1',
      primaryMenuTitle: 'Cafe Nova Menu',
    );
  }

  @override
  Future<OwnerOnboardingMenuPreview?> fetchMenuPreview(String businessId) async {
    return const OwnerOnboardingMenuPreview(
      menuId: 'menu-1',
      menuTitle: 'Cafe Nova Menu',
      sections: <OwnerOnboardingMenuSection>[
        OwnerOnboardingMenuSection(
          id: 'section-1',
          title: 'Kahveler',
          items: <OwnerOnboardingMenuItem>[
            OwnerOnboardingMenuItem(
              name: 'Latte',
              description: 'Çift shot latte',
              priceCents: 22000,
              currency: 'TRY',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<OwnerBusinessProfileScore> fetchProfileScore(String businessId) async {
    return const OwnerBusinessProfileScore(
      score: 72,
      breakdown: <String, dynamic>{
        'logo': 0,
        'cover': 0,
        'hours': 0,
      },
    );
  }
}

class _SmokeOwnerTeamRepository extends OwnerTeamRepository {
  _SmokeOwnerTeamRepository()
    : _members = <OwnerTeamMember>[
        OwnerTeamMember(
          membershipId: 'membership-1',
          userId: 'staff-1',
          email: 'barista@cafenova.example',
          role: OwnerTeamRole.manager,
          scope: TeamAccessScope.thisBusiness,
          status: 'active',
          source: 'direct',
          createdAt: DateTime(2026, 3, 9, 9),
        ),
      ],
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final List<OwnerTeamMember> _members;

  @override
  Future<List<OwnerTeamMember>> listMembers(String businessId) async {
    if (!_matchesOwnerBusiness(businessId)) return const <OwnerTeamMember>[];
    return List<OwnerTeamMember>.from(_members);
  }

  @override
  Future<void> inviteOrAssign({
    required String businessId,
    required String email,
    required OwnerTeamRole role,
    required TeamAccessScope scope,
  }) async {
    if (!_matchesOwnerBusiness(businessId)) return;
    _members.insert(
      0,
      OwnerTeamMember(
        membershipId: 'membership-${_members.length + 1}',
        userId: null,
        email: email.trim(),
        role: role,
        scope: scope,
        status: 'pending',
        source: 'direct',
        createdAt: DateTime(2026, 3, 10, 12),
      ),
    );
  }

  @override
  Future<void> updateMember({
    required String businessId,
    required String membershipId,
    required OwnerTeamRole role,
    required TeamAccessScope scope,
  }) async {
    final index = _members.indexWhere((item) => item.membershipId == membershipId);
    if (index < 0) return;
    final current = _members[index];
    _members[index] = OwnerTeamMember(
      membershipId: current.membershipId,
      userId: current.userId,
      email: current.email,
      role: role,
      scope: scope,
      status: current.status,
      source: current.source,
      createdAt: current.createdAt,
      acceptedAt: current.acceptedAt,
    );
  }

  @override
  Future<void> revokeMember({
    required String businessId,
    required String membershipId,
  }) async {
    _members.removeWhere((item) => item.membershipId == membershipId);
  }
}

class _SmokeOwnerPriceSuggestionsRepository
    extends OwnerPriceSuggestionsRepository {
  _SmokeOwnerPriceSuggestionsRepository()
    : _items = <OwnerPriceSuggestionItem>[
        OwnerPriceSuggestionItem(
          id: 'owner-price-1',
          status: 'pending',
          menuItemId: 'menu-item-1',
          menuItemName: 'Latte',
          currentPriceCents: 21000,
          suggestedPriceCents: 22000,
          createdAt: DateTime(2026, 3, 9, 10),
          ageHours: 3,
          qualityConfidence: 0.84,
          anomalyScore: 0.12,
          anomalyFlags: const <String>[],
          conflictState: 'none',
          conflictVariants24h: 1,
        ),
      ],
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final List<OwnerPriceSuggestionItem> _items;

  @override
  Future<List<OwnerPriceSuggestionItem>> listSuggestions({
    required String businessId,
    required String status,
    int limit = 20,
    int offset = 0,
  }) async {
    if (!_matchesOwnerBusiness(businessId)) {
      return const <OwnerPriceSuggestionItem>[];
    }
    final filtered = status.trim().isEmpty
        ? _items
        : _items.where((item) => item.status == status).toList();
    final safeOffset = offset.clamp(0, filtered.length);
    final end = (safeOffset + limit).clamp(0, filtered.length);
    return filtered.sublist(safeOffset, end);
  }

  @override
  Future<void> approve(String suggestionId) async {
    final index = _items.indexWhere((item) => item.id == suggestionId);
    if (index < 0) return;
    final current = _items[index];
    _items[index] = OwnerPriceSuggestionItem(
      id: current.id,
      status: 'approved',
      menuItemId: current.menuItemId,
      menuItemName: current.menuItemName,
      currentPriceCents: current.currentPriceCents,
      suggestedPriceCents: current.suggestedPriceCents,
      createdAt: current.createdAt,
      ageHours: current.ageHours,
      qualityConfidence: current.qualityConfidence,
      anomalyScore: current.anomalyScore,
      anomalyFlags: current.anomalyFlags,
      conflictState: current.conflictState,
      conflictVariants24h: current.conflictVariants24h,
    );
  }

  @override
  Future<void> reject({
    required String suggestionId,
    required String note,
  }) async {
    final index = _items.indexWhere((item) => item.id == suggestionId);
    if (index < 0) return;
    final current = _items[index];
    _items[index] = OwnerPriceSuggestionItem(
      id: current.id,
      status: 'rejected',
      menuItemId: current.menuItemId,
      menuItemName: current.menuItemName,
      currentPriceCents: current.currentPriceCents,
      suggestedPriceCents: current.suggestedPriceCents,
      createdAt: current.createdAt,
      ageHours: current.ageHours,
      qualityConfidence: current.qualityConfidence,
      anomalyScore: current.anomalyScore,
      anomalyFlags: current.anomalyFlags,
      conflictState: current.conflictState,
      conflictVariants24h: current.conflictVariants24h,
    );
  }
}

class _SmokeOwnerAnalyticsRepository extends OwnerAnalyticsRepository {
  _SmokeOwnerAnalyticsRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<OwnerAnalyticsSnapshot> fetchAnalytics({
    required String businessId,
    required int days,
    required bool compareBranches,
  }) async {
    return OwnerAnalyticsSnapshot(
      summary: const OwnerAnalyticsSummary(
        qrScans: 42,
        menuOpens: 128,
        categoryViews: 76,
        itemClicks: 54,
        sourceTotal: 140,
      ),
      daily: const <OwnerAnalyticsDailyPoint>[
        OwnerAnalyticsDailyPoint(
          day: '2026-03-08',
          qrScans: 10,
          menuOpens: 32,
          menuViews: 24,
          itemClicks: 14,
        ),
        OwnerAnalyticsDailyPoint(
          day: '2026-03-09',
          qrScans: 14,
          menuOpens: 45,
          menuViews: 31,
          itemClicks: 20,
        ),
      ],
      topItems: const <OwnerAnalyticsCountRow>[
        OwnerAnalyticsCountRow(label: 'Latte', count: 22),
        OwnerAnalyticsCountRow(label: 'Cold Brew', count: 14),
      ],
      topCategories: const <OwnerAnalyticsCountRow>[
        OwnerAnalyticsCountRow(label: 'Kahveler', count: 36),
      ],
      sourceBreakdown: const <OwnerAnalyticsCountRow>[
        OwnerAnalyticsCountRow(label: 'qr_short_link', count: 41),
        OwnerAnalyticsCountRow(label: 'normal', count: 87),
      ],
      branchCompare: const <OwnerAnalyticsBranchRow>[],
    );
  }
}

class _SmokeOwnerMenuRepository extends OwnerMenuRepository {
  _SmokeOwnerMenuRepository()
    : _menus = <OwnerMenu>[
        OwnerMenu(
          id: 'menu-1',
          businessId: _ownerBusinesses.first.businessId,
          title: 'Cafe Nova Ana Menü',
          status: 'draft',
          createdAt: DateTime(2026, 3, 9, 10),
          kind: 'all-day',
        ),
      ],
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final List<OwnerMenu> _menus;

  @override
  Future<List<OwnerMenu>> listMenus({required String businessId}) async {
    if (!_matchesOwnerBusiness(businessId)) return const <OwnerMenu>[];
    return List<OwnerMenu>.from(_menus);
  }

  @override
  Future<OwnerRpcResult> createMenu({
    required String businessId,
    required String title,
    String? kind,
    DateTime? activeFrom,
    DateTime? activeTo,
  }) async {
    _menus.insert(
      0,
      OwnerMenu(
        id: 'menu-${_menus.length + 1}',
        businessId: businessId,
        title: title.trim(),
        status: 'draft',
        createdAt: DateTime(2026, 3, 10, 12),
        kind: (kind ?? '').trim().isEmpty ? null : kind!.trim(),
        activeFrom: activeFrom?.toIso8601String(),
        activeTo: activeTo?.toIso8601String(),
      ),
    );
    return OwnerRpcResult(ok: true, id: _menus.first.id);
  }

  @override
  Future<OwnerRpcResult> archiveMenu({required String menuId}) async {
    final index = _menus.indexWhere((item) => item.id == menuId);
    if (index >= 0) {
      final current = _menus[index];
      _menus[index] = OwnerMenu(
        id: current.id,
        businessId: current.businessId,
        title: current.title,
        status: 'archived',
        createdAt: current.createdAt,
        version: current.version,
        updatedAt: DateTime(2026, 3, 10, 12),
        source: current.source,
        confidenceScore: current.confidenceScore,
        kind: current.kind,
        activeFrom: current.activeFrom,
        activeTo: current.activeTo,
      );
    }
    return OwnerRpcResult(ok: true, id: menuId);
  }

  @override
  Future<OwnerRpcResult> publishMenu({required String menuId}) async {
    final index = _menus.indexWhere((item) => item.id == menuId);
    if (index >= 0) {
      final current = _menus[index];
      _menus[index] = OwnerMenu(
        id: current.id,
        businessId: current.businessId,
        title: current.title,
        status: 'published',
        createdAt: current.createdAt,
        version: current.version,
        updatedAt: DateTime(2026, 3, 10, 12),
        source: current.source,
        confidenceScore: current.confidenceScore,
        kind: current.kind,
        activeFrom: current.activeFrom,
        activeTo: current.activeTo,
      );
    }
    return OwnerRpcResult(ok: true, id: menuId);
  }

  @override
  Future<List<OwnerMenuSection>> listSections({required String menuId}) async {
    return <OwnerMenuSection>[
      OwnerMenuSection(
        id: 'section-1',
        menuId: menuId,
        title: 'Kahveler',
        sortOrder: 1,
      ),
    ];
  }

  @override
  Future<List<OwnerMenuItem>> listItems({
    required String sectionId,
    int limit = 50,
    int offset = 0,
  }) async {
    return <OwnerMenuItem>[
      OwnerMenuItem(
        id: 'item-1',
        sectionId: sectionId,
        businessId: _ownerBusinesses.first.businessId,
        name: 'Latte',
        status: 'active',
        priceCents: 22000,
        currency: 'TRY',
      ),
    ];
  }
}

class _SmokeOwnerMenuSafetyRepository extends OwnerMenuSafetyRepository {
  _SmokeOwnerMenuSafetyRepository()
    : _entries = <OwnerTrashEntry>[
        OwnerTrashEntry(
          entityType: OwnerTrashEntityType.item,
          entityId: 'trash-item-1',
          title: 'Eski Latte',
          subtitle: 'Arsivlenen urun',
          occurredAt: DateTime(2026, 3, 9, 14),
          menuId: 'menu-1',
          menuItemId: 'item-legacy-1',
        ),
      ],
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final List<OwnerTrashEntry> _entries;

  @override
  Future<List<OwnerTrashEntry>> listTrash({required String businessId}) async {
    if (!_matchesOwnerBusiness(businessId)) return const <OwnerTrashEntry>[];
    return List<OwnerTrashEntry>.from(_entries);
  }

  @override
  Future<void> restoreTrashEntry(OwnerTrashEntry entry) async {
    _entries.removeWhere((item) => item.entityId == entry.entityId);
  }

  @override
  Future<void> forceDeleteTrashEntry(OwnerTrashEntry entry) async {
    _entries.removeWhere((item) => item.entityId == entry.entityId);
  }
}

class _SmokeOwnerSuspendedRepository extends OwnerSuspendedRepository {
  _SmokeOwnerSuspendedRepository()
    : _items = <OwnerSuspendedClaimItem>[
        OwnerSuspendedClaimItem(
          id: 'suspended-1',
          status: 'pending',
          claimantName: 'Ayse Demir',
          amountCents: 18000,
          currency: 'TRY',
          mealMessage: 'Bir corba ve ana yemek',
          createdAt: DateTime(2026, 3, 10, 10),
          ageHours: 2,
        ),
      ],
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final List<OwnerSuspendedClaimItem> _items;

  @override
  Future<List<OwnerSuspendedClaimItem>> listClaims({
    required String businessId,
    required String status,
    int limit = 20,
    int offset = 0,
  }) async {
    if (!_matchesOwnerBusiness(businessId)) {
      return const <OwnerSuspendedClaimItem>[];
    }
    final filtered = status.trim().isEmpty
        ? _items
        : _items.where((item) => item.status == status).toList();
    final safeOffset = offset.clamp(0, filtered.length);
    final end = (safeOffset + limit).clamp(0, filtered.length);
    return filtered.sublist(safeOffset, end);
  }

  @override
  Future<String> approve(String claimId) async {
    final index = _items.indexWhere((item) => item.id == claimId);
    if (index < 0) return '654321';
    final current = _items[index];
    _items[index] = OwnerSuspendedClaimItem(
      id: current.id,
      status: 'approved',
      claimantName: current.claimantName,
      amountCents: current.amountCents,
      currency: current.currency,
      mealMessage: current.mealMessage,
      createdAt: current.createdAt,
      ageHours: current.ageHours,
    );
    return '654321';
  }

  @override
  Future<void> fulfill({required String claimId, required String code}) async {
    final index = _items.indexWhere((item) => item.id == claimId);
    if (index < 0) return;
    final current = _items[index];
    _items[index] = OwnerSuspendedClaimItem(
      id: current.id,
      status: 'fulfilled',
      claimantName: current.claimantName,
      amountCents: current.amountCents,
      currency: current.currency,
      mealMessage: current.mealMessage,
      createdAt: current.createdAt,
      ageHours: current.ageHours,
    );
  }
}

class _SmokeGroupRequestsRepository extends GroupRequestsRepository {
  _SmokeGroupRequestsRepository()
    : _openRequests = <GroupRequest>[
        GroupRequest(
          id: 'group-request-1',
          createdBy: 'user-1',
          city: 'Istanbul',
          districts: const <String>['Kadikoy'],
          category: 'Cafe',
          dateTime: DateTime(2026, 3, 12, 20),
          partySize: 4,
          budgetTotalCents: 120000,
          currency: 'TRY',
          notes: 'Sessiz bir masa tercih edilir.',
          status: 'open',
          createdAt: DateTime(2026, 3, 10, 9),
        ),
      ],
      _offers = <GroupOffer>[],
      super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  final List<GroupRequest> _openRequests;
  final List<GroupOffer> _offers;

  @override
  Future<String?> fetchBusinessCity(String businessId) async {
    if (!_matchesOwnerBusiness(businessId)) return null;
    return 'Istanbul';
  }

  @override
  Future<List<GroupRequest>> listOpenRequestsForBusiness({
    required String city,
    List<String> categories = const [],
    required String businessId,
    int limit = 30,
    int offset = 0,
  }) async {
    if (!_matchesOwnerBusiness(businessId)) {
      return const <GroupRequest>[];
    }
    final filtered = _openRequests
        .where((item) => item.city == city)
        .toList(growable: false);
    final safeOffset = offset.clamp(0, filtered.length);
    final end = (safeOffset + limit).clamp(0, filtered.length);
    return filtered.sublist(safeOffset, end);
  }

  @override
  Future<List<GroupOffer>> listOffersForBusiness(String businessId) async {
    if (!_matchesOwnerBusiness(businessId)) {
      return const <GroupOffer>[];
    }
    return List<GroupOffer>.from(_offers);
  }

  @override
  Future<void> submitGroupOffer({
    required String requestId,
    required String businessId,
    required int offeredTotalCents,
    Map<String, dynamic> includes = const {},
    String? message,
  }) async {
    if (!_matchesOwnerBusiness(businessId)) return;
    _offers.insert(
      0,
      GroupOffer(
        id: 'group-offer-${_offers.length + 1}',
        requestId: requestId,
        businessId: businessId,
        offeredTotalCents: offeredTotalCents,
        includes: includes,
        message: message,
        status: 'submitted',
        createdBy: 'owner-1',
        createdAt: DateTime(2026, 3, 10, 12),
      ),
    );
    _openRequests.removeWhere((item) => item.id == requestId);
  }
}

class _SmokeAdminSearchRepository extends AdminSearchRepository {
  _SmokeAdminSearchRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<List<AdminSearchResult>> search({
    required String query,
    int limitPerCategory = 6,
  }) async {
    return <AdminSearchResult>[
      AdminSearchResult(
        category: AdminSearchCategory.business,
        id: 'business-1',
        title: 'Cafe Nova',
        subtitle: 'Business',
        searchToken: query,
        createdAt: DateTime(2026, 3, 9, 12),
        meta: const {'business_id': 'business-1'},
        score: 100,
      ),
    ];
  }
}

class _SmokeAdminRepository extends AdminRepository {
  _SmokeAdminRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<AdminQueueCounts> fetchQueueCounts() async {
    return const AdminQueueCounts(
      reportsOpen: 12,
      claimsPending: 5,
      suggestionsPending: 9,
    );
  }

  @override
  Future<AdminSlaMetrics> fetchSlaMetrics() async {
    return const AdminSlaMetrics(
      reportsAvgMinutesToAssign: 11,
      reportsAvgMinutesToClose: 38,
      claimsAvgMinutesToAssign: 14,
      claimsAvgMinutesToDecide: 44,
    );
  }
}

class _SmokeAdminAnalyticsRepository extends AdminAnalyticsRepository {
  _SmokeAdminAnalyticsRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<List<AdminGrowthDay>> fetchGrowth({
    int days = 30,
    String? businessId,
  }) async {
    return <AdminGrowthDay>[
      AdminGrowthDay(
        day: DateTime(2026, 3, 8),
        menuLinkOpened: 44,
        qrScanned: 19,
        menuShared: 7,
        appInstallFromMenu: 3,
      ),
      AdminGrowthDay(
        day: DateTime(2026, 3, 9),
        menuLinkOpened: 51,
        qrScanned: 24,
        menuShared: 8,
        appInstallFromMenu: 4,
      ),
    ];
  }

  @override
  Future<AdminKpiSummary> fetchKpiSummary({int days = 30}) async {
    return const AdminKpiSummary(
      dau: 320,
      dauPrev: 280,
      wau: 1410,
      wauPrev: 1290,
      discoveryImpressions: 12000,
      discoveryImpressionsPrev: 10800,
      discoveryClicks: 2400,
      discoveryClicksPrev: 1980,
      discoveryCtr: 0.20,
      discoveryCtrPrev: 0.183,
      businessViews: 3100,
      businessViewsPrev: 2800,
      menuViews: 1960,
      menuViewsPrev: 1700,
      menuViewRate: 0.632,
      menuViewRatePrev: 0.607,
      priceSuggestions: 410,
      priceSuggestionsPrev: 350,
      priceVerificationRate: 0.209,
      priceVerificationRatePrev: 0.205,
      reportsAvgResolutionMinutes: 46,
      reportsAvgResolutionMinutesPrev: 53,
    );
  }
}

class _SmokeAdminQueueRepository extends AdminQueueRepository {
  _SmokeAdminQueueRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<AdminQueuePageResult> listQueue({
    String? type,
    String? status,
    String? city,
    String? query,
    DateTime? from,
    DateTime? to,
    String sortKey = 'created_at',
    bool sortAscending = false,
    int limit = 20,
    int offset = 0,
  }) async {
    return AdminQueuePageResult(
      items: <AdminQueueItem>[
        AdminQueueItem(
          id: 'price-1',
          type: AdminQueueItemType.priceSuggestion,
          status: 'pending',
          createdAt: DateTime(2026, 3, 9, 10),
          ageHours: 3,
          slaHours: 48,
          slaBreached: false,
          title: 'Latte',
          subtitle: '120 -> 220 TRY',
          businessId: 'business-1',
          businessName: 'Cafe Nova',
          city: 'Istanbul',
          district: 'Kadikoy',
          detail: const {
            'quality_confidence': 0.42,
            'anomaly_score': 0.81,
            'conflict_state': 'queued',
            'conflict_variants_24h': 3,
          },
          totalCount: 1,
        ),
      ],
      totalCount: 1,
    );
  }

  @override
  Future<void> setAssignment({
    required AdminQueueItemType type,
    required String itemId,
    required bool assignToMe,
  }) async {}
}

class _SmokeAdminAuditRepository extends AdminAuditRepository {
  _SmokeAdminAuditRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<List<AdminAuditLogItem>> fetchLogs({
    int limit = 50,
    int offset = 0,
    String? actionFilter,
    String? targetTypeFilter,
    String? actorFilter,
    String? targetId,
    String? businessId,
    DateTime? from,
    DateTime? to,
    String? query,
  }) async {
    return <AdminAuditLogItem>[
      AdminAuditLogItem(
        createdAt: DateTime(2026, 3, 9, 9, 45),
        actorId: 'admin-1',
        actorRole: 'admin',
        action: 'price_suggestion.approved',
        targetType: 'price_suggestion',
        targetId: 'price-2',
      ),
    ];
  }
}

class _SmokeAdminBusinessSubmissionsRepository
    extends AdminBusinessSubmissionsRepository {
  _SmokeAdminBusinessSubmissionsRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<void> approve(String submissionId) async {}

  @override
  Future<void> reject(String submissionId, {String? note}) async {}
}

class _SmokeAdminClaimsRepository extends AdminClaimsRepository {
  _SmokeAdminClaimsRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<void> decideClaim({
    required String claimId,
    required String decision,
    String? note,
  }) async {}
}

class _SmokeAdminPriceSuggestionsRepository
    extends AdminPriceSuggestionsRepository {
  _SmokeAdminPriceSuggestionsRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<void> approve(String suggestionId) async {}

  @override
  Future<void> reject({
    required String suggestionId,
    required String note,
  }) async {}
}

class _SmokeAdminReportsRepository extends AdminReportsRepository {
  _SmokeAdminReportsRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<List<AdminReportItem>> listReports({
    String? status,
    String? assigned,
    bool? slaOnly,
    int limit = 50,
    int offset = 0,
    String? query,
  }) async {
    return <AdminReportItem>[
      AdminReportItem(
        id: 'report-1',
        status: 'acik',
        reason: 'spam',
        createdAt: DateTime(2026, 3, 9, 8),
        details: 'Menu photo looks duplicated.',
        businessId: 'business-1',
        targetType: 'review',
        targetId: 'review-1',
        reporterId: 'user-1',
        ageHours: 4,
        slaBreached: false,
      ),
    ];
  }

  @override
  Future<void> updateReport({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {}

  @override
  Future<void> assignReport(String reportId) async {}
}

class _SmokeAdminBusinessesRepository extends AdminBusinessesRepository {
  _SmokeAdminBusinessesRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<List<AdminBusinessItem>> listBusinesses({
    int limit = 50,
    int offset = 0,
    String? query,
    String? city,
    String? district,
  }) async {
    return <AdminBusinessItem>[
      AdminBusinessItem(
        id: 'business-1',
        name: 'Cafe Nova',
        createdAt: DateTime(2026, 3, 9, 7),
        category: 'Cafe',
        address: 'Moda Cad. 10',
        city: 'Istanbul',
        district: 'Kadikoy',
        isVerified: false,
        publicSlug: 'cafe-nova',
      ),
    ];
  }

  @override
  Future<Map<String, BusinessRiskSignal>> fetchRiskSignals(
    List<String> businessIds,
  ) async {
    return <String, BusinessRiskSignal>{
      for (final id in businessIds)
        id: const BusinessRiskSignal(
          missingAddress: false,
          missingPhone: true,
          photoCount: 2,
          engagementCount: 3,
          suspicious: false,
          riskScore: 1,
        ),
    };
  }
}

class _SmokeAdminReceiptSubmissionsRepository
    extends AdminReceiptSubmissionsRepository {
  _SmokeAdminReceiptSubmissionsRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<AdminReceiptSubmissionSummary?> fetchSummary({
    String? query,
    String? reviewStatus,
    bool onlyUnmatched = false,
  }) async {
    return AdminReceiptSubmissionSummary(
      totalCount: 1,
      pendingCount: 1,
      reviewedCount: 0,
      needsFollowupCount: 0,
      zeroMatchCount: 0,
      businessCount: 1,
      recent24hCount: 1,
    );
  }

  @override
  Future<List<AdminReceiptSubmission>> listSubmissions({
    String? query,
    String? reviewStatus,
    bool onlyUnmatched = false,
    int limit = 50,
    int offset = 0,
  }) async {
    return <AdminReceiptSubmission>[
      AdminReceiptSubmission(
        id: 'receipt-1',
        businessId: 'business-1',
        businessName: 'Cafe Nova',
        userId: 'user-1',
        imageUrl: '',
        matchesCount: 1,
        createdAt: DateTime(2026, 3, 9, 11),
        reviewStatus: 'pending',
        city: 'Istanbul',
        district: 'Kadikoy',
      ),
    ];
  }

  @override
  Future<List<AdminReceiptSubmissionMatch>> listMatches({
    required String receiptId,
  }) async {
    return <AdminReceiptSubmissionMatch>[
      AdminReceiptSubmissionMatch(
        menuItemId: 'item-1',
        itemName: 'Latte',
        detectedPriceCents: 22000,
        currentPriceCents: 21000,
        deltaCents: 1000,
      ),
    ];
  }

  @override
  Future<List<AdminReceiptBatchOpportunity>> listBatchOpportunities({
    int limit = 8,
  }) async {
    return <AdminReceiptBatchOpportunity>[
      AdminReceiptBatchOpportunity(
        businessId: 'business-1',
        businessName: 'Cafe Nova',
        pendingCount: 1,
        zeroMatchCount: 0,
        lastSubmittedAt: DateTime(2026, 3, 9, 11),
      ),
    ];
  }
}

class _SmokeAdminObservabilityRepository extends AdminObservabilityRepository {
  _SmokeAdminObservabilityRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<List<AdminOfflineMutationOutcome>> listOfflineMutationOutcomes({
    int hours = 24,
    int limit = 100,
  }) async {
    return <AdminOfflineMutationOutcome>[
      AdminOfflineMutationOutcome(
        createdAt: DateTime.utc(2026, 3, 9, 11, 0),
        source: 'mobile',
        kind: 'review_submission',
        disposition: 'retry',
        retryCategory: 'network',
        retryCount: 2,
        detail: 'Retry scheduled for review sync.',
        userId: 'user-1',
        clientId: 'client-1',
      ),
      AdminOfflineMutationOutcome(
        createdAt: DateTime.utc(2026, 3, 9, 10, 30),
        source: 'mobile',
        kind: 'favorite_toggle',
        disposition: 'success',
        retryCategory: null,
        retryCount: 0,
        detail: 'Favorite replay completed.',
        userId: 'user-1',
        clientId: 'client-2',
      ),
    ];
  }

  @override
  Future<AdminOfflineMutationAlertSettings>
  getOfflineMutationAlertSettings() async {
    return AdminOfflineMutationAlertSettings.defaults();
  }

  @override
  Future<AdminOfflineMutationAlertSettings> saveOfflineMutationAlertSettings(
    AdminOfflineMutationAlertSettings settings,
  ) async {
    return settings;
  }
}

class _SmokeOwnerMonetizationRepository extends OwnerMonetizationRepository {
  _SmokeOwnerMonetizationRepository()
    : super(SupabaseClient('http://127.0.0.1:54321', 'smoke-key'));

  @override
  Future<List<OwnerSponsorshipCatalogItem>> fetchSponsorshipCatalog({
    required String businessId,
  }) async {
    if (!_matchesOwnerBusiness(businessId)) {
      return const <OwnerSponsorshipCatalogItem>[];
    }
    return <OwnerSponsorshipCatalogItem>[
      OwnerSponsorshipCatalogItem(
        packageId: 'pkg-discovery-1',
        packageName: 'Discovery Boost',
        surface: 'discovery',
        durationDays: 14,
        priceDisplay: '7.500 TRY',
        priceCents: 750000,
        currencyCode: 'TRY',
        inventoryLimit: 8,
        surfaceLiveUnits: 5,
        surfaceOpenSlots: 3,
        businessLiveUnits: 0,
        businessImpressions30d: 18200,
        businessUniqueUsers30d: 4200,
        latestLeadStatus: 'new',
      ),
    ];
  }

  @override
  Future<void> submitSponsorshipLead({
    required String businessId,
    required String phone,
    required String message,
    required String preferredSurface,
    required Map<String, dynamic> preferredTargeting,
  }) async {}
}
