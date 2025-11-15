# 🏗️ MCP - Master Context Protocol
## نظام إدارة الإنتاج AMRTS Manager

**تاريخ الإنشاء:** 2025-01-15
**الإصدار:** 2.0.0 (Feature-First Architecture)
**الحالة:** قيد التطوير

---

## 📋 فهرس المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [البنية المعمارية](#البنية-المعمارية)
3. [خطة التنفيذ](#خطة-التنفيذ)
4. [دليل المطور](#دليل-المطور)
5. [معايير الكود](#معايير-الكود)
6. [أمثلة عملية](#أمثلة-عملية)

---

## 🎯 نظرة عامة

### الهدف الرئيسي
نظام متكامل لإدارة الإنتاج في مصنع ألمنيوم يعتمد على منهجية **CMUP (Coût Moyen Unitaire Pondéré)**.

### التقنيات المستخدمة
- **Frontend:** Flutter + Dart
- **Backend:** PHP (Pure) + RESTful API
- **Database:** MySQL (VPS) + SQL Server (Local)
- **State Management:** Riverpod
- **Design Pattern:** Feature-First Architecture + Glassmorphism UI

### المراحل الإنتاجية
```
المواد الخام (SMP)
       ↓
  1️⃣ FONDERIE (الصهر)
       ↓
  القوالب (Billetes)
       ↓
  2️⃣ EXTRUSION (البثق)
       ↓
  القضبان الخام (Barres Brut)
       ↓
  3️⃣ PEINTURE (الطلاء)
       ↓
  المنتج النهائي (SPF)
```

---

## 🏛️ البنية المعمارية

### البنية المعمارية المستهدفة (Feature-First)

```
lib/
│
├── main.dart                      # نقطة البداية
│
├── shared/                        # موارد مشتركة عبر كل التطبيق
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart           # إعدادات التطبيق
│   │   │   └── env.dart                  # متغيرات البيئة
│   │   │
│   │   ├── constants/
│   │   │   ├── app_constants.dart        # ثوابت التطبيق
│   │   │   └── api_endpoints.dart        # نقاط النهاية
│   │   │
│   │   ├── language/
│   │   │   ├── language.dart             # الترجمات
│   │   │   └── language_provider.dart    # Provider اللغة
│   │   │
│   │   └── theme/
│   │       ├── app_theme.dart            # ثيم التطبيق
│   │       ├── colors.dart               # الألوان
│   │       └── text_styles.dart          # أنماط النص
│   │
│   ├── routes/
│   │   └── routes.dart                   # مسارات التنقل
│   │
│   ├── widgets/                           # Widgets قابلة لإعادة الاستخدام
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── loading_widget.dart
│   │   ├── error_widget.dart
│   │   ├── glassmorphism_container.dart
│   │   └── search_able_dropdown.dart
│   │
│   ├── utils/                             # وظائف مساعدة عامة
│   │   ├── validators.dart                # التحقق من البيانات
│   │   ├── formatters.dart                # تنسيق الأرقام/التواريخ
│   │   ├── helpers.dart                   # وظائف مساعدة
│   │   └── extensions.dart                # String/DateTime extensions
│   │
│   ├── services/                          # خدمات عامة مشتركة
│   │   ├── network/
│   │   │   ├── api_client.dart           # عميل API موحد
│   │   │   ├── dio_client.dart           # Dio configuration
│   │   │   └── network_info.dart         # فحص الاتصال
│   │   │
│   │   ├── storage/
│   │   │   ├── local_storage.dart        # SharedPreferences wrapper
│   │   │   └── cache_service.dart        # Caching service
│   │   │
│   │   └── calculation/
│   │       ├── calculation_service.dart   # حسابات عامة
│   │       └── cmup_calculator.dart       # حسابات CMUP
│   │
│   └── models/                            # Models مشتركة
│       ├── base_model.dart                # Base model class
│       ├── api_response.dart              # استجابة API موحدة
│       └── error_model.dart               # نموذج الأخطاء
│
└── screens/                               # ⭐ الشاشات (Features)
    │
    ├── home/                              # 🏠 الشاشة الرئيسية
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── home_model.dart
    │   │   └── api_service/
    │   │       └── home_api_service.dart
    │   │
    │   ├── providers/
    │   │   └── home_provider.dart
    │   │
    │   ├── widgets/
    │   │   ├── home_card.dart
    │   │   └── home_header.dart
    │   │
    │   └── home_screen.dart
    │
    ├── auth/                              # 🔐 المصادقة
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── user_model.dart
    │   │   └── api_service/
    │   │       └── auth_api_service.dart
    │   │
    │   ├── providers/
    │   │   └── auth_provider.dart
    │   │
    │   ├── widgets/
    │   │   └── login_form.dart
    │   │
    │   └── auth_screen.dart
    │
    ├── production/                        # 🏭 الإنتاج (Feature رئيسي)
    │   │
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── fonderie_model.dart
    │   │   │   ├── fonderie_item_model.dart
    │   │   │   ├── extrusion_model.dart
    │   │   │   ├── extrusion_production_model.dart
    │   │   │   ├── extrusion_arret_model.dart
    │   │   │   ├── extrusion_culot_model.dart
    │   │   │   ├── peinture_model.dart
    │   │   │   └── cmup_model.dart
    │   │   │
    │   │   └── api_service/
    │   │       ├── production_api_service.dart    # API عام للإنتاج
    │   │       ├── fonderie_api_service.dart
    │   │       ├── extrusion_api_service.dart
    │   │       ├── peinture_api_service.dart
    │   │       └── cmup_api_service.dart
    │   │
    │   ├── providers/
    │   │   ├── production_provider.dart           # Provider رئيسي
    │   │   ├── fonderie_provider.dart
    │   │   ├── extrusion_provider.dart
    │   │   ├── peinture_provider.dart
    │   │   └── cmup_provider.dart
    │   │
    │   ├── widgets/
    │   │   ├── fonderie/
    │   │   │   ├── fonderie_card.dart
    │   │   │   ├── fonderie_form.dart
    │   │   │   ├── fonderie_item_table.dart
    │   │   │   └── fonderie_summary.dart
    │   │   │
    │   │   ├── extrusion/
    │   │   │   ├── extrusion_card.dart
    │   │   │   ├── extrusion_form.dart
    │   │   │   ├── extrusion_production_table.dart
    │   │   │   ├── extrusion_arret_form.dart
    │   │   │   └── extrusion_culot_form.dart
    │   │   │
    │   │   ├── peinture/
    │   │   │   ├── peinture_card.dart
    │   │   │   └── peinture_form.dart
    │   │   │
    │   │   └── shared/
    │   │       ├── production_table_editor.dart
    │   │       ├── cmup_calculator_widget.dart
    │   │       └── production_summary_card.dart
    │   │
    │   └── screens/
    │       ├── production_screen.dart             # الشاشة الرئيسية (Tabs)
    │       ├── fonderie_screen.dart               # قائمة الصهر
    │       ├── fonderie_edit_screen.dart          # إضافة/تعديل صهر
    │       ├── extrusion_screen.dart              # قائمة البثق
    │       ├── extrusion_edit_screen.dart         # إضافة/تعديل بثق
    │       ├── peinture_screen.dart               # قائمة الطلاء
    │       └── peinture_edit_screen.dart          # إضافة/تعديل طلاء
    │
    ├── sales/                             # 💰 المبيعات
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── sale_model.dart
    │   │   │   └── sale_item_model.dart
    │   │   └── api_service/
    │   │       └── sales_api_service.dart
    │   │
    │   ├── providers/
    │   │   └── sales_provider.dart
    │   │
    │   ├── widgets/
    │   │   ├── sale_card.dart
    │   │   └── sale_form.dart
    │   │
    │   └── screens/
    │       ├── sales_screen.dart
    │       └── sales_edit_screen.dart
    │
    ├── purchases/                         # 🛒 المشتريات
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── purchase_model.dart
    │   │   │   └── purchase_item_model.dart
    │   │   └── api_service/
    │   │       └── purchases_api_service.dart
    │   │
    │   ├── providers/
    │   │   └── purchases_provider.dart
    │   │
    │   ├── widgets/
    │   │   ├── purchase_card.dart
    │   │   └── purchase_form.dart
    │   │
    │   └── screens/
    │       ├── purchases_screen.dart
    │       └── edit_invoice_screen.dart
    │
    ├── inventory/                         # 📦 المخزون
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── inventory_item_model.dart
    │   │   │   └── stock_movement_model.dart
    │   │   └── api_service/
    │   │       └── inventory_api_service.dart
    │   │
    │   ├── providers/
    │   │   └── inventory_provider.dart
    │   │
    │   ├── widgets/
    │   │   ├── inventory_card.dart
    │   │   └── stock_movement_list.dart
    │   │
    │   └── screens/
    │       └── inventory_screen.dart
    │
    ├── clients/                           # 👥 العملاء
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── client_model.dart
    │   │   └── api_service/
    │   │       └── clients_api_service.dart
    │   │
    │   ├── providers/
    │   │   └── clients_provider.dart
    │   │
    │   ├── widgets/
    │   │   └── client_card.dart
    │   │
    │   └── screens/
    │       └── clients_screen.dart
    │
    ├── financial/                         # 💵 المعاملات المالية
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── transaction_model.dart
    │   │   └── api_service/
    │   │       └── financial_api_service.dart
    │   │
    │   ├── providers/
    │   │   └── financial_provider.dart
    │   │
    │   ├── widgets/
    │   │   └── transaction_card.dart
    │   │
    │   └── screens/
    │       └── financial_transactions_screen.dart
    │
    ├── users/                             # 👤 إدارة المستخدمين
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── user_model.dart
    │   │   └── api_service/
    │   │       └── users_api_service.dart
    │   │
    │   ├── providers/
    │   │   └── users_provider.dart
    │   │
    │   ├── widgets/
    │   │   └── user_card.dart
    │   │
    │   └── screens/
    │       ├── users_management_screen.dart
    │       └── profile_screen.dart
    │
    └── settings/                          # ⚙️ الإعدادات
        ├── data/
        │   ├── models/
        │   │   └── settings_model.dart
        │   └── api_service/
        │       └── settings_api_service.dart
        │
        ├── providers/
        │   └── settings_provider.dart
        │
        ├── widgets/
        │   └── settings_item.dart
        │
        └── screens/
            └── settings_screen.dart
```

### مزايا هذه البنية

✅ **بسيطة وواضحة:** كل feature في مجلد واحد
✅ **سهلة التوسع:** إضافة feature جديد = مجلد جديد
✅ **منطقية للمطورين:** ترتيب حسب الشاشات
✅ **قابلة للصيانة:** كل شيء متعلق بـ feature في مكان واحد
✅ **تقليل الـ Coupling:** كل feature مستقل

---

## 📊 خطة التنفيذ

### المرحلة 1: إعداد البيئة (يوم 1)

#### الخطوة 1: تحديث pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.9

  # Network
  dio: ^5.4.0
  http: ^1.1.2

  # Local Storage
  shared_preferences: ^2.2.2

  # Utils
  intl: ^0.18.1
  logger: ^2.0.2+1

  # UI
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0
  flutter_screenutil: ^5.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

#### الخطوة 2: إنشاء البنية الأساسية

```bash
# إنشاء المجلدات الأساسية
mkdir lib/shared
mkdir lib/shared/core
mkdir lib/shared/routes
mkdir lib/shared/widgets
mkdir lib/shared/utils
mkdir lib/shared/services
mkdir lib/shared/models
mkdir lib/screens
```

### المرحلة 2: إعداد الـ Shared Layer (يوم 2-3)

#### اليوم 2: Core & Config

- [ ] إنشاء `shared/core/config/app_config.dart`
- [ ] إنشاء `shared/core/config/env.dart`
- [ ] إنشاء `shared/core/constants/app_constants.dart`
- [ ] إنشاء `shared/core/constants/api_endpoints.dart`
- [ ] إنشاء `shared/core/theme/` (colors, text_styles, app_theme)
- [ ] نقل `shared/core/language/` من المكان الحالي

#### اليوم 3: Services & Utils

- [ ] إنشاء `shared/services/network/api_client.dart`
- [ ] إنشاء `shared/services/network/dio_client.dart`
- [ ] إنشاء `shared/services/storage/local_storage.dart`
- [ ] إنشاء `shared/utils/validators.dart`
- [ ] إنشاء `shared/utils/formatters.dart`
- [ ] إنشاء `shared/widgets/` (custom_button, loading_widget, etc.)

### المرحلة 3: Feature Production (يوم 4-10)

#### اليوم 4-5: Fonderie (الصهر)

**البنية:**
```
screens/production/
├── data/
│   ├── models/
│   │   ├── fonderie_model.dart
│   │   └── fonderie_item_model.dart
│   └── api_service/
│       └── fonderie_api_service.dart
├── providers/
│   └── fonderie_provider.dart
├── widgets/
│   └── fonderie/
│       ├── fonderie_card.dart
│       ├── fonderie_form.dart
│       └── fonderie_item_table.dart
└── screens/
    ├── fonderie_screen.dart
    └── fonderie_edit_screen.dart
```

**المهام:**
- [ ] نقل الكود الحالي من `screens/production_screen/fonderie_*`
- [ ] إنشاء `FonderieModel` من `Map<String, dynamic>`
- [ ] إنشاء `FonderieApiService`
- [ ] إنشاء `FonderieProvider` (Riverpod)
- [ ] تقسيم `fonderie_edit_screen.dart` إلى widgets
- [ ] ربط UI بـ Provider

#### اليوم 6-8: Extrusion (البثق)

**نفس البنية السابقة:**
- [ ] نقل الكود من `screens/production_screen/extrusion_*`
- [ ] إنشاء Models (ExtrusionModel, ExtrusionProductionModel, etc.)
- [ ] إنشاء `ExtrusionApiService`
- [ ] إنشاء `ExtrusionProvider`
- [ ] تقسيم `extrusion_edit_screen.dart` (53 KB!)
- [ ] ربط UI بـ Provider

#### اليوم 9-10: Peinture (الطلاء)

- [ ] تطوير Peinture من الصفر (الشاشة شبه فارغة حالياً)
- [ ] إنشاء Models
- [ ] إنشاء API Service
- [ ] إنشاء Provider
- [ ] تطوير UI كاملة

### المرحلة 4: باقي الـ Features (يوم 11-20)

#### كل Feature يتبع نفس النمط:

```bash
screens/[feature_name]/
├── data/
│   ├── models/
│   └── api_service/
├── providers/
├── widgets/
└── screens/
```

**الجدول الزمني:**
- يوم 11-12: Sales
- يوم 13-14: Purchases
- يوم 15-16: Inventory
- يوم 17-18: Clients
- يوم 19-20: Users & Settings

---

## 👨‍💻 دليل المطور

### 1️⃣ إنشاء Feature جديد (مثال: Production/Fonderie)

#### الخطوة 1: إنشاء البنية

```bash
# إنشاء المجلدات
mkdir -p lib/screens/production/data/models
mkdir -p lib/screens/production/data/api_service
mkdir -p lib/screens/production/providers
mkdir -p lib/screens/production/widgets/fonderie
mkdir -p lib/screens/production/screens
```

#### الخطوة 2: إنشاء Model

```dart
// lib/screens/production/data/models/fonderie_model.dart

import 'package:intl/intl.dart';

class FonderieModel {
  final int? id;
  final String refFondrie;
  final DateTime operationDate;
  final String operationTime;
  final double totalQuantity;
  final double totalCout;
  final int operationsCount;
  final String status;
  final List<FonderieItemModel> items;

  FonderieModel({
    this.id,
    required this.refFondrie,
    required this.operationDate,
    required this.operationTime,
    required this.totalQuantity,
    required this.totalCout,
    required this.operationsCount,
    this.status = 'completed',
    required this.items,
  });

  // From JSON
  factory FonderieModel.fromJson(Map<String, dynamic> json) {
    return FonderieModel(
      id: json['id'] as int?,
      refFondrie: json['ref_fondrie'] as String,
      operationDate: DateTime.parse(json['operation_date'] as String),
      operationTime: json['operation_time'] as String,
      totalQuantity: (json['total_quantity'] as num).toDouble(),
      totalCout: (json['total_cout'] as num).toDouble(),
      operationsCount: json['operations_count'] as int,
      status: json['status'] as String? ?? 'completed',
      items: (json['items'] as List<dynamic>)
          .map((e) => FonderieItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ref_fondrie': refFondrie,
      'operation_date': DateFormat('yyyy-MM-dd').format(operationDate),
      'operation_time': operationTime,
      'total_quantity': totalQuantity,
      'total_cout': totalCout,
      'operations_count': operationsCount,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  // CopyWith
  FonderieModel copyWith({
    int? id,
    String? refFondrie,
    DateTime? operationDate,
    String? operationTime,
    double? totalQuantity,
    double? totalCout,
    int? operationsCount,
    String? status,
    List<FonderieItemModel>? items,
  }) {
    return FonderieModel(
      id: id ?? this.id,
      refFondrie: refFondrie ?? this.refFondrie,
      operationDate: operationDate ?? this.operationDate,
      operationTime: operationTime ?? this.operationTime,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalCout: totalCout ?? this.totalCout,
      operationsCount: operationsCount ?? this.operationsCount,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }
}

// Item Model
class FonderieItemModel {
  final int? id;
  final String refArticle;
  final String articleName;
  final double quantity;
  final double dechetFondrie;
  final double billete;
  final double propane;
  final double cout;

  FonderieItemModel({
    this.id,
    required this.refArticle,
    required this.articleName,
    required this.quantity,
    required this.dechetFondrie,
    required this.billete,
    required this.propane,
    required this.cout,
  });

  factory FonderieItemModel.fromJson(Map<String, dynamic> json) {
    return FonderieItemModel(
      id: json['id'] as int?,
      refArticle: json['ref_article'] as String,
      articleName: json['article_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      dechetFondrie: (json['dechet_fondrie'] as num).toDouble(),
      billete: (json['billete'] as num).toDouble(),
      propane: (json['propane'] as num).toDouble(),
      cout: (json['cout'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ref_article': refArticle,
      'article_name': articleName,
      'quantity': quantity,
      'dechet_fondrie': dechetFondrie,
      'billete': billete,
      'propane': propane,
      'cout': cout,
    };
  }
}
```

#### الخطوة 3: إنشاء API Service

```dart
// lib/screens/production/data/api_service/fonderie_api_service.dart

import 'package:dio/dio.dart';
import '../../../../shared/services/network/dio_client.dart';
import '../../../../shared/core/constants/api_endpoints.dart';
import '../models/fonderie_model.dart';

class FonderieApiService {
  final DioClient _dioClient;

  FonderieApiService(this._dioClient);

  // Get All
  Future<List<FonderieModel>> getAllFonderies() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.fonderie.getAll);

      if (response.data['success'] == true) {
        final List<dynamic> records = response.data['records'];
        return records.map((json) => FonderieModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get By ID
  Future<FonderieModel> getFonderieById(int id) async {
    try {
      final response = await _dioClient.get(
        '${ApiEndpoints.fonderie.getById}?id=$id',
      );

      if (response.data['success'] == true) {
        return FonderieModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Create
  Future<FonderieModel> createFonderie(FonderieModel fonderie) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.fonderie.create,
        data: fonderie.toJson(),
      );

      if (response.data['success'] == true) {
        return FonderieModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update
  Future<FonderieModel> updateFonderie(FonderieModel fonderie) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.fonderie.update,
        data: fonderie.toJson(),
      );

      if (response.data['success'] == true) {
        return FonderieModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Delete
  Future<void> deleteFonderie(int id) async {
    try {
      final response = await _dioClient.delete(
        '${ApiEndpoints.fonderie.delete}?id=$id',
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('انتهت مهلة الاتصال');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('انتهت مهلة استقبال البيانات');
    } else if (e.type == DioExceptionType.badResponse) {
      return Exception('خطأ في الخادم: ${e.response?.statusCode}');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('لا يوجد اتصال بالإنترنت');
    }
    return Exception('حدث خطأ غير متوقع');
  }
}
```

#### الخطوة 4: إنشاء Provider (Riverpod)

```dart
// lib/screens/production/providers/fonderie_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/fonderie_model.dart';
import '../data/api_service/fonderie_api_service.dart';

// State
class FonderieState {
  final List<FonderieModel> fonderies;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  FonderieState({
    this.fonderies = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  FonderieState copyWith({
    List<FonderieModel>? fonderies,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return FonderieState(
      fonderies: fonderies ?? this.fonderies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Filtered Fonderies
  List<FonderieModel> get filteredFonderies {
    if (searchQuery.isEmpty) return fonderies;

    return fonderies.where((fonderie) {
      return fonderie.refFondrie
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          fonderie.items.any((item) => item.articleName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()));
    }).toList();
  }
}

// StateNotifier
class FonderieNotifier extends StateNotifier<FonderieState> {
  final FonderieApiService _apiService;

  FonderieNotifier(this._apiService) : super(FonderieState()) {
    loadFonderies();
  }

  // Load All
  Future<void> loadFonderies() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final fonderies = await _apiService.getAllFonderies();
      state = state.copyWith(
        isLoading: false,
        fonderies: fonderies,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Add
  Future<void> addFonderie(FonderieModel fonderie) async {
    state = state.copyWith(isLoading: true);

    try {
      final newFonderie = await _apiService.createFonderie(fonderie);
      state = state.copyWith(
        isLoading: false,
        fonderies: [...state.fonderies, newFonderie],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Update
  Future<void> updateFonderie(FonderieModel fonderie) async {
    state = state.copyWith(isLoading: true);

    try {
      final updatedFonderie = await _apiService.updateFonderie(fonderie);
      final updatedList = state.fonderies.map((f) {
        return f.id == updatedFonderie.id ? updatedFonderie : f;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        fonderies: updatedList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Delete
  Future<void> deleteFonderie(int id) async {
    state = state.copyWith(isLoading: true);

    try {
      await _apiService.deleteFonderie(id);
      final updatedList = state.fonderies.where((f) => f.id != id).toList();

      state = state.copyWith(
        isLoading: false,
        fonderies: updatedList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Set Search Query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

// Provider
final fonderieApiServiceProvider = Provider<FonderieApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return FonderieApiService(dioClient);
});

final fonderieProvider = StateNotifierProvider<FonderieNotifier, FonderieState>((ref) {
  final apiService = ref.watch(fonderieApiServiceProvider);
  return FonderieNotifier(apiService);
});
```

#### الخطوة 5: إنشاء Screen

```dart
// lib/screens/production/screens/fonderie_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fonderie_provider.dart';
import '../widgets/fonderie/fonderie_card.dart';
import 'fonderie_edit_screen.dart';

class FonderieScreen extends ConsumerWidget {
  const FonderieScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fonderieProvider);

    // Loading State
    if (state.isLoading && state.fonderies.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error State
    if (state.errorMessage != null && state.fonderies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(fonderieProvider.notifier).loadFonderies();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final filteredFonderies = state.filteredFonderies;

    // Empty State
    if (filteredFonderies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('لا توجد عمليات صهر'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة عملية صهر'),
            ),
          ],
        ),
      );
    }

    // List View
    return Column(
      children: [
        // Header with Add Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عمليات الصهر (${filteredFonderies.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToAdd(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(fonderieProvider.notifier).loadFonderies();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredFonderies.length,
              itemBuilder: (context, index) {
                final fonderie = filteredFonderies[index];
                return FonderieCard(
                  fonderie: fonderie,
                  onTap: () => _navigateToEdit(context, fonderie),
                  onDelete: () => _showDeleteDialog(context, ref, fonderie),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FonderieEditScreen(),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, FonderieModel fonderie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FonderieEditScreen(fonderie: fonderie),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    FonderieModel fonderie,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف عملية الصهر ${fonderie.refFondrie}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(fonderieProvider.notifier)
                    .deleteFonderie(fonderie.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الحذف بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الحذف: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
```

#### الخطوة 6: إنشاء Widget (FonderieCard)

```dart
// lib/screens/production/widgets/fonderie/fonderie_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/fonderie_model.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';

class FonderieCard extends StatelessWidget {
  final FonderieModel fonderie;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FonderieCard({
    Key? key,
    required this.fonderie,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassmorphismContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ref
                  Text(
                    fonderie.refFondrie,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(fonderie.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(fonderie.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date & Time
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy-MM-dd').format(fonderie.operationDate),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    fonderie.operationTime,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Divider(color: Colors.white24),
              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      'الكمية',
                      '${fonderie.totalQuantity.toStringAsFixed(2)} كغ',
                      Icons.scale,
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      'التكلفة',
                      '${fonderie.totalCout.toStringAsFixed(2)} د.م',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      'العمليات',
                      '${fonderie.operationsCount}',
                      Icons.list_alt,
                    ),
                  ),
                ],
              ),

              // Items Count
              if (fonderie.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Text(
                  'العناصر: ${fonderie.items.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],

              // Delete Button
              if (onDelete != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'جاري التنفيذ';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
```

---

## 📏 معايير الكود

### 1. التسمية (Naming Conventions)

```dart
// Files - snake_case
// fonderie_model.dart
// fonderie_api_service.dart

// Classes - PascalCase
class FonderieModel {}
class FonderieProvider {}

// Variables & Functions - camelCase
String refFondrie = '';
void calculateTotal() {}

// Constants - lowerCamelCase
const double defaultTaxRate = 0.20;

// Private - prefix _
String _privateVariable = '';
void _privateMethod() {}
```

### 2. بنية الملفات

**ترتيب Imports:**
```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// 4. Project imports
import '../../data/models/fonderie_model.dart';
import '../../../shared/widgets/loading_widget.dart';
```

**ترتيب الأعضاء داخل Class:**
```dart
class MyClass {
  // 1. Static members
  static const String version = '1.0.0';

  // 2. Fields
  final String name;
  final int age;

  // 3. Constructor
  MyClass({required this.name, required this.age});

  // 4. Named constructors
  MyClass.empty() : name = '', age = 0;

  // 5. Getters
  String get fullInfo => '$name - $age';

  // 6. Public methods
  void doSomething() {}

  // 7. Private methods
  void _privateMethod() {}
}
```

### 3. Error Handling

```dart
// في API Service
try {
  final response = await _dioClient.get(endpoint);
  return response.data;
} on DioException catch (e) {
  throw _handleDioError(e);
} catch (e) {
  throw Exception('حدث خطأ غير متوقع: $e');
}

// في Provider
try {
  final data = await _apiService.getData();
  state = state.copyWith(data: data);
} catch (e) {
  state = state.copyWith(errorMessage: e.toString());
  rethrow; // إذا كنت تريد أن يعرف الـ UI بالخطأ
}

// في UI
try {
  await ref.read(provider.notifier).save();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم الحفظ بنجاح')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('فشل الحفظ: $e')),
  );
}
```

### 4. التعليقات

```dart
/// Documentation comment
/// يُستخدم لتوليد الوثائق
class MyClass {}

// Regular comment
// للملاحظات البسيطة
final variable = '';

// TODO: وصف ما يجب فعله
// FIXME: وصف ما يجب إصلاحه
// HACK: شرح الحل المؤقت
```

---

## 🎨 Shared Widgets

### GlassmorphismContainer

```dart
// lib/shared/widgets/glassmorphism_container.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Border? border;

  const GlassmorphismContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurSigma = 10,
    this.backgroundColor,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (backgroundColor ?? Colors.white).withOpacity(0.1),
            (backgroundColor ?? Colors.white).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
```

### LoadingWidget

```dart
// lib/shared/widgets/loading_widget.dart

import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({
    Key? key,
    this.message,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
```

### CustomButton

```dart
// lib/shared/widgets/custom_button.dart

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}
```

---

## 🔧 API Endpoints

```dart
// lib/shared/core/constants/api_endpoints.dart

class ApiEndpoints {
  static const String baseUrl = 'http://localhost/amrts_manager';

  // Fonderie
  static const fonderie = _FonderieEndpoints();

  // Extrusion
  static const extrusion = _ExtrusionEndpoints();

  // Peinture
  static const peinture = _PeintureEndpoints();
}

class _FonderieEndpoints {
  const _FonderieEndpoints();

  String get getAll => '/api/fonderie/get_all.php';
  String get getById => '/api/fonderie/get_by_id.php';
  String get create => '/api/fonderie/create.php';
  String get update => '/api/fonderie/update.php';
  String get delete => '/api/fonderie/delete.php';
}

class _ExtrusionEndpoints {
  const _ExtrusionEndpoints();

  String get getAll => '/api/extrusion/get_all.php';
  String get getById => '/api/extrusion/get_by_id.php';
  String get create => '/api/extrusion/create.php';
  String get update => '/api/extrusion/update.php';
  String get delete => '/api/extrusion/delete.php';
}

class _PeintureEndpoints {
  const _PeintureEndpoints();

  String get getAll => '/api/peinture/get_all.php';
  String get getById => '/api/peinture/get_by_id.php';
  String get create => '/api/peinture/create.php';
  String get update => '/api/peinture/update.php';
  String get delete => '/api/peinture/delete.php';
}
```

---

## ✅ Checklist

### قبل كل Commit

- [ ] `dart format .` - تنسيق الكود
- [ ] `flutter analyze` - لا توجد warnings
- [ ] اختبار الـ Feature يدوياً
- [ ] مراجعة الـ diff
- [ ] Commit message واضح

### قبل كل Feature

- [ ] إنشاء المجلدات حسب البنية
- [ ] إنشاء Models
- [ ] إنشاء API Service
- [ ] إنشاء Provider
- [ ] إنشاء Screens
- [ ] إنشاء Widgets
- [ ] اختبار شامل

---

## 📚 الموارد

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [Dio Documentation](https://pub.dev/packages/dio)

---

**آخر تحديث:** 2025-01-15
**الإصدار:** 2.0.0
**المطور:** AMRTS Team