import 'package:restore/core/config/app_environment.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';

/// Danh mục cho thanh lọc và gợi ý tìm kiếm (API có cache dùng chung, dữ
/// liệu mẫu khi chạy mock). Lỗi thì trả rỗng: thanh lọc vẫn dùng được, chỉ
/// không hiện tên danh mục đang lọc.
Future<List<CategoryModel>> loadFilterCategories() =>
    (AppEnvironment.useMockData
            ? MockCategoryRepository()
            : ApiCategoryRepository())
        .getCategories()
        .catchError((Object _) => const <CategoryModel>[]);
