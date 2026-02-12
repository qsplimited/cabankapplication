import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // Watches the same provider as the dashboard to get current user details
    final accountAsync = ref.watch(dashboardAccountProvider);

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text('Profile Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kBrandNavy, // Portal Dark Blue
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kAccentOrange)),
        error: (err, _) => Center(child: Text("Unable to load profile: $err")),
        data: (user) => Column(
          children: [
            _buildProfileHeader(user),
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

  Widget _buildProfileHeader(CustomerAccount user) {
    return Container(
      width: double.infinity,
      color: kBrandNavy,
      padding: const EdgeInsets.only(bottom: kPaddingLarge, left: kPaddingMedium, right: kPaddingMedium),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: kAccentOrange,
            child: Text(
              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: kPaddingMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              Text("Customer ID: ${user.customerId}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: kAccentOrange,
        labelColor: kBrandNavy,
        unselectedLabelColor: kLightTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: "PERSONAL INFO"),
          Tab(text: "ACCOUNT DETAILS"),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab(CustomerAccount user) {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _infoCard("Identity Details", [
          _detailRow("Full Name", user.fullName),
          _detailRow("Document Type", user.documentType),
          _detailRow("Document Number", user.documentNumber),
          _detailRow("Registration Date", user.createdDate),
        ]),
        const SizedBox(height: kPaddingMedium),
        _infoCard("Contact Information", [
          _detailRow("Mobile No", user.mobileNo),
          _detailRow("Email Address", user.email),
        ]),
      ],
    );
  }

  Widget _buildAccountTab(CustomerAccount user) {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _infoCard("Banking Information", [
          _detailRow("Account Number", user.savingAccountNumber),
          _detailRow("Account Type", user.accountType),
          _detailRow("Branch Code", user.branchCode),
          //_detailRow("Approver ID", user.approverStaffId ?? "N/A"),
        ]),
        const SizedBox(height: kPaddingMedium),
/*        _infoCard("Balance Summary", [
          _detailRow("Available Balance", "₹ ${user.balance.toStringAsFixed(2)}"),
          _buildStatusRow("Account Status", "ACTIVE"),
        ]),*/
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
        side: const BorderSide(color: kLightDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kBrandNavy)),
            const Divider(height: kPaddingLarge),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kPaddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kLightTextSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kLightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kLightTextSecondary, fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: kSuccessGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(kRadiusExtraSmall),
          ),
          child: Text(
            status,
            style: const TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }
}