import 'package:flutter/material.dart';
import '../api/banking_service.dart';


import 'profile_management_screen.dart';

// We need to import the screen files that are being navigated to.
import 'transfer_funds_screen.dart';
import 'tpin_management_screen.dart';
import 'detailed_statement_screen.dart';
import 'quick_transfer_screen.dart';
import 'detailed_account_view_screen.dart';
// CRITICAL FIX: Use prefixes for screens that are incorrectly defining duplicate types.
import 'transaction_history_screen.dart' as ths;
import 'beneficiary_management_screen.dart' as bms;
// NOTE: Assuming BankingService is correctly defined in '../api/banking_service.dart'
final BankingService _bankingService = BankingService();

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  // Data State
  UserProfile? _userProfile;
  List<Account> _allAccounts = [];
  List<Transaction>? _miniStatement;
  // UI State
  bool _isLoading = true;
  String _errorMessage = '';
  // Global toggle for all account balances (Starts OFF / masked)
  bool _isBalanceVisible = false;
  // State for toggling Account Number visibility (Starts OFF / masked)
  bool _isAccountNoVisible = false; // <<< THIS IS CRITICAL: Starts as false
  int _currentAccountIndex = 0;
  // CRITICAL FIX: Initialize PageController
  late final PageController _pageController;
  // --- REVISED COLOR PALETTE (Vibrant & Professional) ---
  final Color _primaryCorporateBlue = const Color(0xFF0A2B59); // Deep Navy Blue (Primary Background)
  final Color _secondaryAccentBlue = const Color(0xFF1B4E8B); // Medium Blue
  final Color _lightBackground = const Color(0xFFF7F9FB); // Off-White screen background
  final Color _cardBackground = Colors.white; // Pure white for cards
  final Color _accentRed = const Color(0xFFD32F2F);
  final Color _accentGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _fetchDashboardData();
    _bankingService.onDataUpdate.listen((_) {
      if (mounted) {
        _fetchDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Data Fetching Logic (Unchanged) ---
  Future<void> _fetchDashboardData() async {
    if (!_isLoading) {
      setState(() {
        _errorMessage = '';
      });
    }

    try {
      final results = await Future.wait([
        _bankingService.fetchUserProfile(),
        _bankingService.fetchUserAccounts(),
      ]);

      final userProfile = results[0] as UserProfile;
      final allAccounts = results[1] as List<Account>;

      List<Transaction>? miniStatement;
      if (allAccounts.isNotEmpty) {
        miniStatement = await _bankingService.fetchMiniStatement();
      }

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _allAccounts = allAccounts;
          _miniStatement = miniStatement;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data. Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  // 1. Account Carousel (Unchanged)
  Widget _buildAccountCarousel(BuildContext context) {
    if (_allAccounts.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('No accounts found.')));
    }

    const cardHeight = 180.0;
    return SizedBox(
      height: cardHeight,
      child: PageView.builder(
        controller: _pageController, // Use the initialized controller
        itemCount: _allAccounts.length,
        onPageChanged: (index) {
          setState(() {
            _currentAccountIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final account = _allAccounts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildSingleAccountCard(context, account),
          );
        },
      ),
    );
  }
  // **CRITICAL FIXES APPLIED HERE**
  Widget _buildSingleAccountCard(BuildContext context, Account account) {
    final theme = Theme.of(context);

    // Balance display logic (remains the same: masked by default)
    final balanceText = _isBalanceVisible
        ? '₹${account.balance.toStringAsFixed(2)}'
        : '•••••••';

    Color stripeColor;
    if (account.accountType == AccountType.fixedDeposit || account.accountType == AccountType.recurringDeposit) {
      stripeColor = Colors.orange.shade600;
    } else if (account.accountType == AccountType.current) {
      stripeColor = Colors.teal.shade500;
    } else {
      stripeColor = _secondaryAccentBlue;
    }
    // Account Number display logic: Masked by default, shown if _isAccountNoVisible is true.
    final String fullAccountNo = account.accountNumber;
    // Masking format: '5555 **** 4333' (as seen in the screenshot)
    final String maskedAccountNo = '${fullAccountNo.substring(0, 4)} **** ${fullAccountNo.substring(fullAccountNo.length - 4)}';

    // DECISION: Which string to display
    final String displayAccountNo = _isAccountNoVisible ? fullAccountNo : maskedAccountNo;


    return GestureDetector(
      onTap: () {
        _navigateTo(DetailedAccountViewScreen(account: account));
      },
      child: Card(
        color: _cardBackground,
        elevation: 6,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // UNIQUE DESIGN: Colored Vertical Stripe
              Container(
                width: 6.0,
                decoration: BoxDecoration(
                  color: stripeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Type & Balance Visibility Toggle (FIX APPLIED HERE)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ➡️ FIX: Wrap the long text in Flexible to prevent overflow
                          Flexible(
                            child: Text(
                              '${account.accountType.name.toUpperCase()} ACCOUNT',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Balance Visibility Toggle Icon (fixed size)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                // Logic: If visible, show CLOSE eye. If masked, show OPEN eye.
                                _isBalanceVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: _primaryCorporateBlue,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Balance Display
                      Text(
                        'Available Balance',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      // FIX: Ensure font size is constrained to prevent overflow
                      Flexible(
                        child: Text(
                          balanceText,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _primaryCorporateBlue,
                            fontSize: 30, // Kept at 30 for stability
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const Spacer(),

                      // Account Nickname & Number with new Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Account Nickname & Number (Wrapped in Flexible for safety)
                          Flexible(
                            child: Text(
                              '${account.nickname} | $displayAccountNo',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // CORRECTED ICON LOGIC for Account Number (fixed size)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isAccountNoVisible = !_isAccountNoVisible;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                // Logic: If visible, show CLOSE eye. If masked, show OPEN eye (to invite view).
                                _isAccountNoVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: _primaryCorporateBlue.withOpacity(0.7),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // 2. Quick Actions Grid - MODIFIED
  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [
      {'label': 'Quick Transfer', 'icon': Icons.flash_on_outlined, 'color': Colors.orange.shade700, 'screen': const QuickTransferScreen()},
      {'label': 'Standard Transfer', 'icon': Icons.send_outlined, 'color': _primaryCorporateBlue, 'screen': TransferFundsScreen(bankingService: _bankingService)},
      {'label': 'Manage Payees', 'icon': Icons.people_alt_outlined, 'color': Colors.purple.shade700, 'screen': const bms.BeneficiaryManagementScreen()},
      // MODIFICATION: Renamed to Scan & Pay (UPI)
      {'label': 'Scan & Pay (UPI)', 'icon': Icons.qr_code_scanner, 'color': Colors.green.shade700, 'screen': null},
      {'label': 'Transaction History', 'icon': Icons.history, 'color': Colors.brown.shade700, 'screen': ths.TransactionHistoryScreen(bankingService: _bankingService)},
      {'label': 'T-PIN Management', 'icon': Icons.lock_reset_outlined, 'color': _primaryCorporateBlue, 'screen': const TpinManagementScreen()},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 10.0, top: 20.0),
            child: Text(
              'Quick Services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: () {
                  if (action['screen'] != null) {
                    _navigateTo(action['screen'] as Widget);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${action['label']} feature coming soon!')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  color: _cardBackground,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action['icon'], size: 36, color: action['color']),
                        const SizedBox(height: 8),
                        Text(
                          action['label'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  // 3. T-PIN Status Alert (Unchanged)
  Widget _buildTpinAlertCard() {
    if (_bankingService.isTpinSet) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Card(
        color: Colors.red.shade50,
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade300, width: 1.5)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.security_update_warning, color: Colors.red.shade800, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTION REQUIRED: T-PIN Not Set',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set your T-PIN now to enable secure transactions.',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _navigateTo(const TpinManagementScreen()),
                      child: Text(
                        'SET T-PIN NOW >',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryCorporateBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // 4. Mini Statement List (Unchanged)
  // FULL CODE WITH OVERFLOW FIX — NO OTHER CHANGES

// (Your entire code stays identical until this section)

  Widget _buildMiniStatement(BuildContext context) {
    if (_miniStatement == null || _miniStatement!.isEmpty || _allAccounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No recent transactions found for ${_allAccounts.isNotEmpty ? _allAccounts[_currentAccountIndex].nickname : 'the selected account'}.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final currentAccount = _allAccounts[_currentAccountIndex];

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              children: [

                // 🔥 FIX APPLIED HERE — prevents overflow
                Expanded(
                  child: Text(
                    'Recent Transactions (${currentAccount.nickname})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    _navigateTo(
                      DetailedStatementScreen(
                        bankingService: _bankingService,
                        account: currentAccount,
                      ),
                    );
                  },
                  child: Text(
                    'VIEW ALL',
                    style: TextStyle(
                      color: _primaryCorporateBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // (The rest of your code remains unchanged)
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: _cardBackground,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _miniStatement!.length > 5 ? 5 : _miniStatement!.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final tx = _miniStatement![index];
                final isDebit = tx.type == TransactionType.debit;
                final amountColor = isDebit ? _accentRed : _accentGreen;
                final iconColor = isDebit ? _accentRed : _accentGreen;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${tx.date.day}/${tx.date.month} | ${tx.date.hour}:${tx.date.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Text(
                          '${isDebit ? '-' : '+'} ₹${tx.amount.toStringAsFixed(2)}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _primaryCorporateBlue),
              const SizedBox(height: 16),
              const Text('Loading dashboard data...')
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty || _userProfile == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: $_errorMessage',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final String userFullName = _userProfile!.fullName;
    final String userFirstName = userFullName.split(' ').first;
    final String userInitial = userFullName.split(' ').first.substring(0, 1).toUpperCase();
    return Scaffold(
      backgroundColor: _lightBackground,
      // --- DRAWER (Menu Bar) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: _primaryCorporateBlue),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                CircleAvatar(backgroundColor: Colors.white, radius: 30, child: Text(userInitial, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryCorporateBlue))),
                const SizedBox(height: 8),
                Text(userFullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const Text('Account Holder', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ]),
            ),
            ListTile(leading: Icon(Icons.dashboard_outlined, color: _primaryCorporateBlue),
                title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),

            ListTile(leading: Icon(Icons.person_2_outlined, color: Colors.orange.shade700),
                title: const Text('Profile'),
                onTap: () { Navigator.pop(context); _navigateTo(const ProfileManagementScreen()); }),

            ListTile(leading: Icon(Icons.flash_on_outlined, color: Colors.orange.shade700),
                title: const Text('Quick Transfer (IMPS)'),
                onTap: () { Navigator.pop(context); _navigateTo(const QuickTransferScreen()); }),
            ListTile(leading: Icon(Icons.payments_outlined, color: _primaryCorporateBlue),
                title: const Text('Standard Transfer (Beneficiary)'),
                onTap: () { Navigator.pop(context); _navigateTo(TransferFundsScreen(bankingService: _bankingService)); }),
            ListTile(leading: Icon(Icons.people_alt_outlined, color: Colors.purple.shade700),
                title: const Text('Beneficiary Management'),
                onTap: () { Navigator.pop(context); _navigateTo(const bms.BeneficiaryManagementScreen()); }),
            // MODIFIED MENU ITEM
            ListTile(leading: Icon(Icons.qr_code_scanner, color: Colors.green.shade700),
                title: const Text('Scan & Pay (UPI)'), onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan & Pay (UPI) feature coming soon!')));
            }),
            ListTile(leading: Icon(Icons.history_toggle_off_outlined, color: Colors.brown.shade700),
                title: const Text('Transaction History'),
                onTap: () { Navigator.pop(context); _navigateTo(ths.TransactionHistoryScreen(bankingService: _bankingService)); }),
            ListTile(leading: Icon(Icons.lock_reset_outlined, color: _primaryCorporateBlue),
                title: const Text('T-PIN Management'),
                onTap: () { Navigator.pop(context); _navigateTo(const TpinManagementScreen()); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout'), onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logging out user...')));
              Navigator.pop(context);
            }),
          ],
        ),
      ),
      // --- APP BAR (Unique Integrated Design) ---
      appBar: AppBar(
        backgroundColor: _primaryCorporateBlue, // Solid Navy Blue Header
        elevation: 0,
        toolbarHeight: 0, // Set toolbar height to 0 to make it visually disappear
      ),
      // --- BODY (Stabilized CustomScrollView) ---
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: _primaryCorporateBlue,
        child: CustomScrollView(
          slivers: <Widget>[

            // 1. UNIQUE HEADER & WELCOME MESSAGE
            SliverToBoxAdapter(
              child: Container(
                height: 100, // Fixed height for the header background
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: _primaryCorporateBlue,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back,',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              userFirstName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                          onPressed: () { /* Notifications */ },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 12),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 15,
                            child: Text(
                              userInitial,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryCorporateBlue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 2. Account Summary Carousel (Pulled up into the header curve)
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -50), // Less aggressive pull-up
                child: _buildAccountCarousel(context),
              ),
            ),

            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -40), // Slightly reduced offset for safety
                child: Column(
                  children: [
                    // Page Indicator Dots
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_allAccounts.length, (index) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentAccountIndex == index
                                  ? _secondaryAccentBlue
                                  : Colors.grey.shade400,
                            ),
                          );
                        }),
                      ),
                    ),

                    // T-PIN Status Alert
                    _buildTpinAlertCard(),

                    // Quick Actions
                    _buildQuickActions(),

                    // Mini Statement List
                    _buildMiniStatement(context),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}