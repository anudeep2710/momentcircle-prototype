import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MomentCircleApp());
}

class MomentCircleApp extends StatelessWidget {
  const MomentCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MomentCircle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.light,
          surface: AppColors.paper,
        ),
        fontFamily: 'Arial',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.ink, height: 1.35),
          bodySmall: TextStyle(color: AppColors.muted, height: 1.35),
          titleMedium: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      home: const MomentCircleShell(),
    );
  }
}

class AppColors {
  static const ink = Color(0xFF0A0A0A);
  static const paper = Color(0xFFF5F3EE);
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFF6B718);
  static const goldInk = Color(0xFF966800);
  static const line = Color(0xFFE3DED2);
  static const muted = Color(0xFF6F6B63);
  static const purple = Color(0xFF7B53D7);
  static const blue = Color(0xFF3478E5);
  static const orange = Color(0xFFF08A27);
  static const green = Color(0xFF2A9973);
  static const red = Color(0xFFD95B4C);
}

enum DemoStep { create, join, enroll, search, confirm, delete }

extension DemoStepCopy on DemoStep {
  String get label => switch (this) {
    DemoStep.create => 'CREATE',
    DemoStep.join => 'JOIN',
    DemoStep.enroll => 'ENROLL',
    DemoStep.search => 'SEARCH',
    DemoStep.confirm => 'CONFIRM',
    DemoStep.delete => 'DELETE',
  };

  String get time => switch (this) {
    DemoStep.create => '0:00',
    DemoStep.join => '0:25',
    DemoStep.enroll => '0:45',
    DemoStep.search => '1:20',
    DemoStep.confirm => '2:10',
    DemoStep.delete => '2:40',
  };
}

class MomentCircleShell extends StatefulWidget {
  const MomentCircleShell({super.key});

  @override
  State<MomentCircleShell> createState() => _MomentCircleShellState();
}

class _MomentCircleShellState extends State<MomentCircleShell> {
  DemoStep _step = DemoStep.create;
  int _tab = 0;
  bool _eventCreated = false;
  bool _consentGiven = false;
  bool _lockEnabled = false;
  bool _galleryLocked = false;
  bool _matchRejected = false;
  bool _identityDeleted = false;
  int _selfiesCaptured = 0;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
        ),
      );
  }

  void _createEvent() {
    setState(() {
      _eventCreated = true;
      _step = DemoStep.join;
    });
    _showMessage('Event created. The invite QR is ready to scan.');
  }

  void _joinEvent() {
    setState(() => _step = DemoStep.enroll);
    _showMessage('Joined Priya & Arjun’s Wedding — event scope is active.');
  }

  void _captureConsent() {
    setState(() {
      _consentGiven = true;
      _selfiesCaptured = 3;
      _lockEnabled = true;
      _step = DemoStep.search;
    });
    _showMessage('Consent recorded. Three selfie samples indexed locally.');
  }

  void _openSearch() {
    setState(() => _step = DemoStep.confirm);
    _showMessage('127 authorized matches found in this event.');
  }

  void _rejectMatch() {
    setState(() {
      _matchRejected = true;
      _step = DemoStep.delete;
    });
    _showMessage('Low-confidence match excluded from your album.');
  }

  void _deleteIdentity() {
    setState(() => _identityDeleted = true);
    _showMessage('Your event identity and match access were deleted.');
  }

  void _restart() {
    setState(() {
      _step = DemoStep.create;
      _tab = 0;
      _eventCreated = false;
      _consentGiven = false;
      _lockEnabled = false;
      _galleryLocked = false;
      _matchRejected = false;
      _identityDeleted = false;
      _selfiesCaptured = 0;
    });
  }

  Future<void> _lockGallery() async {
    setState(() => _galleryLocked = true);
    _showMessage(
      'Gallery locked. Device authentication is required to reveal it.',
    );
  }

  Future<void> _unlockGallery() async {
    if (kIsWeb) {
      setState(() => _galleryLocked = false);
      _showMessage(
        'Web preview unlocked. Android uses the native device prompt.',
      );
      return;
    }

    try {
      final auth = LocalAuthentication();
      final supported = await auth.isDeviceSupported();
      if (!supported) {
        setState(() => _galleryLocked = false);
        _showMessage(
          'No biometric/PIN service is available; demo unlock used.',
        );
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: 'Unlock your private event gallery',
        biometricOnly: false,
      );
      if (authenticated && mounted) {
        setState(() => _galleryLocked = false);
        _showMessage('Gallery unlocked on this device.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _galleryLocked = false);
      _showMessage(
        'Native lock is not configured on this device; demo unlock used.',
      );
    }
  }

  void _handlePrimaryAction() {
    switch (_step) {
      case DemoStep.create:
        _createEvent();
      case DemoStep.join:
        _joinEvent();
      case DemoStep.enroll:
        _captureConsent();
      case DemoStep.search:
        _openSearch();
      case DemoStep.confirm:
        _rejectMatch();
      case DemoStep.delete:
        if (_identityDeleted) {
          _restart();
        } else {
          _deleteIdentity();
        }
    }
  }

  String get _primaryLabel => switch (_step) {
    DemoStep.create => 'Create event + QR',
    DemoStep.join => 'Scan event QR',
    DemoStep.enroll => 'Consent + capture 3 selfies',
    DemoStep.search => 'Open private album',
    DemoStep.confirm => 'Reject low-confidence match',
    DemoStep.delete => _identityDeleted ? 'Restart demo' : 'Delete identity',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final width = screenWidth > 1120 ? 1120.0 : screenWidth;
            return Center(
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: IndexedStack(
                        index: _tab,
                        children: [
                          _buildStoryTab(),
                          _buildAlbumTab(),
                          _buildSafetyTab(),
                        ],
                      ),
                    ),
                    _buildNavigation(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = MediaQuery.sizeOf(context).width < 520;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.circle_outlined,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'MomentCircle',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const Spacer(),
              if (compact)
                _compactLockIndicator()
              else
                _statusChip(
                  icon: _lockEnabled
                      ? Icons.lock_outline
                      : Icons.lock_open_outlined,
                  label: _lockEnabled ? 'LOCK ACTIVE' : 'DEMO MODE',
                  color: _lockEnabled ? AppColors.green : AppColors.goldInk,
                ),
              if (!compact) ...[
                const SizedBox(width: 10),
                _statusChip(
                  icon: Icons.event_outlined,
                  label: _eventCreated ? '1 EVENT' : 'READY',
                  color: AppColors.ink,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactLockIndicator() {
    final color = _lockEnabled ? AppColors.green : AppColors.goldInk;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      child: Icon(
        _lockEnabled ? Icons.lock_outline : Icons.lock_open_outlined,
        size: 15,
        color: color,
      ),
    );
  }

  Widget _buildStoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('THE THREE-MINUTE PRODUCT STORY'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = MediaQuery.sizeOf(context).width < 740;
              final hero = _buildHero();
              final archive = _buildArchiveCard();
              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [hero, const SizedBox(height: 14), archive],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: hero),
                        const SizedBox(width: 14),
                        Expanded(flex: 4, child: archive),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),
          _buildProgressRail(),
          const SizedBox(height: 20),
          _buildStepContent(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ONE EVENT.\nEVERY AUTHORIZED MOMENT.',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 29,
              fontWeight: FontWeight.w900,
              height: 0.98,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A private photo index for weddings and family functions.\nJoin by QR, consent once, and retrieve only the moments you are allowed to see.',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _DarkTag('QR JOIN'),
              _DarkTag('CONSENTED MATCHING'),
              _DarkTag('PRIVATE ALBUM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRIYA & ARJUN’S WEDDING',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _identityDeleted ? '0' : '300',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 54,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'ARCHIVE\nPHOTOS',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 11,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.ink, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _identityDeleted
                      ? 'Identity deleted'
                      : '10 opt-in participants',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _identityDeleted
                      ? 'No active matches'
                      : '127 authorized matches',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRail() {
    final steps = DemoStep.values;
    final current = steps.indexOf(_step);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _TimelineNode(
                step: steps[i],
                active: i == current,
                complete: i < current || (i == current && _identityDeleted),
              ),
              if (i != steps.length - 1)
                Container(
                  width: 34,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  color: i < current ? AppColors.gold : AppColors.line,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    final child = switch (_step) {
      DemoStep.create => _buildCreateStep(),
      DemoStep.join => _buildJoinStep(),
      DemoStep.enroll => _buildEnrollStep(),
      DemoStep.search => _buildSearchStep(),
      DemoStep.confirm => _buildConfirmStep(),
      DemoStep.delete => _buildDeleteStep(),
    };
    // Keep the active step as a single hit-testable subtree on Android.
    // AnimatedSwitcher can leave an outgoing Flutter semantics node with a
    // zero-sized bound after a long scroll, making the newly painted action
    // button impossible to activate through touch or accessibility tooling.
    return KeyedSubtree(key: ValueKey(_step), child: child);
  }

  Widget _buildCreateStep() {
    return _StepPanel(
      key: const ValueKey('create'),
      eyebrow: '01 / CREATE',
      title: 'Start with the event, not the gallery.',
      description: 'The host creates one scoped archive and displays a short-lived invite QR. No guest identity exists yet.',
      icon: Icons.add_to_photos_outlined,
      accent: AppColors.gold,
      actionLabel: _primaryLabel,
      onAction: _handlePrimaryAction,
      details: const [
        _Fact(label: 'SOURCE', value: 'Host / photographer archive'),
        _Fact(label: 'FIXTURE', value: '300 compressed photos'),
        _Fact(label: 'BOUNDARY', value: 'One event only'),
      ],
    );
  }

  Widget _buildJoinStep() {
    return _StepPanel(
      key: const ValueKey('join'),
      eyebrow: '02 / JOIN',
      title: 'A QR code establishes event scope.',
      description: 'Guests scan the invite at the venue. The token identifies the event, not a person, and expires with the event.',
      icon: Icons.qr_code_2_outlined,
      accent: AppColors.purple,
      actionLabel: _primaryLabel,
      onAction: _handlePrimaryAction,
      preview: const _QrPreview(),
      details: const [
        _Fact(label: 'EVENT', value: 'Priya & Arjun’s Wedding'),
        _Fact(label: 'ACCESS', value: 'Invite token + consent'),
        _Fact(label: 'RESULT', value: 'Private event session'),
      ],
    );
  }

  Widget _buildEnrollStep() {
    return _StepPanel(
      key: const ValueKey('enroll'),
      eyebrow: '03 / ENROLL',
      title: 'Consent before the camera sees a match.',
      description: 'The guest reads the plain-language notice, captures up to three selfie samples, and can delete the event identity later.',
      icon: Icons.face_retouching_natural_outlined,
      accent: AppColors.blue,
      actionLabel: _primaryLabel,
      onAction: _handlePrimaryAction,
      preview: _EnrollmentPreview(
        captured: _selfiesCaptured,
        consented: _consentGiven,
      ),
      details: [
        _Fact(
          label: 'CONSENT',
          value: _consentGiven ? 'Recorded' : 'Not recorded',
        ),
        _Fact(label: 'SAMPLES', value: '$_selfiesCaptured/3 captured'),
        const _Fact(label: 'RETENTION', value: 'Event-scoped identity'),
      ],
    );
  }

  Widget _buildSearchStep() {
    return _StepPanel(
      key: const ValueKey('search'),
      eyebrow: '04 / SEARCH',
      title: 'Find a memory by people, not folders.',
      description: 'The local worker compares the consented identity with this event’s archive. The gallery only returns authorized thumbnails.',
      icon: Icons.search_outlined,
      accent: AppColors.blue,
      actionLabel: _primaryLabel,
      onAction: _handlePrimaryAction,
      preview: const _SearchPreview(),
      details: const [
        _Fact(label: 'QUERY', value: 'You + Mother'),
        _Fact(label: 'RESULT', value: '127 authorized matches'),
        _Fact(label: 'MODEL', value: 'Local face embedding worker'),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return _StepPanel(
      key: const ValueKey('confirm'),
      eyebrow: '05 / CONFIRM',
      title: 'Every match has evidence and an exit.',
      description: 'The guest can reject a low-confidence result before it enters the private album. Nothing is silently shared.',
      icon: Icons.fact_check_outlined,
      accent: AppColors.orange,
      actionLabel: _primaryLabel,
      onAction: _handlePrimaryAction,
      preview: _MatchPreview(rejected: _matchRejected),
      details: [
        const _Fact(label: 'MATCH', value: 'Mother + you'),
        _Fact(
          label: 'DECISION',
          value: _matchRejected ? 'Excluded' : 'Needs review',
        ),
        const _Fact(label: 'OWNER', value: 'Guest controls the result'),
      ],
    );
  }

  Widget _buildDeleteStep() {
    return _StepPanel(
      key: const ValueKey('delete'),
      eyebrow: '06 / DELETE',
      title: _identityDeleted
          ? 'Your identity is gone from this event.'
          : 'Keep the album. Revoke the identity.',
      description: _identityDeleted
          ? 'The event identity, matching access, and raw staging selfie are removed from the demo flow.'
          : 'The guest can delete their identity and leave the event without asking the host.',
      icon: _identityDeleted
          ? Icons.check_circle_outline
          : Icons.delete_outline,
      accent: _identityDeleted ? AppColors.green : AppColors.red,
      actionLabel: _primaryLabel,
      onAction: _handlePrimaryAction,
      preview: _DeletionPreview(deleted: _identityDeleted),
      details: [
        _Fact(
          label: 'MATCH ACCESS',
          value: _identityDeleted ? 'Revoked' : 'Active',
        ),
        _Fact(
          label: 'RAW SELFIE',
          value: _identityDeleted ? 'Deleted' : 'Staged locally',
        ),
        const _Fact(label: 'EXPORT', value: 'Guest-selected album'),
      ],
    );
  }

  Widget _buildAlbumTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: _galleryLocked
          ? _buildLockedGallery()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('YOUR PRIVATE ALBUM'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Text(
                        '127 moments with Mother.',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _lockEnabled ? _lockGallery : null,
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Lock'),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  _identityDeleted
                      ? 'Identity deleted — no new results will be returned.'
                      : 'Only consented results from Priya & Arjun’s Wedding are shown.',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _FilterChip(label: 'ALL', selected: true),
                    _FilterChip(label: 'FAMILY'),
                    _FilterChip(label: 'CEREMONY'),
                    _FilterChip(label: 'DANCE'),
                  ],
                ),
                const SizedBox(height: 18),
                if (_identityDeleted)
                  _EmptyAlbum()
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: const [
                      _PhotoCard(
                        label: 'FAMILY',
                        icon: Icons.people_alt_outlined,
                        colors: [Color(0xFF2B2A28), Color(0xFF6D6255)],
                      ),
                      _PhotoCard(
                        label: 'CEREMONY',
                        icon: Icons.auto_awesome_outlined,
                        colors: [Color(0xFFE9B21E), Color(0xFFF4D77C)],
                      ),
                      _PhotoCard(
                        label: 'DANCE FLOOR',
                        icon: Icons.music_note_outlined,
                        colors: [Color(0xFF5F46A6), Color(0xFFB28CE8)],
                      ),
                      _PhotoCard(
                        label: 'CANDID',
                        icon: Icons.camera_alt_outlined,
                        colors: [Color(0xFF3478E5), Color(0xFF9DC8FF)],
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                const _TrustBanner(
                  icon: Icons.verified_user_outlined,
                  title: 'Private by default',
                  body: 'Photos are event-scoped. The device lock hides the gallery until you unlock it.',
                ),
              ],
            ),
    );
  }

  Widget _buildLockedGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('PRIVATE GALLERY'),
        const SizedBox(height: 12),
        Container(
          height: 420,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.lock_outline, size: 34),
              ),
              const SizedBox(height: 20),
              const Text(
                'Gallery locked',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock this device to reveal your event memories.',
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _unlockGallery,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.ink,
                ),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock gallery'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('TRUST BY DESIGN'),
          const SizedBox(height: 12),
          const Text(
            'The guest stays in control.',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Every result has an owner, an event boundary, and a reversible action.',
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final cards = [
                const _SafetyCard(
                  label: 'OPT-IN',
                  body: 'No identity is created before an explicit consent action.',
                  color: AppColors.ink,
                  textColor: AppColors.white,
                ),
                const _SafetyCard(
                  label: 'EVENT-ONLY',
                  body: 'The identity expires with the event and is never searched globally.',
                  color: AppColors.gold,
                  textColor: AppColors.ink,
                ),
                const _SafetyCard(
                  label: 'TRACEABLE',
                  body:
                      'Uploader, confidence and match evidence remain visible.',
                  color: AppColors.ink,
                  textColor: AppColors.white,
                ),
                _SafetyCard(
                  label: 'DEVICE-LOCKED',
                  body: _lockEnabled
                      ? 'Gallery protected by native device authentication.'
                      : 'Enabled after enrollment.',
                  color: AppColors.gold,
                  textColor: AppColors.ink,
                ),
              ];
              return GridView.count(
                crossAxisCount: compact ? 1 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: compact ? 4.0 : 2.5,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 20),
          const _TrustBanner(
            icon: Icons.cloud_done_outlined,
            title: 'Appwrite permissions + local inference',
            body: 'Cloud storage holds private files and event records. The face index runs in the local worker; no public face search is exposed.',
          ),
          const SizedBox(height: 12),
          const _TrustBanner(
            icon: Icons.delete_sweep_outlined,
            title: 'Retention is a product control',
            body: 'Guests can revoke their event identity, delete staging selfies, and export only their selected album.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _lockEnabled ? _lockGallery : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Lock private gallery'),
              ),
              OutlinedButton.icon(
                onPressed: _identityDeleted ? null : _deleteIdentity,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete event identity'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.gold.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Story',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Album',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Safety',
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.goldInk,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _DarkTag extends StatelessWidget {
  const _DarkTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.white.withValues(alpha: 0.9),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
    required this.details,
    this.preview,
  });
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String actionLabel;
  final VoidCallback onAction;
  final List<_Fact> details;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    eyebrow,
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: details
                    .map((fact) => _FactPill(fact: fact, accent: accent))
                    .toList(),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, size: 17),
                label: Text(actionLabel),
              ),
            ],
          );
          if (preview == null) return copy;
          return compact
              ? Column(children: [copy, const SizedBox(height: 18), preview!])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 20),
                    SizedBox(width: 250, child: preview),
                  ],
                );
        },
      ),
    );
  }
}

class _Fact {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
}

class _FactPill extends StatelessWidget {
  const _FactPill({required this.fact, required this.accent});
  final _Fact fact;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.label,
            style: TextStyle(
              color: accent,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            fact.value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.step,
    required this.active,
    required this.complete,
  });
  final DemoStep step;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = active || complete ? AppColors.gold : AppColors.line;
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.ink
                  : (complete ? AppColors.gold : AppColors.paper),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              complete ? Icons.check : Icons.circle,
              size: complete ? 15 : 7,
              color: active
                  ? AppColors.gold
                  : (complete ? AppColors.ink : AppColors.muted),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            step.label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: active ? AppColors.ink : AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            step.time,
            style: const TextStyle(fontSize: 8, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'INVITE TOKEN',
              style: TextStyle(
                color: AppColors.goldInk,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 170,
            height: 170,
            padding: const EdgeInsets.all(12),
            color: AppColors.white,
            child: CustomPaint(painter: _QrPainter()),
          ),
          const SizedBox(height: 12),
          const Text(
            'MOMENT-7A31',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
          ),
          const SizedBox(height: 4),
          const Text(
            'expires with the event',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 21;
    final paint = Paint()..color = AppColors.ink;
    bool filled(int row, int col) {
      if ((row < 7 && col < 7) ||
          (row < 7 && col > 13) ||
          (row > 13 && col < 7)) {
        final r = row < 7 ? row : row - 14;
        final c = col < 7 ? col : col - 14;
        return r == 0 ||
            r == 6 ||
            c == 0 ||
            c == 6 ||
            (r >= 2 && r <= 4 && c >= 2 && c <= 4);
      }
      return ((row * 7 + col * 11 + row * col) % 5 == 0) ||
          (row + col) % 7 == 0;
    }

    for (var row = 0; row < 21; row++) {
      for (var col = 0; col < 21; col++) {
        if (filled(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell - 1, cell - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnrollmentPreview extends StatelessWidget {
  const _EnrollmentPreview({required this.captured, required this.consented});
  final int captured;
  final bool consented;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONSENTED ENROLLMENT',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 78,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: index < captured ? AppColors.blue : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: index < captured ? AppColors.blue : AppColors.line,
                    ),
                  ),
                  child: Icon(
                    index < captured ? Icons.face : Icons.add_a_photo_outlined,
                    color: index < captured ? AppColors.white : AppColors.muted,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                consented ? Icons.check_circle : Icons.info_outline,
                size: 16,
                color: consented ? AppColors.green : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  consented
                      ? 'Identity scoped to this event.'
                      : 'Read the notice before capture.',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchPreview extends StatelessWidget {
  const _SearchPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NATURAL QUERY',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Show me photos with Mother.',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '127',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 48,
              height: 0.9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'authorized matches',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.68),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'local index ready',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.82),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchPreview extends StatelessWidget {
  const _MatchPreview({required this.rejected});
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const _PhotoCard(
            label: 'MATCH EVIDENCE',
            icon: Icons.family_restroom_outlined,
            colors: [Color(0xFF2E2D2A), Color(0xFFC09855)],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 16,
                color: AppColors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rejected
                      ? 'Rejected by guest'
                      : '0.91 similarity • reviewable',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeletionPreview extends StatelessWidget {
  const _DeletionPreview({required this.deleted});
  final bool deleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: deleted
            ? AppColors.green.withValues(alpha: 0.12)
            : AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: deleted
              ? AppColors.green.withValues(alpha: 0.4)
              : AppColors.line,
        ),
      ),
      child: Column(
        children: [
          Icon(
            deleted ? Icons.check_circle_outline : Icons.delete_sweep_outlined,
            color: deleted ? AppColors.green : AppColors.red,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            deleted ? 'Identity removed' : 'Delete access',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            deleted
                ? 'No new event matches.'
                : 'Revoke matching without deleting your selected album.',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.label,
    required this.icon,
    required this.colors,
  });
  final String label;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 14,
            top: 14,
            child: Icon(
              icon,
              color: AppColors.white.withValues(alpha: 0.76),
              size: 24,
            ),
          ),
          Positioned(
            left: 15,
            bottom: 14,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 33,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 58,
            top: 54,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : AppColors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: selected ? AppColors.ink : AppColors.line),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.white : AppColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({
    required this.label,
    required this.body,
    required this.color,
    required this.textColor,
  });
  final String label;
  final String body;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.82),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlbum extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          Icon(Icons.photo_library_outlined, size: 44, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            'No active identity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Restart the demo to enroll again.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
