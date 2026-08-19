import 'package:flutter/material.dart';
import 'models/memo.dart';
import 'database/db_helper.dart';

class MemoEditPage extends StatefulWidget {
  final Memo? memo; // 若为 null 表示新建

  const MemoEditPage({super.key, this.memo});

  @override
  State<MemoEditPage> createState() => _MemoEditPageState();
}

class _MemoEditPageState extends State<MemoEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final DBHelper _db = DBHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memo?.title ?? '');
    _contentController = TextEditingController(text: widget.memo?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ---------- 保存 ----------
  Future<void> _saveMemo() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题和正文不能为空')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (widget.memo == null) {
      // 新建
      final newMemo = Memo(
        title: title,
        content: content,
        createdAt: DateTime.now(),
      );
      await _db.insertMemo(newMemo);
    } else {
      // 更新
      final updatedMemo = Memo(
        id: widget.memo!.id,
        title: title,
        content: content,
        createdAt: widget.memo!.createdAt,
      );
      await _db.updateMemo(updatedMemo);
    }

    setState(() => _isLoading = false);
    Navigator.pop(context, true);
  }

  // ---------- 删除（带确认对话框） ----------
  Future<void> _deleteMemo() async {
    if (widget.memo == null) return;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text(
          '确认删除',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('确定要删除“${widget.memo!.title}”吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 执行删除
    setState(() => _isLoading = true);
    await _db.deleteMemo(widget.memo!.id!);
    setState(() => _isLoading = false);
    Navigator.pop(context, true);
  }

  // ---------- 构建 UI ----------
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.memo != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑备忘录' : '新建备忘录'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteMemo,
              tooltip: '删除',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '正文',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMemo,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}