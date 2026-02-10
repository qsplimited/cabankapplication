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
import 'tpin_screen.dart';

import 'fund_transfer_screen.dart';

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
    final accountAsync = ref.watch(dashboardAccountProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      drawer: accountAsync.maybeWhen(
        data: (account) => _buildDrawer(context, account),
        orElse: () => const Drawer(child: Center(child: CircularProgressIndicator())),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(dashboardAccountProvider),
        child: CustomScrollView(
          slivers: [
            accountAsync.when(
              data: (account) => _buildAppBar(context, account.firstName),
              loading: () => _buildAppBar(context, "User"),
              error: (_, __) => _buildAppBar(context, "Error"),
            ),

            // THIS IS THE FIX: Wrapping the Column inside accountAsync.when
            accountAsync.when(
              data: (account) => SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: kPaddingMedium),
                    _buildAccountCarousel(context, account), // Preserved
                    _buildTpinAlertCard(),                  // Preserved
                    _buildQuickActions(account),            // FIXED: Passing account
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(child: Text("Connection Error: $err")),
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
      expandedHeight: 90.0, // Reduced from 120 to 90 to remove extra space
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.primary,
      automaticallyImplyLeading: true, // Ensures drawer icon is aligned
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 12), // Aligned with Drawer icon
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back,",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                onPressed: () => _showNotificationOverlay(context),
              ),
              // Optional: Small red dot for "new" notifications
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                ),
              )
            ],
          ),
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

    // Masking logic for Account Number
    final displayAcc = _isAccountNoVisible
        ? account.savingAccountNumber
        : "**** **** ${account.savingAccountNumber.substring(account.savingAccountNumber.length > 4 ? account.savingAccountNumber.length - 4 : 0)}";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Tight margins
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailedAccountViewScreen(customerId: account.customerId)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: const Border(left: BorderSide(color: Colors.orange, width: 5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: Visible Account Type & Hidden Account Number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    account.accountType.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange, letterSpacing: 1),
                  ),
                  Row(
                    children: [
                      Text(displayAcc, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isAccountNoVisible = !_isAccountNoVisible),
                        child: Icon(_isAccountNoVisible ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Text("Available Balance", style: TextStyle(color: Colors.grey, fontSize: 12)),

              // MIDDLE ROW: Hidden Balance with Fixed Alignment (RenderFlex Fix)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FutureBuilder<double>(
                      future: ref.read(dashboardApiServiceProvider).fetchCurrentBalance(account.savingAccountNumber),
                      builder: (context, snapshot) {
                        final balance = snapshot.data ?? 0.0;
                        return FittedBox( // Scales text to fit container perfectly
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _isBalanceVisible ? "₹ ${balance.toStringAsFixed(2)}" : "₹ •••••••",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              letterSpacing: _isBalanceVisible ? 0 : 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(_isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: colorScheme.primary, size: 22),
                    onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 10),

              // BOTTOM ROW: Always Visible User Name
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      account.fullName, // Visible by default
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DESIGN: Quick Actions Grid (Preserved) ---
  Widget _buildQuickActions(CustomerAccount account) { // Added parameter here
    final colorScheme = Theme.of(context).colorScheme;
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'Quick Transfer',
        'icon': Icons.flash_on_outlined,
        'color': kAccentOrange,
        // This passes the real account data fetched from dashboardAccountProvider
        'screen': FundTransferScreen(account: account),
      },


      {'label': 'Transfer', 'icon': Icons.send_outlined, 'color': colorScheme.primary, 'screen': TransferFundsScreen(bankingService: _bankingService)},
      {'label': 'Payees', 'icon': Icons.people_alt_outlined, 'color': colorScheme.primary, 'screen': const bms.BeneficiaryManagementScreen()},
      {'label': 'Loan', 'icon': Icons.request_quote, 'color': colorScheme.primary, 'screen': const LoanLandingScreen()},
      {'label': 'History', 'icon': Icons.history, 'color': colorScheme.primary, 'screen': ths.TransactionHistoryScreen()},
      {
        'label': 'T-PIN',
        'icon': Icons.lock_reset_outlined,
        'color': colorScheme.primary,
        // SUCCESS: Using the real account number from the API
        'screen': TpinScreen(accountNumber: account.savingAccountNumber),
      },
      {'label': 'Services', 'icon': Icons.design_services, 'color': colorScheme.primary, 'screen': ServicesManagementScreen()},
      {'label': 'Deposits', 'icon': Icons.lock_clock, 'color': colorScheme.primary, 'screen': DepositOpeningScreen()},
      {'label': 'Locate Us', 'icon': Icons.map_outlined, 'color': colorScheme.primary, 'screen': AtmLocatorScreen()},
    ];

    // ... Rest of your GridView.builder code remains exactly the same
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
                  Icon(action['icon'], color: action['color'] ?? colorScheme.primary, size: 30),
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