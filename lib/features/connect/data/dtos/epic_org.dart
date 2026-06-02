// One health system from GET /api/v1/integrations/epic/organizations/.
// `fhirBaseUrl` is kept for the (forthcoming) OAuth start call; it is not
// shown to the patient.

class EpicOrg {
  const EpicOrg({
    required this.id,
    required this.name,
    required this.fhirBaseUrl,
    this.state = '',
  });

  final String id;
  final String name;
  final String fhirBaseUrl;
  final String state;

  /// Single-letter leading badge for the list row.
  String get badge {
    final n = name.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  factory EpicOrg.fromJson(Map<String, dynamic> j) => EpicOrg(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        fhirBaseUrl: (j['fhir_base_url'] ?? '').toString(),
        state: (j['state'] ?? '').toString(),
      );
}
