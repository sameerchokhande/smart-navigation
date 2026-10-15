import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CareConnectApp());
}

const primaryGreen = Color(0xFF276749);
const darkGreen = Color(0xFF183D2B);
const pageBackground = Color(0xFFF5F7F5);
const secondaryText = Color(0xFF66736A);

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
        scaffoldBackgroundColor: pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBackground,
          foregroundColor: darkGreen,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7E0)),
          ),
        ),
      ),
      home: const AppGate(),
    );
  }
}

// Local-only prototype session. This will later be replaced by backend auth.
class LocalSession {
  static const _roleKey = 'careconnect_role';
  static const _nameKey = 'careconnect_name';
  static const _emailKey = 'careconnect_email';
  static const _loggedInKey = 'careconnect_logged_in';
  static const _savedKey = 'careconnect_saved_categories';
  static const _visitsKey = 'careconnect_visit_history';

  static Future<Map<String, String>?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_loggedInKey) != true) return null;
    final role = prefs.getString(_roleKey);
    if (role == null) return null;
    return {
      'role': role,
      'name': prefs.getString(_nameKey) ?? 'CareConnect Member',
      'email': prefs.getString(_emailKey) ?? '',
    };
  }

  static Future<void> saveSession({
    required String role,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setBool(_loggedInKey, true);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
  }

  static Future<Set<String>> readSavedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_savedKey) ?? <String>[]).toSet();
  }

  static Future<void> saveCategories(Set<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, categories.toList());
  }

  static Future<List<String>> readVisits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_visitsKey) ?? <String>[];
  }

  static Future<void> addVisit(String serviceName) async {
    final prefs = await SharedPreferences.getInstance();
    final visits = prefs.getStringList(_visitsKey) ?? <String>[];
    visits.insert(0, '$serviceName • ${DateTime.now().toLocal().toString().substring(0, 16)}');
    await prefs.setStringList(_visitsKey, visits.take(30).toList());
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  Map<String, String>? session;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await LocalSession.readSession();
    if (!mounted) return;
    setState(() {
      session = result;
      loading = false;
    });
  }

  void _onAuthenticated(Map<String, String> newSession) {
    setState(() => session = newSession);
  }

  Future<void> _logout() async {
    await LocalSession.logout();
    if (!mounted) return;
    setState(() => session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }
    if (session == null) {
      return WelcomeScreen(onAuthenticated: _onAuthenticated);
    }
    if (session!['role'] == 'provider') {
      return ProviderNavigation(session: session!, onLogout: _logout);
    }
    return UserNavigation(session: session!, onLogout: _logout);
  }
}

class WelcomeScreen extends StatelessWidget {
  final ValueChanged<Map<String, String>> onAuthenticated;
  const WelcomeScreen({super.key, required this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  height: 104,
                  width: 104,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F0E7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.volunteer_activism, size: 58, color: primaryGreen),
                ),
                const SizedBox(height: 22),
                const Text('CareConnect', style: TextStyle(fontSize: 31, fontWeight: FontWeight.bold, color: darkGreen)),
                const SizedBox(height: 8),
                const Text(
                  'Support when you need it most',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryText, fontSize: 16),
                ),
                const SizedBox(height: 34),
                const Text('Welcome', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: darkGreen)),
                const SizedBox(height: 8),
                const Text('Choose how you want to use CareConnect.', textAlign: TextAlign.center, style: TextStyle(color: secondaryText)),
                const SizedBox(height: 24),
                _RoleCard(
                  icon: Icons.person_outline,
                  title: 'I need support',
                  description: 'Find shelters, food, healthcare and other services.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AuthScreen(role: 'user', onAuthenticated: onAuthenticated),
                  )),
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'I provide services',
                  description: 'Manage a shelter, NGO, food service or support centre.',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AuthScreen(role: 'provider', onAuthenticated: onAuthenticated),
                  )),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mobile prototype • Demo authentication only',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE0E7E0))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: const Color(0xFFE5F0E7), child: Icon(icon, color: primaryGreen, size: 29)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: darkGreen)),
                const SizedBox(height: 5),
                Text(description, style: const TextStyle(color: secondaryText, height: 1.4)),
              ])),
              const Icon(Icons.chevron_right, color: primaryGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final String role;
  final ValueChanged<Map<String, String>> onAuthenticated;
  const AuthScreen({super.key, required this.role, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = false;
  bool obscurePassword = true;
  bool busy = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    final email = emailController.text.trim();
    final name = isLogin
        ? (nameController.text.trim().isEmpty ? email.split('@').first : nameController.text.trim())
        : nameController.text.trim();
    // Prototype only: no server verifies these credentials yet.
    await LocalSession.saveSession(role: widget.role, name: name, email: email);
    if (!mounted) return;
    widget.onAuthenticated({'role': widget.role, 'name': name, 'email': email});
    setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.role == 'provider' ? 'Service Provider' : 'Normal User';
    return Scaffold(
      appBar: AppBar(title: Text('$roleLabel account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, color: primaryGreen, size: 48),
                  const SizedBox(height: 12),
                  Text(isLogin ? 'Welcome back' : 'Create your account', textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: darkGreen)),
                  const SizedBox(height: 8),
                  Text('$roleLabel • local demo account', textAlign: TextAlign.center, style: const TextStyle(color: secondaryText)),
                  const SizedBox(height: 26),
                  if (!isLogin) ...[
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) => !isLogin && (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (value) {
                      if (value == null || !value.contains('@') || !value.contains('.')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 4 ? 'Use at least 4 characters for this demo' : null,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    style: FilledButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isLogin ? 'Login' : 'Create account'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(isLogin ? 'New here? Create an account' : 'Already registered? Login'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For now, credentials are not verified by a server. This screen will be connected to secure backend authentication later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryText, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SupportCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String description;
  const SupportCategory({required this.title, required this.subtitle, required this.icon, required this.color, required this.description});
}

const supportCategories = [
  SupportCategory(title: 'Shelter', subtitle: 'Safe places to stay', icon: Icons.home_outlined, color: Color(0xFF276749), description: 'Find shelters and accommodation support for people in need.'),
  SupportCategory(title: 'Food', subtitle: 'Meals and food support', icon: Icons.restaurant_outlined, color: Color(0xFFB7791F), description: 'Find food distribution points, meal services and food assistance.'),
  SupportCategory(title: 'Healthcare', subtitle: 'Medical assistance', icon: Icons.health_and_safety_outlined, color: Color(0xFF3478A5), description: 'Explore healthcare services and medical assistance options.'),
  SupportCategory(title: 'Employment', subtitle: 'Work and livelihood', icon: Icons.work_outline, color: Color(0xFF7656A5), description: 'Explore employment assistance, skills training and livelihood support.'),
  SupportCategory(title: 'Government Support', subtitle: 'Schemes and assistance', icon: Icons.account_balance_outlined, color: Color(0xFF8A5A44), description: 'Discover government assistance and welfare programmes.'),
];

class AppHeader extends StatelessWidget {
  final String? subtitle;
  const AppHeader({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const CircleAvatar(backgroundColor: primaryGreen, child: Icon(Icons.volunteer_activism, color: Colors.white)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CareConnect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: darkGreen)),
        Text(subtitle ?? 'Support when you need it most', style: const TextStyle(fontSize: 11, color: secondaryText)),
      ])),
    ]);
  }
}

class UserNavigation extends StatefulWidget {
  final Map<String, String> session;
  final Future<void> Function() onLogout;
  const UserNavigation({super.key, required this.session, required this.onLogout});

  @override
  State<UserNavigation> createState() => _UserNavigationState();
}

class _UserNavigationState extends State<UserNavigation> {
  int selectedIndex = 0;
  String selectedCategory = '';
  Set<String> savedCategories = {};
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final result = await LocalSession.readSavedCategories();
    if (!mounted) return;
    setState(() { savedCategories = result; loaded = true; });
  }

  Future<void> toggleSaved(String category) async {
    setState(() {
      if (savedCategories.contains(category)) {
        savedCategories.remove(category);
      } else {
        savedCategories.add(category);
      }
    });
    await LocalSession.saveCategories(savedCategories);
  }

  void openExplore([String category = '']) {
    setState(() { selectedIndex = 1; selectedCategory = category; });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryGreen)));
    final pages = [
      HomeScreen(name: widget.session['name'] ?? 'Member', onExploreCategory: openExplore, onProfile: () => setState(() => selectedIndex = 4)),
      ExploreScreen(initialCategory: selectedCategory, savedCategories: savedCategories, onSave: toggleSaved),
      const MapScreen(),
      SavedScreen(savedCategories: savedCategories, onRemove: toggleSaved, onExplore: () => openExplore()),
      UserProfileScreen(session: widget.session, onLogout: widget.onLogout),
      const AboutScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String name;
  final ValueChanged<String> onExploreCategory;
  final VoidCallback onProfile;
  const HomeScreen({super.key, required this.name, required this.onExploreCategory, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Expanded(child: AppHeader()), IconButton(tooltip: 'Profile', onPressed: onProfile, icon: const Icon(Icons.account_circle_outlined, color: primaryGreen, size: 30))]),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: const Color(0xFFE5F0E7), borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.waving_hand_outlined, size: 34, color: primaryGreen),
            const SizedBox(height: 14),
            Text('Hello, $name', style: const TextStyle(fontSize: 16, color: primaryGreen, fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            const Text('How can we help you today?', style: TextStyle(color: darkGreen, fontSize: 25, height: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Find support services for your needs, all in one place.', style: TextStyle(color: Color(0xFF52665A), fontSize: 15, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 28),
        const Text('Explore support services', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: supportCategories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.22),
          itemBuilder: (context, index) => ServiceCard(category: supportCategories[index], onTap: () => onExploreCategory(supportCategories[index].title)),
        ),
        const SizedBox(height: 28),
        const Text('Tell us what you need', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 8),
        const Text('Describe your situation in your own words.', style: TextStyle(color: secondaryText, fontSize: 14)),
        const SizedBox(height: 14),
        const NeedInputCard(),
        const SizedBox(height: 22),
        const Center(child: Text('English · हिंदी · मराठी', style: TextStyle(color: secondaryText, fontSize: 13))),
      ]),
    ));
  }
}

class ServiceCard extends StatelessWidget {
  final SupportCategory category;
  final VoidCallback onTap;
  const ServiceCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE5EAE5))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(category.icon, color: category.color, size: 30),
            const SizedBox(height: 10),
            Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(category.subtitle, style: const TextStyle(fontSize: 11, color: secondaryText)),
          ]),
        ),
      ),
    );
  }
}

class NeedInputCard extends StatefulWidget {
  const NeedInputCard({super.key});
  @override
  State<NeedInputCard> createState() => _NeedInputCardState();
}

class _NeedInputCardState extends State<NeedInputCard> {
  final controller = TextEditingController();
  @override
  void dispose() { controller.dispose(); super.dispose(); }

  void submitNeed() {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe what support you need.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request saved for this demo. AI matching will be connected later.')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE0E7E0))),
      child: Column(children: [
        TextField(controller: controller, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Example: I need a safe place to sleep tonight...', border: InputBorder.none, filled: false)),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: submitNeed, icon: const Icon(Icons.search), label: const Text('Find Support'), style: FilledButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
      ]),
    );
  }
}

class ExploreScreen extends StatefulWidget {
  final String initialCategory;
  final Set<String> savedCategories;
  final ValueChanged<String> onSave;
  const ExploreScreen({super.key, required this.initialCategory, required this.savedCategories, required this.onSave});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final searchController = TextEditingController();
  String selectedLocation = 'Pune';
  String selectedCategory = '';
  final locations = const ['Pune', 'Mumbai', 'Nashik', 'Other'];

  @override
  void initState() { super.initState(); selectedCategory = widget.initialCategory; }
  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      selectedCategory = widget.initialCategory;
      searchController.clear();
    }
  }
  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final filtered = supportCategories.where((c) =>
      (c.title.toLowerCase().contains(query) || c.subtitle.toLowerCase().contains(query) || c.description.toLowerCase().contains(query)) &&
      (selectedCategory.isEmpty || c.title == selectedCategory)).toList();
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppHeader(),
        const SizedBox(height: 28),
        const Text('Explore support', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 8),
        const Text('Search the types of assistance you need.', style: TextStyle(color: secondaryText)),
        const SizedBox(height: 22),
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search shelter, food, healthcare...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); setState(() {}); }) : null,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedLocation,
          decoration: const InputDecoration(labelText: 'Select city', prefixIcon: Icon(Icons.location_on_outlined)),
          items: locations.map((location) => DropdownMenuItem(value: location, child: Text(location))).toList(),
          onChanged: (value) { if (value != null) setState(() => selectedLocation = value); },
        ),
        const SizedBox(height: 22),
        const Text('Support categories', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 6),
        Text('Selected city: $selectedLocation', style: const TextStyle(color: secondaryText, fontSize: 13)),
        if (selectedCategory.isNotEmpty) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => selectedCategory = ''), icon: const Icon(Icons.arrow_back), label: const Text('Show all categories'))),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('No matching categories found. Try another search.', textAlign: TextAlign.center, style: TextStyle(color: secondaryText))))
        else
          ...filtered.map((category) {
            final isSaved = widget.savedCategories.contains(category.title);
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE5EAE5))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 25, backgroundColor: category.color.withAlpha(25), child: Icon(category.icon, color: category.color)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(category.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: darkGreen)),
                    const SizedBox(height: 5),
                    Text(category.description, style: const TextStyle(color: secondaryText, height: 1.4)),
                    const SizedBox(height: 10),
                    Text('Sample category • Listings will be connected later', style: TextStyle(color: category.color, fontSize: 12, fontWeight: FontWeight.w600)),
                  ])),
                  IconButton(tooltip: isSaved ? 'Remove from saved' : 'Save category', onPressed: () => widget.onSave(category.title), icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: primaryGreen)),
                ]),
              ),
            );
          }),
      ]),
    ));
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final samples = [
      ('Community Shelter', 'Shelter', Icons.home_outlined, 'Sample location • Pune'),
      ('Community Meal Point', 'Food', Icons.restaurant_outlined, 'Sample location • Pune'),
      ('Public Health Centre', 'Healthcare', Icons.local_hospital_outlined, 'Sample location • Pune'),
    ];
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppHeader(),
        const SizedBox(height: 26),
        const Text('Services near you', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 7),
        const Text('Map and nearby service discovery preview.', style: TextStyle(color: secondaryText)),
        const SizedBox(height: 18),
        Container(
          height: 245,
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFE4EDE5), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFD5E1D7))),
          child: Stack(children: [
            Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(22), child: CustomPaint(painter: _MapPatternPainter()))),
            const Positioned(left: 18, top: 18, child: _MapPin(icon: Icons.my_location, label: 'Your location', color: Color(0xFF276749))),
            const Positioned(right: 24, top: 80, child: _MapPin(icon: Icons.home, label: 'Shelter', color: Color(0xFF3478A5))),
            const Positioned(left: 75, bottom: 52, child: _MapPin(icon: Icons.restaurant, label: 'Food', color: Color(0xFFB7791F))),
            const Positioned(right: 25, bottom: 25, child: _MapPin(icon: Icons.local_hospital, label: 'Health', color: Color(0xFF7656A5))),
            const Positioned(bottom: 10, left: 0, right: 0, child: Text('Illustrative map preview — GPS and map tiles are not connected yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: secondaryText))),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Nearby service examples', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 10),
        ...samples.map((s) => Card(
          elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFFE5F0E7), child: Icon(s.$3, color: primaryGreen)),
            title: Text(s.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${s.$2} • ${s.$4}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: Text(s.$1), content: const Text('This is sample content for the mobile UI. Verified provider details and directions will be added after backend and map integration.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))])),
          ),
        )),
        const SizedBox(height: 8),
        const Text('Actual GPS permission, interactive maps, verified providers and directions will be integrated in a later development phase.', style: TextStyle(color: secondaryText, fontSize: 12, height: 1.5)),
      ]),
    ));
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MapPin({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 6)]),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 17, color: color), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]),
  );
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = Colors.white..strokeWidth = 8..strokeCap = StrokeCap.round;
    final thinRoad = Paint()..color = const Color(0xFFD0DED2)..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height * .35), Offset(size.width, size.height * .55), road);
    canvas.drawLine(Offset(size.width * .25, 0), Offset(size.width * .48, size.height), road);
    canvas.drawLine(Offset(size.width * .85, 0), Offset(size.width * .63, size.height), road);
    canvas.drawLine(Offset(0, size.height * .75), Offset(size.width, size.height * .2), road);
    canvas.drawLine(Offset(0, size.height * .35), Offset(size.width, size.height * .55), thinRoad);
    canvas.drawLine(Offset(size.width * .25, 0), Offset(size.width * .48, size.height), thinRoad);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SavedScreen extends StatelessWidget {
  final Set<String> savedCategories;
  final ValueChanged<String> onRemove;
  final VoidCallback onExplore;
  const SavedScreen({super.key, required this.savedCategories, required this.onRemove, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final items = supportCategories.where((c) => savedCategories.contains(c.title)).toList();
    return SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppHeader(),
        const SizedBox(height: 28),
        const Text('Saved items', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 8),
        const Text('Keep useful support categories easy to find.', style: TextStyle(color: secondaryText)),
        const SizedBox(height: 22),
        if (items.isEmpty)
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(22), decoration: const BoxDecoration(color: Color(0xFFE5F0E7), shape: BoxShape.circle), child: const Icon(Icons.bookmark_border, size: 42, color: primaryGreen)),
            const SizedBox(height: 18),
            const Text('Nothing saved yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGreen)),
            const SizedBox(height: 8),
            const Text('Explore categories and tap the bookmark icon to save them here.', textAlign: TextAlign.center, style: TextStyle(color: secondaryText, height: 1.5)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onExplore, icon: const Icon(Icons.explore_outlined), label: const Text('Explore categories')),
          ])))
        else
          Expanded(child: ListView(children: items.map((category) => Card(
            elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(backgroundColor: category.color.withAlpha(25), child: Icon(category.icon, color: category.color)),
              title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(category.subtitle),
              trailing: IconButton(tooltip: 'Remove saved item', onPressed: () => onRemove(category.title), icon: const Icon(Icons.bookmark_remove_outlined, color: primaryGreen)),
            ),
          )).toList())),
      ]),
    ));
  }
}

class UserProfileScreen extends StatefulWidget {
  final Map<String, String> session;
  final Future<void> Function() onLogout;
  const UserProfileScreen({super.key, required this.session, required this.onLogout});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<String> visits = [];
  @override
  void initState() { super.initState(); _loadVisits(); }
  Future<void> _loadVisits() async {
    final result = await LocalSession.readVisits();
    if (mounted) setState(() => visits = result);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.session['name'] ?? 'CareConnect Member';
    final email = widget.session['email'] ?? '';
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), children: [
      const AppHeader(),
      const SizedBox(height: 28),
      const Text('My profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
      const SizedBox(height: 18),
      Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        const CircleAvatar(radius: 38, backgroundColor: Color(0xFFE5F0E7), child: Icon(Icons.person_outline, size: 42, color: primaryGreen)),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 5),
        Text(email, style: const TextStyle(color: secondaryText)),
        const SizedBox(height: 10),
        const Chip(label: Text('Normal User'), avatar: Icon(Icons.person_outline, size: 18)),
      ]))),
      const SizedBox(height: 24),
      const Text('Visit history', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: darkGreen)),
      const SizedBox(height: 8),
      const Text('Only visits you manually mark as completed appear here. This demo does not automatically confirm physical visits.', style: TextStyle(color: secondaryText, fontSize: 12, height: 1.45)),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () async {
          final serviceController = TextEditingController();
          final service = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
            title: const Text('Record a visit'),
            content: TextField(controller: serviceController, decoration: const InputDecoration(labelText: 'Service name', hintText: 'e.g. Community meal centre')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, serviceController.text.trim()), child: const Text('Save visit')),
            ],
          ));
          serviceController.dispose();
          if (service != null && service.isNotEmpty) {
            await LocalSession.addVisit(service);
            await _loadVisits();
          }
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Record a completed visit'),
      ),
      if (visits.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('No visits recorded yet.', style: TextStyle(color: secondaryText))))
      else
        ...visits.map((visit) => Card(elevation: 0, color: Colors.white, child: ListTile(leading: const Icon(Icons.check_circle_outline, color: primaryGreen), title: Text(visit)))),
      const SizedBox(height: 20),
      OutlinedButton.icon(onPressed: () async => widget.onLogout(), icon: const Icon(Icons.logout), label: const Text('Logout'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700)),
    ]));
  }
}

class ProviderNavigation extends StatefulWidget {
  final Map<String, String> session;
  final Future<void> Function() onLogout;
  const ProviderNavigation({super.key, required this.session, required this.onLogout});
  @override
  State<ProviderNavigation> createState() => _ProviderNavigationState();
}

class _ProviderNavigationState extends State<ProviderNavigation> {
  int selectedIndex = 0;
  String serviceType = 'Shelter';
  String serviceName = 'My Support Centre';
  String address = 'Add your service address';
  String price = 'Free';
  String hours = '09:00 AM – 06:00 PM';
  int capacity = 30;
  int occupied = 12;
  int confirmedVisitors = 0;
  bool available = true;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ProviderDashboard(name: widget.session['name'] ?? 'Provider', serviceName: serviceName, serviceType: serviceType, available: available, capacity: capacity, occupied: occupied, visitors: confirmedVisitors, onManage: () => setState(() => selectedIndex = 1)),
      _ProviderServiceEditor(
        serviceName: serviceName, serviceType: serviceType, address: address, price: price, hours: hours,
        capacity: capacity, occupied: occupied, available: available,
        onSave: (data) => setState(() {
          serviceName = data.name; serviceType = data.type; address = data.address; price = data.price;
          hours = data.hours; capacity = data.capacity; occupied = data.occupied; available = data.available;
        }),
      ),
      _ProviderStatsScreen(capacity: capacity, occupied: occupied, visitors: confirmedVisitors, onAddVisit: () => setState(() => confirmedVisitors++)),
      _ProviderProfileScreen(session: widget.session, onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'My Service'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Statistics'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ProviderDashboard extends StatelessWidget {
  final String name, serviceName, serviceType;
  final bool available;
  final int capacity, occupied, visitors;
  final VoidCallback onManage;
  const _ProviderDashboard({required this.name, required this.serviceName, required this.serviceType, required this.available, required this.capacity, required this.occupied, required this.visitors, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final remaining = (capacity - occupied).clamp(0, capacity);
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 24), children: [
      const AppHeader(subtitle: 'Service provider workspace'),
      const SizedBox(height: 26),
      Text('Welcome, $name', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: darkGreen)),
      const SizedBox(height: 7),
      const Text('Manage your service and update availability.', style: TextStyle(color: secondaryText)),
      const SizedBox(height: 22),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFE5F0E7), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.storefront, color: primaryGreen), const SizedBox(width: 8), Expanded(child: Text(serviceName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: darkGreen)))]),
        const SizedBox(height: 8),
        Text(serviceType, style: const TextStyle(color: secondaryText)),
        const SizedBox(height: 12),
        Row(children: [Icon(available ? Icons.check_circle : Icons.pause_circle, color: available ? primaryGreen : Colors.orange), const SizedBox(width: 6), Text(available ? 'Marked available' : 'Currently unavailable', style: const TextStyle(fontWeight: FontWeight.w600))]),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: onManage, icon: const Icon(Icons.edit_outlined), label: const Text('Manage service')),
      ])),
      const SizedBox(height: 22),
      const Text('Current capacity', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: darkGreen)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatCard(title: 'Capacity', value: '$capacity', icon: Icons.groups_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(title: 'Occupied', value: '$occupied', icon: Icons.people_outline)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(title: 'Remaining', value: '$remaining', icon: Icons.event_available_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(title: 'Confirmed visits', value: '$visitors', icon: Icons.how_to_reg_outlined)),
      ]),
      const SizedBox(height: 18),
      const Text('Capacity and availability are manually managed in this prototype. Statistics are not connected to verified real-world visits.', style: TextStyle(color: secondaryText, fontSize: 12, height: 1.5)),
    ]));
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5EAE5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: primaryGreen),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkGreen)),
      Text(title, style: const TextStyle(color: secondaryText, fontSize: 12)),
    ]),
  );
}

class _ProviderServiceEditor extends StatefulWidget {
  final String serviceName, serviceType, address, price, hours;
  final int capacity, occupied;
  final bool available;
  final ValueChanged<_ServiceData> onSave;
  const _ProviderServiceEditor({required this.serviceName, required this.serviceType, required this.address, required this.price, required this.hours, required this.capacity, required this.occupied, required this.available, required this.onSave});

  @override
  State<_ProviderServiceEditor> createState() => _ProviderServiceEditorState();
}

class _ProviderServiceEditorState extends State<_ProviderServiceEditor> {
  late TextEditingController nameController, addressController, hoursController;
  late String type, price;
  late int capacity, occupied;
  late bool available;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.serviceName);
    addressController = TextEditingController(text: widget.address);
    hoursController = TextEditingController(text: widget.hours);
    type = widget.serviceType; price = widget.price; capacity = widget.capacity; occupied = widget.occupied; available = widget.available;
  }
  @override
  void dispose() { nameController.dispose(); addressController.dispose(); hoursController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 24), children: [
      const AppHeader(subtitle: 'Edit service listing'),
      const SizedBox(height: 26),
      const Text('My service', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
      const SizedBox(height: 8),
      const Text('Edit the details that will appear on your service profile. Changes are stored in memory for this demo session.', style: TextStyle(color: secondaryText, height: 1.4)),
      const SizedBox(height: 20),
      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Service / organisation name', prefixIcon: Icon(Icons.storefront_outlined))),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: type,
        decoration: const InputDecoration(labelText: 'Service type', prefixIcon: Icon(Icons.category_outlined)),
        items: const ['Shelter', 'Food', 'Healthcare', 'Employment', 'Government Support', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) { if (v != null) setState(() => type = v); },
      ),
      const SizedBox(height: 14),
      TextField(controller: addressController, maxLines: 2, decoration: const InputDecoration(labelText: 'Service address / area', prefixIcon: Icon(Icons.location_on_outlined))),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: price,
        decoration: const InputDecoration(labelText: 'Pricing', prefixIcon: Icon(Icons.currency_rupee)),
        items: const ['Free', 'Paid', 'Free and paid'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) { if (v != null) setState(() => price = v); },
      ),
      const SizedBox(height: 14),
      TextField(controller: hoursController, decoration: const InputDecoration(labelText: 'Operating hours', prefixIcon: Icon(Icons.access_time))),
      const SizedBox(height: 20),
      const Text('Capacity management', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: darkGreen)),
      const SizedBox(height: 8),
      _NumberStepper(label: 'Total capacity', value: capacity, min: 1, onChanged: (v) => setState(() { capacity = v; if (occupied > capacity) occupied = capacity; })),
      _NumberStepper(label: 'Currently occupied', value: occupied, min: 0, max: capacity, onChanged: (v) => setState(() => occupied = v)),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Service currently available'), subtitle: const Text('Update this manually when circumstances change.'), trailing: Switch(value: available, activeThumbColor: primaryGreen, onChanged: (v) => setState(() => available = v))),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () {
          if (nameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a service name.')));
            return;
          }
          widget.onSave(_ServiceData(name: nameController.text.trim(), type: type, address: addressController.text.trim(), price: price, hours: hoursController.text.trim(), capacity: capacity, occupied: occupied, available: available));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service details updated for this demo session.')));
        },
        icon: const Icon(Icons.save_outlined), label: const Text('Save service details'),
      ),
    ]));
  }
}

class _NumberStepper extends StatelessWidget {
  final String label;
  final int value, min;
  final int? max;
  final ValueChanged<int> onChanged;
  const _NumberStepper({required this.label, required this.value, required this.min, this.max, required this.onChanged});
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
      IconButton(onPressed: value > min ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
      Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      IconButton(onPressed: max == null || value < max! ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_circle_outline, color: primaryGreen)),
    ])),
  );
}

class _ServiceData {
  final String name, type, address, price, hours;
  final int capacity, occupied;
  final bool available;
  const _ServiceData({required this.name, required this.type, required this.address, required this.price, required this.hours, required this.capacity, required this.occupied, required this.available});
}

class _ProviderStatsScreen extends StatelessWidget {
  final int capacity, occupied, visitors;
  final VoidCallback onAddVisit;
  const _ProviderStatsScreen({required this.capacity, required this.occupied, required this.visitors, required this.onAddVisit});

  @override
  Widget build(BuildContext context) {
    final remaining = (capacity - occupied).clamp(0, capacity);
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 24), children: [
      const AppHeader(subtitle: 'Service statistics'),
      const SizedBox(height: 26),
      const Text('Service statistics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
      const SizedBox(height: 8),
      const Text('A simple dashboard for manually maintained figures.', style: TextStyle(color: secondaryText)),
      const SizedBox(height: 22),
      _StatCard(title: 'Confirmed physical visits', value: '$visitors', icon: Icons.how_to_reg_outlined),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(title: 'Total capacity', value: '$capacity', icon: Icons.groups_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(title: 'Occupied', value: '$occupied', icon: Icons.people_outline)),
      ]),
      const SizedBox(height: 10),
      _StatCard(title: 'Remaining spaces', value: '$remaining', icon: Icons.event_available_outlined),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: onAddVisit, icon: const Icon(Icons.add), label: const Text('Record confirmed physical visit')),
      const SizedBox(height: 12),
      const Text('Use this control only when a physical visit has been confirmed. Map views, profile views and directions must not count as visits. The prototype counter resets if the app session is recreated.', style: TextStyle(color: secondaryText, fontSize: 12, height: 1.5)),
    ]));
  }
}

class _ProviderProfileScreen extends StatelessWidget {
  final Map<String, String> session;
  final Future<void> Function() onLogout;
  const _ProviderProfileScreen({required this.session, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), children: [
      const AppHeader(subtitle: 'Provider account'),
      const SizedBox(height: 28),
      const Text('Provider profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkGreen)),
      const SizedBox(height: 18),
      Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        const CircleAvatar(radius: 38, backgroundColor: Color(0xFFE5F0E7), child: Icon(Icons.volunteer_activism_outlined, size: 42, color: primaryGreen)),
        const SizedBox(height: 12),
        Text(session['name'] ?? 'Service Provider', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 5),
        Text(session['email'] ?? '', style: const TextStyle(color: secondaryText)),
        const SizedBox(height: 10),
        const Chip(label: Text('Service Provider'), avatar: Icon(Icons.storefront_outlined, size: 18)),
      ]))),
      const SizedBox(height: 14),
      const Card(elevation: 0, color: Colors.white, child: ListTile(leading: Icon(Icons.verified_user_outlined, color: primaryGreen), title: Text('Verification status'), subtitle: Text('Not verified — verification workflow will be added with backend integration.'))),
      const SizedBox(height: 20),
      OutlinedButton.icon(onPressed: () async => onLogout(), icon: const Icon(Icons.logout), label: const Text('Logout'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red)),
    ]));
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppHeader(),
        const SizedBox(height: 30),
        Center(child: Container(width: 100, height: 100, decoration: BoxDecoration(color: const Color(0xFFE5F0E7), borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.volunteer_activism, size: 54, color: primaryGreen))),
        const SizedBox(height: 18),
        const Center(child: Text('About CareConnect', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: darkGreen))),
        const SizedBox(height: 12),
        const Text('CareConnect is a social-impact project designed to help people find support services through one accessible mobile platform.', textAlign: TextAlign.center, style: TextStyle(color: secondaryText, fontSize: 15, height: 1.6)),
        const SizedBox(height: 28),
        const Text('Our goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 14),
        const AboutFeature(icon: Icons.home_outlined, title: 'Access to essential services', description: 'Help people discover shelter, food, healthcare and employment support.'),
        const AboutFeature(icon: Icons.psychology_outlined, title: 'Intelligent assistance', description: 'Plan to add AI-powered understanding and matching of support needs.'),
        const AboutFeature(icon: Icons.map_outlined, title: 'Location-aware discovery', description: 'Plan to connect verified resource locations and relevant geographic information.'),
        const AboutFeature(icon: Icons.storefront_outlined, title: 'Provider tools', description: 'Service providers can manage basic details, capacity, pricing and availability in this prototype.'),
        const SizedBox(height: 24),
        const Text('Supported languages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 10),
        const Wrap(spacing: 8, runSpacing: 8, children: [LanguageChip(label: 'English'), LanguageChip(label: 'हिंदी'), LanguageChip(label: 'मराठी')]),
        const SizedBox(height: 24),
        const Text('Prototype note: Login, profile, saved categories and visit history use local device storage where implemented. Provider service edits and provider statistics are demo data. Live GPS, real maps, verified listings, AI matching, server authentication and database sync are not connected yet.', style: TextStyle(color: secondaryText, fontSize: 13, height: 1.5)),
      ]),
    ));
  }
}

class AboutFeature extends StatelessWidget {
  final IconData icon;
  final String title, description;
  const AboutFeature({super.key, required this.icon, required this.title, required this.description});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFE5F0E7), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: primaryGreen)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkGreen)),
        const SizedBox(height: 5),
        Text(description, style: const TextStyle(color: secondaryText, height: 1.45)),
      ])),
    ]),
  );
}

class LanguageChip extends StatelessWidget {
  final String label;
  const LanguageChip({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Chip(
    avatar: const Icon(Icons.language, size: 18, color: primaryGreen),
    label: Text(label),
    backgroundColor: const Color(0xFFE5F0E7),
    side: BorderSide.none,
  );
}
