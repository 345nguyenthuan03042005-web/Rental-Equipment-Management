import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rental_equipment_app/app_theme.dart';
import 'package:rental_equipment_app/cart_page.dart';
import 'package:rental_equipment_app/details_page.dart';
import 'package:rental_equipment_app/home_page.dart';
import 'package:rental_equipment_app/rental_details_page.dart';
import 'package:rental_equipment_app/rental_page.dart';
import 'package:rental_equipment_app/login_page.dart';
import 'package:rental_equipment_app/profile_page.dart';
import 'package:rental_equipment_app/register_page.dart';
import 'package:rental_equipment_app/category_page.dart';
import 'package:rental_equipment_app/equipment_page.dart';
import 'package:rental_equipment_app/member_page.dart';
import 'package:rental_equipment_app/password_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const useSameOrigin = bool.fromEnvironment('API_USE_SAME_ORIGIN');
  if (kIsWeb && useSameOrigin) {
    dotenv.loadFromString(envString: 'API_URL=${Uri.base.origin}');
  } else {
    const apiUrl = String.fromEnvironment('API_URL');
    await dotenv.load(
      fileName: ".env",
      mergeWith: {if (apiUrl.isNotEmpty) 'API_URL': apiUrl},
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý thiết bị cho thuê',
      debugShowCheckedModeBanner: false,
      theme: rentalTheme(),
      initialRoute: '/',
      routes: {
        "/": (context) => HomePage(title: 'Thiết bị cho thuê'),
        "/register": (context) => RegisterPage(title: 'Đăng ký'),
        "/login": (context) => LoginPage(title: 'Đăng nhập'),
        '/profile': (context) => ProfilePage(title: 'Hồ sơ'),
        '/password': (context) => const PasswordPage(title: 'Đổi mật khẩu'),
        '/admin/category': (context) =>
            const CategoryPage(title: 'Quản lý danh mục'),
        '/admin/equipment': (context) =>
            const EquipmentPage(title: 'Quản lý thiết bị'),
        '/admin/member': (context) =>
            const MemberPage(title: 'Quản lý thành viên'),
        '/details': (context) => DetailsPage(title: 'Chi tiết thiết bị'),
        '/cart': (context) => CartPage(title: 'Giỏ thuê'),
        '/rental': (context) => RentalPage(title: 'Phiếu thuê'),
        '/rental/details': (context) =>
            RentalDetailsPage(title: 'Chi tiết phiếu thuê'),
      },
    );
  }
}
