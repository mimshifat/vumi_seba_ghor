# UI/UX Guidelines — ভূমি কাজের হিসাব

## 1. Visual Identity & Design Direction

"ভূমি কাজের হিসাব" is crafted with a **Modern Fintech × SaaS Business Tool** design philosophy.
It blends high utility and clarity with contemporary aesthetic refinement (inspired by modern digital products like Linear, Stripe, and modern mobile banking apps).

### 1.1 Color System (Tailwind-inspired)

```
Primary: Indigo
  - 500: #4F46E5 (Primary Brand / Interactive CTA)
  - 600: #4338CA (Darker Accent / Headers)
  - 700: #3730A3 (Deep Pressed State)
  - 100: #E0E7FF (Light Container / Highlights)
  - 50:  #EEF2FF (Subtle Active Background)

Success / Income: Emerald
  - 500: #10B981 (Received Payments / Completed / Positive Income)
  - 50:  #ECFDF5 (Success Background Container)

Warning / Due / Attention: Amber
  - 500: #F59E0B (Pending / Dues / Warnings)
  - 50:  #FFFBEB (Pending Background Container)

Danger / Urgent / Expense: Rose
  - 500: #F43F5E (Expenses / Urgent Tasks / Objections / Cancelled)
  - 50:  #FFF1F2 (Expense Background Container)

Neutral Surfaces: Slate
  - Background: #F8FAFC (Slate-50, clean, cool modern canvas)
  - Surface:    #FFFFFF (Pure White Cards with soft border)
  - Card Tint:  #F1F5F9 (Slate-100, muted sections)
  - Border:     #E2E8F0 (Slate-200, crisp hairline dividers)
  - Text Main:  #0F172A (Slate-900, sharp legible Bengali typography)
  - Text Muted: #475569 (Slate-600)
  - Text Hint:  #94A3B8 (Slate-400)
```

### 1.2 Status Color Mapping

Every government land workflow status has a dedicated, easily recognizable color badge grouped by workflow role:

| Status Bengali | English Meaning | Category | Color Family | Hex |
|---|---|---|---|---|
| আবেদন | Application Created | Happy Flow | Sky Blue | `#0284C7` |
| প্রস্তাব প্রেরণ | Proposal Sent / Report | Happy Flow | Indigo | `#6366F1` |
| শুনানি | Hearing Scheduled | Happy Flow | Violet | `#8B5CF6` |
| মঞ্জুর | Approved (পাস) | Happy Flow | Emerald | `#10B981` |
| ডিসিআর প্রস্তুত | DCR Ready / Paid | Happy Flow | Cyan | `#06B6D4` |
| সম্পন্ন | Work Completed | Happy Flow | Green | `#16A34A` |
| অপেক্ষমাণ | Waiting / On Hold | Exception | Amber | `#F59E0B` |
| আপত্তি | Objection Raised | Exception | Orange | `#EA580C` |
| সংশোধন প্রয়োজন | Correction Needed | Exception | Rose | `#F43F5E` |
| নামঞ্জুর | Rejected (বাতিল) | Exception | Slate | `#64748B` |

---

## 2. Typography

- **Font Family:** `Noto Sans Bengali` (bundled offline)
- Numbers formatted in natural Bengali digits (০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯) for currency and dates.

### Type Scale (Optimized for Crisp Bengali Legibility)
- **Display / Big Money:** 30sp / Bold (700)
- **Heading Large:** 24sp / Bold (700)
- **Heading Medium:** 20sp / SemiBold (600)
- **Heading Small:** 17.5sp / SemiBold (600)
- **Title Medium:** 16sp / Medium (500)
- **Body Large:** 16sp / Regular (400)
- **Body Medium:** 14.5sp / Regular (400)
- **Body Small:** 13sp / Regular (400)
- **Badge / Label:** 13sp / SemiBold (600)
- **Bottom Navigation Label:** 12.5sp (Active) / 11.5sp (Inactive)

---

## 3. Spacing & Dimensions

- **Base Grid:** 4px
  - 4px (xs), 8px (sm), 12px (md), 16px (base), 20px (lg), 24px (xl), 32px (2xl)
- **Border Radii:**
  - Cards: 16px (Modern smooth corners)
  - Buttons: 12px
  - Inputs: 12px
  - Badges / Chips: 20px (Pill)
  - Bottom Sheets: 24px (Top radius)
- **Elevation & Shadows:**
  - Low elevation (0 to 1dp) with subtle rgba(15, 23, 42, 0.04) shadow + 1px Slate-200 border for crisp modern look.

---

## 4. Navigation Architecture (5-Tab Model)

Bottom Navigation with 5 clean, non-overlapping destinations:
1. **ড্যাশবোর্ড (Dashboard):** Privacy-first operational landing screen (zero money figures visible on open), instant search bar, quick action shortcuts, hearing schedule & reminders, pipeline counters, recent applications.
2. **আবেদন (Applications):** Search bar, active filter chips, multi-select filter bottom sheet, tabbed status filters, rich application cards with work type, status badges, due indicators, and distinct **মৌজা** badge.
3. **হিসাব (Finance & Ledger Dashboard):** কেন্দ্রীয় আর্থিক ব্যবস্থাপনা ড্যাশবোর্ড:
   - **মাল্টি-পিরিয়ড ফিল্টারিং ও নেভিগেটর:** শীর্ষে কুইক ফিল্টার চিপস (`[চলতি মাস]`, `[বিগত মাস]`, `[চলতি বছর]`, `[সব সময়]`, `[মাস/বছর বাছাই ▾]`, `[কাস্টম তারিখ 📅]`) এবং দ্রুত মাস পরিবর্তন নেভিগেটর (`◀ [📅 পিরিয়ড] ▶`)।
   - **হিরো প্রকৃত নিট ইনকাম কার্ড:** আধুনিক গাঢ় নীল গ্রেডিয়েন্টে নির্বাচিত সময়কালের **"প্রকৃত নিট ইনকাম"** (মোট আদায় - খরচ), ইনকাম স্ট্যাটাস ব্যাজ (`ইতিবাচক ইনকাম` / `ঘাটতি`), মার্জিন %, এবং নিচে ৪-কলাম সারসংক্ষেপে মোট আদায়, মোট খরচ, মোট বকেয়া ও মোট লেনদেন সংখ্যা।
   - **দৈনিক পরিসংখ্যান:** আজকের আদায় ও আজকের খরচ কার্ড।
   - **আদায় বনাম ব্যয়ের তুলনা চার্ট (`fl_chart`):** নির্বাচিত সময়ের ডায়নামিক লেনদেন ডেটা ভিত্তিক ক্যাশফ্লো ভিজ্যুয়াল বার চার্ট।
   - **বকেয়া তালিকা সেকশন:** বকেয়া থাকা গ্রাহক ও আবেদন তালিকা, সর্বোচ্চ বকেয়া হাইলাইট, এবং এক ক্লিকে সংশ্লিষ্ট **আবেদন বিস্তারিত** স্ক্রিনে যাওয়ার শর্টকাট।
   - **প্রাইমারি অ্যাকশন বাটন:** স্ক্রিনের নিচে ডানপাশে দুটি সুনির্দিষ্ট ভাসমান বাটন: `[+ আয়]` (স্বাধীন/দোকানের অন্যান্য আয়) এবং `[- খরচ]` (কাজের খরচ বনাম সাধারণ খরচ)।
4. **বিশ্লেষণ (Business Intelligence & Analytics Dashboard):** সরাসরি একটি পূর্ণাঙ্গ ইন্টারেক্টিভ ভিজ্যুয়াল অ্যানালিটিক্স হাব (কোনো সাধারণ লিঙ্ক তালিকা বা জটিল PDF/শেয়ারের ওপর নির্ভরশীলতা ছাড়াই):
   - **ডায়নামিক পিরিয়ড ফিল্টার:** `[চলতি মাস]`, `[গত ৩ মাস]`, `[চলতি বছর]`, `[সর্বকালের]` নির্বাচনযোগ্য ফিল্টার চিপস।
   - **এক্সিকিউটিভ কেপিআই সামারি:** মোট আবেদন (+প্রবৃদ্ধি), সম্পন্নতার হার %, প্রকৃত ইনকাম, এবং ফাইলপ্রতি গড় ইনকাম।
   - **মাসভিত্তিক আদায় ও ইনকাম প্রবৃদ্ধি কার্ভ (`LineChart`):** ধারাবাহিক ৫ মাসের আর্থিক ট্রেন্ডলাইন, আদায় ও ইনকাম রেখা, মার্জিন শেডিং ও টাচ ডিটেইলস (রেসপনসিভ টেক্সট কলাম সহ ফিক্সড হেডার)।
   - **কাজের ধরনভিত্তিক ডোনাট চার্ট (`PieChart`):** ইন্টারঅ্যাক্টিভ টাচ হাইলাইট, সেন্টারে মোট ফাইলের সংখ্যা এবং বিস্তারিত টাকার অংক।
   - **অগ্রগতি ও রূপান্তর পাইপলাইন ফানেল:** নতুন আবেদন থেকে শুরু করে প্রস্তাব, শুনানি, অনুমোদন ও ডেলিভারি পর্যন্ত প্রতিটি স্তরের রূপান্তর গতি ও ড্রপ-অফ প্রগ্রেস বার।
   - **ভূমি অফিসভিত্তিক কাজের চাপ ও রাজস্ব:** অফিসভিত্তিক কাজের শতকরা অনুপাত ও রাজস্ব অর্জন সূচক।
   - **স্মার্ট ব্যবসায়িক অন্তর্দৃষ্টি (Insights):** সর্বোচ্চ ইনকাম সৃষ্টিকারী সেবা, দ্রুততম নিষ্পত্তি ও প্রধান অপারেশন কেন্দ্রের হাইলাইট কার্ড।
5. **মেনু (Management & System):**
   - *দোকান ও প্রতিষ্ঠান প্রোফাইল:* শীর্ষে সরাসরি প্রতিষ্ঠানের নাম, স্বত্বাধিকারী ও মোবাইল নম্বর প্রদর্শন এবং ১-ক্লিকে সম্পাদনা।
   - *দৈনিক ব্যবস্থাপনা ও খাতা:* করণীয় কাজ ও রিমাইন্ডার, গ্রাহক খাতা (আবেদনকারী), রেফারেন্স খাতা (রেফারেন্স ব্যক্তি ও আনীত আবেদন), ভূমি অফিস তালিকা
   - *কনফিগারেশন ও ডেটা ব্যাকআপ:* কাজের ধরন ও খরচের খাত (`CategoryManagementScreen`), ডেটা ব্যাকআপ ও রিস্টোর (`BackupRestoreScreen` - ফোনে অফলাইন ব্যাকআপ এক্সপোর্ট ও ইমপোর্ট এবং ঐচ্ছিক টেলিগ্রাম ক্লাউড ব্যাকআপ)
   - *সহায়তা ও তথ্য:* কারিগরি সহায়তা কেন্দ্র ও হেল্পলাইন, সংস্করণ ১.০.০
   - *জিরো রিডানডেন্সি:* মধ্যবর্তী অতিরিক্ত ও ডুপ্লিকেট সেটিংস সাব-স্ক্রিন মুক্ত সরাসরি নেভিগেশন।

---

## 5. Screen Inventory & Flow (28 Interconnected Screens)

- All 28 screens are interconnected with smooth, type-safe routing.
- **Financial Workflow Components:**
  - `IncomeFormScreen`: Dedicated independent income entry (strictly isolated from application service payments with no application selector).
  - `ExpenseFormScreen`: Dynamic toggle between specific work expenses (with application selector) and shop overheads (application-free).
  - `StatusChangeDialog`: Includes an optional financial entry card (`টাকা গ্রহণ` vs `টাকা খরচ`). Skipping amount updates only status history without creating transactions.
  - `ApplicationDetailScreen > টাকার হিসাব`: Standalone "খরচ যোগ করুন" button removed; displays automatically aggregated expense records and installment deposits.
  - `TransactionHistoryScreen`: Multi-criteria filter bar (Type, Date, Category, Application) with active filter removal tags and a 1-click reset button.
- **Dedicated Reference Management components:**
  - `ReferenceCard`: Profile avatar, phone, address, total applications count, total service value, and operational status chips.
  - `ReferenceStatsRow`: Completed, Ongoing, and Pending breakdown chips.
  - `ReferenceSelectorSheet`: Live search, clear selection, and inline reference creation.
- Responsive to screen height variations with proper scrolling and keyboard avoidance.
- Empty states with cheerful icons and clear call-to-actions.

---

## 6. Form Validation, Error Handling & Wizard Architecture

### 6.1 Multi-Step Wizard Flow (ApplicationCreateScreen)
To eliminate long scroll fatigue and reduce form abandonment, complex data entry is partitioned into a focused **3-Step Wizard**:
1. **ধাপ ১: গ্রাহকের তথ্য (Client Identity):**
   - In-step quick selector banner for existing customers (`DemoPerson`) with auto-fill (Name, Phone, and Address).
   - Fields: আবেদনকারীর নাম (`*`), মোবাইল নম্বর (`*`), এবং গ্রাহকের ঠিকানা (ঐচ্ছিক কিন্তু স্পষ্ট টেক্সটফিল্ড)।
2. **ধাপ ২: কাজ ও অফিস (Work & Office Logistics):**
   - Fields: কাজের ধরন (`*` ChoiceChips + নতুন ধরন যোগ), অফিসের নাম (`*` Dropdown + নতুন অফিস যোগ), আবেদনের তারিখ (`*` Date Picker), মৌজার নাম, এবং ১ সারিতে আবেদন ও কেস নম্বর।
3. **ধাপ ৩: চুক্তি ও সম্পন্ন (Financials, Reference & Completion):**
   - **শীর্ষে রিয়েল-টাইম সারসংক্ষেপ কার্ড (Summary Card):** গ্রাহক ও কাজের তথ্য এক নজরে রিভিউ এবং এক ক্লিকে ধাপ ১ বা ২-এ ফিরে যাওয়ার সম্পাদনা শর্টকাট।
   - Fields: রেফারেন্স ব্যক্তি (সিলেক্টর শীট ও ইনলাইন তৈরি), চুক্তিকৃত মোট সার্ভিস ফি (`*` কুইক চিপস সহ), প্রাথমিক অগ্রিম জমা, ফাইল/ডকুমেন্ট সংযুক্তি, এবং বিশেষ নোট।

### 6.2 Visual Indicator Standards (`AppFieldLabel`)
- **Required Fields:** Explicit red asterisk (` *`) rendered via `AppFieldLabel` with `isRequired: true` (Hex: `#F43F5E`, FontWeight: bold).
- **Optional Fields:** Clean label without any asterisk. Redundant text like "(ঐচ্ছিক)" is strictly prohibited in label titles to maintain visual clarity.

### 6.3 Validation & Error Message Standards
- **Inline Validation:** All input fields must implement clear, unambiguous Bengali error messages returned via `validator`:
  - Name: `'আবেদনকারীর নাম আবশ্যক'`
  - Phone: `'মোবাইল নম্বর আবশ্যক'` (বা `'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন'`)
  - Office: `'ভূমি অফিস নির্বাচন আবশ্যক'`
  - Work Type: `'কাজের ধরন নির্বাচন আবশ্যক'`
  - Service Fee: `'চুক্তির সার্ভিস ফি উল্লেখ করুন'`
- **Per-Step Gating:** The wizard enforces strict step validation (`_formKey.currentState!.validate()`). Users cannot navigate to subsequent steps or submit the application with invalid or empty required fields.
- **Error Styling:**
  - Input border transitions to Rose-500 (`#F43F5E`) on validation failure.
  - Helper error text displayed directly below the field in 12sp Bengali typography.
- **Interactive Feedback:**
  - Success confirmations use Emerald SnackBar (`#10B981`) with clear Bengali message.
  - Warnings/destructive prompts use Rose SnackBar or `ConfirmDialog`.

---

## 7. Application Card & Detail Screen Design Standards

### 7.1 Application Card Standards (`ApplicationCard`)
- **Status Accent Strip:** A prominent 4px vertical bar on the left edge colored dynamically using `AppColors.getStatusColor(status)`. This establishes instantaneous file status recognition across long lists.
- **Card Depth & Affordance:** Double soft box shadows (`Offset(0, 3), blur 10, rgba(15,23,42,0.04)` and `Offset(0, 1), blur 3, rgba(15,23,42,0.02)`) wrapped with a smooth clipped `InkWell` to ensure consistent touch feedback.
- **Micro-Categorization:** 
  - Applicant name at Bold 16sp in Slate-900.
  - Work type (`নামজারি`) in an Indigo container (`#EEF2FF`) with crisp border.
  - Mouza (`মৌজা: ...`) in a Slate-50 micro-badge with location pin icon.
  - Official IDs (Application & Case number) using interactive `CopyChip` with inline checkmark feedback.
- **Metadata Container:** Office name and Bengali application date enclosed within a light Slate-50 inset with bank and calendar icons.
- **3-Column Inset Financial Summary:** Contained inside a `#F8FAFC` rounded inset separated by clean 1px vertical dividers:
  1. *চুক্তি (Agreed):* Slate muted label with bold Slate-800 amount.
  2. *জমা (Received):* Emerald-600 label with bold Emerald-700 amount.
  3. *বকেয়া/পরিশোধিত Status Pill:* Amber clock badge with remaining due or Emerald checkmark pill (`পরিশোধিত ✓`).

### 7.2 Application Detail Screen Standards (`ApplicationDetailScreen`)
- **Header & Navigation:**
  - Two-line AppBar with applicant name as primary heading and `WorkType • OfficeName` as subtitle.
  - Minimal action buttons (Edit and Delete only) with compact visual density to maximize title area. Due settlement is cleanly handled inside Tab 3.
  - 4 clean single-line tabs fitting on a single screen without scrolling:
    - Tab 1: `১. তথ্য`
    - Tab 2: `২. অগ্রগতি`
    - Tab 3: `৩. টাকার হিসাব`
    - Tab 4: `৪. ডকুমেন্ট`
- **Quick Action Bar:** Fixed top strip featuring a large `StatusBadge`, an outlined `[অবস্থা বদলান]` button, and a vibrant Emerald `[জমা নিন]` button (automatically hidden when due balance is zero).
- **Connected Vertical Timeline & Directional Transitions:**
  - Semantic Status Coloring: Normal progression stages (আবেদন, প্রস্তাব, শুনানি, ডিসিআর) share a unified Primary Indigo identity instead of an arbitrary rainbow of colors. Distinct semantic colors reserved strictly for outcomes: Success/Approved (`Emerald`), Objection/Hold (`Amber/Orange`), and Cancelled/Rejected (`Rose`).
  - Directional Transition Badge: Clearly illustrates origin to destination transition: `[পূর্ববর্তী অবস্থা] ➔ [নতুন অবস্থা]`, with an active `[বর্তমান]` badge on the topmost active stage.
  - Reverse-chronological sorting so the latest active stage is always anchored at the top of the timeline.
  - Active/latest status has a glowing status dot (`blur: 6px`) with appropriate semantic icon (check, warning, or clock).
  - Past steps use outlined circles connected by a continuous 2px vertical guide line (`AppColors.slate200`).
- **Finance Tab Structure:**
  - **Hero Realized Income Banner (এই ফাইলে আপনার প্রকৃত ইনকাম):** Vibrant Emerald gradient (`#ECFDF5` to `#D1FAE5`) with wallet icon, bold realized income number (আদায় - খরচ), and total collection vs. expense equation.
  - **Balanced 2x2 Grid:** 4 essential metrics (`চুক্তিকৃত টাকা`, `মোট আদায়`, `কাজের মোট খরচ`, `বকেয়া`) enclosed in responsive tiles protected with `FittedBox.scaleDown`.
  - **Transaction Cards:** Distinct cards replacing standard list tiles; green downward arrows for deposits with payment method tags (নগদ, বিকাশ, ইত্যাদি); red upward arrows for expenses with category tags.
- **Modern Modal & Dialog Architecture:**
  - Status change and Mark-as-Paid dialogs use 20px rounded corners (`radiusXl`), soft info banners, and clean responsive scroll views.

---

## 8. Dialog & Modal Action Alignment Standards (`AppDialogActionRow`)

- **Strict One-Alignment Rule (এক অনুভূমিক সারিতে বাটন):** 
  - ফ্লাটারের ডিফল্ট `AlertDialog` অ্যাকশন বারের আন-অ্যালাইন্ড বা ভার্টিক্যাল স্ট্যাকিং (যেখানে "বাতিল" বাটন উপরে এবং "যোগ করুন" বাটন নিচে বিচ্ছিন্নভাবে নেমে যায়) কঠোরভাবে নিষিদ্ধ।
  - প্রতিটি ডায়লগে `AppDialogActionRow` ব্যবহার বাধ্যতামূলক।
- **বাটন অবস্থান ও স্টাইলিং:**
  - **বাম পাশে:** `[ বাতিল ]` — `ButtonVariant.outline` (হালকা বর্ডার, ধূসর টেক্সট, কোনো ব্যাকগ্রাউন্ড ফিল নেই)।
  - **ডান পাশে:** `[ যোগ করুন / সংরক্ষণ করুন / নিশ্চিত করুন ]` — `ButtonVariant.primary` (সলিড ব্র্যান্ড কালার) বা `ButtonVariant.danger` (মুছে ফেলার নিশ্চিতকরণে লাল কালার)।
- **প্রস্থ ও অনুপাত:**
  - উভয় বাটন `Expanded` উইজেট দ্বারা আবৃত থাকায় ৫০%-৫০% প্রস্থ পায়।
  - মাঝে `AppSpacing.md` (12px) স্পষ্ট গ্যাপ এবং নির্দিষ্ট `42px` উচ্চতা বজায় থাকে।
- **প্যাডিং:** ডায়লগ অ্যাকশন প্যাডিং সবসময় `EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg)` (20px, 0, 20px, 20px) যাতে কোনো ওভারফ্লো না হয়।



