import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/onboarding_role_screen.dart';
import 'screens/signup_screen.dart';
import 'state/app_profile.dart';
import 'state/app_profile_scope.dart';

void main() {
  runApp(const BrushAndCoinApp());
}

class BrushAndCoinApp extends StatelessWidget {
  const BrushAndCoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProfileScope(
      notifier: AppProfileState(),
      child: MaterialApp(
        title: 'Brush&Coin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/onboarding': (_) => const OnboardingRoleScreen(),
          '/app': (_) => const MainShell(),
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    ArtistsScreen(),
    ProjectsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'Artists',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class Artist {
  final String name;
  final String location;
  final double rating;

  Artist({
    required this.name,
    required this.location,
    required this.rating,
  });
}

class Project {
  final String title;
  final String clientName;
  final ProjectStatus status;
  final List<Milestone> milestones;

  Project({
    required this.title,
    required this.clientName,
    required this.status,
    this.milestones = const [],
  });
}

enum ProjectStatus { inquiry, inProgress, completed }

class Milestone {
  final String title;
  final double amount;
  final bool isReleased;

  Milestone({
    required this.title,
    required this.amount,
    this.isReleased = false,
  });
}

class Review {
  final String reviewerName;
  final double rating;
  final String comment;

  Review({
    required this.reviewerName,
    required this.rating,
    required this.comment,
  });
}

enum PaymentMethodType { gcash, paymaya, paypal, stripe }

class PaymentMethod {
  final PaymentMethodType type;
  final String label;

  PaymentMethod({required this.type, required this.label});
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = [
      Project(
        title: 'Portrait Commission',
        clientName: 'Ana Santos',
        status: ProjectStatus.inProgress,
        milestones: [
          Milestone(title: 'Sketch Approval', amount: 50),
          Milestone(title: 'Final Artwork', amount: 150),
        ],
      ),
      Project(
        title: 'Event Mural',
        clientName: 'Local Café',
        status: ProjectStatus.inquiry,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Brush&Coin',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unified hub for your creative work, clients, and secure payments.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Active Projects',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...projects.map((p) => ProjectCard(project: p)),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                QuickActionChip(
                  icon: Icons.add_circle_outline,
                  label: 'New Project',
                  onTap: () {},
                ),
                QuickActionChip(
                  icon: Icons.map_outlined,
                  label: 'Find Local Events',
                  onTap: () {},
                ),
                QuickActionChip(
                  icon: Icons.payment_outlined,
                  label: 'View Escrow',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  String get statusLabel {
    switch (project.status) {
      case ProjectStatus.inquiry:
        return 'Inquiry';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
    }
  }

  Color statusColor(BuildContext context) {
    switch (project.status) {
      case ProjectStatus.inquiry:
        return Colors.orange;
      case ProjectStatus.inProgress:
        return Colors.blue;
      case ProjectStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountTotal = project.milestones.fold<double>(
      0,
      (sum, m) => sum + m.amount,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Client: ${project.clientName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (amountTotal > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Total escrow: ₱${amountTotal.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final artists = [
      Artist(name: 'Lara Cruz', location: 'Quezon City', rating: 4.9),
      Artist(name: 'Miguel Ramos', location: 'Makati', rating: 4.7),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Artists'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(artist.name.characters.first),
              ),
              title: Text(artist.name),
              subtitle: Text('${artist.location} • ⭐ ${artist.rating}'),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.upload_file),
        label: const Text('Update Portfolio'),
      ),
    );
  }
}

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = [
      Project(
        title: 'Portrait Commission',
        clientName: 'Ana Santos',
        status: ProjectStatus.inProgress,
        milestones: [
          Milestone(title: 'Sketch Approval', amount: 50),
          Milestone(title: 'Final Artwork', amount: 150),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects & Contracts'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final p = projects[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(p.title),
              subtitle: Text('Client: ${p.clientName}'),
              children: [
                for (final m in p.milestones)
                  ListTile(
                    title: Text(m.title),
                    trailing: Text('₱${m.amount.toStringAsFixed(0)}'),
                    leading: Icon(
                      m.isReleased
                          ? Icons.verified
                          : Icons.lock_clock_outlined,
                    ),
                    onTap: () {},
                  ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('View Digital Contract'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversations = [
      'Ana Santos',
      'Local Café',
      'Event Organizer',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final name = conversations[index];
          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: const Text('Tap to view conversation…'),
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}

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
                if (p.birthday != null)
                  'Birthday: ${_fmtDate(p.birthday!)}',
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

