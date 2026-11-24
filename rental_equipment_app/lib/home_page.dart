import 'package:flutter/material.dart';
import 'package:rental_equipment_app/app_theme.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/management_layout.dart';
import 'package:rental_equipment_app/cart_repository.dart';
import 'package:rental_equipment_app/member_repository.dart';
import 'package:rental_equipment_app/equipment.dart';
import 'package:rental_equipment_app/equipment_repository.dart';
import 'package:rental_equipment_app/category.dart';
import 'package:rental_equipment_app/category_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';
import 'package:rental_equipment_app/sub_category.dart';
import 'package:rental_equipment_app/sub_category_repository.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  List<Equipment> _equipment = [];
  int? _categoryId;
  final Set<int> _selected = {};
  String? _email;
  String? _unit;
  List<String> _units = [];
  String? _error;
  final _searchController = TextEditingController();
  String _search = '';
  int _page = 1;
  int _total = 0;
  int _cartCount = 0;
  bool _isAdmin = false;
  bool _offline = false;
  bool _loading = true;
  final _scroll = ScrollController();
  int _equipmentRequest = 0;
  int _subCategoryRequest = 0;
  Future<void> _loadEquipment() async {
    final request = ++_equipmentRequest;
    setState(() => _loading = true);
    try {
      final data = await EquipmentRepository.getPage(
        page: _page,
        categoryId: _categoryId,
        subCategoryIds: _selected.toList()..sort(),
        unit: _unit,
        search: _search,
      );
      if (!mounted || request != _equipmentRequest) return;
      if (_page > 1 && data.items.isEmpty && !data.offline) {
        _goToPage(data.total > 0 ? (data.total + 11) ~/ 12 : 1);
        return;
      }
      setState(() {
        _equipment = data.items;
        _total = data.total;
        _offline = data.offline;
        _error = null;
      });
    } catch (_) {
      if (!mounted || request != _equipmentRequest) return;
      setState(() => _error = 'Không tải được thiết bị');
    } finally {
      if (mounted && request == _equipmentRequest) {
        setState(() => _loading = false);
      }
    }
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    _loadEquipment();
  }

  void _onSearch() {
    _search = _searchController.text.trim();
    _goToPage(1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await CategoryRepository.getCategories();
      final units = await EquipmentRepository.getUnits();
      if (mounted) {
        setState(() {
          _categories = data;
          _units = units;
        });
        if (_unit != null && !units.contains(_unit)) {
          _unit = null;
          _goToPage(1);
        }
        if (_categoryId != null && !data.any((p) => p.id == _categoryId)) {
          _categoryId = null;
          _selected.clear();
          _loadSubCategories();
          _goToPage(1);
        }
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Không tải được danh mục hoặc đơn vị');
    }
  }

  Future<void> _loadSubCategories() async {
    final request = ++_subCategoryRequest;
    try {
      final data = _categoryId == null
          ? await SubCategoryRepository.getSubCategories()
          : await SubCategoryRepository.getSubCategoriesByCategory(
              _categoryId!,
            );
      if (mounted && request == _subCategoryRequest) {
        setState(() => _subCategories = data);
      }
    } catch (_) {
      if (mounted && request == _subCategoryRequest) {
        showMessage(context, 'Không tải được nhóm thiết bị');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCategories();
    _loadSubCategories();
    _loadEquipment();
  }

  Future<void> _loadData() async {
    final email = await SessionHelper.email;
    final token = await SessionHelper.token;
    if (!mounted) return;
    setState(() => _email = email);
    if (token == null) return;

    try {
      final member = await MemberRepository.getMember(token);
      if (await SessionHelper.token != token || !mounted) return;
      if (member == null) {
        await _logout();
        return;
      }
      setState(() => _isAdmin = member.role == 2);
      final carts = await CartRepository.getCarts(token);
      if (await SessionHelper.token != token || !mounted) return;
      setState(() => _cartCount = carts.length);
    } catch (_) {
      // The cached catalogue is still available when the phone is offline.
    }
  }

  Future<void> _onAdmin(String route) async {
    await Navigator.pushNamed(context, route);
    if (!mounted) return;
    _loadCategories();
    _loadSubCategories();
    _goToPage(1);
  }

  void _selectManagement(String route) {
    if (route == '/rental') {
      _onRental();
    } else if (route != '/') {
      _onAdmin(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 560;
    final showSidebar = _isAdmin && screenWidth >= managementBreakpoint;
    final showDrawer = _isAdmin && !showSidebar;
    return Scaffold(
      drawer: showDrawer ? managementDrawer('/', _selectManagement) : null,
      appBar: AppBar(
        title: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colors.onPrimary,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: compact
                    ? theme.textTheme.titleLarge?.copyWith(fontSize: 17)
                    : null,
              ),
            ),
          ],
        ),
        actions: [
          if (_email == null || _email!.isEmpty) ...[
            if (!compact)
              TextButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Đăng nhập'),
              )
            else
              IconButton(
                onPressed: _login,
                tooltip: 'Đăng nhập',
                icon: const Icon(Icons.login),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton(
                onPressed: _register,
                child: const Text('Đăng ký'),
              ),
            ),
          ] else ...[
            IconButton(
              onPressed: _onCart,
              tooltip: 'Giỏ thuê',
              icon: Badge(
                isLabelVisible: _cartCount > 0,
                label: Text('$_cartCount'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            IconButton(
              onPressed: _onRental,
              tooltip: 'Phiếu thuê',
              icon: const Icon(Icons.receipt_long_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Tài khoản',
              onSelected: (value) {
                if (value == 'profile') {
                  _profile();
                } else {
                  _logout();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('Hồ sơ'),
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Đăng xuất'),
                  ),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: rentalLightBlue,
                  foregroundColor: rentalBlue,
                  child: Icon(Icons.person_outline, size: 19),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Row(
        children: [
          if (showSidebar)
            SizedBox(
              width: 228,
              child: ManagementNavigation(
                activeRoute: '/',
                onSelected: _selectManagement,
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final margin = ((constraints.maxWidth - 1420) / 2).clamp(
                  compact ? 12.0 : 20.0,
                  double.infinity,
                );
                final width = constraints.maxWidth - margin * 2;
                final columns = switch (width) {
                  >= 1390 => 5,
                  >= 1050 => 4,
                  >= 680 => 3,
                  >= 330 => 2,
                  _ => 1,
                };
                final wide = width >= 750;
                return CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(margin, 18, margin, 0),
                      sliver: SliverToBoxAdapter(child: _buildSearch(width)),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(margin, 14, margin, 16),
                      sliver: SliverToBoxAdapter(child: _buildFilters(wide)),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(margin, 0, margin, 10),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _search.isNotEmpty
                                        ? 'Kết quả tìm kiếm'
                                        : _categoryId == null &&
                                              _unit == null &&
                                              _selected.isEmpty
                                        ? 'Thiết bị mới nhất'
                                        : 'Kết quả lọc',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ),
                                if (!_loading && _error == null)
                                  Text(
                                    '$_total thiết bị',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            if (_offline)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Đang xem danh sách đã lưu trên điện thoại',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_loading || _error != null || _equipment.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: _loading
                              ? const CircularProgressIndicator()
                              : _error != null
                              ? TextButton.icon(
                                  onPressed: _loadEquipment,
                                  icon: const Icon(Icons.refresh),
                                  label: Text('$_error. Thử lại'),
                                )
                              : const Text('Chưa có thiết bị phù hợp'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(margin, 0, margin, 24),
                        sliver: SliverGrid.builder(
                          itemCount: _equipment.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                mainAxisExtent: width < 450 ? 252 : 277,
                              ),
                          itemBuilder: (context, index) {
                            final item = _equipment[index];
                            return _EquipmentCard(
                              item: item,
                              onDetails: () => _onDetails(item.id),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _error == null && _total > 0
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: pageButtons(_page, (_total + 11) ~/ 12, (page) {
                  if (_loading) return;
                  if (_scroll.hasClients) _scroll.jumpTo(0);
                  _goToPage(page);
                }),
              ),
            )
          : null,
    );
  }

  Widget _buildSearch(double width) {
    final wide = width >= 750;
    const background = rentalNavy;
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: background,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 26 : 16,
                  vertical: wide ? 22 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tìm thiết bị',
                      style: wide
                          ? theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            )
                          : theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _onSearch(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: width < 420
                            ? 'Tên, hãng hoặc model'
                            : 'Tìm thiết bị theo tên, hãng, model',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(4),
                          child: FilledButton(
                            onPressed: _onSearch,
                            child: const Text('Tìm'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (wide)
              SizedBox(
                height: 154,
                width: (width * .42).clamp(310.0, 540.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CatalogPhoto(alignment: Alignment.centerRight),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              background,
                              rentalBlue.withValues(alpha: .16),
                            ],
                            stops: const [0, .62],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onCategory(int? id) {
    setState(() {
      _categoryId = id;
      _selected.clear();
    });
    _loadSubCategories();
    _goToPage(1);
  }

  Widget _buildFilters(bool wide) {
    final theme = Theme.of(context);
    final categories = _filterChips(wide, [
      ChoiceChip(
        label: const Text('Tất cả danh mục'),
        selected: _categoryId == null,
        onSelected: (_) => _onCategory(null),
      ),
      for (final item in _categories)
        ChoiceChip(
          avatar: categoryImage(item.icon),
          label: Text(item.name),
          selected: _categoryId == item.id,
          onSelected: (value) => _onCategory(value ? item.id : null),
        ),
    ]);
    final unit = DropdownButtonFormField<String>(
      key: ValueKey(_unit),
      initialValue: _unit ?? '',
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.apartment_outlined, size: 19),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Tất cả đơn vị')),
        for (final name in _units)
          DropdownMenuItem(
            value: name,
            child: Text(name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        _unit = value == '' ? null : value;
        _goToPage(1);
      },
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wide)
              Row(
                children: [
                  Expanded(child: categories),
                  const SizedBox(width: 14),
                  SizedBox(width: 224, child: unit),
                ],
              )
            else ...[
              categories,
              const SizedBox(height: 8),
              unit,
            ],
            if (_subCategories.isNotEmpty) ...[
              const Divider(height: 18),
              _filterChips(wide, [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'Nhóm thiết bị',
                    style: theme.textTheme.labelLarge,
                  ),
                ),

                for (final item in _subCategories)
                  FilterChip(
                    avatar: categoryImage(item.imageUrl),
                    label: Text(item.name),
                    onSelected: (value) {
                      if (value) {
                        _selected.add(item.id);
                      } else {
                        _selected.remove(item.id);
                      }
                      _goToPage(1);
                    },
                    selected: _selected.contains(item.id),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChips(bool wide, List<Widget> chips) {
    if (wide) {
      return Wrap(
        spacing: 8,
        runSpacing: 3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(spacing: 8, children: chips),
    );
  }

  void _onRental() async {
    await Navigator.pushNamed(context, '/rental');
    _loadEquipment();
  }

  void _onCart() async {
    await Navigator.pushNamed(context, '/cart');
    if (!mounted) return;
    _loadData();
    _loadEquipment();
  }

  void _onDetails(int id) async {
    await Navigator.pushNamed(context, '/details', arguments: id);
    if (!mounted) return;
    _loadData();
    _loadCategories();
    _loadEquipment();
  }

  void _login() async {
    var result = await Navigator.pushNamed(context, '/login');
    if (result == true) {
      _loadData();
    }
  }

  void _register() {
    Navigator.pushNamed(context, '/register');
  }

  Future<void> _logout() async {
    await SessionHelper.delete();
    if (!mounted) return;
    setState(() {
      _email = null;
      _isAdmin = false;
      _cartCount = 0;
    });
  }

  void _profile() async {
    await Navigator.pushNamed(context, '/profile');
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.item, required this.onDetails});

  final Equipment item;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 19, 8, 4),
                        child: Center(
                          child: equipmentImage(item.imageUrl, size: 110),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      left: 6,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: equipmentStatus(item.status),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 39,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            Text(
              item.unit ?? 'Chưa phân đơn vị',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 5),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatPrice(item.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  TextSpan(text: '/ngày', style: theme.textTheme.bodySmall),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onDetails,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chi tiết'),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
