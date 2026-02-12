import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For formatting the date
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/customer_account_model.dart';
import '../providers/dashboard_provider.dart';

class ProfileManagementScreen extends ConsumerStatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  ConsumerState<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends ConsumerState<ProfileManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(dashboardAccountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: kAccentOrange,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kAccentOrange)),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (user) => Column(
          children: [
            _buildSimpleHeader(user),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalInfoTab(user),
                  _buildAccountTab(user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleHeader(CustomerAccount user) {
    // Creating a mock last login date (You can replace this with actual data from your model)
    String lastLogin = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now().subtract(const Duration(hours: 2)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: kPaddingLarge, horizontal: kPaddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: kAccentOrange.withOpacity(0.1),
            child: Text(
              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 32, color: kAccentOrange, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text("Customer ID: ${user.customerId}",
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),

          // Last Login Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history, size: 14, color: Colors.orange),
              const SizedBox(width: 5),
              Text("Last Login: $lastLogin",
                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: kAccentOrange,
      indicatorWeight: 3,
      labelColor: kAccentOrange,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      tabs: const [
        Tab(text: "PERSONAL"),
        Tab(text: "ACCOUNT"),
      ],
    );
  }

  Widget _buildPersonalInfoTab(CustomerAccount user) {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _simpleInfoCard([
          _detailRow("Full Name", user.fullName),
          _detailRow("Mobile", user.mobileNo),
          _detailRow("Email", user.email),
          _detailRow("Doc Type", user.documentType),
          _detailRow("Doc No", user.documentNumber),
        ]),
      ],
    );
  }

  Widget _buildAccountTab(CustomerAccount user) {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _simpleInfoCard([
          _detailRow("Account No", user.savingAccountNumber),
          _detailRow("Type", user.accountType),
          _detailRow("Branch", user.branchCode),
          _detailRow("Joined", user.createdDate),
          _statusRow("Account Status", "ACTIVE"),
        ]),
      ],
    );
  }

  // Simplified Card with light orange border
  Widget _simpleInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusMedium),
        border: Border.all(color: kAccentOrange.withOpacity(0.3)),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(status, style: const TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}