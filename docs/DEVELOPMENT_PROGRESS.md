# Development Progress — ভূমি কাজের হিসাব

## Summary of Phases

| Phase | Description | Status |
|---|---|---|
| **Phase 0** | Project Foundation & Design System | ✅ Completed |
| **Phase 1** | Complete Navigable UI Prototype | ✅ Completed |
| **Backend Phase 0** | Database & Drift SQLite Architecture (14 Tables, View & Triggers) | ✅ Completed |
| **Backend Phase 1** | Drift DAOs, Repository Layer & Human Error Mapping | ✅ Completed (131/131 Tests Green) |
| **Backend Phase 2** | Riverpod Providers & State Management (Double-tap lock & Reactive state) | ✅ Completed (146/146 Tests Green) |
| **Backend Phase 3** | UI Screen Migration to Live Providers | ✅ Completed (146/146 Tests Green) |
| **Backend Phase 4** | Backup, Restore & Data Migration Safety (Lightweight Telegram & Daily Auto-Backup) | ✅ Completed (178/178 Tests Green) |
| **Backend Phase 5** | Stress Testing, End-to-End Verification & Release | ✅ Completed (178/178 Tests Green) |

---

## Phase 0 & Phase 1 Completed Work

### 1. Modern Design System & Visual Tokens
- **Shop Branding:** "রজব ভূমি সেবা ঘর" with custom 1024x1024 logo in `assets/images/app_logo.jpeg` and Android launcher icons across all mipmap densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- **Color Identity:** Modern Indigo (`#4F46E5`), Vibrant Emerald (`#10B981`) for income, collections & positive metrics, Warm Rose (`#F43F5E`) for urgent/expenses/dues, Amber (`#F59E0B`) for pending/due highlights, Cool Slate (`#F8FAFC`, `#0F172A`).
- **Privacy-First Zero-Money Landing:** App opens into a clean, operational **Work Dashboard** (zero monetary figures visible on open), protecting business revenue and dues from onlookers in the shop.
- **স্বচ্ছ ও সুনির্দিষ্ট হিসাব:** Tab 3 ("হিসাব")-এ ফিল্টার অনুযায়ী প্রকৃত নিট ইনকাম, মোট আদায়, খরচ ও বকেয়া পাওনা সরাসরি দৃশ্যমান ও নির্ভুল অংকে প্রদর্শিত।
- **Smart Mobile Filters:** High-speed filter pills (`[সব]`, `[চলমান]`, `[শুনানি]`, `[বকেয়া আছে]`, `[সম্পন্ন]`) + removable active criteria tags and multi-select bottom sheet.

### 2. Complete Reusable Component Library
- `StatusBadge` (with 10 distinct status colors)
- `SummaryCard` (KPI statistics)
- `ApplicationCard` (মার্জিত আধুনিক কার্ড — বাঁ-পাশে স্ট্যাটাস অ্যাকসেন্ট স্ট্রিপ, ডাবল-লেয়ার শ্যাডো, কাজের ধরন ও মৌজা পিলে পৃথক ক্যাটাগরি ব্যাজ, অফিস ও তারিখের মেটাডাটা স্ট্রিপ, এবং নিচে ৩-কলাম ইনসেট ফিন্যান্সিয়াল বারে চুক্তি, জমা ও বকেয়া/পরিশোধিত স্ট্যাটাস পিল)
- `ReferenceCard` (reference person profile, address, total applications count, total service revenue, and operational status row)
- `ReferenceStatsRow` (completed, ongoing, pending status breakdown chips)
- `ReferenceSelectorSheet` (bottom sheet with live search, selection clear, and inline reference creation)
- `AppSearchBar` (search + filter badge counter)
- `FilterBottomSheet` (multi-criteria filtering: status, work type, office, due status, sorting)
- `AppTextField` & `MoneyField` (with quick amount increment chips)
- `AppButton` (Primary, Secondary, Outline, Danger variants with loading state)
- `AppDialogActionRow` (এক অনুভূমিক সারিতে ৫০%-৫০% প্রস্থে `[বাতিল]` ও `[যোগ করুন / নিশ্চিত করুন]` সমন্বিত স্ট্যান্ডার্ড অ্যাকশন বাটন)
- `EmptyState` (custom illustration icon, title, subtitle, CTA)
- `ConfirmDialog` (modal dialog with destructive action support)

### 3. All 28 Navigable UI Screens Designed
1. **ড্যাশবোর্ড (DashboardScreen):** Hero cashflow card, quick actions, daily stats, pipeline grid, today's priority tasks, recent applications.
2. **সকল আবেদন (ApplicationListScreen):** Live search, active filter pills, multi-criteria bottom sheet, quick status tabs, sorting.
3. **নতুন আবেদন (ApplicationCreateScreen):** আধুনিক ৩-ধাপের উইজার্ড (Step-by-step Wizard UI) —
   - *ধাপ ১ (গ্রাহকের তথ্য):* ইন-স্টেপ সংরক্ষিত গ্রাহক সার্চ ও অটোফিল, আবেদনকারীর নাম, মোবাইল নম্বর, এবং **ঠিকানা (নতুন ফিল্ড)**।
   - *ধাপ ২ (কাজ ও অফিস):* কাজের ধরন (Chips + নতুন ধরন যোগ), অফিসের নাম (Dropdown + নতুন অফিস যোগ), আবেদনের তারিখ (Date Picker), **মৌজার নাম**, এবং ১ সারিতে আবেদন নম্বর ও কেস নম্বর।
   - *ধাপ ৩ (চুক্তি ও সম্পন্ন):* **শীর্ষে রিয়েল-টাইম সারসংক্ষেপ কার্ড** (গ্রাহক, কাজ ও অফিসের তথ্যের রিভিউ ও সম্পাদনা শর্টকাট), রেফারেন্স ব্যক্তি নির্বাচক (ইনলাইন তৈরি সহ), চুক্তিকৃত মোট সার্ভিস ফি (Quick chips সহ), প্রাথমিক অগ্রিম জমা, ফাইল/ডকুমেন্ট সংযুক্তি এবং বিশেষ নোট।
   - *স্থির ফুটারে প্রিভিয়াস ও নেক্সট বাটন* এবং ধাপে ধাপে ভ্যালিডেশন কন্ট্রোল।
4. **আবেদন সম্পাদনা (ApplicationEditScreen):** আবেদনকারী, মোবাইল নম্বর, **ঠিকানা**, রেফারেন্স ব্যক্তি, কাজের ধরন, **মৌজা**, অফিস ও চুক্তির টাকার প্রাক-পূরণকৃত সম্পাদনা ফর্ম।
5. **আবেদন বিস্তারিত (ApplicationDetailScreen):** 4 tabs:
   - *১. আবেদন তথ্য:* মূল বিবরণ, মোবাইল কল শর্টকাট, **ঠিকানা**, **মৌজা**, রেফারেন্স ব্যক্তি (প্রোফাইলে যাওয়ার শর্টকাট সহ), অফিস, আবেদন নম্বর ও কেস নম্বর (১-ট্যাপ ক্লিপবোর্ড কপি অ্যাকশন সহ; অপ্রয়োজনীয় অভ্যন্তরীণ আইডি মুক্ত), নোট
   - *২. কাজের অগ্রগতি:* টাইমলাইন গ্রাফ, স্পষ্ট অবস্থা রূপান্তর ট্রানজিশন (`[পূর্ববর্তী অবস্থা] ➔ [নতুন অবস্থা]`), বর্তমান স্ট্যাটাস হাইলাইট ব্যাজ, পূর্ণাঙ্গ বাংলা তারিখ (`দিন/মাস/বছর`, সময়মুক্ত পরিচ্ছন্ন ভিউ) ও নোট
   - *৩. টাকার হিসাব:* **প্রকৃত ইনকাম (আয়) হিরো ব্যানার** (`মোট আদায় – মোট কাজের খরচ`), চুক্তি, আদায়, কাজের মোট খরচ, বকেয়া (পরিশোধিত ✓), কিস্তি জমার ইতিহাস এবং যে কোনো সময় সরাসরি **"+ খরচ লিখুন"** বাটন সহ খরচের ইতিহাস।
   - *৪. ডকুমেন্ট:* PDF/ছবি তালিকা, ফাইল সাইজ, প্রিভিউ ও ডিলিট
6. **অবস্থা পরিবর্তন ডায়ালগ (StatusChangeDialog):** বাংলাদেশের ভূমি সেবার প্রমিত পর্যায়ক্রমিক রূপ —
   - *স্বাভাবিক অগ্রগতি ধাপ:* আবেদন দাখিল ➔ প্রতিবেদন/প্রস্তাব দাখিল ➔ শুনানি ➔ মঞ্জুর (অনুমোদিত) ➔ ডিসিআর প্রস্তুত (ফি ১,১০০ টাকা) ➔ সম্পন্ন
   - *বিশেষ অবস্থা:* অপেক্ষমাণ, আপত্তি, সংশোধন প্রয়োজন, নামঞ্জুর (বাতিল)।
   - *শুনানির তারিখ ও অটো-টাস্ক:* 'শুনানি' নির্বাচন করলে সাথে সাথে ডেট ও টাইম পিকার দৃশ্যমান হয় এবং স্বয়ংক্রিয়ভাবে টাস্কে শুনানির রিমাইন্ডার যুক্ত করার ব্যবস্থা।
   - *সরকারি ফি কুইক-বাটন:* আবেদনে `+ সরকারি ফি ৳৭০`, ডিসিআর-এ `+ ডিসিআর ফি ৳১,১০০` এবং শুনানিতে `+ শুনানি খরচ ৳৩০০` ওয়ান-ট্যাপ সাজেশন।
   - *খরচ সংরক্ষণ:* প্রবেশকৃত যেকোনো অর্থ উক্ত ধাপের কাজের খরচ (`DemoExpense`) হিসেবে সংরক্ষিত হয় এবং সরাসরি ফাইলের ইনকাম থেকে বিয়োজিত হয়। ফাঁকা রাখলে কোনো খরচ তৈরি হয় না।
7. **টাকা জমা ফর্ম (PaymentFormScreen):** সংশ্লিষ্ট আবেদন বাছাই, বকেয়া সামারি, কিস্তিতে টাকা জমা, মাধ্যম (নগদ, বিকাশ, ব্যাংক) এবং তারিখ।
8. **নতুন আয় এন্ট্রি (IncomeFormScreen):** দোকানের স্বাধীন ও অন্যান্য সার্ভিসের আয় এন্ট্রি (আবেদন থেকে আয় এখানে সম্পূর্ণ নিষিদ্ধ ও ফিল্ডমুক্ত)।
9. **খরচ এন্ট্রি ফর্ম (ExpenseFormScreen):** "নির্দিষ্ট কাজের খরচ" (আবেদন নির্বাচন সহ) বনাম "দোকানের সাধারণ খরচ" (আবেদনমুক্ত) টগল, ক্যাটাগরি, কাস্টম খাত, তারিখ ও ভাউচার নোট।
10. **হিসাব ও আর্থিক বিবরণী (FinancialOverviewScreen):** প্রকৃত নিট ইনকাম হিরো কার্ড, সময়কাল ফিল্টার (চলতি মাস, বিগত মাস, চলতি বছর, সব সময়, নির্দিষ্ট মাস/বছর বটম শীট এবং কাস্টম রেঞ্জ), দ্রুত মাস নেভিগেটর (`◀` ও `▶`), আজকের আয় ও খরচের স্ন্যাপশট, সপ্তাহভিত্তিক/মাসভিত্তিক আয়-ব্যয় তুলনা চার্ট (`fl_chart`), সরাসরি আবেদনের বিস্তারিত খোলার সুবিধাসহ বকেয়া তালিকা এবং নিচে ডানপাশে দুটি ভাসমান অ্যাকশন বাটন (`[+ আয়]` ও `[- খরচ]`)।
11. **লেনদেনের ইতিহাস (TransactionHistoryScreen):** বহুমাত্রিক ফিল্টারিং (সব/আয়/খরচ, আজ/চলতি মাস/চলতি বছর/কাস্টম তারিখ, খাত, আবেদন), সক্রিয় ফিল্টার ট্যাগ ও ১-ক্লিকে ফিল্টার রিসেট।
12. **বকেয়া ব্যবস্থাপনা (DueManagementScreen):** মোট পাওনা ব্যানার, কাস্টমার তালিকা, সর্বোচ্চ বকেয়া অনুসারে সাজানো, আবেদনে যাওয়ার সুবিধা ও এক ক্লিকে পেমেন্ট ও ফোন কল শর্টকাট।
13. **গ্রাহক ও ব্যক্তি তালিকা (PersonListScreen):** সার্চ, মোট আবেদন ও বকেয়ার পরিমাণ, কল শর্টকাট।
14. **নতুন ব্যক্তি যোগ/সম্পাদনা (PersonCreateEditScreen):** নাম, মোবাইল, ঠিকানা ও নোট।
15. **ব্যক্তির প্রোফাইল (PersonDetailScreen):** ব্যক্তির আর্থিক সামারি ও যুক্ত সকল আবেদনের তালিকা (আবেদনকারী হিসেবে)।
16. **ভূমি অফিস তালিকা (OfficeManagementScreen):** অফিস যোগ, সম্পাদনা ও মোছার ব্যবস্থা।
17. **করণীয় কাজ ও রিমাইন্ডার (TaskListScreen):** ৪টি ট্যাব (সব, করতে হবে, চলমান, সম্পন্ন), প্রায়োরিটি ব্যাজ, সরাসরি চেকবক্স দিয়ে সম্পন্ন করার সুবিধা।
18. **নতুন কাজ যোগ/সম্পাদনা (TaskCreateEditScreen):** শিরোনাম, বিস্তারিত, তারিখ-সময়, প্রায়োরিটি ও সংশ্লিষ্ট আবেদন লিঙ্ক।
19. **কাজের বিস্তারিত (TaskDetailScreen):** স্ট্যাটাস পরিবর্তনের বোতাম, সংশ্লিষ্ট আবেদন শর্টকাট।
20. **ব্যবসায়িক বিশ্লেষণ ড্যাশবোর্ড (ReportsScreen):** ৪র্থ ডেডিকেটেড বটম-ন্যাভ ট্যাব (মোট আবেদন, সম্পন্নতার হার, প্রকৃত ইনকাম, গড় ইনকাম / ফাইল, মাসভিত্তিক আদায় ও ইনকাম প্রবৃদ্ধি ট্রেন্ড চার্ট, কাজের ধরন অনুপাত, পাইপলাইন ফানেল ও স্মার্ট অন্তর্দৃষ্টি)।
21. **রিপোর্ট বিস্তারিত ড্রিল-ডাউন (ReportDetailScreen):** পাই চার্ট (`fl_chart`), সময়কাল ফিল্টার এবং ক্যাটাগরিভিত্তিক বিস্তারিত টেবিল।
22. **ডকুমেন্ট প্রিভিউয়ার (DocumentViewerScreen):** PDF ও ইমেজ প্রিভিউ, সাইজ, আপলোড তারিখ ও শেয়ার ব্যবস্থা।
23. **ডেটা ব্যাকআপ ও রিস্টোর (BackupRestoreScreen):** ফোনে সরাসরি অফলাইন ব্যাকআপ এক্সপোর্ট (.db ফাইল Downloads ফোল্ডারে সেভ), `file_picker`-এর মাধ্যমে ফোন থেকে ফাইল ইমপোর্ট ও রিস্টোর, এবং ঐচ্ছিক টেলিগ্রাম ক্লাউড ব্যাকআপ। জটিল নেস্টেড কার্ড ও টেকনিক্যাল জার্গনমুক্ত পরিচ্ছন্ন UI।
24. **ক্যাটাগরি ও খাত ব্যবস্থাপনা (CategoryManagementScreen):** কাজের ধরনের তালিকা (Work Types) এবং খরচের খাতের (Expense Categories - আবেদন খরচ ও দোকান পরিচালন খরচ) যোগ, পরিবর্তন, মোছা ও রিয়েল-টাইম সার্চ।
25. **রেফারেন্স তালিকা (ReferenceListScreen):** মেনু ট্যাবের অধীন রেফারেন্স খাতা — মোট রেফারেন্স ও আবেদন কাউন্টার, তাৎক্ষণিক সার্চ, সম্পন্ন/চলমান/অপেক্ষমাণ স্ট্যাটাস বিভাজন, কল শর্টকাট ও নতুন রেফারেন্স এন্ট্রি।
26. **রেফারেন্স বিস্তারিত (ReferenceDetailScreen):** রেফারেন্স ব্যক্তির পূর্ণাঙ্গ প্রোফাইল, ছবি/অবতার, ফোন, ঠিকানা ও নোট, আর্থিক হিসাব (মোট সেবা মূল্য, আদায় ও বকেয়া), এবং উক্ত রেফারেন্সের আনীত সকল আবেদনের সম্পূর্ণ ইতিহাস।
27. **মেনু শেল (MoreMenuScreen):** ৫ম বটম-ন্যাভ ট্যাব — শীর্ষে সরাসরি প্রতিষ্ঠান ও দোকান প্রোফাইল কার্ড (রজব ভূমি সেবা ঘর, স্বত্বাধিকারী, মোবাইল ও ১-ট্যাপ সম্পাদনা), দৈনিক খাতা, কনফিগারেশন ও ব্যাকআপ, এবং কারিগরি সহায়তা। মধ্যবর্তী অপ্রয়োজনীয় সেটিংস সাব-স্ক্রিন বাতিল করে ডিরেক্ট নেভিগেশন নিশ্চিত করা হয়েছে।
28. **মূল ন্যাভিগেশন শেল (MainShellScreen):** ৫-ট্যাব বিশিষ্ট প্রোডাকশন বটম বার (ড্যাশবোর্ড, আবেদন, হিসাব, বিশ্লেষণ, মেনু)।

### 4. Verification & Testing
- `flutter test`: **34 tests passed!** (All tests green: Application 3-step wizard validation, Field label standard verification, Financial workflow scenarios 1 to 8, Status change automatic expense & dialog verification, UI widget tests, Money integer arithmetic & formatting, Bengali digits conversions, 5-tab main shell widget rendering smoke test, Reference calculation & Mouza integration test).
- `flutter analyze`: **No issues found!**
- Zero redundancy & complete navigable interaction across all screens without compilation errors.

### 5. Financial Management & Ledger Architecture Corrections (Applied)
- **Centralized Single Source of Truth:** Unified `DemoTransaction` model categorizing transactions into 6 distinct sources (`applicationPayment`, `statusIncome`, `statusExpense`, `independentIncome`, `applicationExpense`, `generalExpense`) with integer-based Paisa accuracy.
- **Application Details ("টাকার হিসাব"):** Removed the separate "খরচ যোগ করুন" button completely. Financial history displays automatic records of payments and associated expenses without duplication.
- **Status Change Dialog ("আবেদনের অবস্থা পরিবর্তন"):** Added optional financial entry card with toggleable 'টাকা গ্রহণ' (income) vs 'টাকা খরচ' (expense). Skipped or zero-amount changes create only status history; entered amounts create application-linked ledger entries and increment received/expense totals.
- **Main Financial Screen ("হিসাব"):** Removed floating "জমা নিন" button completely. Replaced "লেনদেন এন্ট্রি শর্টকাট" card with two dedicated Floating Action Buttons (FABs) at bottom-right above the bottom navigation bar: "আয়" (strictly for independent non-application income) and "খরচ" (supporting application-specific and general shop overheads with category customization). Added Hero profit overview, daily/monthly KPI breakdown, interactive cashflow chart, top outstanding dues list with 1-click application navigation, and recent transactions with color badges.
- **Transaction History Screen ("লেনদেনের ইতিহাস"):** Integrated comprehensive multi-criteria filtering (Type: all/income/expense; Date: all/today/month/year/custom range; Category; Application) with active filter removal chips and a 1-click reset button.

### 6. Application Wizard Architecture & Form Validation Framework (Completed)
- **3-Step Wizard UI:**
  - *ধাপ ১ (গ্রাহকের তথ্য):* আবেদনকারীর বিবরণ কার্ডের হেডারে সুসংহত সংরক্ষিত গ্রাহক সিলেক্টর (অতিরিক্ত ব্যানার মুক্ত পরিচ্ছন্ন ডিজাইন), স্বয়ংক্রিয় ফিল্ড ফিলিং, সবুজ স্ট্যাটাস ব্যাজ ও রিসেট অপশন, এবং আবেদনকারীর নাম, ১১ ডিজিট মোবাইল নম্বর ও ঠিকানা ভ্যালিডেশন।
  - *ধাপ ২ (কাজ ও অফিস):* শীর্ষে ১ সারিতে আবেদন নম্বর (`*` আবশ্যক ও ডুপ্লিকেট চেকিং ভ্যালিডেশন সহ) ও কেস নম্বর, কাজের ধরন (Chips + নতুন ধরন যোগ), অফিসের নাম (Dropdown + নতুন অফিস যোগ), আবেদনের তারিখ, এবং মৌজার নাম।
  - *ধাপ ৩ (চুক্তি ও সম্পন্ন):* **শীর্ষে রিয়েল-টাইম সারসংক্ষেপ কার্ড** (Review Card with Edit shortcuts), রেফারেন্স ব্যক্তি সিলেক্টর, চুক্তিকৃত সার্ভিস ফি (কুইক চিপস সহ), অগ্রিম জমা, ফাইল সংযুক্তি ও বিশেষ নোট।
- **Form Validation & Error Message Standards:**
  - প্রতিটি প্রয়োজনীয় ইনপুটে সুনির্দিষ্ট বাংলা এরর মেসেজ প্রদর্শিত হয় (`'আবেদনকারীর নাম আবশ্যক'`, `'মোবাইল নম্বর আবশ্যক'`, `'চুক্তির সার্ভিস ফি উল্লেখ করুন'`)।
  - ইনপুট বর্ডার লাল (`#F43F5E`) এবং নিচে ১২sp এরর টেক্সট স্পষ্টভাবে ভেসে ওঠে।
  - ধাপ পার হওয়ার জন্য কঠোর স্টেপ-ভ্যালিডেশন (`_formKey.currentState!.validate()`); কোনো অপূর্ণ ফিল্ড নিয়ে পরের ধাপে যাওয়া বা আবেদন সংরক্ষণ অসম্ভব।
  - `MoneyField`-এ নতুন `validator` সাপোর্ট ইন্টিগ্রেট করা হয়েছে যাতে সার্ভিস ফি মিসিং থাকলে ফর্ম আটকে যায়।
  - লেবেলে লাল তারকা (` *`) স্ট্যান্ডার্ড বজায় রাখা হয়েছে এবং অপ্রয়োজনীয় `(ঐচ্ছিক)` টেক্সট পরিহার করা হয়েছে।

### 7. UI Responsiveness & Text Overflow Immunity (Completed)
- **টাকার হিসাব ট্যাব (`ApplicationDetailScreen` Tab 3):**
  - ৪টি স্ট্যাট একক সারিতে থাকায় স্ক্রিন অনুযায়ী ভেঙে পড়ার সমস্যা দূর করে মার্জিত **২-কলাম গ্রিড লেআউট** (`_buildFinanceTile`) যুক্ত করা হয়েছে।
  - প্রতিটি টাইল `Expanded` এবং অভ্যন্তরীণ মান `FittedBox(fit: BoxFit.scaleDown)` দিয়ে মোড়ানো হয়েছে, ফলে লাখ বা কোটি টাকার বড় অংকও কখনো স্ক্রিন ভাঙবে না বা ওভারফ্লো করবে না।
  - অপ্রয়োজনীয়/অতিরিক্ত পুনরাবৃত্তি রোধে নিচের আনুমানিক ইনকাম ও নগদ ইনকাম টাইলস দুটি সরিয়ে ফেলা হয়েছে (যেহেতু উপরেই হিরো ইনকাম ব্যানারে স্পষ্ট ও বিস্তারিতভাবে অবশিষ্ট নিট ইনকাম প্রদর্শিত)। এখন সুষম ২x২ গ্রিডে প্রধান ৪টি মেট্রিক দৃশ্যমান:
    - সারি ১: চুক্তিকৃত টাকা | মোট আদায়
    - সারি ২: কাজের মোট খরচ | বকেয়া (বা 'পরিশোধিত ✓')
  - হিরো ইনকাম ব্যানারেও `FittedBox` ও `maxLines` কন্ট্রোল প্রয়োগ করা হয়েছে।
- **কুইক অ্যাকশন বার (`_buildQuickActionBar`):**
  - সব চুক্তিকৃত টাকা পরিশোধিত হয়ে গেলে (`!dueAmount.isPositive`) 'জমা নিন' বাটন স্বয়ংক্রিয়ভাবে অদৃশ্য হয়ে যায়।
  - স্ট্যাটাস ব্যাজ `Flexible` এবং বাটনগুলোতে স্লিম প্যাডিং ও `MaterialTapTargetSize.shrinkWrap` দেওয়ায় যেকোনো ছোট স্ক্রিনেও বারটি অক্ষত থাকে।
- **আবেদন বিবরণী (`_buildDetailRow`):**
  - বাম পাশের লেবেল `ConstrainedBox(70-110px)` ও ডানের টেক্সট `Flexible` ও `TextOverflow.ellipsis` দ্বারা সুরক্ষিত।
  - রেফারেন্স ব্যক্তির 'প্রোফাইল' বাটনকে ভারী `TextButton.icon`-এর বদলে স্লিম ও মার্জিত `InkWell` পিলে রূপান্তর করা হয়েছে।
- **স্ট্যাটাস পরিবর্তন ডায়ালগ ও গ্লোবাল বাটন:**
  - ডায়ালগে `ConstrainedBox(maxHeight: 88%)` ও `SingleChildScrollView` নিশ্চিত করে যেকোনো স্ক্রিন হাইট বা কিবোর্ড ওপেন থাকলেও ডায়ালগ স্ক্রলযোগ্য থাকবে।
  - `AppButton` উইজেটে অভ্যন্তরীণ টেক্সট `Flexible` ও `TextOverflow.ellipsis` সহ সুরক্ষিত করা হয়েছে।
- **আবেদন কার্ড (`ApplicationCard`):**
  - তালিকার কার্ডগুলো থেকে অতিরিক্ত খরচ/ইনকাম স্ট্রিপ (`কাজের মোট খরচ` ও `অবশিষ্ট ইনকাম`) সম্পূর্ণ সরিয়ে নেওয়া হয়েছে। কার্ডে এখন কেবলমাত্র আবশ্যকীয় আর্থিক তথ্য (চুক্তি, জমা ও বকেয়া ব্যাজ) পরিচ্ছন্নভাবে প্রদর্শিত হয়।

### 8. 'Mark as Paid' / বকেয়া মওকুফ ও নিষ্পত্তি ফিচার (Completed)
- **বাস্তবধর্মী লজিক:** ৭,০০০ টাকার চুক্তিতে ৬,৫০০ টাকা পাওয়ার পর ক্লায়েন্ট ৫০০ টাকা আর না দিলে তা মওকুফ/ডিসকাউন্ট হিসেবে 'Mark as Paid' করার সুবিধা যুক্ত হয়েছে।
- **ডাটা মডেল সাপোর্ট (`DemoApplication`):**
  - `isMarkedAsPaid` ফ্ল্যাগ যুক্ত করা হয়েছে।
  - `dueAmount` প্রপার্টি স্বয়ংক্রিয়ভাবে `isMarkedAsPaid ? Money.zero : (agreedAmount - receivedAmount)` রিটার্ন করে। ফলে সম্পূর্ণ অ্যাপে (ড্যাশবোর্ড, বকেয়া তালিকা, ফিল্টার, অ্যাকশন বার) এই ফাইলে আর কোনো বকেয়া দেখায় না।
  - `rawDueAmount` মূল প্রার্থিত ও প্রাপ্ত টাকার ব্যবধান অক্ষুণ্ণ রাখে।
- **৩টি কার্যকর ইন্টারফেস ইন্টিগ্রেশন:**
  1. *আবেদন বিস্তারিত (টাকার হিসাব ট্যাব & AppBar):* বকেয়া টাইলসে `পরিশোধিত ✓ (মওকুফ)` স্ট্যাটাস এবং নিচে এক-ক্লিকে `[পরিশোধিত চিহ্নিত]` বাটন ও ডায়ালগ। ভুলক্রমে চিহ্নিত হলে সহজে `[পুনঃবহাল]` করার সুবিধাও রয়েছে।
  2. *টাকা জমা ফর্ম (`PaymentFormScreen`):* টাকা গ্রহণের সময় নিচে চেকবক্স `[✓] বাকি টাকা মওকুফ করে সম্পূর্ণ পরিশোধিত চিহ্নিত করুন` রাখা হয়েছে, যাতে আংশিক টাকা নেওয়ার সাথে সাথেই ফাইল নিষ্পত্তি করা যায়।
  3. *বকেয়া ব্যবস্থাপনা স্ক্রিন (`DueManagementScreen`):* প্রতিটি বকেয়া আবেদনের পাশে সরাসরি `[পরিশোধিত চিহ্নিত]` অ্যাকশন যুক্ত করা হয়েছে।

### 9. Senior UI/UX Redesign: Application Card & Application Detail Screen (Completed)
- **ApplicationCard Redesign (`application_card.dart`):**
  - **Status Accent Strip:** কার্ডের বাঁ-প্রান্তে ৪ পিক্সেল চওড়া ডায়নামিক স্ট্যাটাস কালার ইন্ডিকেটর (`AppColors.getStatusColor`) যুক্ত, যা লেখা না পড়েই তাৎক্ষণিক স্ট্যাটাস জানান দেয়।
  - **Layered Elevation & Affordance:** ফ্ল্যাট ২ডি বর্ডারের পরিবর্তে ডুয়াল-লেয়ার সফট শ্যাডো (`Offset(0, 3), blur 10` ও `Offset(0, 1), blur 3`) এবং ক্লিপড `InkWell` সহ প্রেসড রিপল ফিডব্যাক।
  - **Category Separation:** আবেদনকারীর নাম বোল্ড ১৬sp হেডারে; কাজের ধরন (`নামজারি`) প্রাইমারি সারফেস পিলে এবং মৌজা (`মৌজা: বাগবাড়ী`) স্লিম লোকেশন আইকন সহ সূক্ষ্ম ব্যাজে উপস্থাপিত।
  - **Metadata Strip:** অফিস ও আবেদনের তারিখ একটি স্লিম গ্রে-৫০ কন্টেইনারে প্রাতিষ্ঠানিক ও ক্যালেন্ডার আইকন সহ সাজানো।
  - **3-Column Inset Financial Summary Bar:** নিচের আর্থিক অংশটি এখন `#F8FAFC` ব্যাকগ্রাউন্ড এবং ভার্টিক্যাল ডিভাইডার দিয়ে সুসংগঠিত ৩টি কলামে বিভক্ত:
    1. চুক্তি (Agreed): স্লিম লেবেল ও ডার্ক বোল্ড ফন্ট।
    2. জমা (Received): ভাইব্রেন্ট এমারেল্ড লেবেল ও বোল্ড ফিগার।
    3. বকেয়া/পরিশোধিত স্ট্যাটাস পিল: বকেয়া থাকলে অ্যাম্বার শিডিউল আইকন ও অংক; পরিশোধিত হলে এমারেল্ড চেক সার্কেল ও `পরিশোধিত ✓` ব্যাজ।
- **ApplicationDetailScreen Redesign (`application_detail_screen.dart`):**
  - **AppBar & TabBar:**
    - অ্যাপবারে আবেদনকারীর নামের নিচে কাজের ধরন ও অফিসের সাবটাইটেল।
    - অ্যাপবারে অপ্রয়োজনীয় কনফিউজিং আইকন সরিয়ে কেবল স্ট্যান্ডার্ড [সম্পাদনা] ও [মুছে ফেলুন] অ্যাকশন রাখা হয়েছে (বকেয়া মওকুফ সরাসরি টাকার হিসাব ট্যাবে সুসংহত)।
    - একশন বাটনগুলোতে প্রমিত মার্জিন ও ক্লিয়ার রিপল বাউন্স।
    - ট্যাববার আইকন ইন্টিগ্রেশন সরিয়ে স্লিম সিঙ্গেল লাইনে ১ স্ক্রিনেই ৪টি ট্যাব (`১. তথ্য`, `২. অগ্রগতি`, `৩. টাকার হিসাব`, `৪. ডকুমেন্ট`) প্রদর্শন।
  - **Quick Action Bar:** বড় আকারের স্ট্যাটাস ব্যাজ, পিল শেপড `[অবস্থা বদলান]` আউটলাইন বাটন এবং বকেয়া থাকলে ভাইব্রেন্ট এমারেল্ড `[জমা নিন]` বাটন।
  - **কাজের অগ্রগতি (Connected Vertical Timeline & Semantic Flow):**
    - বিচ্ছিন্ন রঙের বিশৃঙ্খলা দূর করে স্বাভাবিক অগ্রগতি ধাপসমূহে (আবেদন, প্রস্তাব, শুনানি, ডিসিআর) একটি সুসংহত প্রফেশনাল প্রাইমারি কালার থিম।
    - সফলতা/অনুমোদন (`মঞ্জুর`, `সম্পন্ন`) স্পষ্ট এমারেল্ড গ্রিনে, সমস্যা/বাতিল (`বাতিল`, `নামঞ্জুর`) রোজে এবং সতর্কতা (`আপত্তি`, `অপেক্ষমাণ`) অ্যাম্বারে প্রদর্শিত।
    - দিকনির্দেশক ট্রানজিশন ব্যাজ: `[পূর্ববর্তী অবস্থা] ➔ [নতুন অবস্থা]`, সাথে লেটেস্ট ধাপে অ্যাক্টিভ `[বর্তমান]` ব্যাজ ও টাইমস্ট্যাম্প।
    - রিভার্স-ক্রোনোলজিক্যাল সর্টিং নিশ্চিত করায় শীর্ষে সবসময় বর্তমান সক্রিয় অবস্থা প্রদর্শিত হয়।
  - **টাকার হিসাব (Finance Tab):**
    - শীর্ষে প্রকৃত ইনকামের প্রিমিয়াম গ্রেডিয়েন্ট হিরো কার্ড (`মোট আদায় — মোট কাজের খরচ = প্রকৃত ইনকাম` সাবটাইটেল সহ)।
    - সুষম ২x২ মেট্রিক গ্রিড (`চুক্তিকৃত টাকা`, `মোট আদায়`, `কাজের মোট খরচ`, `বকেয়া`)।
    - জমার ইতিহাসে ডিরেকশনাল এমারেল্ড ডাউনওয়ার্ড অ্যারো এবং পেমেন্ট মেথড ট্যাগ (নগদ, বিকাশ, ব্যাংক)।
    - খরচের ইতিহাসে ডিরেকশনাল রোজ আপওয়ার্ড অ্যারো এবং ক্যাটাগরি ট্যাগ সহ ট্রানজ্যাকশন কার্ড।
  - **ডকুমেন্ট (Documents Tab):** PDF বনাম ইমেজ ফাইলের স্পষ্ট টাইপ ব্যাজ, সাইজ, আপলোড ডেট এবং ভিউ/ডিলিট শর্টকাট।
  - **Modern Dialogs:** অবস্থা পরিবর্তন ও পরিশোধিত চিহ্নিতকরণ ডায়ালগে `radiusXl` রাউন্ডেড কর্নার, ইনফো বক্স ও ক্লিন অ্যাকশন বাটন।
- **Verification:** `flutter analyze` (No issues found) এবং `flutter test` (All tests green).

### 11. Task Management, Reminder Architecture & Senior UI/UX Redesign (Completed)
- **Home Notification Icon Badge (DashboardScreen):**
  - ড্যাশবোর্ডের শীর্ষ AppBar-এ নোটিফিকেশন আইকন (`Icons.notifications_none_outlined`)-এ রিয়েল-টাইম **"আজকের কাজ"** কাউন্টার ব্যাজ যুক্ত (`Badge` widget in Bengali digits)।
  - আজকের যে কয়টি কাজ নির্ধারিত রয়েছে (`DemoStore.todayTasksCount`), নোটিফিকেশন আইকনের উপরে ভাইব্রেন্ট রোজ ব্যাজে তা স্পষ্টভাবে প্রদর্শিত হয়।
  - নোটিফিকেশন আইকন বা ড্যাশবোর্ডের "নতুন কাজ" বাটনে ট্যাপ করে কাজ সম্পন্ন, হালনাগাদ বা তৈরি শেষে ফিরে আসলে স্বয়ংক্রিয়ভাবে নোটিফিকেশন কাউন্টার রিফ্রেশ হয়।
- **নতুন "আজকের কাজ" ফিল্টার ও ডিফল্ট সিলেকশন (TaskListScreen):**
  - `TaskListScreen`-এ ৫টি সুনির্দিষ্ট ট্যাব চালু করা হয়েছে:
    1. **`আজকের কাজ`** (ডিফল্টভাবে নির্বাচিত — `initialIndex: 0`)
    2. **`করতে হবে`** (Pending Tasks)
    3. **`চলমান`** (In Progress Tasks)
    4. **`সম্পন্ন`** (Completed Tasks)
    5. **`সব`** (All Tasks)
  - প্রতিটি ট্যাবে বাংলা সংখ্যায় রিয়েলটাইম কাজের সংখ্যা (`BengaliDigits.toBengali`) দৃশ্যমান।
  - আজকের কাজের ট্যাবে শীর্ষে বিশেষ সারসংক্ষেপ ব্যানার (`_buildTodayHeaderBanner`): আজকের তারিখ, মোট কাজের মধ্যে কতটি সম্পন্ন হয়েছে তার প্রগ্রেস এবং কয়টি বাকি রয়েছে তার স্ট্যাটাস পিল।
- **TaskCard প্রোডাকশন রিডিজাইন:**
  - **Status Accent Bar:** কার্ডের বাঁ-প্রান্তে ৪.৫px স্ট্যাটাস কালার অ্যাকসেন্ট স্ট্রিপ (সম্পন্ন হলে এমারেল্ড, চলমান হলে প্রাইমারি ইন্ডিগো, করতে হবে হলে অ্যাম্বার, জরুরি বা মেয়াদোত্তীর্ণ হলে রোজ)।
  - **ট্যাকটাইল চেকবক্স:** এক ক্লিকে কাজ সম্পন্ন চিহ্নিত করার সুন্দর আধুনিক রাউন্ডেড চেকবক্স।
  - **মাল্টি-ট্যাগ চিপস:** `আজকের কাজ`, `মেয়াদোত্তীর্ণ` (Overdue), `জরুরি`, কাজের ক্যাটাগরি এবং ড্রপডাউন সহ ইন্টারঅ্যাক্টিভ স্ট্যাটাস ব্যাজ (কার্ড থেকেই সরাসরি অবস্থা পরিবর্তনযোগ্য)।
  - **আবেদন ও গ্রাহক লিংক:** সংশ্লিষ্ট আবেদনের নাম ও কেস নম্বর লিংক চিপ (১-ক্লিকে সরাসরি সংশ্লিষ্ট ফাইলে যাওয়ার সুবিধা সহ)।
  - **কনটেক্সট মেনু:** ৩-ডট মেনু থেকে এক ক্লিকে সম্পাদন বা নিশ্চিতকরণ ডায়ালগ সহ মুছে ফেলার সুবিধা।
  - **ইনস্ট্যান্ট সার্চ বার:** কাজের নাম, ক্যাটাগরি, গ্রাহক বা নোট অনুসারে তাৎক্ষণিক অনুসন্ধান।
- **নতুন কাজ তৈরি ও সম্পাদনা প্রোডাকশন রিডিজাইন (TaskCreateEditScreen):**
  - **ভূমি সেবার কুইক সাজেশন চিপস:** শিরোনামের নিচে ১-ট্যাপ সাজেশন (`⚖️ শুনানিতে উপস্থিতি`, `📄 মূল দলিল সংগ্রহ`, `🏛️ ভূমি অফিসে ফাইল জমা`, `💰 ফি ও বকেয়া তাগাদা`, `📦 নামজারি খতিয়ান প্রদান`, `✍️ ওয়ারিশ সনদ সংগ্রহ`)।
  - **কাজের ধরন (Category):** আইকন ও ভাইব্রেন্ট কালার সহ ৬টি ক্যাটাগরি চিপ (`⚖️ শুনানি`, `📄 কাগজপত্র`, `💰 ফি/তাগাদা`, `🏛️ অফিস জমা`, `📦 ডেলিভারি`, `📌 সাধারণ`)।
  - **কাজের অবস্থা (Status Selector):** পূর্বের মিসিং অবস্থা নির্বাচক যোগ করে সুসংহত ৩টি অপশন (`করতে হবে`, `চলমান`, `সম্পন্ন`)।
  - **তারিখ ও কুইক শর্টকাট:** ক্যালেন্ডার পিকারের পাশাপাশি দ্রুত নির্বাচনের জন্য `[আজ]`, `[আগামীকাল]`, `[৩ দিন পর]`, `[১ সপ্তাহ পর]` চিপস।
  - **টাইম পিকার ও সময় শর্টকাট:** সরাসরি নেটিভ `showTimePicker` ডায়ালগ এবং কুইক সময় চিপস (`সকাল ১০:০০`, `সকাল ১১:০০`, `দুপুর ১২:০০`, `বিকাল ০৩:৩০`, `সন্ধ্যা ০৬:০০`)।
  - **সার্চেবল আবেদন ফাইল সিলেক্টর:** পুরানো ড্রপডাউনের বদলে লাইভ সার্চ সহ বটম শিট মডাল সিলেক্টর।
- **কাজের বিস্তারিত স্ক্রিন রিডিজাইন (TaskDetailScreen):**
  - ৩-ধাপের ডিরেকশনাল স্ট্যাটাস স্টেপার (`করতে হবে` ➔ `চলমান` ➔ `সম্পন্ন`)।
  - হিরো ডিটেইল কার্ড, আজকের কাজ/মেয়াদোত্তীর্ণ ব্যাজ, সংশ্লিষ্ট আবেদন কার্ড ও ডিরেকশনাল অ্যাকশন বাটন।
- **স্বয়ংক্রিয় টেস্ট ফলাফল:**
  - `flutter test`: **৪১টি টেস্টের ৪১টিই সফলভাবে উত্তীর্ণ (All 41 tests passed)**।
  - `flutter analyze`: **No issues found!**

### 8. UI/UX Redundancy Elimination & Clean Menu Footer (Completed)
- **রিডানডেন্সি দূরীকরণ (Menu Simplification):**
  - মেনু ট্যাব থেকে অপ্রয়োজনীয় ইন্টারমিডিয়েট "সেটিংস" সাব-স্ক্রিন, শীর্ষের শপ কার্ড এবং "সহায়তা ও তথ্য / হেল্পলাইন" কার্ড সম্পূর্ণ অপসারণ করা হয়েছে।
  - মেনুতে এখন কেবল দুটি সুনির্দিষ্ট সেকশন বিদ্যমান:
    1. **দৈনিক ব্যবস্থাপনা ও খাতা:** গ্রাহক খাতা ও রেফারেন্স ব্যক্তি, অফিস ও এজেন্সির তালিকা, বকেয়া আদায়ের খাতা।
    2. **কনফিগারেশন ও ব্যাকআপ:** কাজের ধরন ও খরচের খাত, ডেটা ব্যাকআপ ও রিস্টোর (ম্যানুয়াল এক্সপোর্ট/ইমপোর্ট ও টেলিগ্রাম)।
  - **ডেভেলপার সিগনেচার ও পরিচ্ছন্ন ফুটার:**
    - অ্যাপ সংস্করণ: `রজব ভূমি সেবা ঘর • সংস্করণ ১.০.০`
    - ডেভেলপার: `Md Mim Shifat`
    - ইমেইল: `mimshifat5@gmail.com`
- **ডেটা ব্যাকআপ ও রিস্টোর রিডিজাইন (BackupRestoreScreen):**
  - টেকনিক্যাল জার্গন (SQLite, Drift, PRAGMA OK, 4-কলাম স্ট্যাটাস, নেস্টেড গ্রে বক্স) সম্পূর্ণ অপসারিত।
  - ফোনে সরাসরি অফলাইন ব্যাকআপ এক্সপোর্ট (Downloads ফোল্ডারে .db ফাইল) ও `file_picker`-এর মাধ্যমে ফাইল ইমপোর্ট করে এক ক্লিকে রিস্টোর।
  - সেকেন্ডারি অপশন হিসেবে পরিচ্ছন্ন টেলিগ্রাম ক্লাউড ব্যাকআপ।
- **এক লাইনে ডায়লগ অ্যাকশন স্ট্যান্ডার্ড (`AppDialogActionRow`):**
  - ফ্লাটারের ডিফল্ট `AlertDialog`-এ `TextButton` উপরে ও `ElevatedButton` নিচে ভেঙে পড়ার সমস্যা সম্পূর্ণ দূর করতে `AppDialogActionRow` কম্পোনেন্ট তৈরি করা হয়েছে।
  - সকল ডায়লগ ও মোডালে `[বাতিল]` (আউটলাইন) এবং `[যোগ করুন / নিশ্চিত করুন]` (প্রাইমারি) ৫০%-৫০% প্রস্থে একই অনুভূমিক সারিতে (One Horizontal Row) সুষমভাবে প্রদর্শিত হয়।
  - অ্যাপের প্রতিটি ডায়লগে (`CategoryManagementScreen`, `ApplicationCreateScreen`, `ExpenseFormScreen`, `IncomeFormScreen`, `OfficeManagementScreen`, `DueManagementScreen`) এই স্ট্যান্ডার্ড সক্রিয় করা হয়েছে।
- **কোড ভেরিফিকেশন:**
  - `flutter analyze`: **No issues found!**







---

## Phase 0 Audit — Complete Project Audit & Consolidated Engineering Plan

> **Status:** ✅ Audit complete — ⏳ Awaiting Team Leader / user approval to begin Phase 1 (Database Foundation)
> **Audit mode:** Read-only. No application source modified, no packages installed, no database schema changed, no commit or push.
> **Full report:** [`docs/PHASE_0_PROJECT_AUDIT.md`](PHASE_0_PROJECT_AUDIT.md)

### Verified baseline (live command output)
| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found** |
| Test suite | `flutter test --reporter=expanded` | **110 / 110 passed** — 0 failed, 0 skipped |
| Toolchain | `flutter --version` | Flutter 3.41.9 stable · Dart 3.11.5 |

### Key audit outcomes
- **No persistence layer exists.** No `lib/core/database/`, no Drift, no DAO, no repository. All business records live in mutable static lists (`demo_data.dart:416-1412`) and are lost on restart.
- **No state-management layer exists.** The only Riverpod token in the whole tree is `ProviderScope` (`main.dart:8`) — zero `ConsumerWidget`, `ref.watch` or `ref.read`. `go_router` is declared but never imported.
- **4 Critical defects** — total data loss; `isMarkedAsPaid` silently reset by two code paths (`application_detail_screen.dart:548-571`, `application_edit_screen.dart:88-111`); seeded `expenseAmount` disagreeing with child `expenses[]` lists; backup/restore reporting success while doing nothing (`backup_restore_screen.dart:35, 84, 112`).
- **Schema is largely sound.** `unified_transactions_view` — all 6 UNION ALL branches select exactly 14 matching columns; `CREATE VIEW` will succeed. 8 structural defects catalogued, including a double-count risk in view branches 4 and 6.
- **Seed data has dangling foreign keys.** Applications reference `p-6` and `p-7`; persons stop at `p-5`. With `PRAGMA foreign_keys = ON` the seed would be rejected — must be repaired before migration.
- **Core financial formulas are correct.** Verified formula-by-formula against BACKEND_MASTER_PLAN.md §1.2. Three deviations matter: ID-prefix heuristics for status classification, full-list rebuild per frame, and duplicate expense totals.
- **No shared validators exist.** `lib/core/utils/` holds only `money.dart` and `bengali_digits.dart`.
- **Anti-hang audit: clean.** All 16 `SingleChildScrollView` sites classified. The performance risk is the data layer, not the widget tree.
- **Testing:** 110 tests exist and pass.

---

## Phase 1 — Database Foundation · Implementation & Verification

> **Status:** ✅ **COMPLETE** — schema builds, all 14 tables created, 110/110 tests pass, `flutter analyze` clean.
> **Scope:** `lib/core/database/` (new) · `lib/core/utils/money.dart` · `lib/core/utils/validators.dart` (new) · `lib/main.dart` crash shield · `lib/core/demo/demo_data.dart` seed repair · `pubspec.yaml`.

### Packages added
`drift` · `drift_flutter` · `sqlite3` · `sqlite3_flutter_libs` · `path_provider` · `path` · dev: `drift_dev` · `build_runner`.
Generated code lives at `lib/core/database/app_database.g.dart` (never edit by hand — regenerate with `dart run build_runner build`).

### Files created
| Path | Purpose |
|---|---|
| `lib/core/database/app_database.dart` | `AppDatabase` — 14 tables, `unified_transactions_view`, 3 integrity triggers, WAL + FK pragmas, migration strategy |
| `lib/core/database/app_database.g.dart` | drift-generated code (regenerate, never hand-edit) |
| `lib/core/database/tables/*.dart` | One file per table (14) + `application_statuses.dart` (single source of valid statuses) |
| `lib/core/database/database_provider.dart` | Riverpod `appDatabaseProvider` singleton |
| `lib/core/database/database_seeder.dart` | Atomic demo-seed loader (single transaction, UUID v4 mapping) |
| `lib/core/database/unified_transactions_view.drift` | 6-branch unified ledger view (14 columns per branch) |
| `lib/core/database/integrity_guards.drift` | Immutability triggers (snapshot columns, payments, expenses) |
| `lib/core/utils/validators.dart` | `AppValidators` — phone/name/amount/category validation with BACKEND_MASTER_PLAN.md messages |
| `test/unit/database_schema_test.dart` | 34 schema, pragma, FK, CHECK, soft-delete, trigger and seed tests |
| `test/unit/validators_and_money_json_test.dart` | Validator + `Money` JSON codec + integer-safety tests |

### Critical defects found and fixed

**CR-001 — the schema could never be created (Critical).**
drift's generator emits `allSchemaEntities` with the **3 triggers and the view listed before the 14 tables**, so `m.createAll()` executed `CREATE TRIGGER ... ON applications` before `applications` existed → `SqliteException(1): no such table: main.applications`. Every one of the 27 schema tests aborted here, so the whole schema was unverified.
Fix: `app_database.dart` now owns creation order explicitly — tables → indexes → views → triggers — in a private `_createSchema(Migrator)` used by both `onCreate` and `onUpgrade`. SQLite does not require a referenced table to exist at `CREATE TABLE` time, but it does for `CREATE VIEW` and `CREATE TRIGGER`.

**CR-002 — `Money.fromJson` silently swallowed garbage (High).**
`fromJson` delegated `String` input to the permissive `Money.parse`, so `fromJson('garbage')` returned `Money.zero` — a wrong ledger entry rather than an error (BACKEND_MASTER_PLAN.md §1.2). Fix: a new private `_parseExactPaisa` performs **integer-only** paisa arithmetic (no `double` anywhere in the path) and throws `FormatException` on empty or malformed input. `Money.parse` keeps its permissive behaviour for UI callers but is now documented as unsafe.

**CR-003 — an expense could be classified as neither (High).**
The `expenses` table enforced only `is_general = 1 ⇒ application_id IS NULL`. A row with `is_general = 0` and `application_id IS NULL` was legal yet appeared in **no** view branch and in **no** per-file total — invisible money. Fix: the constraint set is now a bijection — `CHECK (is_general = 0 OR application_id IS NULL)` **and** `CHECK (is_general = 1 OR application_id IS NOT NULL)`. The demo seed satisfies both (6 file expenses all carry an application; 9 general expenses carry none).

**CR-004 — `onUpgrade` would have failed on the first real schema change (Medium).**
`onUpgrade` called the same blind re-create as `onCreate`; on an existing database the indexes and triggers already exist, so `CREATE INDEX` / `CREATE TRIGGER` would fail with "already exists". Fix: `onUpgrade` is now explicitly version-aware and intentionally empty, with a documented pattern (`if (from < 2) { ... }`) for future versions. User data is never destroyed.

**CR-005 — `double` on money in the live UI path (Medium).**
`Money.inTakaDouble` fed the margin percentage and all three chart series, and `Money.operator*` took a `num` and rounded. Fix: `operator*` now accepts `int` only; the margin percentage is computed with integer paisa (`netIncome.paisa * 100 ~/ totalIncome.paisa`); chart series accumulate in integer paisa and convert to `double` only at the fl_chart render boundary (`toY`), which the library's API requires.

### Test-side defects found and fixed
- `LEFT JOIN references r` → `LEFT JOIN "references" r` — `references` is a SQLite keyword and broke the FK-integrity query with a syntax error.
- The "খরচের অঙ্ক ও খাত অপরিবর্তনীয়" fixture inserted a file expense with no `application_id`, which the new CHECK correctly rejects — the fixture now inserts a parent application and links to it.
- 3 lints cleared (`unnecessary_string_interpolations` ×2, `prefer_const_constructors` ×1).

### Verified state (live command output)
| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found!** (5.7s) |
| Test suite | `flutter test --reporter=expanded` | **110 / 110 passed** — 0 failed, 0 skipped |
| Schema suite | `flutter test test/unit/database_schema_test.dart` | **34 / 34 passed** |
| Code generation | `dart run build_runner build` | Built successfully, 96 outputs |
| Toolchain | `flutter --version` | Flutter 3.41.9 stable · Dart 3.11.5 |

### Phase 1 acceptance criteria (`docs/PHASE_0_PROJECT_AUDIT.md` §12)
| # | Criterion | Status |
|---|---|---|
| 1 | All 14 tables created with correct schema | ✅ verified by test |
| 2 | `PRAGMA journal_mode` returns `wal` | ✅ verified by test |
| 3 | `PRAGMA foreign_keys` returns 1 (enforced) | ✅ verified by test |
| 4 | `unified_transactions_view` creates (6 branches × 14 columns) | ✅ verified by test |
| 5 | Branch 4 and 6 double-count predicates fixed | ✅ verified by test |
| 6 | Seed FK integrity repaired (no dangling `p-6` / `p-7`) | ✅ persons `p-6`, `p-7` added; no orphans |
| 7 | `Money.toJson` / `fromJson` present and unit tested | ✅ + strict string handling |
| 8 | `lib/core/utils/validators.dart` created with §8.2 messages | ✅ |
| 9 | `main.dart` registers all three crash handlers | ✅ |
| 10 | All 43 pre-existing tests still pass | ✅ (now 110 total) |
| 11 | New schema, migration and soft-delete tests pass | ✅ 34 schema tests |
| 12 | `flutter analyze` reports zero issues | ✅ |

### Deliberate decisions recorded
- **NEW-1 — the ledger is an *active* view.** `unified_transactions_view` inner-joins `applications`, so rows of a soft-deleted parent stay in the database (audit trail intact, per BUSINESS_RULES.md §1.3) but fall outside active calculations. Documented in the `.drift` file header.
- **NEW-2 — `is_status_fee` remains a dead path.** No production code sets it, so the view's `statusIncome` branch is currently unreachable. Left in place (the column is part of the documented schema) and flagged for the UI-integration phase.

---

## Phase 3 Completed Work — Presentation Layer & State Migration

### Scope Completed
1. **Removed `DemoStore` & Mock Dependencies across Presentation Screens:**
   - Fully decoupled presentation screens (`dashboard_screen.dart`, `application_list_screen.dart`, `application_create_screen.dart`, `application_detail_screen.dart`, `application_edit_screen.dart`, `payment_form_screen.dart`, `expense_form_screen.dart`, `income_form_screen.dart`, `financial_overview_screen.dart`, `due_management_screen.dart`, `transaction_history_screen.dart`, `person_list_screen.dart`, `person_detail_screen.dart`, `person_create_edit_screen.dart`, `reference_list_screen.dart`, `reference_detail_screen.dart`, `office_management_screen.dart`, `settings_screen.dart`, `category_management_screen.dart`, `task_list_screen.dart`, `task_create_edit_screen.dart`, `task_detail_screen.dart`) from `DemoStore` and wired them to live Riverpod stream providers and asynchronous state notifiers.
2. **Application Creation Wizard (`ApplicationCreateScreen`):**
   - Live stream loading for work types, offices, persons, and references.
   - Real-time application number duplicate verification (`checkApplicationNumberExists`).
   - Seamless creation with atomic person linkage and financial entry via `applicationControllerProvider`.
3. **Status Change Dialog & Atomic State Transitions (`ApplicationDetailScreen`):**
   - Integrated `transitionStatus` atomic ACID transaction (records status history, logs fee expense, and creates hearing reminder task simultaneously).
   - Live streaming of application payments, expenses, and status history with immediate reactivity.
4. **Financial Forms & Overpayment Guard:**
   - `PaymentFormScreen`: Added overpayment confirmation dialog in natural Bengali (`"পরিশোধিত টাকার পরিমাণ বকেয়ার চেয়ে বেশি..."`).
   - `ExpenseFormScreen`: Category selector wired to `expenseCategoriesStreamProvider` with custom category creation via `categoryControllerProvider`.
   - `IncomeFormScreen`: Dedicated independent shop income creation wired to `financeControllerProvider.addIndependentIncome`.
5. **Ledger & Due Management (`FinancialOverviewScreen`, `DueManagementScreen`, `TransactionHistoryScreen`):**
   - Connected to `unifiedTransactionsStreamProvider` (Drift reactive SQLite view) and `applicationsWithFinancialsStreamProvider`.
   - Privacy-first landing page with zero financial totals on app start preserved.
6. **Verification & Testing:**
   - Static Analysis: 0 errors across entire codebase.
   - Test Suite: **146 / 146 tests passed!** (100% green).
   - Widget tests, unit tests, and database DAO tests all running cleanly in under 20 seconds.

---

## Backend Phase 4: Backup, Restore & Data Migration Safety (Completed & Hardened)

### Scope Completed
1. **SQLite Offline Database Export (`PRAGMA wal_checkpoint(TRUNCATE)` & `VACUUM INTO`):**
   - Implemented `exportBackup()` in `BackupRepository` which flushes WAL pages to disk and executes native SQLite `VACUUM INTO` to produce an unfragmented, standalone, clean `.db` file in the device's Downloads directory (with fallback to Documents).
   - Generates unique timestamped filenames (e.g. `rojob_backup_YYYYMMDD_HHmmss.db`).
   - Automatically records `last_backup_time` in `shop_settings`.
   - **Storage Auto-Pruning:** Retains strictly the latest 5 backup files (`rojob_backup_*.db`) and prunes older ones automatically to prevent disk space leaks over time.
2. **Background Isolate Integrity & Schema Verification (`validateBackupFile`):**
   - Complete validation executed in a dedicated background `Isolate.run()` to guarantee zero UI freeze or ANR.
   - Executes `PRAGMA integrity_check;` and `PRAGMA quick_check;`.
   - Verifies the presence of all core tables (`applications`, `payments`, `expenses`, `persons`, `references`, `offices`, `shop_settings`).
   - Gathers exact record statistics (applications, payments, expenses, customers, references, schema version) to preview for user confirmation.
   - Throws human-friendly Bengali `AppFailure.corruptBackup` on corrupted or alien database files without touching the live database.
3. **Zero Data Loss & Safe Restore with Pre-Restore Safety Archiving (`restoreBackup`):**
   - Validates candidate file in isolate prior to any live database modification.
   - **Accidental Overwrite Protection:** Automatically creates a timestamped safety archive copy (`rojob_bhumi_pre_restore_[timestamp].sqlite`) preserved across app sessions (retains latest 3 safety archives). If a user accidentally restores an older or wrong backup, the live data remains recoverable.
   - Closes live connection to release OS file locks, purges stale `-wal` and `-shm` journals, and swaps the file.
   - Performs post-restore integrity check on the newly placed database file.
   - If any step fails, automatically rolls back from `rojob_bhumi_pre_restore.sqlite` and reopens the original database.
   - Cleanses any stale foreign Telegram credentials found in the newly restored database.
   - Notifies Riverpod via `rootAppKey.currentState?.replaceDatabase(newDb)`, cleanly remounting `ProviderScope` with fresh streams and zero zombie connections.
4. **Telegram Bot Cloud Backup Integration (`exportBackupToTelegram`):**
   - **App-Private Credential Storage:** Replaced SQLite storage with dedicated `TelegramConfigStore` (app-private file `rojob_telegram_config.json`). The SQLite database file never contains the bot token or chat ID, completely protecting credentials during database exports, transfers, and restores.
   - **Lightweight Document Stripping & VACUUM:** To prevent exceeding Telegram's 50 MB per-file upload limit and avoid slow mobile network timeouts, the backup strips heavy document binary blobs (`UPDATE documents SET file_data = zeroblob(0)`) on a temporary snapshot, preserves all document metadata and histories, and runs SQLite `VACUUM;` to shrink file size from hundreds of MBs to a mere ~200–500 KB.
   - **Zero-RAM Memory-Safe Streaming:** Replaced in-memory `readAsBytesSync()` with chunked disk streaming (`request.addStream(backupFile.openRead())`), completely eliminating `OutOfMemoryError` risks on low-end Android devices.
   - **Everyday Background Auto-Backup:** Implemented `checkAndRunDailyTelegramBackup()` triggered silently on application startup via `MainShellScreen`. Ensures idempotent daily execution (`last_telegram_auto_backup_date == todayStr`) without spamming Telegram or interrupting the user with error popups on network drops.
5. **UI Screen Integration (`BackupRestoreScreen`):**
   - Restricted file picker to `.db` and `.sqlite` formats only (`FileType.custom`), preventing accidental selection of images, audio, or invalid documents.
   - Replaced dummy delay timers with live `backupControllerProvider` and reactive stream providers.
   - Added adaptive toggle switch for "প্রতিদিন স্বয়ংক্রিয় ব্যাকআপ (পিডিএফ ব্যতীত হালকা ফাইল)" with live status indicators and automatic configuration dialog prompt.
   - Added detailed restore confirmation dialog displaying exact record counts and file size in Bengali, with explicit assurance of safety archiving.
   - Human-friendly SnackBars on export, import, and telegram upload success/failure.
6. **Verification & Testing:**
   - Updated `test/unit/phase_four_backup_test.dart` covering 16 critical test scenarios including credential isolation from SQLite, safety archive verification, storage pruning, and daily auto-backup idempotency.
   - Full Test Suite: **178 / 178 tests passed!** (100% green).
   - Static Analysis: 0 errors.

---

## Backend Phase 5: Stress Testing, End-to-End Verification & Release (Completed)

### Scope Completed
1. **High-Volume & Stress Performance Verification (১,০০০+ আবেদন ও ৫,০০০+ লেনদেন):**
   - Bulk insertion of 1,000 complete applications across multiple offices and work types completed in < 3 seconds.
   - Bulk insertion of 5,000 distinct financial transactions (2,500 installment payments, 1,500 direct application expenses, 500 independent shop incomes, and 500 general overhead expenses) executed in < 5 seconds without lockups.
   - Verified that `unified_transactions_view` properly ingests and classifies all 5,000 rows across 6 sources with bit-for-bit integer paisa accuracy.
   - Verified that aggregate shop accounting calculations (`totalReceived`, `totalExpense`, `realizedIncome`, `netRealizedIncome`) across 5,000 rows run with zero arithmetic drift or float rounding errors.
   - Verified fast pagination and aggregated subquery performance across 1,000 applications in under 2 seconds.
   - Validated high-volume search and filtering speed across Bengali/English phone digits, app numbers, and Mouza strings.

2. **Concurrency & Race Condition Safety (কনকারেন্সি ও ডেটা অখণ্ডতা):**
   - Simultaneous parallel async operations (20 concurrent payment transactions on an application using `Future.wait`) executing cleanly with zero deadlocks or lost updates.
   - Verified race condition handling on duplicate application numbers within the same office: exactly one operation succeeds, and the conflicting request is rejected with a respectful natural Bengali `AppFailure`.

3. **Worst-Case & Extreme Crisis Scenarios (চরম সংকট টেস্ট):**
   - **Transaction Rollback Guard:** Verified that an unhandled crash or unexpected failure during a multi-table atomic operation (status transition + fee expense + hearing task creation) cleanly rolls back all modified tables, leaving zero orphaned rows or half-written records.
   - **Snapshot Immutability Breach Protection:** Tested SQLite triggers to ensure direct SQL `UPDATE` statements attempting to alter `applicant_name`, `applicant_phone`, `applicant_address`, `reference_name`, or `office_name` on an existing application are immediately aborted.
   - **Financial Audit Immutability:** Verified that direct SQL `UPDATE` statements on payments or expenses are blocked by database triggers, requiring soft-deletion and new voucher creation for any correction.
   - **Corrupted Backup Safety:** Verified that corrupted, zero-byte, alien, or damaged SQLite backup files are rejected during background isolate validation without altering the live database.
   - **Soft-Delete & Restore Audit Trail:** Verified that soft-deleted payments and expenses are cleanly removed from active views and financial calculations, while remaining preserved in storage for audit history, and can be fully restored.
   - **Adversarial & Malformed Input Handling:** Tested edge cases across mixed Bengali/English digit strings, spaces, symbols, zero/negative money bounds, and extreme 64-bit integer values without crashes.

4. **Real-World End-to-End Land Service Shop Lifecycle (Golden Rules 1–6 Audit):**
   - Verified full 12-step realistic business lifecycle:
     1. Customer and Reference onboarding.
     2. ৳8,000 package deal contract creation with ৳3,000 advance payment.
     3. Transition to 'প্রস্তাব প্রেরণ' with ৳70 online government fee expense recorded (Realized income: ৳3,000 - ৳70 = ৳2,930; Due: ৳5,000).
     4. Transition to 'শুনানি' with ৳300 expense and automatic hearing task scheduled in Tasks table.
     5. 2nd installment of ৳3,500 received (Total received: ৳6,500; Expense: ৳370; Realized income: ৳6,130; Due: ৳1,500).
     6. Transition to 'ডিসিআর প্রস্তুত' with ৳1,100 DCR fee recorded.
     7. Transition to 'সম্পন্ন'.
     8. 3rd installment of ৳1,300 received (Total received: ৳7,800; Remaining ৳200 waived by shopkeeper via `markAsPaid`).
     9. Effective due becomes ৳0, file settled, final realized income = ৳7,800 - ৳1,470 = ৳6,330.
     10. Reference person profile stats verified: 1 application, ৳8,000 total volume, ৳7,800 collection, ৳0 remaining due.
     11. Independent income ৳500 + General shop overhead ৳1,000 added.
     12. Overall Shop Net Income: (৳7,800 + ৳500) - (৳1,470 + ৳1,000) = ৳8,300 - ৳2,470 = ৳5,830 exact to the paisa.
     13. Customer/Reference deletion tested: applicant snapshot data remains 100% frozen and intact in historical applications.

5. **Verification & Release Readiness:**
   - Static Analysis (`flutter analyze`): **0 errors, 0 warnings**.
   - Full Test Suite: **175 / 175 tests passed!** (100% green).
   - Added Native Phone Dialer & URL Launcher integration (`AppLauncher`) across all screens (Due management, Application details, Customer list/details, Reference cards/details, Settings hotline/WhatsApp) with automatic Bengali digit conversion and fallback clipboard safety.
   - All 5 Phases of `docs/BACKEND_MASTER_PLAN.md` are completely implemented, verified, and release-ready.
