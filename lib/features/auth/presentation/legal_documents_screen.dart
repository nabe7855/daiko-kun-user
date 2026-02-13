import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('法的文書'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDocumentCard(
            context,
            title: '利用規約',
            icon: Icons.description,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TermsOfServiceScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDocumentCard(
            context,
            title: 'プライバシーポリシー',
            icon: Icons.privacy_tip,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDocumentCard(
            context,
            title: '特定商取引法に基づく表記',
            icon: Icons.gavel,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CommercialTransactionsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: AppColors.navy, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用規約'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ダイコー君 利用規約',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '第1条（適用）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '本規約は、ユーザーと当社との間の本サービスの利用に関わる一切の関係に適用されるものとします。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第2条（利用登録）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '1. 本サービスにおいては、登録希望者が本規約に同意の上、当社の定める方法によって利用登録を申請し、当社がこれを承認することによって、利用登録が完了するものとします。\n'
              '2. 当社は、利用登録の申請者に以下の事由があると判断した場合、利用登録の申請を承認しないことがあり、その理由については一切の開示義務を負わないものとします。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第3条（禁止事項）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。\n'
              '1. 法令または公序良俗に違反する行為\n'
              '2. 犯罪行為に関連する行為\n'
              '3. 当社、本サービスの他のユーザー、または第三者のサーバーまたはネットワークの機能を破壊したり、妨害したりする行為\n'
              '4. 当社のサービスの運営を妨害するおそれのある行為\n'
              '5. 他のユーザーに関する個人情報等を収集または蓄積する行為\n'
              '6. 不正アクセスをし、またはこれを試みる行為\n'
              '7. 他のユーザーに成りすます行為\n'
              '8. その他、当社が不適切と判断する行為',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第4条（本サービスの提供の停止等）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。\n'
              '1. 本サービスにかかるコンピュータシステムの保守点検または更新を行う場合\n'
              '2. 地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合\n'
              '3. コンピュータまたは通信回線等が事故により停止した場合\n'
              '4. その他、当社が本サービスの提供が困難と判断した場合',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第5条（利用制限および登録抹消）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '当社は、ユーザーが以下のいずれかに該当する場合には、事前の通知なく、ユーザーに対して、本サービスの全部もしくは一部の利用を制限し、またはユーザーとしての登録を抹消することができるものとします。\n'
              '1. 本規約のいずれかの条項に違反した場合\n'
              '2. 登録事項に虚偽の事実があることが判明した場合\n'
              '3. その他、当社が本サービスの利用を適当でないと判断した場合',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 24),
            Text(
              '最終更新日: 2026年2月13日',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'プライバシーポリシー',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '当社は、本サービスにおけるユーザーの個人情報の取扱いについて、以下のとおりプライバシーポリシー（以下、「本ポリシー」といいます。）を定めます。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第1条（個人情報）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '「個人情報」とは、個人情報保護法にいう「個人情報」を指すものとし、生存する個人に関する情報であって、当該情報に含まれる氏名、生年月日、住所、電話番号、連絡先その他の記述等により特定の個人を識別できる情報及び容貌、指紋、声紋にかかるデータ、及び健康保険証の保険者番号などの当該情報単体から特定の個人を識別できる情報（個人識別情報）を指します。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第2条（個人情報の収集方法）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '当社は、ユーザーが利用登録をする際に氏名、電話番号、メールアドレスなどの個人情報をお尋ねすることがあります。また、ユーザーと提携先などとの間でなされたユーザーの個人情報を含む取引記録や決済に関する情報を、当社の提携先（情報提供元、広告主、広告配信先などを含みます。以下、｢提携先｣といいます。）などから収集することがあります。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第3条（個人情報を収集・利用する目的）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '当社が個人情報を収集・利用する目的は、以下のとおりです。\n'
              '1. 本サービスの提供・運営のため\n'
              '2. ユーザーからのお問い合わせに回答するため（本人確認を行うことを含む）\n'
              '3. ユーザーが利用中のサービスの新機能、更新情報、キャンペーン等及び当社が提供する他のサービスの案内のメールを送付するため\n'
              '4. メンテナンス、重要なお知らせなど必要に応じたご連絡のため\n'
              '5. 利用規約に違反したユーザーや、不正・不当な目的でサービスを利用しようとするユーザーの特定をし、ご利用をお断りするため\n'
              '6. ユーザーにご自身の登録情報の閲覧や変更、削除、ご利用状況の閲覧を行っていただくため\n'
              '7. 上記の利用目的に付随する目的',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第4条（利用目的の変更）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '当社は、利用目的が変更前と関連性を有すると合理的に認められる場合に限り、個人情報の利用目的を変更するものとします。利用目的の変更を行った場合には、変更後の目的について、当社所定の方法により、ユーザーに通知し、または本ウェブサイト上に公表するものとします。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第5条（個人情報の第三者提供）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '当社は、次に掲げる場合を除いて、あらかじめユーザーの同意を得ることなく、第三者に個人情報を提供することはありません。ただし、個人情報保護法その他の法令で認められる場合を除きます。\n'
              '1. 人の生命、身体または財産の保護のために必要がある場合であって、本人の同意を得ることが困難であるとき\n'
              '2. 公衆衛生の向上または児童の健全な育成の推進のために特に必要がある場合であって、本人の同意を得ることが困難であるとき\n'
              '3. 国の機関もしくは地方公共団体またはその委託を受けた者が法令の定める事務を遂行することに対して協力する必要がある場合であって、本人の同意を得ることにより当該事務の遂行に支障を及ぼすおそれがあるとき',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第6条（個人情報の開示）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '当社は、本人から個人情報の開示を求められたときは、本人に対し、遅滞なくこれを開示します。ただし、開示することにより次のいずれかに該当する場合は、その全部または一部を開示しないこともあり、開示しない決定をした場合には、その旨を遅滞なく通知します。\n'
              '1. 本人または第三者の生命、身体、財産その他の権利利益を害するおそれがある場合\n'
              '2. 当社の業務の適正な実施に著しい支障を及ぼすおそれがある場合\n'
              '3. その他法令に違反することとなる場合',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第7条（個人情報の訂正および削除）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'ユーザーは、当社の保有する自己の個人情報が誤った情報である場合には、当社が定める手続きにより、当社に対して個人情報の訂正、追加または削除（以下、「訂正等」といいます。）を請求することができます。当社は、ユーザーから前項の請求を受けてその請求に応じる必要があると判断した場合には、遅滞なく、当該個人情報の訂正等を行うものとします。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '第8条（個人情報の利用停止等）',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '当社は、本人から、個人情報が、利用目的の範囲を超えて取り扱われているという理由、または不正の手段により取得されたものであるという理由により、その利用の停止または消去（以下、「利用停止等」といいます。）を求められた場合には、遅滞なく必要な調査を行います。前項の調査結果に基づき、その請求に応じる必要があると判断した場合には、遅滞なく、当該個人情報の利用停止等を行います。',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 24),
            Text(
              '最終更新日: 2026年2月13日',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class CommercialTransactionsScreen extends StatelessWidget {
  const CommercialTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('特定商取引法に基づく表記'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '特定商取引法に基づく表記',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _InfoRow(label: '販売業者', value: '株式会社ダイコー君'),
            _InfoRow(label: '運営統括責任者', value: '代表取締役 山田太郎'),
            _InfoRow(label: '所在地', value: '〒100-0001 東京都千代田区千代田1-1-1'),
            _InfoRow(label: '電話番号', value: '03-1234-5678'),
            _InfoRow(label: 'メールアドレス', value: 'support@daiko-kun.jp'),
            _InfoRow(label: '販売価格', value: 'サービス利用時に表示される料金に準じます'),
            _InfoRow(label: '支払方法', value: 'クレジットカード、現金'),
            _InfoRow(label: '支払時期', value: 'サービス利用後、即時決済'),
            _InfoRow(label: 'サービス提供時期', value: '予約確定後、指定された日時'),
            _InfoRow(
              label: 'キャンセルについて',
              value: '利用開始前であればキャンセル可能です。利用開始後のキャンセルはできません。',
            ),
            SizedBox(height: 24),
            Text(
              '最終更新日: 2026年2月13日',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
