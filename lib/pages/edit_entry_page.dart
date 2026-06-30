import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../l10n/app_localizations.dart';
import '../platform/platform_capabilities.dart';
import '../models/password_entry.dart';
import '../models/custom_category.dart';
import '../services/password_generator.dart';
import '../services/category_service.dart';
import '../services/auto_close_service.dart';
import '../services/premium_service.dart';
import '../services/onboarding_service.dart';
import '../widgets/coach_mark_system.dart';
import '../widgets/premium_badge.dart';
import '../app/app.dart';
import 'premium_page.dart';

class EditEntryPage extends StatefulWidget {
  const EditEntryPage({super.key, this.entry, this.startTutorial = false, this.existingUsernames});
  final PasswordEntry? entry;
  final bool startTutorial;
  final List<String>? existingUsernames;

  @override
  State<EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<EditEntryPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _url;
  late final TextEditingController _notes;
  late final TextEditingController _tags;
  bool _obscurePassword = true;
  String? _selectedCategory;
  final _categoryService = CategoryService();
  final _premiumService = PremiumService();
  List<CustomCategory> _categories = [];
  List<Map<String, String>> _additionalPasswords = [];
  String? _selectedEmoji;
  Color _selectedIconColor = PassKeyraColors.primary;
  List<String> _usernameSuggestions = const [];

  late final AnimationController _coachPulseController;
  final _emojiButtonKey          = GlobalKey();
  final _addPasswordButtonKey    = GlobalKey();
  final _nameFieldKey            = GlobalKey();
  final _categoryFieldKey        = GlobalKey();
  final _usernameFieldKey        = GlobalKey();
  final _passwordRowKey          = GlobalKey();
  final _urlFieldKey             = GlobalKey();
  final _notesFieldKey           = GlobalKey();
  final _tagsFieldKey            = GlobalKey();
  final _saveButtonKey           = GlobalKey();
  bool _isTutorialRunning = false;
  String? _activeTargetKey;

  @override
  void initState() {
    super.initState();
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    if (widget.startTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runEditEntryTutorial());
    } else if (widget.entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndRunFirstEntryTutorial());
    }
    if (widget.existingUsernames != null) {
      final freq = <String, int>{};
      for (final u in widget.existingUsernames!) {
        if (u.isNotEmpty) freq[u] = (freq[u] ?? 0) + 1;
      }
      _usernameSuggestions = freq.keys.toList()
        ..sort((a, b) => freq[b]!.compareTo(freq[a]!));
    }
    final e = widget.entry;
    _name = TextEditingController(text: e?.name ?? '');
    _username = TextEditingController(text: e?.username ?? '');
    _password = TextEditingController(text: e?.password ?? '');
    _url = TextEditingController(text: e?.url ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _tags = TextEditingController(text: (e?.tags ?? []).join(','));
    _selectedCategory = e?.category;
    _additionalPasswords = List<Map<String, String>>.from(e?.additionalPasswords ?? []);
    _selectedEmoji = e?.emoji;
    if (e?.iconColor != null) {
      _selectedIconColor = Color(int.parse(e!.iconColor!.replaceFirst('#', '0xFF')));
    }
    _categoryService.addListener(_loadCategories);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categories = _categoryService.getAllCategories();
    });
  }

  @override
  void dispose() {
    _coachPulseController.dispose();
    _categoryService.removeListener(_loadCategories);
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _url.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _runEditEntryTutorial() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() { _isTutorialRunning = true; _activeTargetKey = 'emoji'; });

    final result1 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _emojiButtonKey,
      pulseController: _coachPulseController,
      title: l10n.premiumTutorialEmojiTitle,
      message: l10n.premiumTutorialEmojiMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '1 / 2',
    );

    if (!mounted) return;
    if (result1 != CoachStepResult.primary) {
      setState(() { _isTutorialRunning = false; _activeTargetKey = null; });
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _activeTargetKey = 'passwords');

    await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _addPasswordButtonKey,
      pulseController: _coachPulseController,
      title: l10n.premiumTutorialMultiPasswordTitle,
      message: l10n.premiumTutorialMultiPasswordMessage,
      primaryLabel: l10n.onboardingFinish,
      stepIndicator: '2 / 2',
    );

    if (!mounted) return;
    setState(() { _isTutorialRunning = false; _activeTargetKey = null; });
    Navigator.of(context).pop(true);
  }

  void _endTutorial() {
    if (mounted) setState(() { _isTutorialRunning = false; _activeTargetKey = null; });
    // Marquer le tutoriel comme complété quel que soit le mode de sortie
    // (Terminer OU Passer). Plus jamais d'auto-relance — l'utilisateur peut
    // le rejouer manuellement depuis le Mode Découverte.
    OnboardingService.instance.markDiscoveryCompleted(DiscoveryTutorial.firstEntry);
  }

  Future<void> _checkAndRunFirstEntryTutorial() async {
    if (!mounted) return;
    final done = await OnboardingService.instance.isDiscoveryCompleted(DiscoveryTutorial.firstEntry);
    if (!done && mounted) await _runFirstEntryTutorialPhase1();
  }

  Future<void> _runFirstEntryTutorialPhase1() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() { _isTutorialRunning = true; _activeTargetKey = 'name'; });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Step 1 — Nom
    final r1 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _nameFieldKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialNameTitle, message: l10n.firstEntryTutorialNameMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '1 / 10',
    );
    if (!mounted || r1 != CoachStepResult.primary) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'category');

    // Step 2 — Catégorie
    final r2 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _categoryFieldKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialCategoryTitle, message: l10n.firstEntryTutorialCategoryMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '2 / 10',
    );
    if (!mounted || r2 != CoachStepResult.primary) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'username');

    // Step 3 — Identifiant
    final r3 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _usernameFieldKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialUsernameTitle, message: l10n.firstEntryTutorialUsernameMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '3 / 10',
    );
    if (!mounted || r3 != CoachStepResult.primary) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'password');

    // Step 4 — Mot de passe → ouvre le générateur en mode tutoriel
    final r4 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _passwordRowKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialPasswordTitle, message: l10n.firstEntryTutorialPasswordMessage,
      primaryLabel: l10n.firstEntryTutorialOpenGenerator, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '4 / 10',
    );
    if (!mounted || r4 != CoachStepResult.primary) { _endTutorial(); return; }

    // Ouvrir le générateur en mode tutoriel
    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _PasswordGeneratorDialog(startTutorial: true),
    );
    if (options != null && mounted) {
      final pwd = PasswordGenerator.generate(
        length: options['length'] as int,
        includeLower: options['lower'] as bool,
        includeUpper: options['upper'] as bool,
        includeDigits: options['digits'] as bool,
        includeSymbols: options['symbols'] as bool,
      );
      setState(() => _password.text = pwd);
    }
    if (!mounted) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'url');

    // Step 5 — URL
    final r5 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _urlFieldKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialUrlTitle, message: l10n.firstEntryTutorialUrlMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '5 / 10',
    );
    if (!mounted || r5 != CoachStepResult.primary) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'notes');

    // Step 6 — Notes
    final r6 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _notesFieldKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialNotesTitle, message: l10n.firstEntryTutorialNotesMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '6 / 10',
    );
    if (!mounted || r6 != CoachStepResult.primary) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'tags');

    // Step 7 — Tags
    final r7 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _tagsFieldKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialTagsTitle, message: l10n.firstEntryTutorialTagsMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '7 / 10',
    );
    if (!mounted || r7 != CoachStepResult.primary) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'emoji');

    // Step 8 — Icône personnalisée
    final r8 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _emojiButtonKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialEmojiTitle, message: l10n.firstEntryTutorialEmojiMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '8 / 10',
    );
    if (!mounted || r8 != CoachStepResult.primary) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'passwords');

    // Step 9 — Mots de passe additionnels
    final r9 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _addPasswordButtonKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialAdditionalPasswordsTitle, message: l10n.firstEntryTutorialAdditionalPasswordsMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '9 / 10',
    );
    if (!mounted || r9 != CoachStepResult.primary) { _endTutorial(); return; }
    setState(() => _activeTargetKey = 'save');

    // Step 10 — Bouton valider
    await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _saveButtonKey, pulseController: _coachPulseController,
      title: l10n.firstEntryTutorialSaveTitle, message: l10n.firstEntryTutorialSaveMessage,
      primaryLabel: l10n.firstEntryTutorialSaveAction,
      stepIndicator: '10 / 10',
    );

    if (!mounted) return;
    await OnboardingService.instance.requestFirstEntryPhase2();
    _endTutorial();
  }

  Future<void> _generate({bool startTutorial = false}) async {
    // Afficher un dialogue pour personnaliser le mot de passe
    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PasswordGeneratorDialog(startTutorial: startTutorial),
    );
    
    if (options != null) {
      final pwd = PasswordGenerator.generate(
        length: options['length'] as int,
        includeLower: options['lower'] as bool,
        includeUpper: options['upper'] as bool,
        includeDigits: options['digits'] as bool,
        includeSymbols: options['symbols'] as bool,
      );
      setState(() => _password.text = pwd);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.entry;
    final entry = PasswordEntry(
      id: base?.id,
      name: _name.text.trim(),
      username: _username.text.trim(),
      password: _password.text,
      url: _url.text.trim().isEmpty ? null : _url.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      tags: _tags.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      category: _selectedCategory,
      additionalPasswords: _additionalPasswords,
      emoji: _selectedEmoji,
      iconColor: _selectedEmoji != null
          ? '#${_selectedIconColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}'
          : null,
    );
    Navigator.of(context).pop(entry);
  }

  void _addAdditionalPassword() async {
    if (!_premiumService.isPremium) {
      _showPremiumDialog();
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AdditionalPasswordDialog(
        existingPasswords: _additionalPasswords,
      ),
    );

    if (result != null) {
      setState(() {
        _additionalPasswords.add(result);
      });
    }
  }

  void _editAdditionalPassword(int index) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AdditionalPasswordDialog(
        initialData: _additionalPasswords[index],
        existingPasswords: _additionalPasswords,
      ),
    );

    if (result != null) {
      setState(() {
        _additionalPasswords[index] = result;
      });
    }
  }

  void _deleteAdditionalPassword(int index) {
    setState(() {
      _additionalPasswords.removeAt(index);
    });
  }

  void _showPremiumDialog() {
    showPremiumLockedDialog(
      context,
      featureName: 'Mots de passe additionnels',
      customMessage:
          'Les mots de passe additionnels sont réservés aux utilisateurs Premium. '
          'Passez à Premium pour débloquer cette fonctionnalité et bien plus encore !',
    );
  }

  void _showEmojiPicker() {
    if (!_premiumService.isPremium) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: PassKeyraColors.primary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.premium),
            ],
          ),
          content: Text(AppLocalizations.of(context)!.customIconsPremiumFeature),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, PremiumPage.route);
              },
              child: Text(AppLocalizations.of(context)!.viewPremium),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: 400,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              setState(() => _selectedEmoji = emoji.emoji);
              Navigator.pop(context);
            },
            config: const Config(
              height: 256,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                emojiSizeMax: 28,
                columns: 7,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construit les items du dropdown de categorie en respectant la hierarchie :
  /// chaque categorie racine est suivie de ses sous-categories, indentees.
  List<DropdownMenuItem<String>> _buildCategoryDropdownItems() {
    final items = <DropdownMenuItem<String>>[];

    void addCategoryAndChildren(CustomCategory cat, int depth) {
      items.add(DropdownMenuItem<String>(
        value: cat.name,
        child: Row(
          children: [
            SizedBox(width: depth * 20.0),
            if (depth > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.subdirectory_arrow_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            if (cat.isEmoji)
              Text(cat.emoji!, style: const TextStyle(fontSize: 20))
            else
              Icon(cat.icon, color: cat.color, size: 20),
            const SizedBox(width: 12),
            Flexible(child: Text(cat.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ));
      for (final child in _categoryService.getChildren(cat.id)) {
        addCategoryAndChildren(child, depth + 1);
      }
    }

    for (final root in _categoryService.getRootCategories()) {
      addCategoryAndChildren(root, 0);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CallbackShortcuts(
      // Force Esc = retour, même si le Form ou un TextField consomme l'event
      // (DismissIntent default Flutter peut intercepter et empêcher la remontée
      // au CallbackShortcuts global).
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? l10n.newEntry : l10n.editEntry),
        actions: isDesktop
            ? null
            : [
                CoachMarkSystem.buildHalo(
                  key: _saveButtonKey,
                  pulseController: _coachPulseController,
                  isActive: _isTutorialRunning && _activeTargetKey == 'save',
                  borderRadius: BorderRadius.circular(20),
                  child: IconButton(onPressed: _save, icon: const Icon(Icons.check)),
                ),
              ],
      ),
      bottomNavigationBar: isDesktop
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    CoachMarkSystem.buildHalo(
                      key: _saveButtonKey,
                      pulseController: _coachPulseController,
                      isActive:
                          _isTutorialRunning && _activeTargetKey == 'save',
                      borderRadius: BorderRadius.circular(8),
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: GestureDetector(
        onTap: () => AutoCloseService.instance.onUserActivity(),
        onPanStart: (_) => AutoCloseService.instance.onUserActivity(),
        behavior: HitTestBehavior.translucent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            AutoCloseService.instance.onUserActivity();
            return false;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
              TextFormField(
                key: _nameFieldKey,
                controller: _name,
                inputFormatters: [LengthLimitingTextInputFormatter(256)],
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.name, border: const OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.required : null,
                onChanged: (_) => AutoCloseService.instance.onUserActivity(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: _categoryFieldKey,
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.category,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.folder_outlined),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.other),
                  ),
                  // Categories ordonnees hierarchiquement : chaque parent suivi
                  // de ses enfants, indentes selon la profondeur. Permet de
                  // choisir une sous-categorie pour une entree.
                  ..._buildCategoryDropdownItems(),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  AutoCloseService.instance.onUserActivity();
                },
              ),
              const SizedBox(height: 12),
              _usernameSuggestions.isEmpty
                ? TextFormField(
                    key: _usernameFieldKey,
                    controller: _username,
                    inputFormatters: [LengthLimitingTextInputFormatter(512)],
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.username, border: const OutlineInputBorder()),
                    onChanged: (_) => AutoCloseService.instance.onUserActivity(),
                  )
                : Autocomplete<String>(
                    initialValue: _username.value,
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      final query = textEditingValue.text.toLowerCase();
                      return _usernameSuggestions.where((s) => s.toLowerCase().contains(query));
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        key: _usernameFieldKey,
                        controller: controller,
                        focusNode: focusNode,
                        inputFormatters: [LengthLimitingTextInputFormatter(512)],
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.username, border: const OutlineInputBorder()),
                        onChanged: (v) {
                          _username.text = v;
                          AutoCloseService.instance.onUserActivity();
                        },
                      );
                    },
                    onSelected: (value) {
                      _username.text = value;
                    },
                  ),
              const SizedBox(height: 12),
              Row(
                key: _passwordRowKey,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      inputFormatters: [LengthLimitingTextInputFormatter(1024)],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          tooltip: _obscurePassword ? AppLocalizations.of(context)!.showPassword : AppLocalizations.of(context)!.hidePassword,
                        ),
                      ),
                      validator: (v) {
                        // Mitigation L2 : autoriser les passphrases avec espaces.
                        // Aucune validation cote formulaire ; le password peut contenir
                        // n'importe quel caractere.
                        return null;
                      },
                      onChanged: (_) => AutoCloseService.instance.onUserActivity(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.generatePassword,
                    onPressed: _generate,
                    icon: const Icon(Icons.autorenew),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: _urlFieldKey,
                controller: _url,
                inputFormatters: [LengthLimitingTextInputFormatter(2048)],
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.url, border: const OutlineInputBorder()),
                onChanged: (_) => AutoCloseService.instance.onUserActivity(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: _notesFieldKey,
                controller: _notes,
                maxLines: 4,
                inputFormatters: [LengthLimitingTextInputFormatter(4096)],
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.notes, border: const OutlineInputBorder()),
                onChanged: (_) => AutoCloseService.instance.onUserActivity(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: _tagsFieldKey,
                controller: _tags,
                inputFormatters: [LengthLimitingTextInputFormatter(1024)],
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.tags, border: const OutlineInputBorder()),
                onChanged: (_) => AutoCloseService.instance.onUserActivity(),
              ),
              const SizedBox(height: 24),

              // Section icône personnalisée (Premium)
              Row(
                children: [
                  Icon(Icons.emoji_emotions_outlined, color: PassKeyraColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.customIcon,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PassKeyraColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!_premiumService.isPremium) const PremiumBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Affichage de l'emoji sélectionné
              if (_selectedEmoji != null)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: PassKeyraColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedIconColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _selectedEmoji!,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.iconSelected,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: PassKeyraColors.error),
                          onPressed: () => setState(() => _selectedEmoji = null),
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                  ),
                ),

              // Boutons pour choisir emoji et couleur
              Row(
                children: [
                  Expanded(
                    child: CoachMarkSystem.buildHalo(
                      key: _emojiButtonKey,
                      pulseController: _coachPulseController,
                      isActive: _isTutorialRunning && _activeTargetKey == 'emoji',
                      borderRadius: BorderRadius.circular(8),
                      child: OutlinedButton.icon(
                        onPressed: _showEmojiPicker,
                        icon: const Icon(Icons.emoji_emotions),
                        label: Text(_selectedEmoji == null
                            ? AppLocalizations.of(context)!.chooseIcon
                            : AppLocalizations.of(context)!.changeIcon),
                      ),
                    ),
                  ),
                  if (_selectedEmoji != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        // 8 couleurs prédéfinies
                        final predefinedColors = [
                          PassKeyraColors.primary,
                          Colors.red,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.pink,
                          Colors.teal,
                          Colors.indigo,
                        ];

                        // 18 couleurs palette PassKeyra (comme CategoryDialog)
                        final paletteColors = [
                          const Color(0xFF2196F3), // Bleu PassKeyra principal
                          const Color(0xFF42A5F5), // Bleu clair
                          const Color(0xFF64B5F6), // Bleu très clair
                          const Color(0xFF90CAF9), // Bleu pastel
                          const Color(0xFF29B6F6), // Bleu ciel clair
                          const Color(0xFF26C6DA), // Cyan clair
                          const Color(0xFF4DD0E1), // Cyan très clair
                          const Color(0xFF4DB6AC), // Teal clair
                          const Color(0xFF66BB6A), // Vert clair
                          const Color(0xFF9CCC65), // Vert lime clair
                          const Color(0xFFFFEE58), // Jaune clair
                          const Color(0xFFFFB74D), // Orange clair
                          const Color(0xFFFF8A65), // Orange saumon clair
                          const Color(0xFFEF5350), // Rouge clair
                          const Color(0xFFEC407A), // Rose clair
                          const Color(0xFFAB47BC), // Violet clair
                          const Color(0xFF5C6BC0), // Indigo clair
                          const Color(0xFF78909C), // Gris bleuté clair
                        ];

                        final selectedColor = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.chooseColor),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section 1: Couleurs prédéfinies
                                  Text(
                                    AppLocalizations.of(context)!.categoryPredefinedColors,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: predefinedColors.map((color) {
                                      final isSelected = _selectedIconColor.value == color.value;
                                      return InkWell(
                                        onTap: () => Navigator.pop(context, color),
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.white : Colors.transparent,
                                              width: 3,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: color.withOpacity(0.5),
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check, color: Colors.white)
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 24),

                                  // Section 2: Palette complète
                                  Text(
                                    AppLocalizations.of(context)!.categoryColorPicker,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: paletteColors.map((color) {
                                      final isSelected = _selectedIconColor.value == color.value;
                                      return InkWell(
                                        onTap: () => Navigator.pop(context, color),
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.white : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                            ],
                          ),
                        );
                        if (selectedColor != null) {
                          setState(() => _selectedIconColor = selectedColor);
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _selectedIconColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Section mots de passe additionnels (Premium)
              Row(
                children: [
                  Icon(Icons.vpn_key_outlined, color: PassKeyraColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Mots de passe additionnels',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PassKeyraColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!_premiumService.isPremium) const PremiumBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Liste des mots de passe additionnels
              if (_additionalPasswords.isNotEmpty)
                ...List.generate(_additionalPasswords.length, (index) {
                  final item = _additionalPasswords[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: PassKeyraColors.border),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.key, color: PassKeyraColors.primary),
                        title: Text(
                          item['label'] ?? 'Sans titre',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(item['username'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editAdditionalPassword(index),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: PassKeyraColors.error),
                              onPressed: () => _deleteAdditionalPassword(index),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              // Bouton Ajouter
              CoachMarkSystem.buildHalo(
                key: _addPasswordButtonKey,
                pulseController: _coachPulseController,
                isActive: _isTutorialRunning && _activeTargetKey == 'passwords',
                borderRadius: BorderRadius.circular(8),
                child: OutlinedButton.icon(
                  onPressed: _addAdditionalPassword,
                  icon: const Icon(Icons.add),
                  label: Text(_additionalPasswords.isEmpty
                    ? 'Ajouter un mot de passe additionnel'
                    : 'Ajouter un autre mot de passe'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}

// Dialogue de personnalisation du générateur de mot de passe
class _PasswordGeneratorDialog extends StatefulWidget {
  const _PasswordGeneratorDialog({this.startTutorial = false});
  final bool startTutorial;

  @override
  State<_PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<_PasswordGeneratorDialog>
    with SingleTickerProviderStateMixin {
  int _length = 16;
  bool _includeLower = true;
  bool _includeUpper = true;
  bool _includeDigits = true;
  bool _includeSymbols = true;

  late final AnimationController _pulseController;
  final _lengthKey  = GlobalKey();
  final _lowerKey   = GlobalKey();
  final _upperKey   = GlobalKey();
  final _digitsKey  = GlobalKey();
  final _symbolsKey = GlobalKey();
  bool _isTutorialRunning = false;
  String? _activeTutorialKey;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    if (widget.startTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runGeneratorTutorial());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runGeneratorTutorial() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() { _isTutorialRunning = true; _activeTutorialKey = 'length'; });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final r1 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _lengthKey, pulseController: _pulseController,
      title: l10n.firstEntryTutorialGeneratorLengthTitle,
      message: l10n.firstEntryTutorialGeneratorLengthMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '1 / 5',
    );
    if (!mounted || r1 != CoachStepResult.primary) {
      setState(() { _isTutorialRunning = false; _activeTutorialKey = null; }); return;
    }
    setState(() => _activeTutorialKey = 'lower');

    final r2 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _lowerKey, pulseController: _pulseController,
      title: l10n.firstEntryTutorialGeneratorLowerTitle,
      message: l10n.firstEntryTutorialGeneratorLowerMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '2 / 5',
    );
    if (!mounted || r2 != CoachStepResult.primary) {
      setState(() { _isTutorialRunning = false; _activeTutorialKey = null; }); return;
    }
    setState(() => _activeTutorialKey = 'upper');

    final r3 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _upperKey, pulseController: _pulseController,
      title: l10n.firstEntryTutorialGeneratorUpperTitle,
      message: l10n.firstEntryTutorialGeneratorUpperMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '3 / 5',
    );
    if (!mounted || r3 != CoachStepResult.primary) {
      setState(() { _isTutorialRunning = false; _activeTutorialKey = null; }); return;
    }
    setState(() => _activeTutorialKey = 'digits');

    final r4 = await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _digitsKey, pulseController: _pulseController,
      title: l10n.firstEntryTutorialGeneratorDigitsTitle,
      message: l10n.firstEntryTutorialGeneratorDigitsMessage,
      primaryLabel: l10n.onboardingNext, secondaryLabel: l10n.onboardingSkipTutorial,
      fullWidth: true, stepIndicator: '4 / 5',
    );
    if (!mounted || r4 != CoachStepResult.primary) {
      setState(() { _isTutorialRunning = false; _activeTutorialKey = null; }); return;
    }
    setState(() => _activeTutorialKey = 'symbols');

    await CoachMarkSystem.showCoachStep(
      context: context, targetKey: _symbolsKey, pulseController: _pulseController,
      title: l10n.firstEntryTutorialGeneratorSymbolsTitle,
      message: l10n.firstEntryTutorialGeneratorSymbolsMessage,
      primaryLabel: l10n.onboardingFinish,
      fullWidth: true, stepIndicator: '5 / 5',
    );

    if (mounted) setState(() { _isTutorialRunning = false; _activeTutorialKey = null; });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.generatePassword),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoachMarkSystem.buildHalo(
              key: _lengthKey,
              pulseController: _pulseController,
              isActive: _isTutorialRunning && _activeTutorialKey == 'length',
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.passwordLength}: $_length'),
                  Slider(
                    value: _length.toDouble(),
                    min: 8,
                    max: 32,
                    divisions: 24,
                    label: _length.toString(),
                    onChanged: (value) => setState(() => _length = value.toInt()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            CoachMarkSystem.buildHalo(
              key: _lowerKey,
              pulseController: _pulseController,
              isActive: _isTutorialRunning && _activeTutorialKey == 'lower',
              borderRadius: BorderRadius.circular(8),
              child: CheckboxListTile(
                title: Text(l10n.includeLowercase),
                value: _includeLower,
                onChanged: (val) => setState(() => _includeLower = val ?? true),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            CoachMarkSystem.buildHalo(
              key: _upperKey,
              pulseController: _pulseController,
              isActive: _isTutorialRunning && _activeTutorialKey == 'upper',
              borderRadius: BorderRadius.circular(8),
              child: CheckboxListTile(
                title: Text(l10n.includeUppercase),
                value: _includeUpper,
                onChanged: (val) => setState(() => _includeUpper = val ?? true),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            CoachMarkSystem.buildHalo(
              key: _digitsKey,
              pulseController: _pulseController,
              isActive: _isTutorialRunning && _activeTutorialKey == 'digits',
              borderRadius: BorderRadius.circular(8),
              child: CheckboxListTile(
                title: Text(l10n.includeNumbers),
                value: _includeDigits,
                onChanged: (val) => setState(() => _includeDigits = val ?? true),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            CoachMarkSystem.buildHalo(
              key: _symbolsKey,
              pulseController: _pulseController,
              isActive: _isTutorialRunning && _activeTutorialKey == 'symbols',
              borderRadius: BorderRadius.circular(8),
              child: CheckboxListTile(
                title: Text(l10n.includeSymbols),
                value: _includeSymbols,
                onChanged: (val) => setState(() => _includeSymbols = val ?? true),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!_includeLower && !_includeUpper && !_includeDigits && !_includeSymbols)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.required,
                  style: const TextStyle(color: PassKeyraColors.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: (_includeLower || _includeUpper || _includeDigits || _includeSymbols)
              ? () {
                  Navigator.pop(context, {
                    'length': _length,
                    'lower': _includeLower,
                    'upper': _includeUpper,
                    'digits': _includeDigits,
                    'symbols': _includeSymbols,
                  });
                }
              : null,
          child: Text(l10n.generatePassword),
        ),
      ],
    );
  }
}

// Dialogue pour ajouter/éditer un mot de passe additionnel
class _AdditionalPasswordDialog extends StatefulWidget {
  const _AdditionalPasswordDialog({this.initialData, this.existingPasswords});
  final Map<String, String>? initialData;
  final List<Map<String, String>>? existingPasswords;

  @override
  State<_AdditionalPasswordDialog> createState() => _AdditionalPasswordDialogState();
}

class _AdditionalPasswordDialogState extends State<_AdditionalPasswordDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialData?['label'] ?? '');
    _usernameController = TextEditingController(text: widget.initialData?['username'] ?? '');
    _passwordController = TextEditingController(text: widget.initialData?['password'] ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    // Valider que le mot de passe est rempli
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe est requis'),
          backgroundColor: PassKeyraColors.error,
        ),
      );
      return;
    }

    // Si le libellé est vide, générer un numéro automatique
    String label = _labelController.text.trim();
    if (label.isEmpty) {
      // Récupérer le nombre de mots de passe additionnels existants pour générer le numéro
      final currentCount = widget.existingPasswords?.length ?? 0;
      label = 'Mot de passe additionnel #${currentCount + 1}';
    }

    Navigator.pop(context, {
      'label': label,
      'username': _usernameController.text.trim(),
      'password': _passwordController.text.trim(),
    });
  }

  Future<void> _generate() async {
    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _PasswordGeneratorDialog(),
    );

    if (options != null) {
      final pwd = PasswordGenerator.generate(
        length: options['length'] as int,
        includeLower: options['lower'] as bool,
        includeUpper: options['upper'] as bool,
        includeDigits: options['digits'] as bool,
        includeSymbols: options['symbols'] as bool,
      );
      setState(() => _passwordController.text = pwd);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialData == null
        ? 'Nouveau mot de passe'
        : 'Modifier le mot de passe'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              inputFormatters: [LengthLimitingTextInputFormatter(256)],
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.additionalPasswordLabel,
                hintText: 'Ex: Email secondaire, Compte admin...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              inputFormatters: [LengthLimitingTextInputFormatter(512)],
              decoration: const InputDecoration(
                labelText: 'Identifiant (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    inputFormatters: [LengthLimitingTextInputFormatter(1024)],
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _generate,
                  icon: const Icon(Icons.autorenew),
                  tooltip: 'Générer',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

