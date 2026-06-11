import 'package:datasolids_mobile/core/auth/auth_state.dart';
import 'package:datasolids_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:datasolids_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:datasolids_mobile/features/auth/presentation/screens/mfa_challenge_screen.dart';
import 'package:datasolids_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:datasolids_mobile/features/connect/presentation/screens/connect_ehr_screen.dart';
import 'package:datasolids_mobile/features/connect/presentation/screens/select_health_system_screen.dart';
import 'package:datasolids_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/condition_detail_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/conditions_list_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/diagnostic_report_detail_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/diagnostic_reports_list_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/document_reference_detail_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/documents_list_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/imaging_studies_list_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/imaging_study_detail_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/labs_list_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/medication_detail_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/medications_list_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/observation_detail_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/resource_detail_screen.dart';
import 'package:datasolids_mobile/features/pod/presentation/screens/vitals_list_screen.dart';
import 'package:datasolids_mobile/features/profile/presentation/screens/personal_profile_screen.dart';
import 'package:datasolids_mobile/features/security/presentation/screens/active_sessions_screen.dart';
import 'package:datasolids_mobile/features/security/presentation/screens/change_password_screen.dart';
import 'package:datasolids_mobile/features/security/presentation/screens/mfa_setup_flow.dart';
import 'package:datasolids_mobile/features/security/presentation/screens/mfa_status_screen.dart';
import 'package:datasolids_mobile/features/security/presentation/screens/delete_account_screen.dart';
import 'package:datasolids_mobile/features/security/presentation/screens/security_activity_screen.dart';
import 'package:datasolids_mobile/features/security/presentation/screens/security_home_screen.dart';
import 'package:datasolids_mobile/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Single source of truth for navigation. Authenticated state lives in
/// `authStateProvider`; the router redirects unauthenticated users to
/// /login and authenticated users away from /login.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: ref.watch(authStateChangesProvider),
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final atSplash = state.matchedLocation == '/';
      // Paths reachable when logged out. Two groups:
      //   • Auth-entry paths (login/signup/forgot/mfa-challenge) — logged-in
      //     users on these get bounced to /home so they can't see a stale
      //     login form.
      //   • MFA setup paths (/security/mfa-choose, /mfa-totp-qr, /mfa-totp-verify)
      //     — reachable both when logged out (forced setup after grace) AND
      //     when logged in (turning on MFA from Settings), so we DON'T bounce
      //     logged-in users away.
      //   • /security/mfa-status is the logged-in-only status view.
      const authEntryPaths = {
        '/login', '/signup', '/forgot-password', '/mfa-challenge',
      };
      const mfaSetupPaths = {
        '/security/mfa-choose',
        '/security/mfa-totp-qr',
        '/security/mfa-totp-verify',
      };
      final loc = state.matchedLocation;
      final onAuthEntry = authEntryPaths.contains(loc);
      final onMfaSetup = mfaSetupPaths.contains(loc);

      if (atSplash) return loggedIn ? '/home' : '/login';
      // Unauthenticated users may only see auth-entry paths and MFA setup.
      if (!loggedIn && !onAuthEntry && !onMfaSetup) return '/login';
      // Authenticated users shouldn't sit on auth-entry pages.
      if (loggedIn && onAuthEntry) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      // MFA challenge during sign-in. `extra` carries the challenge token
      // returned by /auth/login when mfa_required is true.
      GoRoute(
        path: '/mfa-challenge',
        name: 'mfa_challenge',
        builder: (context, state) {
          final token = state.extra is String
              ? state.extra as String
              : '';
          return MfaChallengeScreen(challengeToken: token);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile/personal',
        name: 'personal_profile',
        builder: (_, __) => const PersonalProfileScreen(),
      ),
      GoRoute(
        path: '/connect',
        name: 'connect_ehr',
        builder: (_, __) => const ConnectEhrScreen(),
      ),
      GoRoute(
        path: '/connect/epic',
        name: 'connect_epic',
        builder: (_, __) => const SelectHealthSystemScreen(),
      ),
      // My Pod category lists — each category has its own screen so the
      // copy, filter chips, and row layout can differ per data type.
      // Unknown keys fall through to a friendly placeholder.
      GoRoute(
        path: '/pod/category/:key',
        name: 'pod_category',
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? '';
          switch (key) {
            case 'labs':
              return const LabsListScreen();
            case 'medications':
              return const MedicationsListScreen();
            case 'vitals':
              return const VitalsListScreen();
            case 'documents':
              return const DocumentsListScreen();
            case 'imaging':
              return const ImagingStudiesListScreen();
            case 'diagnostic_reports':
              return const DiagnosticReportsListScreen();
            case 'conditions':
              return const ConditionsListScreen();
            default:
              return _CategoryComingSoon(categoryKey: key);
          }
        },
      ),
      // Resource detail — works for any FHIR type (structured summary +
      // raw FHIR section). Reached from any category list row tap.
      GoRoute(
        path: '/pod/resource/:id',
        name: 'pod_resource_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ResourceDetailScreen(resourceId: id);
        },
      ),
      // Typed DiagnosticReport detail — used by the Labs list (typed)
      // and any future category screen built on the clinical API.
      GoRoute(
        path: '/pod/clinical/diagnostic-report/:id',
        name: 'clinical_diagnostic_report_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DiagnosticReportDetailScreen(reportId: id);
        },
      ),
      // Typed Observation detail — used by Vitals row tap.
      GoRoute(
        path: '/pod/clinical/observation/:id',
        name: 'clinical_observation_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ObservationDetailScreen(observationId: id);
        },
      ),
      // Typed DocumentReference detail — clinical-note PDFs etc.
      GoRoute(
        path: '/pod/clinical/document-reference/:id',
        name: 'clinical_document_reference_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DocumentReferenceDetailScreen(docRefId: id);
        },
      ),
      // Typed ImagingStudy detail — radiology read PDFs / preview JPEGs.
      GoRoute(
        path: '/pod/clinical/imaging-study/:id',
        name: 'clinical_imaging_study_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ImagingStudyDetailScreen(studyId: id);
        },
      ),
      // Typed MedicationRequest detail.
      GoRoute(
        path: '/pod/clinical/medication-request/:id',
        name: 'clinical_medication_request_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MedicationDetailScreen(medicationId: id);
        },
      ),
      // Typed Condition detail.
      GoRoute(
        path: '/pod/clinical/condition/:id',
        name: 'clinical_condition_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ConditionDetailScreen(conditionId: id);
        },
      ),
      // Security & MFA
      GoRoute(
        path: '/security',
        name: 'security_home',
        builder: (_, __) => const SecurityHomeScreen(),
      ),
      GoRoute(
        path: '/security/mfa-status',
        name: 'security_mfa_status',
        builder: (_, __) => const MfaStatusScreen(),
      ),
      GoRoute(
        path: '/security/mfa-choose',
        name: 'security_mfa_choose',
        builder: (_, __) => const MfaMethodChoiceScreen(),
      ),
      GoRoute(
        path: '/security/mfa-totp-qr',
        name: 'security_mfa_totp_qr',
        builder: (_, __) => const MfaTotpQrScreen(),
      ),
      GoRoute(
        path: '/security/mfa-totp-verify',
        name: 'security_mfa_totp_verify',
        builder: (_, __) => const MfaTotpVerifyScreen(),
      ),
      GoRoute(
        path: '/security/recovery-codes',
        name: 'security_recovery_codes',
        builder: (_, __) => const RecoveryCodesScreen(),
      ),
      GoRoute(
        path: '/security/sessions',
        name: 'security_sessions',
        builder: (_, __) => const ActiveSessionsScreen(),
      ),
      GoRoute(
        path: '/security/activity',
        name: 'security_activity',
        builder: (_, __) => const SecurityActivityScreen(),
      ),
      GoRoute(
        path: '/security/password',
        name: 'security_change_password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/security/delete-account',
        name: 'security_delete_account',
        builder: (_, __) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/security/recovery-codes-after-setup',
        name: 'security_recovery_codes_after_setup',
        builder: (context, state) {
          final codes = state.extra is List<String>
              ? state.extra as List<String>
              : null;
          return RecoveryCodesScreen(initialCodes: codes);
        },
      ),

      // Feature routes — every new feature appends one GoRoute here.
      // Resist building a giant tree-of-routes file; if this grows past
      // ~30 routes split per-feature into router fragments.
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

/// Placeholder screen for category keys we haven't built a dedicated
/// list screen for yet (medications, imaging, conditions, …). Avoids
/// dead-ending the user — they can tap a tile, see what's coming,
/// and use back to return to the explorer.
class _CategoryComingSoon extends StatelessWidget {
  const _CategoryComingSoon({required this.categoryKey});
  final String categoryKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
        title: Text(_titleFor(categoryKey)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_outlined, size: 56),
            const SizedBox(height: 14),
            Text(
              '${_titleFor(categoryKey)} list coming soon',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This category will get its own list screen — '
              'we ship them one at a time.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static String _titleFor(String key) {
    switch (key) {
      case 'medications':
        return 'Medications';
      case 'imaging':
        return 'Imaging';
      case 'vitals':
        return 'Vitals';
      case 'conditions':
        return 'Conditions';
      case 'allergies':
        return 'Allergies';
      case 'immunizations':
        return 'Immunizations';
      case 'encounters':
        return 'Encounters';
      case 'procedures':
        return 'Procedures';
      case 'documents':
        return 'Documents';
      case 'diagnostic_reports':
        return 'Diagnostic Reports';
      default:
        return 'Category';
    }
  }
}
