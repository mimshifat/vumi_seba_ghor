import '../../../../core/database/app_database.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/money.dart';

/// আবেদন এবং তার মোট আদায় ও মোট খরচের একত্রিত সামগ্রিক রূপ (Domain Aggregate)
class ApplicationWithFinancials {
  final Application application;
  final int totalReceivedPaisa;
  final int totalExpensePaisa;

  const ApplicationWithFinancials({
    required this.application,
    required this.totalReceivedPaisa,
    required this.totalExpensePaisa,
  });

  Money get agreed => Money.fromPaisa(application.agreedAmount);
  Money get received => Money.fromPaisa(totalReceivedPaisa);
  Money get expense => Money.fromPaisa(totalExpensePaisa);

  /// অপরিশোধিত কাঁচা বকেয়া
  Money get rawDue => Money.fromPaisa(
      (application.agreedAmount - totalReceivedPaisa).clamp(0, double.maxFinite.toInt()));

  /// কার্যকর বকেয়া ('Mark as Paid' হলে ০) - BACKEND_MASTER_PLAN.md §1.2 নিয়ম ২
  Money get effectiveDue => application.isMarkedAsPaid == 1
      ? Money.zero
      : Money.fromPaisa(
          (application.agreedAmount - totalReceivedPaisa).clamp(0, double.maxFinite.toInt()));

  /// প্রকৃত ইনকাম (Golden rule §1.2): মোট আদায় - কাজের খরচ
  Money get actualIncome => Money.fromPaisa(totalReceivedPaisa - totalExpensePaisa);

  /// সম্ভাব্য চুক্তি ইনকাম: চুক্তির টাকা - কাজের খরচ
  Money get estimatedIncome => Money.fromPaisa(application.agreedAmount - totalExpensePaisa);

  /// UI প্রেজেন্টেশন ও কার্ডের সাথে তাৎক্ষণিক সামঞ্জস্য নিশ্চিতকারী রূপান্তর
  DemoApplication toDemoApplication() {
    return DemoApplication(
      id: application.id,
      applicantId: application.applicantId ?? '',
      applicantName: application.applicantName,
      applicantPhone: application.applicantPhone,
      applicantAddress: application.applicantAddress,
      referencePersonId: application.referenceId,
      referencePersonName: application.referenceName,
      mouza: application.mouza,
      appNumber: application.appNumber,
      caseNumber: application.caseNumber,
      workType: application.workType,
      officeName: application.officeName,
      applicationDate:
          DateTime.fromMillisecondsSinceEpoch(application.applicationDate),
      status: application.status,
      agreedAmount: agreed,
      receivedAmount: received,
      expenseAmount: expense,
      portalPhone: application.portalPhone,
      portalPassword: application.portalPassword,
      notes: application.notes,
      isMarkedAsPaid: application.isMarkedAsPaid == 1,
    );
  }
}

