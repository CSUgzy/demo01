import 'package:flutter/material.dart';

class CustomDropdownSelect<T> extends StatefulWidget {
  final String hint;
  final List<T> items;
  final List<T> selectedItems;
  final Function(T) onItemSelected;
  final Function(T) onItemRemoved;
  final String Function(T) labelBuilder;
  final bool isSearchable;
  final bool isMultiSelect;
  final double? width;

  const CustomDropdownSelect({
    super.key,
    required this.hint,
    required this.items,
    required this.selectedItems,
    required this.onItemSelected,
    required this.onItemRemoved,
    required this.labelBuilder,
    this.isSearchable = false,
    this.isMultiSelect = false,
    this.width,
  });

  @override
  State<CustomDropdownSelect<T>> createState() => _CustomDropdownSelectState<T>();
}

class _CustomDropdownSelectState<T> extends State<CustomDropdownSelect<T>> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isOpen = false;
  List<T> _filteredItems = [];
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // 保存下拉菜单触发器的引用
  final GlobalKey _dropdownTriggerKey = GlobalKey();
  
  // 定义颜色常量
  final Color _hintTextColor = Colors.grey.shade400; // 提示文字颜色
  final Color _borderColor = const Color(0xFFE2E8F0); // 边框颜色 - 更浅的灰色
  final Color _backgroundColor = Colors.white; // 背景颜色
  final Color _chipBackgroundColor = const Color(0xFFE6EFFF); // 标签背景颜色 - 浅蓝色
  final Color _chipTextColor = const Color(0xFF3B82F6); // 标签文字颜色 - 蓝色

  @override
  void initState() {
    super.initState();
    _updateFilteredItems();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isOpen) {
        _openDropdown();
      } else if (!_focusNode.hasFocus && _isOpen) {
        _closeDropdown();
      }
    });
  }

  @override
  void didUpdateWidget(CustomDropdownSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItems != widget.selectedItems || oldWidget.items != widget.items) {
      _updateFilteredItems();
    }
  }

  void _updateFilteredItems() {
    // 过滤掉已选择的项目
    _filteredItems = widget.items.where((item) => !widget.selectedItems.contains(item)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    
    // 安全地关闭下拉菜单
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    
    super.dispose();
  }

  void _openDropdown() {
    _isOpen = true;
    // 每次打开下拉菜单时更新过滤后的项目
    _updateFilteredItems();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((_) {
        if (_overlayEntry != null) {
          _overlayEntry!.remove();
          _overlayEntry = null;
        }
      });
    }
    _isOpen = false;
    
    // 安全地清除搜索文本
    if (_searchController.hasListeners) {
      _searchController.clear();
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _updateFilteredItems();
      } else {
        _filteredItems = widget.items
            .where((item) => 
                !widget.selectedItems.contains(item) && // 排除已选择的项目
                widget.labelBuilder(item)
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
      
      // 重新创建下拉菜单以反映过滤后的项目
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  OverlayEntry _createOverlayEntry() {
    // 获取触发器的位置和大小
    final RenderBox? triggerBox = _dropdownTriggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (triggerBox == null) return OverlayEntry(builder: (_) => const SizedBox.shrink());
    
    final Size triggerSize = triggerBox.size;
    final Offset triggerOffset = triggerBox.localToGlobal(Offset.zero);
    
    return OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 透明层，用于捕获点击事件关闭下拉菜单
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            // 下拉菜单内容
            Positioned(
              width: triggerSize.width,
              left: triggerOffset.dx,
              top: triggerOffset.dy + triggerSize.height,
              child: SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: 1,
                child: Material(
                  elevation: 8.0,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(8.0),
                  color: _backgroundColor,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: 250,
                      minWidth: triggerSize.width,
                    ),
                    child: _filteredItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '没有更多选项',
                            style: TextStyle(color: _hintTextColor),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            
                            return ListTile(
                              title: Text(widget.labelBuilder(item)),
                              onTap: () {
                                widget.onItemSelected(item);
                                // 选择后关闭下拉菜单
                                _focusNode.unfocus();
                              },
                            );
                          },
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 自定义标签组件，替代Chip
  Widget _buildCustomTag(T item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.labelBuilder(item),
            style: TextStyle(
              color: _chipTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => widget.onItemRemoved(item),
            child: Icon(
              Icons.close,
              size: 16,
              color: _chipTextColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 下拉菜单触发器
        GestureDetector(
          key: _dropdownTriggerKey,
          onTap: _toggleDropdown,
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: _backgroundColor,
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(16.0), // 更大的圆角
            ),
            child: widget.isSearchable
              ? TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(color: _hintTextColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // 增加内边距
                    suffixIcon: Icon(Icons.arrow_drop_down, color: _borderColor),
                    filled: true,
                    fillColor: _backgroundColor,
                  ),
                  onChanged: _filterItems,
                )
              : InputDecorator(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // 增加内边距
                    suffixIcon: Icon(Icons.arrow_drop_down, color: _borderColor),
                    filled: true,
                    fillColor: _backgroundColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.selectedItems.isEmpty
                              ? widget.hint
                              : widget.isMultiSelect
                                  ? '已选择 ${widget.selectedItems.length} 项'
                                  : widget.labelBuilder(widget.selectedItems.first),
                          style: TextStyle(
                            color: widget.selectedItems.isEmpty ? _hintTextColor : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Focus(
                        focusNode: _focusNode,
                        child: Container(width: 0, height: 0),
                      ),
                    ],
                  ),
                ),
          ),
        ),
        // 已选项标签
        if (widget.selectedItems.isNotEmpty && widget.isMultiSelect)
          Container(
            width: widget.width,
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedItems.map((item) => _buildCustomTag(item)).toList(),
            ),
          ),
      ],
    );
  }
} 