import 'package:flutter/material.dart';
import '../api/banking_service.dart'; // Retaining user's service path
import '../main.dart'; // Retaining user's main import

import 'transfer_funds_screen.dart';
// FIX: Import the file containing the unified TpinManagementScreen.
import 'tpin_management_screen.dart'; // <-- CORRECTED IMPORT

final BankingService _bankingService = BankingService();

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Data State
  UserProfile? _userProfile;
  Account? _primaryAccount;
  List<Transaction>? _miniStatement;

  // UI State
  bool _isLoading = true;
  String _errorMessage = '';
  // Balance is now hidden by default
  bool _isBalanceVisible = false;

  // --- Final Color Palette (Deeper Navy Blue - Hex: 0xFF003366) ---
  final Color _primaryNavyBlue = const Color(0xFF003366); // Deep Navy Blue for header and main accents
  final Color _accentRed = const Color(0xFFD32F2F); // Standard Red for negative/debit
  final Color _accentGreen = const Color(0xFF4CAF50); // Green for credit/positive
  final Color _lightBackground = const Color(0xFFF0F0F0); // General screen background

  // Colors for Quick Actions
  final Color _transferColor = const Color(0xFFE3F2FD);
  final Color _withdrawColor = const Color(0xFFFFEBEE);
  final Color _billPayColor = const Color(0xFFFFECB3);
  final Color _loansColor = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    // CRITICAL: Listen to the BankingService stream for real-time updates (e.g., T-PIN status change)
    _bankingService.onDataUpdate.listen((_) {
      if (mounted) {
        _fetchDashboardData();
      }
    });
  }

  // --- Data Fetching Logic ---
  Future<void> _fetchDashboardData() async {
    // Only show full loading screen on initial load
    if (!_isLoading) {
      setState(() {
        // Only set loading indicator for partial rebuilds
        _errorMessage = '';
      });
    }

    try {
      final results = await Future.wait([
        _bankingService.fetchUserProfile(),
        _bankingService.fetchAccountSummary(),
        _bankingService.fetchMiniStatement(),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = results[0] as UserProfile;
          _primaryAccount = results[1] as Account;
          _miniStatement = results[2] as List<Transaction>;
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

  // --- NAVIGATION HELPER FUNCTION ---
  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // --- UI Components ---

  // 1. Account Card with Balance and Toggle
  Widget _buildAccountCard(BuildContext context) {
    if (_primaryAccount == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final account = _primaryAccount!;
    final balanceText = _isBalanceVisible
        ? '₹${account.balance.toStringAsFixed(2)}'
        : '•••••••';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Nickname
            Text(
              account.nickname,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 15),

            // Balance Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      balanceText,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _primaryNavyBlue, // Navy Blue for Balance
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Corrected Account Type Display
                    Text(
                      'Type: ${account.accountType}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
                // Visibility Toggle Icon
                InkWell(
                  onTap: () {
                    setState(() {
                      _isBalanceVisible = !_isBalanceVisible;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      _isBalanceVisible ? Icons.visibility_off : Icons.visibility,
                      color: _primaryNavyBlue.withOpacity(0.7),
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. Quick Actions Grid
  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [
      {'label': 'Transfer', 'icon': Icons.send_outlined, 'color': _primaryNavyBlue, 'bgColor': _transferColor, 'screen': TransferFundsScreen(bankingService: _bankingService)},
      {'label': 'Withdraw', 'icon': Icons.account_balance_wallet_outlined, 'color': _accentRed, 'bgColor': _withdrawColor, 'screen': null}, // Placeholder
      {'label': 'Bill Pay', 'icon': Icons.receipt_long_outlined, 'color': _primaryNavyBlue, 'bgColor': _billPayColor, 'screen': null}, // Placeholder
      {'label': 'My Loans', 'icon': Icons.savings_outlined, 'color': _accentGreen, 'bgColor': _loansColor, 'screen': null}, // Placeholder
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
            child: Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
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
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: action['bgColor'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action['icon'], size: 30, color: action['color']),
                      const SizedBox(height: 5),
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
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. T-PIN Status Alert
  Widget _buildTpinAlertCard() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          color: const Color(0xFFFFE0B2), // Light Orange/Amber
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.security_update_warning, color: Color(0xFFE65100), size: 30), // Darker Orange
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SECURITY ALERT: T-PIN Required',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You must set your T-PIN to perform transactions.',
                        style: TextStyle(fontSize: 13, color: Color(0xFFE65100)),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _navigateTo(const TpinManagementScreen()), // Navigate to the unified screen
                        child: const Text(
                          'SET T-PIN NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
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
      ),
    );
  }


  // 4. Mini Statement List
  Widget _buildMiniStatement(BuildContext context) {
    if (_miniStatement == null || _miniStatement!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          // Transaction List Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _miniStatement!.length > 5 ? 5 : _miniStatement!.length, // Show top 5
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final tx = _miniStatement![index];
                final isDebit = tx.type == TransactionType.debit;
                final amountColor = isDebit ? _accentRed : _accentGreen;
                final iconColor = isDebit ? _accentRed : _accentGreen;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      // Transaction Icon Circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1), // Very light colored background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
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
                      // Amount
                      Text(
                        '${isDebit ? '-' : '+'} ₹${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                          fontSize: 15,
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
              CircularProgressIndicator(color: _primaryNavyBlue),
              const SizedBox(height: 16),
              const Text('Loading dashboard data...')
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
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
    final String lastLogin = '${_userProfile!.lastLogin.hour}:${_userProfile!.lastLogin.minute.toString().padLeft(2, '0')} on ${_userProfile!.lastLogin.day}/${_userProfile!.lastLogin.month}';


    return Scaffold(
      backgroundColor: _lightBackground,
      // --- DRAWER ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: _primaryNavyBlue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Text(userInitial, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryNavyBlue)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      userFullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                  ),
                  Text(
                      'Last Login: $lastLogin',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard_outlined, color: _primaryNavyBlue),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.payments_outlined, color: _primaryNavyBlue),
              title: const Text('Transfer Funds'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(TransferFundsScreen(bankingService: _bankingService));
              },
            ),
            ListTile(
              leading: Icon(Icons.history_toggle_off_outlined, color: _primaryNavyBlue),
              title: const Text('Transaction History'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction History Screen is next!')),
                );
              },
            ),
            // CRITICAL FIX 2: Navigate to the correct unified TpinManagementScreen.
            ListTile(
              leading: Icon(Icons.lock_reset_outlined, color: _primaryNavyBlue),
              title: const Text('T-PIN Management'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _navigateTo(
                  // CORRECT CLASS NAME and NO extra parameters needed
                  const TpinManagementScreen(),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logging out user...')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      // --- APP BAR ---
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('Hello, $userFirstName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primaryNavyBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () { /* Notifications */ },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 15,
              child: Text(
                userInitial,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryNavyBlue),
              ),
            ),
          ),
        ],
      ),
      // --- BODY ---
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: _primaryNavyBlue,
        child: CustomScrollView(
          slivers: <Widget>[
            // 1. Header background color
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.only(bottom: 50),
                decoration: BoxDecoration(
                  color: _primaryNavyBlue,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
              ),
            ),

            // 2. Account Summary Card
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -50),
                child: _buildAccountCard(context),
              ),
            ),

            // 3. T-PIN Status Alert (Conditional check added)
            if (!_bankingService.isTpinSet) // Check if T-PIN is set
              SliverToBoxAdapter(
                child: _buildTpinAlertCard(),
              ),

            // 4. Quick Actions
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: _buildQuickActions(),
              ),
            ),

            // 5. Mini Statement List
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: _buildMiniStatement(context),
              ),
            ),

            // 6. Padding for Scroll End
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}
