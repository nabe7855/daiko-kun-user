import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/saved_address_model.dart';
import 'address_provider.dart';
import 'address_search_screen.dart';
import 'auth_provider.dart';
import 'legal_documents_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final addressesAsync = ref.watch(addressProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('ログインしていません')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('アカウント'), elevation: 0),
      body: ListView(
        children: [
          _buildProfileHeader(user),
          const Divider(),
          _buildSectionHeader('プロフィール設定'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('名前・メールアドレスの変更'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEditProfileDialog(user),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('予約済みのライド'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/reservations'),
          ),
          const Divider(),
          _buildSectionHeader('登録済みの住所'),
          addressesAsync.when(
            data: (addresses) => Column(
              children: [
                ...addresses.map((a) => _buildAddressTile(a)),
                ListTile(
                  leading: const Icon(
                    Icons.add_location_alt_outlined,
                    color: AppColors.actionOrange,
                  ),
                  title: const Text('新しい住所を追加'),
                  onTap: () => _navigateToAddressSearch(),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => ListTile(title: Text('エラーが発生しました: $e')),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('ログアウト'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton(
              onPressed: () => _showDeleteAccountConfirmation(user),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                textStyle: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: const Text('退会する（アカウント削除）'),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalDocumentsScreen(),
                ),
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('利用規約・プライバシーポリシー'),
              style: TextButton.styleFrom(foregroundColor: AppColors.navy),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントを削除しますか？'),
        content: const Text(
          'アカウントを削除すると、これまでの走行データや保存した住所、ポイントなどがすべて失われ、元に戻せません。本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(authProvider.notifier)
                  .deleteAccount(user.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('アカウントを削除しました。ご利用ありがとうございました。')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('エラーが発生しました。時間を置いて再度お試しください。')),
                );
              }
            },
            child: const Text('削除する', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile(SavedAddress address) {
    return ListTile(
      leading: Icon(
        address.label == '自宅'
            ? Icons.home_outlined
            : address.label == '職場'
            ? Icons.work_outline
            : Icons.location_on_outlined,
        color: AppColors.navy,
      ),
      title: Text(address.label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(address.address, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (address.description.isNotEmpty)
            Text(
              address.description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () => _deleteAddressConfirmation(address),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _showAddressDetails(address),
    );
  }

  Future<void> _navigateToAddressSearch() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressSearchScreen(title: '住所'),
      ),
    );

    if (result != null && mounted) {
      _showSaveAddressDialog(result);
    }
  }

  void _showSaveAddressDialog(Map<String, dynamic> locationData) {
    final labelController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('住所の保存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locationData['address'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: '名前（例: 田中様、自宅、職場）',
                hintText: '名前を入力してください',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '備考（例: 裏口から入る、常連様）',
                hintText: '備考があれば入力してください',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (labelController.text.isEmpty) return;
              Navigator.pop(context);
              final success = await ref
                  .read(addressProvider.notifier)
                  .addAddress(
                    labelController.text,
                    locationData['address'],
                    descriptionController.text,
                    locationData['latitude'],
                    locationData['longitude'],
                  );
              if (success && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('住所を保存しました')));
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAddressDetails(SavedAddress address) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address.label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(address.address, style: const TextStyle(fontSize: 16)),
            if (address.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '備考',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                address.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAddressConfirmation(SavedAddress address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${address.label}の削除'),
        content: const Text('この住所を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(addressProvider.notifier)
                  .deleteAddress(address.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${address.label}を削除しました')),
                );
              }
            },
            child: const Text('削除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.background,
            child: Icon(Icons.person, size: 40, color: AppColors.navy),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? '名前未設定',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.phoneNumber,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (user.email != null)
                  Text(user.email!, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showEditProfileDialog(dynamic user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィール編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'お名前'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(authProvider.notifier)
                  .updateProfile(
                    user.id,
                    nameController.text,
                    emailController.text,
                  );
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('プロフィールを更新しました')));
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
