import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchableDropdownT<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) displayText;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final String? Function(String?)? validator;
  final String hintText;
  final String searchHint;
  final Widget? prefixIcon;
  final bool isLoading;
  final String loadingText;
  final String noResultsText;
  final Color? primaryColor;
  final bool enabled;
  final VoidCallback? onPrefixIconTap;

  const SearchableDropdownT({
    super.key,
    required this.items,
    required this.displayText,
    this.selectedValue,
    this.onChanged,
    this.validator,
    this.hintText = 'Pick...',
    this.searchHint = "Search...",
    this.prefixIcon,
    this.isLoading = false,
    this.loadingText = "Loading...",
    this.noResultsText = 'Empty',
    this.primaryColor,
    this.enabled = true,
    this.onPrefixIconTap,
  });

  @override
  State<SearchableDropdownT<T>> createState() => _SearchableDropdownTState<T>();
}

class _SearchableDropdownTState<T> extends State<SearchableDropdownT<T>>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  OverlayEntry? _overlayEntry;
  List<T> _filteredItems = [];
  bool _isOpen = false;
  String _searchQuery = "";
  int _hoveredIndex = -1;
  bool _isHovered = false;

  Color get _primaryColor =>
      widget.primaryColor ?? Theme.of(context).primaryColor;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items); // نسخ صريح

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.selectedValue != null) {
      _controller.text = widget.displayText(widget.selectedValue as T);
    }

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(SearchableDropdownT<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // تحديث البيانات عند تغيير items
    if (oldWidget.items != widget.items) {
      _filteredItems = List.from(widget.items);

      if (_searchQuery.isNotEmpty) {
        _filterItems(_searchQuery);
      }

      if (_isOpen && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateOverlay();
        });
      }
    }

    // تحديث النص عند تغيير selectedValue
    if (oldWidget.selectedValue != widget.selectedValue) {
      // استخدام addPostFrameCallback لتجنب setState أثناء البناء
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (widget.selectedValue != null) {
          _controller.text = widget.displayText(widget.selectedValue as T);
        } else {
          _controller.clear();
        }
      });

      // إعادة تعيين البحث
      _searchQuery = "";
      _filteredItems = List.from(widget.items);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isOpen && widget.enabled && mounted) {
      // تأخير بسيط للتأكد من عدم الفتح أثناء validation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _focusNode.hasFocus && !_isOpen) {
          _openDropdown();
        }
      });
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // حذف القيمة إذا لا توجد نتائج
      if (_filteredItems.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
        widget.onChanged?.call(null);
        _filterItems("");
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _closeDropdown();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveSelection(1);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveSelection(-1);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _selectCurrentItem();
        return true;
      }
    }
    return false;
  }

  void _moveSelection(int direction) {
    if (_filteredItems.isEmpty || !mounted) return;

    setState(() {
      _hoveredIndex = (_hoveredIndex + direction).clamp(
        0,
        _filteredItems.length - 1,
      );
    });
    _updateOverlay();
  }

  void _selectCurrentItem() {
    if (_hoveredIndex >= 0 && _hoveredIndex < _filteredItems.length) {
      _selectItem(_filteredItems[_hoveredIndex]);
    }
  }

  void _filterItems(String query) {
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
      _hoveredIndex = -1;

      // تحسين الفلتر ليدعم البحث بالعربية والإنجليزية
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          final itemText = widget.displayText(item).toLowerCase().trim();
          final searchQuery = query.toLowerCase().trim();

          // البحث العادي
          if (itemText.contains(searchQuery)) {
            return true;
          }

          // البحث بالكلمات المفردة للنصوص العربية
          final itemWords = itemText.split(' ');
          final queryWords = searchQuery.split(' ');

          for (String queryWord in queryWords) {
            if (queryWord.isNotEmpty) {
              bool foundWord = itemWords.any(
                (word) => word.contains(queryWord),
              );
              if (foundWord) return true;
            }
          }

          return false;
        }).toList();
      }
    });

    // تأكد من تحديث الـ overlay بعد الفلتر
    if (mounted && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateOverlay();
      });
    }
  }

  void _openDropdown() {
    if (_isOpen || !widget.enabled || !mounted) return;

    setState(() => _isOpen = true);
    _animationController.forward();

    // تأكد من إعادة تعيين القائمة المفلترة
    if (widget.selectedValue == null) {
      _controller.clear();
      _searchQuery = "";
      _filteredItems = List.from(widget.items);
    } else {
      // إذا كان هناك قيمة محددة، اعرض جميع العناصر أولاً
      _filteredItems = List.from(widget.items);
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    // إضافة مستمع لوحة المفاتيح
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void _closeDropdown() {
    if (!_isOpen) return;

    // إزالة الـ overlay أولاً
    _overlayEntry?.remove();
    _overlayEntry = null;

    // إيقاف الأنيميشن
    _animationController.reverse();

    // إزالة مستمع لوحة المفاتيح
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);

    // إزالة الـ focus
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }

    // تحديث الحالة في النهاية فقط إذا كان الـ widget ما زال mounted
    if (mounted) {
      setState(() {
        _isOpen = false;
        _hoveredIndex = -1;
      });
    } else {
      // إذا لم يكن mounted، حدث المتغيرات مباشرة
      _isOpen = false;
      _hoveredIndex = -1;
    }
  }

  void _selectItem(T item) {
    if (!mounted) return;

    _controller.text = widget.displayText(item);
    widget.onChanged?.call(item);

    // إعادة تعيين البحث
    _searchQuery = "";
    _filteredItems = List.from(widget.items);

    _closeDropdown();

    // تأثير اهتزاز خفيف للتأكيد
    HapticFeedback.lightImpact();
  }

  void _clearSelection() {
    _controller.clear();
    widget.onChanged?.call(null);
    _filterItems("");
    if (!_isOpen) _openDropdown();
    HapticFeedback.selectionClick();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Colors.black.withValues(alpha: 0.15),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.grey[50]!],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.isLoading
                        ? _buildLoadingItem()
                        : _filteredItems.isEmpty
                        ? _buildNoResultsItem()
                        : _buildItemsList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(_primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            widget.loadingText,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsItem() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // حساب الأبعاد بشكل متجاوب
    final containerHeight = screenHeight * 0.08; // 8% من ارتفاع الشاشة
    final iconSize = screenWidth * 0.05; // 5% من عرض الشاشة
    final fontSize = screenWidth * 0.035; // 3.5% من عرض الشاشة
    final spacing = screenWidth * 0.03; // 3% من عرض الشاشة

    return Container(
      height: containerHeight.clamp(48.0, 72.0), // حد أدنى 48 وحد أقصى 72
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: iconSize.clamp(18.0, 24.0),
            color: Colors.grey[400],
          ),
          SizedBox(width: spacing.clamp(8.0, 16.0)),
          Flexible(
            child: Text(
              widget.noResultsText,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: fontSize.clamp(12.0, 16.0),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Scrollbar(
      controller: _scrollController, // أضف هذا السطر
      thumbVisibility: _filteredItems.length > 6,
      radius: const Radius.circular(6),
      child: ListView.builder(
        controller: _scrollController, // أضف هذا السطر أيضاً
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          // باقي الكود يبقى كما هو
          final item = _filteredItems[index];
          final isSelected = widget.selectedValue == item;
          final isHovered = _hoveredIndex == index;

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = -1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? _primaryColor.withValues(alpha: 0.1)
                    : isHovered
                    ? Colors.grey[100]
                    : Colors.transparent,
                border: isSelected
                    ? Border.all(
                        color: _primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      )
                    : null,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _selectItem(item),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: _primaryColor,
                            size: 18,
                          ),
                        ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildHighlightedText(
                            widget.displayText(item),
                            _searchQuery,
                            isSelected,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, bool isSelected) {
    final textStyle = TextStyle(
      color: isSelected ? _primaryColor : Colors.grey[800],
      fontSize: 15,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    );

    if (query.isEmpty) {
      return Text(text, style: textStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: textStyle);
    }

    return RichText(
      text: TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: textStyle.copyWith(
              fontWeight: FontWeight.bold,
              backgroundColor: _primaryColor.withValues(alpha: 0.2),
              color: _primaryColor,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  void _updateOverlay() {
    if (mounted && _overlayEntry != null) {
      try {
        _overlayEntry!.markNeedsBuild();
      } catch (e) {
        // في حالة حدوث خطأ، أعد إنشاء الـ overlay
        _closeDropdown();
        if (widget.enabled) {
          _openDropdown();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered && widget.enabled
                ? [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: false,
            validator:
                widget.validator ??
                (v) {
                  // للتحقق من القيمة المختارة وليس فقط النص
                  if (widget.selectedValue == null) {
                    return 'مطلوب';
                  }
                  return null;
                },
            onTap: widget.enabled
                ? () {
                    if (!_isOpen && mounted) {
                      // تحقق من أن الـ focus مستقر
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (mounted && _focusNode.hasFocus && !_isOpen) {
                          _openDropdown();
                        }
                      });
                    }
                  }
                : null,
            onChanged: widget.enabled
                ? (value) {
                    if (!_isOpen && mounted && _focusNode.hasFocus) {
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (mounted && !_isOpen && _focusNode.hasFocus) {
                          _openDropdown();
                        }
                      });
                    }
                    _filterItems(value);
                  }
                : null,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: widget.enabled ? Colors.grey[800] : Colors.grey[400],
            ),
            decoration: InputDecoration(
              hintText: widget.selectedValue == null
                  ? widget.hintText
                  : widget.searchHint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? GestureDetector(
                      onTap: widget.enabled ? widget.onPrefixIconTap : null,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: widget.prefixIcon,
                      ),
                    )
                  : null,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty && widget.enabled)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                        onPressed: _clearSelection,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        splashRadius: 16,
                      ),
                    ),
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) => Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.enabled
                            ? (_isOpen ? _primaryColor : Colors.grey[500])
                            : Colors.grey[300],
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              filled: true,
              fillColor: widget.enabled
                  ? (_isOpen ? Colors.white : Colors.grey[50])
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // إغلاق الـ dropdown أولاً
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
      _isOpen = false;
    }

    // تنظيف الـ controllers
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}

// مثال على الاستخدام:
/*
SearchableDropdownT<String>(
  items: ['أحمد محمد', 'أحلام علي', 'محمد أحمد', 'سارة محمود'],
  displayText: (item) => item,
  selectedValue: selectedClient,
  onChanged: (value) => setState(() => selectedClient = value),
  hintText: "اختر عميل...",
  prefixIcon: Icon(Icons.person_outline_rounded),
  primaryColor: Colors.blue,
  enabled: true,
)
*/
