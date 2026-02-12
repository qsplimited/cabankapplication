import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../api/banking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'profile_management_screen.dart';
import 'transfer_funds_screen.dart';
import 'detailed_account_view_screen.dart';
import 'transaction_history_screen.dart' as ths;
import 'beneficiary_management_screen.dart' as bms;
import 'services_management_screen.dart';
import 'deposit_opening_screen.dart';
import 'loan_landing_screen.dart';
import 'atm_locator_screen.dart';
import '../providers/dashboard_provider.dart';
import '../models/customer_account_model.dart';
import 'tpin_screen.dart';
import 'fund_transfer_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Ensure this matches your project structure
import '../providers/transaction_history_provider.dart';

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
        color: kAccentOrange,
        onRefresh: () async {
          // Refreshes the Account Details
          await ref.refresh(dashboardAccountProvider.future);

          // Refreshes the Transaction History based on the account number
          final account = ref.read(dashboardAccountProvider).value;
          if (account != null) {
            await ref.refresh(transactionHistoryProvider(account.savingAccountNumber).future);
          }
        },
        child: CustomScrollView(
          slivers: [
            accountAsync.when(
              data: (account) => _buildAppBar(context, account.firstName),
              loading: () => _buildAppBar(context, "User"),
              error: (_, __) => _buildAppBar(context, "Error"),
            ),
            accountAsync.when(
              data: (account) => SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: kPaddingMedium),

                    // 1. Preserved Balance Card Carousel
                    _buildAccountCarousel(context, account),

                    _buildTpinAlertCard(),

                    // 2. Quick Services Section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(kPaddingMedium, kPaddingLarge, kPaddingMedium, 0),
                      child: Text("Quick Services",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandNavy)),
                    ),
                    _buildQuickActions(account),

                    // 3. Recent Transactions Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Recent Transactions",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandNavy)),
                          TextButton(
                            onPressed: () => _navigateTo(ths.TransactionHistoryScreen(accountNumber: account.savingAccountNumber)),
                            child: const Text("View All", style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                    // Displaying the list of top 5 transactions
                    _buildDashboardTransactionList(account.savingAccountNumber),

                    const SizedBox(height: kPaddingXXL), // Spacing for bottom of screen
                  ],
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: kAccentOrange))),
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

  // Transaction List UI for Dashboard
  Widget _buildDashboardTransactionList(String accountNumber) {
    final historyAsync = ref.watch(transactionHistoryProvider(accountNumber));

    return historyAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(kPaddingLarge),
        child: CircularProgressIndicator(strokeWidth: 2, color: kAccentOrange),
      )),
      error: (err, _) => const Center(child: Text("Unable to load transactions")),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(kPaddingLarge),
            child: Text("No recent activity", style: TextStyle(color: Colors.grey)),
          ));
        }

        final latest5 = transactions.reversed.take(5).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
          itemCount: latest5.length,
          itemBuilder: (context, index) {
            final tx = latest5[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kRadiusMedium),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: tx.isDebit ? kErrorRed.withOpacity(0.1) : kSuccessGreen.withOpacity(0.1),
                    child: Icon(
                      tx.isDebit ? Icons.call_made : Icons.call_received,
                      size: 16,
                      color: tx.isDebit ? kErrorRed : kSuccessGreen,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.isDebit ? "Money Sent" : "Money Received",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(DateFormat('dd MMM yyyy').format(tx.transactionDateTime),
                            style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    "${tx.isDebit ? '-' : '+'} ₹${tx.transactionAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: tx.isDebit ? kErrorRed : kSuccessGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- PRESERVED METHODS ---

  Widget _buildAppBar(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 90.0,
      pinned: true,
      backgroundColor: colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 12),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () {}),
      ],
    );
  }

  Widget _buildAccountCarousel(BuildContext context, CustomerAccount account) {
    return SizedBox(
      height: 200,
      child: PageView(
        controller: _pageController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildSingleAccountCard(context, account),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAccountCard(BuildContext context, CustomerAccount account) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayAcc = _isAccountNoVisible ? account.savingAccountNumber : "**** **** ${account.savingAccountNumber.substring(account.savingAccountNumber.length - 4)}";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateTo(DetailedAccountViewScreen(customerId: account.customerId)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: const Border(left: BorderSide(color: Colors.orange, width: 5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(account.accountType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange)),
                  Row(
                    children: [
                      Text(displayAcc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      IconButton(icon: Icon(_isAccountNoVisible ? Icons.visibility : Icons.visibility_off, size: 18), onPressed: () => setState(() => _isAccountNoVisible = !_isAccountNoVisible)),
                    ],
                  ),
                ],
              ),
              const Text("Available Balance", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isBalanceVisible ? "₹ ${account.savingAccountNumber}" : "₹ •••••••", // Note: Usually fetch balance via API here
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  IconButton(icon: Icon(_isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: colorScheme.primary), onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible)),
                ],
              ),
              const Spacer(),
              const Divider(),
              Text(account.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(CustomerAccount account) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Map<String, dynamic>> actions = [
      {'label': 'Quick Transfer', 'icon': Icons.flash_on_outlined, 'color': kAccentOrange, 'screen': FundTransferScreen(account: account)},
      {'label': 'Transfer', 'icon': Icons.send_outlined, 'screen': TransferFundsScreen(bankingService: _bankingService)},
      {'label': 'Payees', 'icon': Icons.people_alt_outlined, 'screen': const bms.BeneficiaryManagementScreen()},
      {'label': 'Loan', 'icon': Icons.request_quote, 'screen': const LoanLandingScreen()},
      {'label': 'History', 'icon': Icons.history, 'screen': ths.TransactionHistoryScreen(accountNumber: account.savingAccountNumber)},
      {'label': 'T-PIN', 'icon': Icons.lock_reset_outlined, 'screen': TpinScreen(accountNumber: account.savingAccountNumber)},
      {'label': 'Services', 'icon': Icons.design_services, 'screen': const ServicesManagementScreen()},
      {'label': 'Deposits', 'icon': Icons.lock_clock, 'screen': const DepositOpeningScreen()},
      {'label': 'Locate Us', 'icon': Icons.map_outlined, 'screen': const AtmLocatorScreen()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(kPaddingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () => _navigateTo(action['screen']),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'], color: action['color'] ?? colorScheme.primary, size: 28),
                const SizedBox(height: 4),
                Text(action['label'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
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
            accountName: Text(account.fullName),
            accountEmail: Text(account.email),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Text(account.firstName[0], style: TextStyle(color: colorScheme.primary, fontSize: 24))),
          ),
          ListTile(leading: const Icon(Icons.person_outline), title: const Text("Profile"), onTap: () => _navigateTo(const ProfileManagementScreen())),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              // 1. Close the drawer first
              Navigator.pop(context);
              // 2. Run the simple logout logic
              _handleLogout(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // 1. SET FLAG TO FALSE FIRST (The "Hard Lock")
    // This prevents any background logic from thinking the user is still logged in.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);

    if (!context.mounted) return;

    // 2. CLEAR THE ENTIRE STACK
    // Using (route) => false ensures the Dashboard is destroyed.
    // It cannot "flash" if it is deleted from the phone's memory.
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );

    // 3. WIPE SENSITIVE DATA
    // Do this after navigation has started to keep the transition smooth.
    ref.invalidate(dashboardAccountProvider);
  }



  Widget _buildTpinAlertCard() {
    if (_bankingService.isTpinSet) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text("Set your T-PIN to enable transactions", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }
}