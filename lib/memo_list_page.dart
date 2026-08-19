import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/memo.dart';
import 'database/db_helper.dart';
import 'memo_edit_page.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备忘录'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
            tooltip: '切换主题',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索标题或内容...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // 备忘录列表
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
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(
                            memo.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            memo.content.length > 50
                                ? '${memo.content.substring(0, 50)}...'
                                : memo.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(memo.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemoEditPage(memo: memo),
                              ),
                            );
                            if (result == true) _refreshList();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MemoEditPage(),
            ),
          );
          if (result == true) _refreshList();
        },
      ),
    );
  }
}
