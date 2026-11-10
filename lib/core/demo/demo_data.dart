import 'dart:typed_data';
import '../utils/money.dart';

class DemoReference {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final Uint8List? photo;
  final String? notes;

  const DemoReference({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.photo,
    this.notes,
  });
}

class DemoPerson {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final int applicationCount;
  final Money totalAgreed;
  final Money totalDue;

  const DemoPerson({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    this.applicationCount = 1,
    required this.totalAgreed,
    required this.totalDue,
  });
}

class DemoOffice {
  final String id;
  final String name;
  final int activeApplications;

  const DemoOffice({
    required this.id,
    required this.name,
    this.activeApplications = 0,
  });
}

class DemoPayment {
  final String id;
  final String applicationId;
  final Money amount;
  final DateTime date;
  final String method; // নগদ, বিকাশ, ব্যাংক
  final String? note;
  final String? statusHistoryId;
  final String? statusName;
  final bool isStatusFee;

  const DemoPayment({
    required this.id,
    required this.applicationId,
    required this.amount,
    required this.date,
    required this.method,
    this.note,
    this.statusHistoryId,
    this.statusName,
    this.isStatusFee = false,
  });
}

class DemoExpense {
  final String id;
  final String? applicationId;
  final String? applicationTitle;
  final Money amount;
  final String category;
  final DateTime date;
  final bool isGeneral;
  final String? note;
  final String? statusHistoryId;
  final String? statusName;
  final bool isStatusExpense;

  const DemoExpense({
    required this.id,
    this.applicationId,
    this.applicationTitle,
    required this.amount,
    required this.category,
    required this.date,
    required this.isGeneral,
    this.note,
    this.statusHistoryId,
    this.statusName,
    this.isStatusExpense = false,
  });
}

class DemoIncome {
  final String id;
  final String category;
  final Money amount;
  final DateTime date;
  final String paymentMethod; // নগদ, বিকাশ, ব্যাংক
  final String? customerName;
  final String? note;

  const DemoIncome({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.customerName,
    this.note,
  });
}

enum TransactionType {
  income,  // আয়
  expense, // খরচ
}

enum TransactionSource {
  applicationPayment,   // আবেদনের চুক্তি জমা / কিস্তি
  statusIncome,         // অবস্থা পরিবর্তন - ফি আদায়
  statusExpense,        // অবস্থা পরিবর্তন - খরচ
  independentIncome,    // স্বতন্ত্র / স্বাধীন আয়
  applicationExpense,   // আবেদন সংশ্লিষ্ট কাজের খরচ
  generalExpense,       // দোকানের সাধারণ খরচ
}

class DemoTransaction {
  final String id;
  final TransactionType type;
  final TransactionSource source;
  final Money amount;
  final DateTime date;
  final String category;
  final String? applicationId;
  final String? applicationTitle;
  final String? applicantName;
  final String? customerName;
  final String? paymentMethod;
  final String? statusHistoryId;
  final String? statusName;
  final String? note;

  const DemoTransaction({
    required this.id,
    required this.type,
    required this.source,
    required this.amount,
    required this.date,
    required this.category,
    this.applicationId,
    this.applicationTitle,
    this.applicantName,
    this.customerName,
    this.paymentMethod,
    this.statusHistoryId,
    this.statusName,
    this.note,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  String get sourceDisplayName {
    switch (source) {
      case TransactionSource.applicationPayment:
        return 'আবেদন কিস্তি জমা';
      case TransactionSource.statusIncome:
        return 'অবস্থা পরিবর্তন ফি';
      case TransactionSource.statusExpense:
        return 'অবস্থা পরিবর্তন খরচ';
      case TransactionSource.independentIncome:
        return 'স্বতন্ত্র আয়';
      case TransactionSource.applicationExpense:
        return 'কাজের খরচ';
      case TransactionSource.generalExpense:
        return 'দোকানের খরচ';
    }
  }
}

class DemoStatusHistory {
  final String id;
  final String prevStatus;
  final String newStatus;
  final DateTime changedAt;
  final String? note;

  const DemoStatusHistory({
    required this.id,
    required this.prevStatus,
    required this.newStatus,
    required this.changedAt,
    this.note,
  });
}

class DemoDocument {
  final String id;
  final String name;
  final String type; // 'pdf', 'image'
  final String size;
  final DateTime uploadDate;
  final Uint8List? fileData;

  const DemoDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadDate,
    this.fileData,
  });
}

class DemoApplication {
  final String id;
  final String applicantId;
  final String applicantName;
  final String applicantPhone;
  final String? applicantAddress;
  final String? referencePersonId;
  final String? referencePersonName;
  final String? mouza;
  final String? appNumber;
  final String? caseNumber;
  final String workType;
  final String officeName;
  final DateTime applicationDate;
  final String status;
  final Money agreedAmount;
  final Money receivedAmount;
  final Money expenseAmount;
  final String? notes;
  final List<DemoPayment> payments;
  final List<DemoExpense> expenses;
  final List<DemoStatusHistory> statusHistory;
  final List<DemoDocument> documents;
  final bool isMarkedAsPaid;

  const DemoApplication({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.applicantPhone,
    this.applicantAddress,
    this.referencePersonId,
    this.referencePersonName,
    this.mouza,
    this.appNumber,
    this.caseNumber,
    required this.workType,
    required this.officeName,
    required this.applicationDate,
    required this.status,
    required this.agreedAmount,
    required this.receivedAmount,
    required this.expenseAmount,
    this.notes,
    this.payments = const [],
    this.expenses = const [],
    this.statusHistory = const [],
    this.documents = const [],
    this.isMarkedAsPaid = false,
  });

  /// The raw difference between agreed and received amounts
  Money get rawDueAmount => agreedAmount - receivedAmount;

  /// Effective due amount: returns Money.zero when marked as paid (waived/settled)
  Money get dueAmount => isMarkedAsPaid ? Money.zero : (agreedAmount - receivedAmount);

  /// Service income earned from this application: received - work expenses
  Money get actualIncome => receivedAmount - expenseAmount;

  /// Potential income based on contract: agreed - work expenses
  Money get estimatedIncome => agreedAmount - expenseAmount;

  DemoApplication copyWith({
    String? id,
    String? applicantId,
    String? applicantName,
    String? applicantPhone,
    String? applicantAddress,
    String? referencePersonId,
    String? referencePersonName,
    String? mouza,
    String? appNumber,
    String? caseNumber,
    String? workType,
    String? officeName,
    DateTime? applicationDate,
    String? status,
    Money? agreedAmount,
    Money? receivedAmount,
    Money? expenseAmount,
    String? notes,
    List<DemoPayment>? payments,
    List<DemoExpense>? expenses,
    List<DemoStatusHistory>? statusHistory,
    List<DemoDocument>? documents,
    bool? isMarkedAsPaid,
  }) {
    return DemoApplication(
      id: id ?? this.id,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      applicantAddress: applicantAddress ?? this.applicantAddress,
      referencePersonId: referencePersonId ?? this.referencePersonId,
      referencePersonName: referencePersonName ?? this.referencePersonName,
      mouza: mouza ?? this.mouza,
      appNumber: appNumber ?? this.appNumber,
      caseNumber: caseNumber ?? this.caseNumber,
      workType: workType ?? this.workType,
      officeName: officeName ?? this.officeName,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      agreedAmount: agreedAmount ?? this.agreedAmount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      notes: notes ?? this.notes,
      payments: payments ?? this.payments,
      expenses: expenses ?? this.expenses,
      statusHistory: statusHistory ?? this.statusHistory,
      documents: documents ?? this.documents,
      isMarkedAsPaid: isMarkedAsPaid ?? this.isMarkedAsPaid,
    );
  }
}

class DemoTask {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String? dueTime;
  final String priority; // 'জরুরি', 'সাধারণ'
  final String status; // 'করতে হবে', 'চলমান', 'সম্পন্ন'
  final String category; // 'শুনানি', 'কাগজপত্র', 'ফি/তাগাদা', 'অফিস জমা', 'ডেলিভারি', 'সাধারণ'
  final String? relatedApplicationId;
  final String? relatedApplicantName;
  final DateTime? completedAt;

  const DemoTask({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.dueTime,
    required this.priority,
    required this.status,
    this.category = 'সাধারণ',
    this.relatedApplicationId,
    this.relatedApplicantName,
    this.completedAt,
  });

  bool get isToday {
    final now = DateTime.now();
    return dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day;
  }

  bool get isOverdue {
    if (status == 'সম্পন্ন') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return taskDate.isBefore(today);
  }

  bool get isCompleted => status == 'সম্পন্ন';
  bool get isUrgent => priority == 'জরুরি';

  DemoTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? dueTime,
    String? priority,
    String? status,
    String? category,
    String? relatedApplicationId,
    String? relatedApplicantName,
    DateTime? completedAt,
  }) {
    return DemoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      relatedApplicationId: relatedApplicationId ?? this.relatedApplicationId,
      relatedApplicantName: relatedApplicantName ?? this.relatedApplicantName,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class DemoStore {
  // স্বাভাবিক পর্যায়ক্রমিক অগ্রগতি (Happy Flow)
  static const List<String> progressStatuses = [
    'আবেদন',
    'প্রস্তাব প্রেরণ',
    'শুনানি',
    'মঞ্জুর',
    'ডিসিআর প্রস্তুত',
    'সম্পন্ন',
  ];

  // ব্যতিক্রমী বা বিশেষ অবস্থা
  static const List<String> exceptionStatuses = [
    'অপেক্ষমাণ',
    'আপত্তি',
    'সংশোধন প্রয়োজন',
    'নামঞ্জুর',
  ];

  static List<String> statuses = [
    ...progressStatuses,
    ...exceptionStatuses,
  ];

  // Shop & Business Profile
  static String shopName = 'রজব ভূমি সেবা ঘর';
  static String proprietorName = 'মোঃ রজব আলী';
  static String shopPhone = '০১৭১২-৩৪৫৬৭৮';
  static String shopAddress = 'উপজেলা ভূমি অফিস সংলগ্ন, সাভার, ঢাকা';

  static List<String> workTypes = [
    'নামজারি',
    'জমাভাগ',
    'খতিয়ান সংশোধন',
    'মিস কেস',
    'দাখিলা ও খাজনা',
    'অন্যান্য',
  ];

  static List<DemoOffice> offices = [
    const DemoOffice(id: 'off-1', name: 'জেলা প্রশাসকের কার্যালয়, চাঁপাইনবাবগঞ্জ', activeApplications: 0),
    const DemoOffice(id: 'off-2', name: 'উপজেলা ভূমি অফিস, চাঁপাইনবাবগঞ্জ সদর', activeApplications: 0),
    const DemoOffice(id: 'off-3', name: 'পৌর ভূমি অফিস, চাঁপাইনবাবগঞ্জ', activeApplications: 0),
    const DemoOffice(id: 'off-4', name: 'উপজেলা সেটেলমেন্ট অফিস, চাঁপাইনবাবগঞ্জ সদর', activeApplications: 0),
    const DemoOffice(id: 'off-5', name: 'সাব-রেজিস্ট্রি অফিস, চাঁপাইনবাবগঞ্জ সদর', activeApplications: 0),
    const DemoOffice(id: 'off-6', name: 'ইউনিয়ন ভূমি অফিস, আলাতুলী', activeApplications: 0),
    const DemoOffice(id: 'off-7', name: 'ইউনিয়ন ভূমি অফিস, ইসলামপুর', activeApplications: 0),
    const DemoOffice(id: 'off-8', name: 'ইউনিয়ন ভূমি অফিস, গোবরাতলা', activeApplications: 0),
    const DemoOffice(id: 'off-9', name: 'ইউনিয়ন ভূমি অফিস, চর অনুপনগর', activeApplications: 0),
    const DemoOffice(id: 'off-10', name: 'ইউনিয়ন ভূমি অফিস, চরবাগডাঙ্গা', activeApplications: 0),
    const DemoOffice(id: 'off-11', name: 'ইউনিয়ন ভূমি অফিস, ঝিলিম', activeApplications: 0),
    const DemoOffice(id: 'off-12', name: 'ইউনিয়ন ভূমি অফিস, দেবীনগর', activeApplications: 0),
    const DemoOffice(id: 'off-13', name: 'ইউনিয়ন ভূমি অফিস, নারায়ণপুর', activeApplications: 0),
    const DemoOffice(id: 'off-14', name: 'ইউনিয়ন ভূমি অফিস, বারঘরিয়া', activeApplications: 0),
    const DemoOffice(id: 'off-15', name: 'ইউনিয়ন ভূমি অফিস, বালিয়াডাঙ্গা', activeApplications: 0),
    const DemoOffice(id: 'off-16', name: 'ইউনিয়ন ভূমি অফিস, মহারাজপুর', activeApplications: 0),
    const DemoOffice(id: 'off-17', name: 'ইউনিয়ন ভূমি অফিস, রানীহাটি', activeApplications: 0),
    const DemoOffice(id: 'off-18', name: 'ইউনিয়ন ভূমি অফিস, শাহজাহানপুর', activeApplications: 0),
    const DemoOffice(id: 'off-19', name: 'ইউনিয়ন ভূমি অফিস, সুন্দরপুর', activeApplications: 0),
  ];

  static List<String> applicationExpenseCategories = [
    'সরকারি ফি',
    'কাগজপত্র ও ফটোকপি',
    'যাতায়াত খরচ',
    'অন্যান্য কাজের খরচ',
  ];

  static List<String> generalExpenseCategories = [
    'দোকান ভাড়া',
    'বিদ্যুৎ বিল',
    'ইন্টারনেট বিল',
    'প্রিন্টিং ও স্টেশনারি',
    'অন্যান্য দোকানের খরচ',
  ];

  static List<String> incomeCategories = [
    'অন্যান্য আয়',
    'দোকানের অন্যান্য সেবা',
    'অনলাইন আবেদন ও প্রিন্টিং',
    'ব্যক্তিগত ব্যবসায়িক আয়',
  ];

  static List<String> expenseCategories = [
    'সরকারি ফি',
    'কাগজপত্র ও ফটোকপি',
    'যাতায়াত খরচ',
    'দোকান ভাড়া',
    'বিদ্যুৎ বিল',
    'ইন্টারনেট বিল',
    'প্রিন্টিং ও স্টেশনারি',
    'অন্যান্য খরচ',
  ];

  static List<DemoIncome> independentIncomes = [
    DemoIncome(
      id: 'inc-1',
      category: 'অন্যান্য আয়',
      amount: Money.fromTaka(1500),
      date: DateTime.now().subtract(const Duration(days: 1)),
      paymentMethod: 'নগদ',
      customerName: 'বশির আহমেদ',
      note: 'অনলাইন চাকরির আবেদন ও ছবি প্রিন্ট ফি',
    ),
    DemoIncome(
      id: 'inc-2',
      category: 'দোকানের অন্যান্য সেবা',
      amount: Money.fromTaka(800),
      date: DateTime.now().subtract(const Duration(days: 3)),
      paymentMethod: 'বিকাশ',
      customerName: 'সেলিম রানা',
      note: 'জরুরি জাতীয় পরিচয়পত্র রি-ইস্যু আবেদন ফরম',
    ),
    DemoIncome(
      id: 'inc-3',
      category: 'অন্যান্য আয়',
      amount: Money.fromTaka(2800),
      date: DateTime.now().subtract(const Duration(days: 35)),
      paymentMethod: 'নগদ',
      customerName: 'রফিকুল ইসলাম',
      note: 'অনলাইন ফরম ফিলাপ ও কালার প্রিন্ট সেবা',
    ),
    DemoIncome(
      id: 'inc-4',
      category: 'দোকানের অন্যান্য সেবা',
      amount: Money.fromTaka(3500),
      date: DateTime.now().subtract(const Duration(days: 68)),
      paymentMethod: 'বিকাশ',
      customerName: 'হানিফ মোল্লা',
      note: 'দলিল ড্রাফটিং ও নোটারি সহযোগিতা ফি',
    ),
    DemoIncome(
      id: 'inc-5',
      category: 'অন্যান্য আয়',
      amount: Money.fromTaka(4200),
      date: DateTime.now().subtract(const Duration(days: 95)),
      paymentMethod: 'নগদ',
      customerName: 'মজিবুর রহমান',
      note: 'অনলাইন ভূমি উন্নয়ন কর পরিশোধ সেবা',
    ),
    DemoIncome(
      id: 'inc-6',
      category: 'অন্যান্য আয়',
      amount: Money.fromTaka(12000),
      date: DateTime.now().subtract(const Duration(days: 380)),
      paymentMethod: 'ব্যাংক',
      customerName: 'বার্ষিক সেবা চুক্তি',
      note: '২০২৫ সালের বাৎসরিক কর ও রিটার্ন ফাইলিং সেবা',
    ),
  ];

  static List<DemoReference> references = [
    const DemoReference(
      id: 'ref-1',
      name: 'হাজি মোখলেছুর রহমান',
      phone: '01912345678',
      address: 'মানিকগঞ্জ সদর ও সাভার',
      notes: 'এলাকার মুরুব্বি ও পরিচিত রেফারেন্সদাতা।',
    ),
    const DemoReference(
      id: 'ref-2',
      name: 'করিম মিয়া',
      phone: '01819876543',
      address: 'জিনজিরা, কেরানীগঞ্জ',
      notes: 'নিয়মিত জমি কেনাবেচা ও ক্লায়েন্ট পাঠান।',
    ),
    const DemoReference(
      id: 'ref-3',
      name: 'সালাম তালুকদার',
      phone: '01711002233',
      address: 'ধামরাই বাজার',
      notes: 'ইউনিয়ন পরিষদের মেম্বার।',
    ),
    const DemoReference(
      id: 'ref-4',
      name: 'জলিল মোল্লা',
      phone: '01678998877',
      address: 'কাউন্দিয়া, সাভার',
      notes: 'স্থানীয় সমাজসেবক ও পরিচিত মধ্যস্থতাকারী।',
    ),
  ];

  static List<DemoPerson> persons = [
    DemoPerson(
      id: 'p-1',
      name: 'মো: রহিম উদ্দিন',
      phone: '01711223344',
      address: 'গ্রাম: কাউন্দিয়া, সাভার, ঢাকা',
      notes: 'নিয়মিত গ্রাহক, ৩টি জমির কাজ করিয়েছেন।',
      applicationCount: 3,
      totalAgreed: Money.fromTaka(21000),
      totalDue: Money.fromTaka(4000),
    ),
    DemoPerson(
      id: 'p-2',
      name: 'করিম মিয়া',
      phone: '01819876543',
      address: 'জিনজিরা, কেরানীগঞ্জ',
      notes: 'রেফারেন্স: হাজি মোখলেছুর রহমান',
      applicationCount: 1,
      totalAgreed: Money.fromTaka(8500),
      totalDue: Money.fromTaka(2500),
    ),
    DemoPerson(
      id: 'p-3',
      name: 'হাজি মোখলেছুর রহমান',
      phone: '01912345678',
      address: 'মানিকগঞ্জ সদর',
      notes: 'এলাকার মুরুব্বি ও পরিচিত রেফারেন্সদাতা।',
      applicationCount: 2,
      totalAgreed: Money.fromTaka(14000),
      totalDue: Money.fromTaka(0),
    ),
    DemoPerson(
      id: 'p-4',
      name: 'আব্দুল জলিল',
      phone: '01671112233',
      address: 'ধামরাই বাজার',
      notes: 'খতিয়ান সংশোধনের জন্য ফাইল জমা দিয়েছেন।',
      applicationCount: 1,
      totalAgreed: Money.fromTaka(6000),
      totalDue: Money.fromTaka(3000),
    ),
    DemoPerson(
      id: 'p-5',
      name: 'ফাতেমা বেগম',
      phone: '01733445566',
      address: 'নবাবগঞ্জ, ঢাকা',
      notes: 'পৈত্রিক সূত্রে পাওয়া জমির নামজারি।',
      applicationCount: 1,
      totalAgreed: Money.fromTaka(7500),
      totalDue: Money.fromTaka(0),
    ),
    // নিচের দুটি আবেদন (APP-2026-006, APP-2026-007) এই গ্রাহকদের সাথে
    // যুক্ত — অতীতে এখানে রেকর্ড না থাকায় ডেটাবেজের বিদেশী কী
    // (foreign key) অখণ্ড ছিল।
    DemoPerson(
      id: 'p-6',
      name: 'আনোয়ার হোসেন',
      phone: '01712998877',
      address: 'বাগবাড়ী, সাভার, ঢাকা',
      notes: 'হাজি সাহেবের মাধ্যমে আসা নিয়মিত গ্রাহক।',
      applicationCount: 1,
      totalAgreed: Money.fromTaka(8000),
      totalDue: Money.fromTaka(0),
    ),
    DemoPerson(
      id: 'p-7',
      name: 'শাহ আলম',
      phone: '01822334455',
      address: 'ধামরাই বাজার, ঢাকা',
      notes: 'জমাভাগ কাজের জন্য ফাইল জমা দিয়েছেন।',
      applicationCount: 1,
      totalAgreed: Money.fromTaka(6500),
      totalDue: Money.fromTaka(1500),
    ),
  ];

  static List<DemoApplication> applications = [
    DemoApplication(
      id: 'APP-2026-001',
      applicantId: 'p-1',
      applicantName: 'মো: রহিম উদ্দিন',
      applicantPhone: '01711223344',
      referencePersonId: 'ref-1',
      referencePersonName: 'হাজি মোখলেছুর রহমান',
      mouza: 'বাগবাড়ী (জে.এল নং ৪৫)',
      appNumber: 'SAV-MUT-2026-8841',
      caseNumber: 'কেস নং ৪২/২০২৬',
      workType: 'নামজারি',
      officeName: 'উপজেলা ভূমি অফিস, সাভার',
      applicationDate: DateTime.now().subtract(const Duration(days: 4)),
      status: 'শুনানি',
      agreedAmount: Money.fromTaka(7000),
      receivedAmount: Money.fromTaka(4000),
      expenseAmount: Money.fromTaka(1200),
      notes: 'আগামী ১০ তারিখ শুনানির নোটিশ দেওয়া হয়েছে। খতিয়ান কপি সাথে নিতে হবে।',
      payments: [
        DemoPayment(
          id: 'pay-1',
          applicationId: 'APP-2026-001',
          amount: Money.fromTaka(2500),
          date: DateTime.now().subtract(const Duration(days: 4)),
          method: 'নগদ',
          note: 'আবেদনের সময় প্রাথমিক জমা',
        ),
        DemoPayment(
          id: 'pay-2',
          applicationId: 'APP-2026-001',
          amount: Money.fromTaka(1500),
          date: DateTime.now().subtract(const Duration(days: 1)),
          method: 'বিকাশ',
          note: 'শুনানির ফি বাবদ জমা',
        ),
      ],
      expenses: [
        DemoExpense(
          id: 'exp-1',
          applicationId: 'APP-2026-001',
          applicationTitle: 'নামজারি - মো: রহিম উদ্দিন',
          amount: Money.fromTaka(750),
          category: 'সরকারি ফি',
          date: DateTime.now().subtract(const Duration(days: 3)),
          isGeneral: false,
          note: 'অনলাইন চালান ফি পরিশোধ',
        ),
        DemoExpense(
          id: 'exp-2',
          applicationId: 'APP-2026-001',
          applicationTitle: 'নামজারি - মো: রহিম উদ্দিন',
          amount: Money.fromTaka(450),
          category: 'কাগজপত্র ও ফটোকপি',
          date: DateTime.now().subtract(const Duration(days: 2)),
          isGeneral: false,
          note: 'দলিল ফটোকপি ও ফাইল কাভার',
        ),
      ],
      statusHistory: [
        DemoStatusHistory(
          id: 'sh-1',
          prevStatus: 'আবেদন',
          newStatus: 'প্রস্তাব প্রেরণ',
          changedAt: DateTime.now().subtract(const Duration(days: 3)),
          note: 'ইউনিয়ন ভূমি অফিস থেকে প্রস্তাব সহকারী কমিশনার (ভূমি) বরাবর পাঠানো হয়েছে।',
        ),
        DemoStatusHistory(
          id: 'sh-2',
          prevStatus: 'প্রস্তাব প্রেরণ',
          newStatus: 'শুনানি',
          changedAt: DateTime.now().subtract(const Duration(days: 1)),
          note: 'শুনানির তারিখ ধার্য হয়েছে আগামী ১০ তারিখে।',
        ),
      ],
      documents: [
        DemoDocument(
          id: 'doc-1',
          name: 'Online_Mutation_SAV-8841.pdf',
          type: 'pdf',
          size: '1.2 MB',
          uploadDate: DateTime.now().subtract(const Duration(days: 4)),
        ),
        DemoDocument(
          id: 'doc-2',
          name: 'Dolil_Photocopy_Page1.jpg',
          type: 'image',
          size: '850 KB',
          uploadDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
    ),
    DemoApplication(
      id: 'APP-2026-002',
      applicantId: 'p-2',
      applicantName: 'করিম মিয়া',
      applicantPhone: '01819876543',
      referencePersonId: 'ref-4',
      referencePersonName: 'জলিল মোল্লা',
      mouza: 'জিনজিরা',
      appNumber: 'KER-JAM-2026-3012',
      caseNumber: 'কেস নং ১৫/২০২৬',
      workType: 'জমাভাগ',
      officeName: 'সহকারী কমিশনার (ভূমি) কার্যালয়, কেরানীগঞ্জ',
      applicationDate: DateTime.now().subtract(const Duration(days: 8)),
      status: 'প্রস্তাব প্রেরণ',
      agreedAmount: Money.fromTaka(8500),
      receivedAmount: Money.fromTaka(6000),
      expenseAmount: Money.fromTaka(1800),
      notes: 'ওয়ারিশান সনদপত্র জমা দেওয়া হয়েছে। প্রস্তাব অনুমোদনের অপেক্ষায়।',
      payments: [
        DemoPayment(
          id: 'pay-3',
          applicationId: 'APP-2026-002',
          amount: Money.fromTaka(6000),
          date: DateTime.now().subtract(const Duration(days: 8)),
          method: 'নগদ',
          note: 'অগ্রিম ৫০% এর বেশি জমা',
        ),
      ],
      expenses: [
        DemoExpense(
          id: 'exp-3',
          applicationId: 'APP-2026-002',
          applicationTitle: 'জমাভাগ - করিম মিয়া',
          amount: Money.fromTaka(1800),
          category: 'সরকারি ফি',
          date: DateTime.now().subtract(const Duration(days: 7)),
          isGeneral: false,
          note: 'জমাভাগ কোর্ট ফি ও আবেদন ফি',
        ),
      ],
      statusHistory: [
        DemoStatusHistory(
          id: 'sh-3',
          prevStatus: 'আবেদন',
          newStatus: 'প্রস্তাব প্রেরণ',
          changedAt: DateTime.now().subtract(const Duration(days: 6)),
          note: 'প্রস্তাব পাঠানো হয়েছে।',
        ),
      ],
      documents: [
        DemoDocument(
          id: 'doc-3',
          name: 'Jomabhag_Application.pdf',
          type: 'pdf',
          size: '950 KB',
          uploadDate: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ],
    ),
    DemoApplication(
      id: 'APP-2026-003',
      applicantId: 'p-3',
      applicantName: 'হাজি মোখলেছুর রহমান',
      applicantPhone: '01912345678',
      mouza: 'কাউন্দিয়া',
      appNumber: 'DHK-KHOT-2026-119',
      caseNumber: 'কেস নং ৮৯/২০২৬',
      workType: 'খতিয়ান সংশোধন',
      officeName: 'জেলা প্রশাসকের কার্যালয়, ঢাকা',
      applicationDate: DateTime.now().subtract(const Duration(days: 15)),
      status: 'সম্পন্ন',
      agreedAmount: Money.fromTaka(9000),
      receivedAmount: Money.fromTaka(9000),
      expenseAmount: Money.fromTaka(2500),
      notes: 'সংশোধিত খতিয়ানের জাবেদা নকল গ্রাহককে বুঝিয়ে দেওয়া হয়েছে। সম্পূর্ণ টাকা পরিশোধিত।',
      payments: [
        DemoPayment(
          id: 'pay-4',
          applicationId: 'APP-2026-003',
          amount: Money.fromTaka(5000),
          date: DateTime.now().subtract(const Duration(days: 15)),
          method: 'ব্যাংক',
          note: 'চেক নং ৪৪২১১',
        ),
        DemoPayment(
          id: 'pay-5',
          applicationId: 'APP-2026-003',
          amount: Money.fromTaka(4000),
          date: DateTime.now().subtract(const Duration(days: 2)),
          method: 'নগদ',
          note: 'ফাইল বুঝিয়ে দেওয়ার সময় শেষ কিস্তি',
        ),
      ],
      expenses: [
        DemoExpense(
          id: 'exp-4',
          applicationId: 'APP-2026-003',
          applicationTitle: 'খতিয়ান সংশোধন - হাজি মোখলেছুর রহমান',
          amount: Money.fromTaka(2500),
          category: 'সরকারি ফি',
          date: DateTime.now().subtract(const Duration(days: 12)),
          isGeneral: false,
          note: 'ডিসি অফিস নকল ফি ও ডাক খরচ',
        ),
      ],
      statusHistory: [
        DemoStatusHistory(
          id: 'sh-4',
          prevStatus: 'ডিসিআর প্রস্তুত',
          newStatus: 'সম্পন্ন',
          changedAt: DateTime.now().subtract(const Duration(days: 2)),
          note: 'কাজ সম্পন্ন ও ডেলিভারি দেওয়া হয়েছে।',
        ),
      ],
      documents: [
        DemoDocument(
          id: 'doc-4',
          name: 'Corrected_Khatian_Copy.pdf',
          type: 'pdf',
          size: '2.4 MB',
          uploadDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
    DemoApplication(
      id: 'APP-2026-004',
      applicantId: 'p-4',
      applicantName: 'আব্দুল জলিল',
      applicantPhone: '01671112233',
      referencePersonId: 'ref-3',
      referencePersonName: 'সালাম তালুকদার',
      mouza: 'ধামরাই',
      appNumber: 'DHM-MUT-2026-054',
      caseNumber: '',
      workType: 'নামজারি',
      officeName: 'উপজেলা ভূমি অফিস, ধামরাই',
      applicationDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'আবেদন',
      agreedAmount: Money.fromTaka(6000),
      receivedAmount: Money.fromTaka(3000),
      expenseAmount: Money.fromTaka(500),
      notes: 'অনলাইন আবেদন সম্পন্ন, হার্ড কপি জমা দেওয়া বাকি।',
      payments: [
        DemoPayment(
          id: 'pay-6',
          applicationId: 'APP-2026-004',
          amount: Money.fromTaka(3000),
          date: DateTime.now().subtract(const Duration(days: 2)),
          method: 'নগদ',
          note: 'প্রাথমিক অগ্রিম',
        ),
      ],
      expenses: [
        DemoExpense(
          id: 'exp-5',
          applicationId: 'APP-2026-004',
          applicationTitle: 'নামজারি - আব্দুল জলিল',
          amount: Money.fromTaka(500),
          category: 'কাগজপত্র ও ফটোকপি',
          date: DateTime.now().subtract(const Duration(days: 2)),
          isGeneral: false,
          note: 'আবেদন প্রিন্ট ও বাঁধাই',
        ),
      ],
      statusHistory: [
        DemoStatusHistory(
          id: 'sh-5',
          prevStatus: '',
          newStatus: 'আবেদন',
          changedAt: DateTime.now().subtract(const Duration(days: 2)),
          note: 'নতুন আবেদন এন্ট্রি',
        ),
      ],
      documents: [],
    ),
    DemoApplication(
      id: 'APP-2026-005',
      applicantId: 'p-5',
      applicantName: 'ফাতেমা বেগম',
      applicantPhone: '01733445566',
      referencePersonId: 'ref-2',
      referencePersonName: 'করিম মিয়া',
      mouza: 'কেওড়া',
      appNumber: 'SAV-MUT-2026-9011',
      caseNumber: 'কেস নং ৯/২০২৬',
      workType: 'নামজারি',
      officeName: 'উপজেলা ভূমি অফিস, সাভার',
      applicationDate: DateTime.now().subtract(const Duration(days: 12)),
      status: 'মঞ্জুর',
      agreedAmount: Money.fromTaka(7500),
      receivedAmount: Money.fromTaka(7500),
      expenseAmount: Money.fromTaka(1150),
      notes: 'DCR ফি পরিশোধ করা হয়েছে। খতিয়ান প্রিন্ট কপি তৈরি।',
      payments: [
        DemoPayment(
          id: 'pay-7',
          applicationId: 'APP-2026-005',
          amount: Money.fromTaka(7500),
          date: DateTime.now().subtract(const Duration(days: 12)),
          method: 'বিকাশ',
          note: 'এককালীন পরিশোধ',
        ),
      ],
      expenses: [
        DemoExpense(
          id: 'exp-6',
          applicationId: 'APP-2026-005',
          applicationTitle: 'নামজারি - ফাতেমা বেগম',
          amount: Money.fromTaka(1150),
          category: 'সরকারি ফি',
          date: DateTime.now().subtract(const Duration(days: 4)),
          isGeneral: false,
          note: 'DCR সরকারি ফি ১১৫০ টাকা',
        ),
      ],
      statusHistory: [
        DemoStatusHistory(
          id: 'sh-6',
          prevStatus: 'শুনানি',
          newStatus: 'মঞ্জুর',
          changedAt: DateTime.now().subtract(const Duration(days: 3)),
          note: 'নামজারি সহকারী কমিশনার মহোদয় কর্তৃক অনুমোদিত হয়েছে।',
        ),
      ],
      documents: [
        DemoDocument(
          id: 'doc-5',
          name: 'DCR_Chalan_Paid.pdf',
          type: 'pdf',
          size: '620 KB',
          uploadDate: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ],
    ),
    DemoApplication(
      id: 'APP-2026-006',
      applicantId: 'p-6',
      applicantName: 'আনোয়ার হোসেন',
      applicantPhone: '01712998877',
      referencePersonId: 'ref-1',
      referencePersonName: 'হাজি মোখলেছুর রহমান',
      mouza: 'বাগবাড়ী',
      appNumber: 'SAV-MUT-2026-7712',
      caseNumber: 'কেস নং ১৯/২০২৬',
      workType: 'নামজারি',
      officeName: 'উপজেলা ভূমি অফিস, সাভার',
      applicationDate: DateTime.now().subtract(const Duration(days: 20)),
      status: 'সম্পন্ন',
      agreedAmount: Money.fromTaka(8000),
      receivedAmount: Money.fromTaka(8000),
      expenseAmount: Money.fromTaka(1500),
      notes: 'হাজি সাহেবের মাধ্যমে আসা কাজ। খতিয়ান কপি ডেলিভারি দেওয়া হয়েছে।',
      payments: [
        DemoPayment(
          id: 'pay-8',
          applicationId: 'APP-2026-006',
          amount: Money.fromTaka(8000),
          date: DateTime.now().subtract(const Duration(days: 20)),
          method: 'নগদ',
          note: 'সম্পূর্ণ পরিশোধ',
        ),
      ],
      expenses: [],
      statusHistory: [
        DemoStatusHistory(
          id: 'sh-7',
          prevStatus: 'ডিসিআর প্রস্তুত',
          newStatus: 'সম্পন্ন',
          changedAt: DateTime.now().subtract(const Duration(days: 5)),
          note: 'খতিয়ান বুঝিয়ে দেওয়া হয়েছে',
        ),
      ],
      documents: [],
    ),
    DemoApplication(
      id: 'APP-2026-007',
      applicantId: 'p-7',
      applicantName: 'শাহ আলম',
      applicantPhone: '01822334455',
      referencePersonId: 'ref-2',
      referencePersonName: 'করিম মিয়া',
      mouza: 'কেরানীগঞ্জ',
      appNumber: 'KER-MIS-2026-105',
      caseNumber: 'কেস নং ৩/২০২৬',
      workType: 'মিস কেস',
      officeName: 'সহকারী কমিশনার (ভূমি) কার্যালয়, কেরানীগঞ্জ',
      applicationDate: DateTime.now().subtract(const Duration(days: 6)),
      status: 'অপেক্ষমাণ',
      agreedAmount: Money.fromTaka(10000),
      receivedAmount: Money.fromTaka(5000),
      expenseAmount: Money.fromTaka(1000),
      notes: 'করিম ভাইয়ের পরিচিত গ্রাহক। মিস কেসের ফাইলিং সম্পন্ন।',
      payments: [
        DemoPayment(
          id: 'pay-9',
          applicationId: 'APP-2026-007',
          amount: Money.fromTaka(5000),
          date: DateTime.now().subtract(const Duration(days: 6)),
          method: 'নগদ',
          note: 'অগ্রিম ৫০%',
        ),
      ],
      expenses: [],
      statusHistory: [
        DemoStatusHistory(
          id: 'sh-8',
          prevStatus: 'আবেদন',
          newStatus: 'অপেক্ষমাণ',
          changedAt: DateTime.now().subtract(const Duration(days: 2)),
          note: 'শুনানির তারিখ পাওয়ার অপেক্ষায়',
        ),
      ],
      documents: [],
    ),
  ];

  static List<DemoExpense> generalExpenses = [
    DemoExpense(
      id: 'gexp-1',
      amount: Money.fromTaka(6000),
      category: 'দোকান ভাড়া',
      date: DateTime.now().subtract(const Duration(days: 5)),
      isGeneral: true,
      note: 'নভেম্বর মাসের দোকান ভাড়া',
    ),
    DemoExpense(
      id: 'gexp-2',
      amount: Money.fromTaka(1450),
      category: 'বিদ্যুৎ বিল',
      date: DateTime.now().subtract(const Duration(days: 3)),
      isGeneral: true,
      note: 'পল্লী বিদ্যুৎ বিল',
    ),
    DemoExpense(
      id: 'gexp-3',
      amount: Money.fromTaka(800),
      category: 'ইন্টারনেট বিল',
      date: DateTime.now().subtract(const Duration(days: 2)),
      isGeneral: true,
      note: 'ব্রডব্যান্ড ইন্টারনেট মাসিক বিল',
    ),
    DemoExpense(
      id: 'gexp-4',
      amount: Money.fromTaka(1200),
      category: 'প্রিন্টিং ও স্টেশনারি',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isGeneral: true,
      note: 'A4 সাইজ কাগজ ও টোনার রিফিল',
    ),
    DemoExpense(
      id: 'gexp-5',
      amount: Money.fromTaka(6000),
      category: 'দোকান ভাড়া',
      date: DateTime.now().subtract(const Duration(days: 35)),
      isGeneral: true,
      note: 'অক্টোবর মাসের দোকান ভাড়া',
    ),
    DemoExpense(
      id: 'gexp-6',
      amount: Money.fromTaka(1350),
      category: 'বিদ্যুৎ বিল',
      date: DateTime.now().subtract(const Duration(days: 38)),
      isGeneral: true,
      note: 'অক্টোবর মাসের বিদ্যুৎ বিল',
    ),
    DemoExpense(
      id: 'gexp-7',
      amount: Money.fromTaka(6000),
      category: 'দোকান ভাড়া',
      date: DateTime.now().subtract(const Duration(days: 68)),
      isGeneral: true,
      note: 'সেপ্টেম্বর মাসের দোকান ভাড়া',
    ),
    DemoExpense(
      id: 'gexp-8',
      amount: Money.fromTaka(1150),
      category: 'বিদ্যুৎ বিল',
      date: DateTime.now().subtract(const Duration(days: 70)),
      isGeneral: true,
      note: 'সেপ্টেম্বর মাসের বিদ্যুৎ বিল',
    ),
    DemoExpense(
      id: 'gexp-9',
      amount: Money.fromTaka(15000),
      category: 'দোকান ভাড়া',
      date: DateTime.now().subtract(const Duration(days: 380)),
      isGeneral: true,
      note: '২০২৫ সালের বাৎসরিক সাধারণ দোকান পরিচালনা খরচ',
    ),
  ];

  static List<DemoTask> tasks = [
    DemoTask(
      id: 'tsk-1',
      title: 'রহিম উদ্দিনের শুনানিতে উপস্থিত হওয়া',
      description: 'সাভার এসিল্যান্ড অফিসে সকাল ১১টায় মূল দলিল ও বায়া দলিলসহ উপস্থিত থাকতে হবে।',
      dueDate: DateTime.now(),
      dueTime: 'সকাল ১১:০০',
      priority: 'জরুরি',
      status: 'চলমান',
      category: 'শুনানি',
      relatedApplicationId: 'APP-2026-001',
      relatedApplicantName: 'মো: রহিম উদ্দিন',
    ),
    DemoTask(
      id: 'tsk-2',
      title: 'করিম মিয়ার ওয়ারিশ সনদের মূল কপি সংগ্রহ',
      description: 'গ্রাহককে ফোন দিয়ে কাউন্দিয়া থেকে চেয়ারম্যানের সই করা ওয়ারিশ সনদ আনতে বলতে হবে।',
      dueDate: DateTime.now(),
      dueTime: 'বিকাল ০৩:৩০',
      priority: 'সাধারণ',
      status: 'করতে হবে',
      category: 'কাগজপত্র',
      relatedApplicationId: 'APP-2026-002',
      relatedApplicantName: 'করিম মিয়া',
    ),
    DemoTask(
      id: 'tsk-3',
      title: 'আব্দুল জলিলের বকেয়া ৩,০০০ টাকা তাগাদা',
      description: 'আবেদন অনলাইন সাবমিট হয়ে গেছে, বাকি ফি বাবদ টাকা নিতে হবে।',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      dueTime: 'সকাল ১০:০০',
      priority: 'জরুরি',
      status: 'করতে হবে',
      category: 'ফি/তাগাদা',
      relatedApplicationId: 'APP-2026-004',
      relatedApplicantName: 'আব্দুল জলিল',
    ),
    DemoTask(
      id: 'tsk-4',
      title: 'ধামরাই ভূমি অফিসে হার্ড কপি ফাইল জমা',
      description: '৫টি নতুন নামজারি আবেদনের প্রিন্ট কপি সংশ্লিষ্ট পেশকারের টেবিলে জমা দেওয়া।',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      dueTime: 'দুপুর ১২:০০',
      priority: 'সাধারণ',
      status: 'করতে হবে',
      category: 'অফিস জমা',
    ),
    DemoTask(
      id: 'tsk-5',
      title: 'হাজি মোখলেছুর রহমানের খতিয়ান ডেলিভারি',
      description: 'জাবেদা নকল বুঝিয়ে দিয়ে বাকি টাকা গ্রহণ সম্পন্ন হয়েছে।',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      priority: 'সাধারণ',
      status: 'সম্পন্ন',
      category: 'ডেলিভারি',
      relatedApplicationId: 'APP-2026-003',
      relatedApplicantName: 'হাজি মোখলেছুর রহমান',
    ),
  ];

  /// আজকের কাজের তালিকা (অপেক্ষমাণ/চলমান কাজ)
  static List<DemoTask> get todayTasks => tasks.where((t) => t.isToday && t.status != 'সম্পন্ন').toList();

  /// আজকের মোট বাকি কাজের সংখ্যা (যা সম্পন্ন করা বাকি)
  static int get todayTasksCount => tasks.where((t) => t.isToday && t.status != 'সম্পন্ন').length;

  /// আজকের সকল কাজের সংখ্যা (সম্পন্ন সহ)
  static int get todayAllTasksCount => tasks.where((t) => t.isToday).length;

  // ==========================================
  // CENTRALIZED FINANCIAL REPOSITORY & ENGINE
  // ==========================================

  /// Returns all financial transactions sorted chronologically (latest first).
  /// Combines:
  /// 1. Application installment payments
  /// 2. Status-change fee receipts
  /// 3. Independent / other business incomes
  /// 4. Application-specific work expenses
  /// 5. Status-change expenses
  /// 6. General shop overhead expenses
  /// Without any duplicate counting or duplicate storage.
  static List<DemoTransaction> getAllTransactions() {
    final list = <DemoTransaction>[];

    // 1. Application-related Incomes & Expenses
    for (final app in applications) {
      for (final p in app.payments) {
        final isStatus = p.isStatusFee || p.id.startsWith('pay-sh-');
        list.add(
          DemoTransaction(
            id: p.id,
            type: TransactionType.income,
            source: isStatus ? TransactionSource.statusIncome : TransactionSource.applicationPayment,
            amount: p.amount,
            date: p.date,
            category: isStatus ? 'অবস্থা পরিবর্তন ফি' : '${app.workType} ফি জমা',
            applicationId: app.id,
            applicationTitle: '${app.workType} - ${app.applicantName}',
            applicantName: app.applicantName,
            paymentMethod: p.method,
            statusHistoryId: p.statusHistoryId,
            statusName: p.statusName,
            note: p.note,
          ),
        );
      }

      for (final e in app.expenses) {
        final isStatus = e.isStatusExpense || e.id.startsWith('exp-sh-');
        list.add(
          DemoTransaction(
            id: e.id,
            type: TransactionType.expense,
            source: isStatus ? TransactionSource.statusExpense : TransactionSource.applicationExpense,
            amount: e.amount,
            date: e.date,
            category: e.category,
            applicationId: app.id,
            applicationTitle: '${app.workType} - ${app.applicantName}',
            applicantName: app.applicantName,
            statusHistoryId: e.statusHistoryId,
            statusName: e.statusName,
            note: e.note,
          ),
        );
      }
    }

    // 2. Independent Incomes (never linked to applications)
    for (final inc in independentIncomes) {
      list.add(
        DemoTransaction(
          id: inc.id,
          type: TransactionType.income,
          source: TransactionSource.independentIncome,
          amount: inc.amount,
          date: inc.date,
          category: inc.category,
          customerName: inc.customerName,
          paymentMethod: inc.paymentMethod,
          note: inc.note,
        ),
      );
    }

    // 3. General Shop Expenses (never linked to applications)
    for (final ge in generalExpenses) {
      list.add(
        DemoTransaction(
          id: ge.id,
          type: TransactionType.expense,
          source: TransactionSource.generalExpense,
          amount: ge.amount,
          date: ge.date,
          category: ge.category,
          note: ge.note,
        ),
      );
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Total application payments & fees received
  static Money get totalApplicationIncome {
    Money sum = Money.zero;
    for (final app in applications) {
      for (final p in app.payments) {
        sum += p.amount;
      }
    }
    return sum;
  }

  /// Total independent / other business income received
  static Money get totalIndependentIncome {
    Money sum = Money.zero;
    for (final inc in independentIncomes) {
      sum += inc.amount;
    }
    return sum;
  }

  /// Grand Total Income = Application Incomes + Independent Incomes
  static Money get totalIncome => totalApplicationIncome + totalIndependentIncome;

  /// Total expenses directly spent on applications
  static Money get totalApplicationExpense {
    Money sum = Money.zero;
    for (final app in applications) {
      for (final e in app.expenses) {
        sum += e.amount;
      }
    }
    return sum;
  }

  /// Total general overhead shop expenses
  static Money get totalGeneralExpense {
    Money sum = Money.zero;
    for (final ge in generalExpenses) {
      sum += ge.amount;
    }
    return sum;
  }

  /// Grand Total Expenses = Application Expenses + General Expenses
  static Money get totalExpense => totalApplicationExpense + totalGeneralExpense;

  /// Net Business Income = Grand Total Income - Grand Total Expenses
  static Money get netIncome => totalIncome - totalExpense;

  /// Total outstanding dues across all active applications
  static Money get totalOutstandingDue {
    Money sum = Money.zero;
    for (final app in applications) {
      if (app.dueAmount.isPositive) {
        sum += app.dueAmount;
      }
    }
    return sum;
  }

  /// Applications that have unpaid dues, sorted by highest due first
  static List<DemoApplication> getDueApplications() {
    final list = applications.where((a) => a.dueAmount.isPositive).toList();
    list.sort((a, b) => b.dueAmount.compareTo(a.dueAmount));
    return list;
  }

  /// Today's income
  static Money get todayIncome {
    final now = DateTime.now();
    Money sum = Money.zero;
    for (final t in getAllTransactions()) {
      if (t.isIncome &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day) {
        sum += t.amount;
      }
    }
    return sum;
  }

  /// Today's expense
  static Money get todayExpense {
    final now = DateTime.now();
    Money sum = Money.zero;
    for (final t in getAllTransactions()) {
      if (t.isExpense &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day) {
        sum += t.amount;
      }
    }
    return sum;
  }

  /// Current month's income
  static Money get thisMonthIncome {
    final now = DateTime.now();
    Money sum = Money.zero;
    for (final t in getAllTransactions()) {
      if (t.isIncome &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        sum += t.amount;
      }
    }
    return sum;
  }

  /// Current month's expense
  static Money get thisMonthExpense {
    final now = DateTime.now();
    Money sum = Money.zero;
    for (final t in getAllTransactions()) {
      if (t.isExpense &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        sum += t.amount;
      }
    }
    return sum;
  }

  /// Current month's net income
  static Money get thisMonthIncomeNet => thisMonthIncome - thisMonthExpense;
}

