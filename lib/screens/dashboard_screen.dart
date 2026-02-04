import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/banking_service.dart';
import '../api/notification_service.dart';
import '../models/notificationmodel.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'profile_management_screen.dart';
import 'transfer_funds_screen.dart';
import 'tpin_management_screen.dart';
import 'detailed_statement_screen.dart';
import 'quick_transfer_screen.dart';
import 'detailed_account_view_screen.dart';
import 'transaction_history_screen.dart' as ths;
import 'beneficiary_management_screen.dart' as bms;
import 'services_management_screen.dart';
import 'deposit_opening_screen.dart';
import 'loan_landing_screen.dart';
import 'chat_bot_screen.dart';
import 'atm_locator_screen.dart';
import '../providers/dashboard_provider.dart';
import '../models/customer_account_model.dart';

final BankingService _bankingService = BankingService();

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isBalanceVisible = false;
  bool _isAccountNoVisible = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    // WATCH THE REAL API DATA
    final accountAsync = ref.watch(dashboardAccountProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      // 1. DRAWER (Preserved Logic)
      drawer: accountAsync.maybeWhen(
        data: (account) => _buildDrawer(context, account),
        orElse: () => const Drawer(child: Center(child: CircularProgressIndicator())),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(dashboardAccountProvider),
        child: CustomScrollView(
          slivers: [
            // 2. APP BAR (Preserved with dynamic Welcome Name)
            accountAsync.when(
              data: (account) => _buildAppBar(context, account.firstName),
              loading: () => _buildAppBar(context, "User"),
              error: (_, __) => _buildAppBar(context, "Error"),
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: kPaddingMedium),

                  // 3. ACCOUNT CARD (Preserved Design, Real Data)
                  accountAsync.when(
                    data: (account) => _buildAccountCarousel(context, account),
                    loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => Center(child: Text("Connection Error: $err")),
                  ),

                  _buildTpinAlertCard(),

                  // 4. QUICK SERVICES GRID (Preserved Logic - Not Skipped)
                  _buildQuickActions(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DESIGN: SliverAppBar with Notification Logic ---
  Widget _buildAppBar(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 55, bottom: 16),
        title: Text(
          "Welcome back, $name",
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () => _showNotificationOverlay(context),
        ),
      ],
    );
  }

  Widget _buildAccountCarousel(BuildContext context, CustomerAccount account) {
    return SizedBox(
      height: 200, // Increased slightly from 180 to 200 to give the Column more breathing room
      child: PageView(
        controller: _pageController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: _buildSingleAccountCard(context, account),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAccountCard(BuildContext context, CustomerAccount account) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayAcc = _isAccountNoVisible
        ? account.savingAccountNumber
        : "**** **** ${account.savingAccountNumber.substring(account.savingAccountNumber.length - 4)}";

    return GestureDetector(
      onTap: () => _navigateTo(DetailedAccountViewScreen(customerId: account.customerId)),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          // FIX: Constrain height to prevent overflow
          constraints: const BoxConstraints(minHeight: 160, maxHeight: 185),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: const Border(left: BorderSide(color: Colors.orange, width: 6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min, // FIX: Don't take unnecessary vertical space
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(account.accountType.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  SizedBox(
                    height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(_isBalanceVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                    ),
                  )
                ],
              ),
              const Text("Available Balance", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),

              // THE LIVE BALANCE FETCH
              FutureBuilder<double>(
                future: ref.read(dashboardApiServiceProvider).fetchCurrentBalance(account.customerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("₹ ...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
                  }

                  final balance = snapshot.data ?? 0.0;
                  return FittedBox( // FIX: Prevents horizontal RenderFlex error
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isBalanceVisible ? "₹ ${balance.toStringAsFixed(2)}" : "•••••••",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  );
                },
              ),

              const Spacer(), // Pushes the footer to the bottom safely

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // FIX: Prevents long names from causing overflow
                    child: Text(
                      "${account.firstName} | $displayAcc",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(_isAccountNoVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isAccountNoVisible = !_isAccountNoVisible),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- DESIGN: Quick Actions Grid (Preserved) ---
  Widget _buildQuickActions() {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Map<String, dynamic>> actions = [
      {'label': 'Quick Transfer', 'icon': Icons.flash_on_outlined, 'color': kAccentOrange, 'screen': const QuickTransferScreen()},
      {'label': 'Transfer', 'icon': Icons.send_outlined, 'color': colorScheme.primary, 'screen': TransferFundsScreen(bankingService: _bankingService)},
      {'label': 'Payees', 'icon': Icons.people_alt_outlined, 'color': colorScheme.primary, 'screen': const bms.BeneficiaryManagementScreen()},
      {'label': 'Loan', 'icon': Icons.request_quote, 'color': colorScheme.primary, 'screen': const LoanLandingScreen()},
      {'label': 'History', 'icon': Icons.history, 'color': colorScheme.primary, 'screen': ths.TransactionHistoryScreen()},
      {'label': 'T-PIN', 'icon': Icons.lock_reset_outlined, 'color': colorScheme.primary, 'screen': const TpinManagementScreen()},
      {'label': 'Services', 'icon': Icons.design_services, 'color': colorScheme.primary, 'screen': ServicesManagementScreen()},
      {'label': 'Deposits', 'icon': Icons.lock_clock, 'color': colorScheme.primary, 'screen': DepositOpeningScreen()},
      {'label': 'Locate Us', 'icon': Icons.map_outlined, 'color': colorScheme.primary, 'screen': AtmLocatorScreen()},
    ];

    return Padding(
      padding: const EdgeInsets.all(kPaddingMedium),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return InkWell(
            onTap: () => _navigateTo(action['screen']),
            child: Card(
              elevation: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action['icon'], color: action['color'], size: 30),
                  const SizedBox(height: 5),
                  Text(action['label'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- DESIGN: Notification Slide Down (Preserved) ---
  void _showNotificationOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 400,
              margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)]),
              child: const Center(child: Text("No New Notifications")),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, -0.1), end: const Offset(0, 0)).animate(anim1),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, CustomerAccount account) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            accountName: Text(account.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(account.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(account.firstName[0], style: TextStyle(color: colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          ListTile(leading: const Icon(Icons.person_outline), title: const Text("Profile"), onTap: () => _navigateTo(const ProfileManagementScreen())),
          ListTile(leading: const Icon(Icons.logout), title: const Text("Logout"), onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildTpinAlertCard() {
    if (_bankingService.isTpinSet) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 10),
          Expanded(child: Text("Set your T-PIN to enable transactions", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}