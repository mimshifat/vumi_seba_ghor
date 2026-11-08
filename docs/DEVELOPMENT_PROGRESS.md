# Development Progress — ভূমি কাজের হিসাব

## Summary of Phases

| Phase | Description | Status |
|---|---|---|
| **Phase 0** | Project Foundation & Design System | ✅ Completed |
| **Phase 1** | Complete Navigable UI Prototype | ✅ Completed (Awaiting User Review) |
| **Phase 2** | Database & Drift SQLite Architecture | ⏳ Pending Phase 1 Approval |
| **Phase 3** | Person & Office Management | ⏳ Scheduled |
| **Phase 4** | Applications & Status Pipeline | ⏳ Scheduled |
| **Phase 5** | Financial Management & Ledger | ⏳ Scheduled |
| **Phase 6** | Documents & Task Management | ⏳ Scheduled |
| **Phase 7** | Dashboard & Aggregated Reports | ⏳ Scheduled |
| **Phase 8** | Telegram Snapshot Backup & Restore | ⏳ Scheduled |
| **Phase 9** | Testing & QA Suite | ⏳ Scheduled |
| **Phase 10** | Release Build & Delivery | ⏳ Scheduled |

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
23. **টেলিগ্রাম ব্যাকআপ ও রিস্টোর (BackupRestoreScreen):** বট টোকেন ও চ্যাট আইডি কনফিগারেশন, SQLite স্ন্যাপশট ইন্টিগ্রিটি চেক (PRAGMA OK), এক ক্লিকে ব্যাকআপ ও রিস্টোর, দৈনিক অটো-ব্যাকআপ টগল এবং সিকিউরিটি নোটিশ।
24. **সেটিংস ও কাস্টমাইজেশন (SettingsScreen):** কাস্টম কাজের ধরন ব্যবস্থাপনা, খরচের খাত ও আয়ের খাত ব্যবস্থাপনা, অ্যাপের বিবরণ।
25. **রেফারেন্স তালিকা (ReferenceListScreen):** মেনু ট্যাবের অধীন রেফারেন্স খাতা — মোট রেফারেন্স ও আবেদন কাউন্টার, তাৎক্ষণিক সার্চ, সম্পন্ন/চলমান/অপেক্ষমাণ স্ট্যাটাস বিভাজন, কল শর্টকাট ও নতুন রেফারেন্স এন্ট্রি।
26. **রেফারেন্স বিস্তারিত (ReferenceDetailScreen):** রেফারেন্স ব্যক্তির পূর্ণাঙ্গ প্রোফাইল, ছবি/অবতার, ফোন, ঠিকানা ও নোট, আর্থিক হিসাব (মোট সেবা মূল্য, আদায় ও বকেয়া), এবং উক্ত রেফারেন্সের আনীত সকল আবেদনের সম্পূর্ণ ইতিহাস।
27. **মেনু শেল (MoreMenuScreen):** ৫ম বটম-ন্যাভ ট্যাব — গ্রাহক খাতা এবং রেফারেন্স খাতা পরিষ্কারভাবে আলাদা হিসেবে প্রদর্শিত।
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
  - অপ্রয়োজনীয়/অতিরিক্ত পুনরাবৃত্তি রোধে নিচের আনুমানিক লাভ ও নগদ লাভ টাইলস দুটি সরিয়ে ফেলা হয়েছে (যেহেতু উপরেই হিরো লাভ ব্যানারে স্পষ্ট ও বিস্তারিতভাবে অবশিষ্ট নিট লাভ প্রদর্শিত)। এখন সুষম ২x২ গ্রিডে প্রধান ৪টি মেট্রিক দৃশ্যমান:
    - সারি ১: চুক্তিকৃত টাকা | মোট আদায়
    - সারি ২: কাজের মোট খরচ | বকেয়া (বা 'পরিশোধিত ✓')
  - হিরো লাভ ব্যানারেও `FittedBox` ও `maxLines` কন্ট্রোল প্রয়োগ করা হয়েছে।
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
  - তালিকার কার্ডগুলো থেকে অতিরিক্ত খরচ/লাভ স্ট্রিপ (`কাজের মোট খরচ` ও `অবশিষ্ট লাভ`) সম্পূর্ণ সরিয়ে নেওয়া হয়েছে। কার্ডে এখন কেবলমাত্র আবশ্যকীয় আর্থিক তথ্য (চুক্তি, জমা ও বকেয়া ব্যাজ) পরিচ্ছন্নভাবে প্রদর্শিত হয়।

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

### 10. Realized Income & Zero-Profit Accounting Architecture (Completed)
- **"লাভ" (Profit) পরিহার ও "প্রকৃত ইনকাম" (Actual Realized Income) প্রতিষ্ঠা:** 
  - ভূমি সেবা ও এজেন্সির বাস্তব হিসাবরীতি অনুযায়ী সম্পূর্ণ অ্যাপ থেকে বিভ্রান্তিকর "লাভ / Profit" পরিহার করে "ইনকাম / Income" মান্য করা হয়েছে।
  - কাজের চুক্তি যতই হোক না কেন (যেমন: ৮,০০০ টাকা), গ্রাহক প্রকৃতপক্ষে যত টাকা জমা দেয় (যেমন: ৭,৫০০ টাকা) তা থেকে কাজের প্রত্যক্ষ সরকারি ও দাপ্তরিক খরচ (যেমন: ৩,০০০ টাকা) বাদ দিলে যা থাকে, কেবল সেটাই উক্ত ফাইলের আসল ইনকাম (৪,৫০০ টাকা)।
  - অপরিশোধিত টাকা (৫০০ টাকা) কখনোই ইনকাম হিসেবে গণ্য হয় না; তা বকেয়া থাকে অথবা মওকুফ করলে ইনকাম ৪,৫০০ টাকাই থাকে।
- **আর্থিক বিবরণী স্ক্রিন রিডিজাইন (`FinancialOverviewScreen`):**
  - **বহুমাত্রিক সময়কাল ফিল্টার:** `চলতি মাস`, `বিগত মাস`, `চলতি বছর`, `সব সময়`, `মাস/বছর বাছাই ▾` (১২ মাসের পপআপ বটম শীট) এবং `কাস্টম তারিখ 📅` রেঞ্জ পিকার।
  - **পিরিয়ড নেভিগেটর স্ট্রিপ:** এক ক্লিকে পূর্ববর্তী বা পরবর্তী মাসে যাওয়ার জন্য `◀` ও `▶` বাটন।
  - **হিরো ইনকাম কার্ড:** ফিল্টার অনুযায়ী ডায়নামিকালি নিট ইনকাম, মোট আদায়, মোট খরচ, মোট বকেয়া এবং মোট লেনদেন সংখ্যা রিয়েলটাইমে প্রদর্শিত।
  - **অপ্রয়োজনীয় জটিলতা নিরসন:** অপ্রয়োজনীয় ও স্ক্রিন নষ্টকারী "আর্থিক খাতভিত্তিক বিবরণী" এবং "সাম্প্রতিক লেনদেন" সেকশন বাদ দিয়ে স্ক্রিনকে অত্যন্ত দ্রুত, ফোকাসড ও ক্ল্যারিশাল করা হয়েছে।
  - **ডায়নামিক ক্যাশফ্লো চার্ট:** ফিল্টারকৃত সময়ের বাস্তব লেনদেন থেকে সপ্তাহভিত্তিক ও মাসভিত্তিক ইনকাম বনাম খরচ তুলনা গ্রাফ।
- **গ্লোবাল নেমিং কনভেনশন ইউনিফিকেশন:** `app_strings.dart`, `demo_data.dart`, `reports_screen.dart`, `report_detail_screen.dart`, এবং `application_detail_screen.dart`-এ সকল `profit` ভ্যারিয়েবল ও লেবেলকে স্ট্যান্ডার্ড `income` কনভেনশনে পরিবর্তন করা হয়েছে।





