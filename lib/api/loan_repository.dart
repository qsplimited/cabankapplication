import 'package:flutter/material.dart';
import '../models/loan_model.dart';

class LoanRepository {
  Future<Map<String, dynamic>> fetchLoanData() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    return {
      "activeLoans": [
        ActiveLoan(
          loanId: "LN-8829-X",
          type: "Personal Loan",
          balance: 14250.00,
          totalLoan: 25000.00,
          nextEmiDate: "Oct 12, 2024",
          progress: 0.43,
        ),
        ActiveLoan(
          loanId: "LN-4410-V",
          type: "Vehicle Loan",
          balance: 8900.00,
          totalLoan: 15000.00,
          nextEmiDate: "Oct 25, 2024",
          progress: 0.60,
        ),
      ],
      "products": [
        LoanProduct(
          id: "pl_01",
          title: "Personal Loan",
          interestRate: "10.5%",
          rawRate: 10.5,
          minAmount: 5000,
          maxAmount: 50000,
          maxTenureMonths: 60,
          icon: Icons.person_outline,
          tag: "Instant Approval",
          requiredDocs: ["ID Proof", "3 Months Salary Slip", "Bank Statement"],
        ),
        LoanProduct(
          id: "hl_02",
          title: "Home Loan",
          interestRate: "8.25%",
          rawRate: 8.25,
          minAmount: 50000,
          maxAmount: 1000000,
          maxTenureMonths: 360,
          icon: Icons.home_outlined,
          tag: "Low Interest",
          requiredDocs: ["Property Title", "Income Proof", "ID Proof"],
        ),
        LoanProduct(
          id: "vl_03",
          title: "Vehicle Loan",
          interestRate: "9.5%",
          rawRate: 9.5,
          minAmount: 10000,
          maxAmount: 80000,
          maxTenureMonths: 84,
          icon: Icons.directions_car_outlined,
          tag: "90% Funding",
          requiredDocs: ["Dealer Invoice", "Driver's License", "Income Proof"],
        ),
        LoanProduct(
          id: "el_04",
          title: "Education Loan",
          interestRate: "7.0%",
          rawRate: 7.0,
          minAmount: 5000,
          maxAmount: 150000,
          maxTenureMonths: 120,
          icon: Icons.school_outlined,
          tag: "Student Special",
          requiredDocs: ["Admission Letter", "Fee Structure"],
        ),
        LoanProduct(
          id: "fd_05",
          title: "Loan Against FD",
          interestRate: "6.0%",
          rawRate: 6.0,
          minAmount: 1000,
          maxAmount: 20000,
          maxTenureMonths: 24,
          icon: Icons.lock_clock_outlined,
          tag: "No Documents",
          requiredDocs: [],
        ),
      ]
    };
  }
}