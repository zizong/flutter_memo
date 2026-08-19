import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/memo.dart';
import 'database/db_helper.dart';
import 'memo_edit_page.dart';
import 'utils/backup_helper.dart';   // 导入备份工具

class MemoListPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDark;

  const MemoListPage({
    super.key,
    required this.onThemeToggle,
    required this.isDark,
  });

  @override
  State<MemoListPage> createState() => _MemoListPageState();
}

class _MemoListPageState extends State<MemoListPage> {
  List<Memo> _allMemos = [];
  List<Memo> _filteredMemos = [];
  final DBHelper _db = DBHelper();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ---------- 批量删除相关 ----------
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  // ---------- 导出/导入 ----------
  final BackupHelper _backupHelper = BackupHelper();

  @override
  void initState() {
    super.initState();
    _loadMemos();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterMemos();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- 数据加载与过滤 ----------
  Future<void> _loadMemos() async {
    final data = await _db.getAllMemos();
    setState(() {
      _allMemos = data;
      _filterMemos();
    });
  }

  void _filterMemos() {
    if (_searchQuery.isEmpty) {
      _filteredMemos = List.from(_allMemos);
    } else {
      _filteredMemos = _allMemos.where((memo) {
        final titleLower = memo.title.toLowerCase();
        final contentLower = memo.content.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        return titleLower.contains(queryLower) || contentLower.contains(queryLower);
      }).toList();
    }
  }

  void _refreshList() {
    _loadMemos();
    _exitSelectionMode();
  }

  // ---------- 批量删除 ----------
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<bool> _showDeleteConfirmDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    await _showDeleteConfirmDialog(
      title: '确认批量删除',
      content: '确定要删除选中的 ${_selectedIds.length} 条备忘录吗？此操作不可撤销。',
      onConfirm: () async {
        for (final id in _selectedIds) {
          await _db.deleteMemo(id);
        }
        _refreshList();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${_selectedIds.length} 条备忘录'), backgroundColor: Colors.green),
        );
      },
    );
  }

  Future<void> _deleteMemoWithConfirm(Memo memo) async {
    await _showDeleteConfirmDialog(
      title: '删除备忘录',
      content: '确定要删除“${memo.title}”吗？此操作不可撤销。',
      onConfirm: () async {
        await _db.deleteMemo(memo.id!);
        _refreshList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), backgroundColor: Colors.green),
        );
      },
    );
  }

  // ---------- 导出/导入 ----------
  Future<void> _exportData() async {
    final result = await _backupHelper.exportData();
    if (result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: result.startsWith('导出失败') ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _importData() async {
    final result = await _backupHelper.importData();
    if (result == null) return;
    _refreshList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: result.startsWith('导入失败') ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ---------- 构建 UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _filteredMemos.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty ? '还没有备忘录，点击 + 添加' : '没有匹配的备忘录',
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredMemos.length,
                    itemBuilder: (context, index) {
                      final memo = _filteredMemos[index];
                      final isSelected = _selectedIds.contains(memo.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: isSelected ? Colors.blue.withOpacity(0.15) : null,
                        child: _isSelectionMode
                            ? CheckboxListTile(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(memo.id!),
                                title: Text(memo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  memo.content.length > 50 ? '${memo.content.substring(0, 50)}...' : memo.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                secondary: Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(memo.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              )
                            : ListTile(
                                title: Text(memo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  memo.content.length > 50 ? '${memo.content.substring(0, 50)}...' : memo.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(memo.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                onTap: () async {
                                  if (_isSelectionMode) {
                                    _toggleSelection(memo.id!);
                                  } else {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MemoEditPage(memo: memo),
                                      ),
                                    );
                                    if (result == true) _refreshList();
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    setState(() {
                                      _isSelectionMode = true;
                                      _selectedIds.add(memo.id!);
                                    });
                                  }
                                },
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _selectedIds.isEmpty ? null : _batchDelete,
              icon: const Icon(Icons.delete),
              label: Text('删除 ${_selectedIds.length} 条'),
              backgroundColor: _selectedIds.isEmpty ? Colors.grey : Colors.red,
            )
          : FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MemoEditPage()),
                );
                if (result == true) _refreshList();
              },
            ),
    );
  }

  // ---------- AppBar ----------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isSelectionMode ? '已选择 ${_selectedIds.length} 项' : '备忘录'),
      centerTitle: true,
      actions: [
        if (_isSelectionMode)
          IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode, tooltip: '退出选择模式')
        else ...[
          IconButton(icon: const Icon(Icons.upload_file), onPressed: _exportData, tooltip: '导出数据'),
          IconButton(icon: const Icon(Icons.download), onPressed: _importData, tooltip: '导入数据'),
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _toggleSelectionMode, tooltip: '批量删除'),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
            tooltip: '切换主题',
          ),
        ],
      ],
    );
  }

  // ---------- 搜索栏 ----------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        enabled: !_isSelectionMode,
        decoration: InputDecoration(
          hintText: '搜索标题或内容...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
              : null,
        ),
      ),
    );
  }
}