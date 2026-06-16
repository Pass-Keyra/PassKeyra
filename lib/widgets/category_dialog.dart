import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../models/custom_category.dart';
import '../services/premium_service.dart';
import '../l10n/app_localizations.dart';
import '../app/app.dart';

class CategoryDialog extends StatefulWidget {
  final CustomCategory? category; // null = création, non-null = modification

  const CategoryDialog({super.key, this.category});

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late Color _selectedColor;
  late IconData _selectedIcon;
  String? _selectedEmoji;
  bool _isRoundShape = false;
  late TabController _tabController;
  final _premiumService = PremiumService();

  // Palette de 18 couleurs CLAIRES harmonisée avec PassKeyra (#2196F3)
  static const List<Color> _colorPalette = [
    Color(0xFF2196F3), // Bleu PassKeyra principal (logo)
    Color(0xFF42A5F5), // Bleu clair
    Color(0xFF64B5F6), // Bleu très clair
    Color(0xFF90CAF9), // Bleu pastel
    Color(0xFF29B6F6), // Bleu ciel clair
    Color(0xFF26C6DA), // Cyan clair
    Color(0xFF4DD0E1), // Cyan très clair
    Color(0xFF4DB6AC), // Teal clair
    Color(0xFF66BB6A), // Vert clair
    Color(0xFF9CCC65), // Vert lime clair
    Color(0xFFFFEE58), // Jaune clair
    Color(0xFFFFB74D), // Orange clair
    Color(0xFFFF8A65), // Orange saumon clair
    Color(0xFFEF5350), // Rouge clair
    Color(0xFFEC407A), // Rose clair
    Color(0xFFAB47BC), // Violet clair
    Color(0xFF5C6BC0), // Indigo clair
    Color(0xFF78909C), // Gris bleuté clair
  ];

  // 8 couleurs prédéfinies pour le color picker (comme edit_entry_page)
  static final List<Color> _predefinedColors = [
    PassKeyraColors.primary,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  // 30 icônes pertinentes
  static const List<IconData> _iconsList = [
    Icons.people, // Réseaux sociaux
    Icons.email, // Email
    Icons.account_balance, // Banque
    Icons.shopping_cart, // Shopping
    Icons.work, // Travail
    Icons.person, // Personnel
    Icons.category, // Autre
    Icons.games, // Jeux
    Icons.sports_esports, // Gaming
    Icons.movie, // Films
    Icons.music_note, // Musique
    Icons.restaurant, // Restaurant
    Icons.local_cafe, // Café
    Icons.flight, // Voyage
    Icons.hotel, // Hôtel
    Icons.school, // Éducation
    Icons.fitness_center, // Sport
    Icons.local_hospital, // Santé
    Icons.pets, // Animaux
    Icons.home, // Maison
    Icons.directions_car, // Voiture
    Icons.phone, // Téléphone
    Icons.computer, // Ordinateur
    Icons.camera, // Photo
    Icons.book, // Livre
    Icons.favorite, // Favori
    Icons.star, // Étoile
    Icons.security, // Sécurité
    Icons.cloud, // Cloud
    Icons.vpn_key, // Clé/Mot de passe
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? _colorPalette[0];
    _selectedIcon = widget.category?.icon ?? _iconsList[0];
    _selectedEmoji = widget.category?.emoji;
    _isRoundShape = false; // Toujours carré
    _tabController = TabController(length: 2, vsync: this);

    // Si une catégorie avec emoji est en édition, sélectionner l'onglet Emoji
    if (_selectedEmoji != null) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
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
          content: Text(AppLocalizations.of(context)!.categoryEmojisPremium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseIcon),
        content: SizedBox(
          width: 300,
          height: 300,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              setState(() {
                _selectedEmoji = emoji.emoji;
              });
              Navigator.pop(context);
            },
            config: Config(
              height: 256,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                emojiSizeMax: 28,
                columns: 7,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              categoryViewConfig: CategoryViewConfig(
                iconColorSelected: PassKeyraColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker() async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseColor),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Couleurs prédéfinies
              Text(
                AppLocalizations.of(context)!.categoryPredefinedColors,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedColors.map((color) {
                  final isSelected = _selectedColor.value == color.value;
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
              // Palette complète de catégories
              Text(
                AppLocalizations.of(context)!.categoryColorPicker,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorPalette.map((color) {
                  final isSelected = _selectedColor.value == color.value;
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
      setState(() => _selectedColor = selectedColor);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'color': _selectedColor,
      'icon': _selectedIcon,
      'emoji': _selectedEmoji,
      'isRoundShape': _isRoundShape,
    });
  }

  Widget _buildPreview() {
    if (_selectedEmoji != null) {
      // Aperçu avec emoji
      return Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _selectedColor,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            _selectedEmoji!,
            style: const TextStyle(fontSize: 40),
          ),
        ),
      );
    } else {
      // Aperçu avec icône Material
      return Center(
        child: Chip(
          avatar: Icon(_selectedIcon, color: _selectedColor, size: 18),
          label: Text(
            _nameController.text.isEmpty
                ? 'Nom de catégorie'
                : _nameController.text,
            style: TextStyle(
              color: _selectedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: _selectedColor.withOpacity(0.1),
          side: BorderSide(color: _selectedColor, width: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la catégorie',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Le nom est requis';
                    if (value.length < 2) return 'Au moins 2 caractères';
                    if (value.length > 30) return 'Maximum 30 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Onglets Icônes / Emojis
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, size: 16),
                          const SizedBox(width: 4),
                          Text(l10n.categoryIconsTab),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_emotions, size: 16),
                          const SizedBox(width: 4),
                          Text(l10n.categoryEmojisTab),
                          if (!_premiumService.isPremium) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.workspace_premium,
                              size: 14,
                              color: PassKeyraColors.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contenu des onglets
                SizedBox(
                  height: 250,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet Icônes Material
                      SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _iconsList.map((icon) {
                            final isSelected = _selectedIcon.codePoint == icon.codePoint && _selectedEmoji == null;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon;
                                  _selectedEmoji = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _selectedColor.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? _selectedColor : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected ? _selectedColor : Colors.grey,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Onglet Emojis (Premium)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_selectedEmoji != null) ...[
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _selectedColor,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _selectedEmoji!,
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton(
                                    onPressed: _showEmojiPicker,
                                    child: Text(l10n.changeIcon),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedEmoji = null;
                                        _tabController.index = 0;
                                      });
                                    },
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Icon(
                                Icons.emoji_emotions_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _showEmojiPicker,
                                icon: const Icon(Icons.add),
                                label: Text(l10n.chooseIcon),
                              ),
                              if (!_premiumService.isPremium) ...[
                                const SizedBox(height: 8),
                                Text(
                                  l10n.categoryEmojisPremium,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Couleur
                Row(
                  children: [
                    Text(
                      'Couleur',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _showColorPicker,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _showColorPicker,
                      child: Text(l10n.chooseColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Aperçu
                Text(
                  'Aperçu',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                _buildPreview(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }
}
