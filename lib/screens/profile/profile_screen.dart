import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../state/app_profile.dart';
import '../../state/app_profile_scope.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileState = AppProfileScope.of(context);
    final p = profileState.profile;

    final paymentMethods = [
      PaymentMethod(type: PaymentMethodType.gcash, label: 'GCash'),
      PaymentMethod(type: PaymentMethodType.paymaya, label: 'PayMaya'),
      PaymentMethod(type: PaymentMethodType.paypal, label: 'PayPal'),
      PaymentMethod(type: PaymentMethodType.stripe, label: 'Stripe'),
    ];

    final roleLabel = p.role == UserRole.artist ? 'Artist' : 'Patron';
    final displayName = [
      p.firstName.trim(),
      p.lastName.trim(),
    ].where((s) => s.isNotEmpty).join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Payments'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(displayName.isEmpty ? 'Your Profile' : displayName),
            subtitle: Text(
              [
                'Role: $roleLabel',
                if (p.username.trim().isNotEmpty) '@${p.username.trim()}',
              ].join(' • '),
            ),
            onTap: () {},
          ),
          if (p.phoneNumber.trim().isNotEmpty || p.birthday != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (p.phoneNumber.trim().isNotEmpty)
                  'Phone: ${p.countryCode} ${p.phoneNumber}',
                if (p.birthday != null) 'Birthday: ${_fmtDate(p.birthday!)}',
              ].join('   '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const Divider(height: 32),
          Text(
            'Payment Methods',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...paymentMethods.map(
            (m) => Card(
              child: SwitchListTile(
                title: Text(m.label),
                subtitle: const Text('Connect / disconnect account'),
                value: true,
                onChanged: (value) {},
              ),
            ),
          ),
          const Divider(height: 32),
          Text(
            'Verification & Reviews',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text('Verify your identity'),
              subtitle: const Text(
                'Build trust with clients and unlock higher-value projects.',
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$mm/$dd/$yyyy';
  }
}
