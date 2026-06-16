import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/password_entry.dart';
import '../services/secure_clipboard_service.dart';
import '../services/auto_close_service.dart';
import 'edit_entry_page.dart';

class ViewEntryPage extends StatefulWidget {
  const ViewEntryPage({super.key, required this.entry});
  final PasswordEntry entry;

  @override
  State<ViewEntryPage> createState() => _ViewEntryPageState();
}

class _ViewEntryPageState extends State<ViewEntryPage> {
  bool _obscurePassword = true;
  final Map<int, bool> _obscureAdditionalPasswords = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Ouvrir la page d'édition
              final result = await Navigator.of(context).push<PasswordEntry>(
                MaterialPageRoute(
                  builder: (_) => EditEntryPage(entry: widget.entry),
                ),
              );
              
              // Si modifié, retourner le résultat
              if (result != null && mounted) {
                Navigator.of(context).pop(result);
              }
            },
            tooltip: AppLocalizations.of(context)!.edit,
          ),
        ],
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Nom
            _buildReadOnlyField(
              label: AppLocalizations.of(context)!.name,
              value: widget.entry.name,
              icon: Icons.label,
            ),
            const SizedBox(height: 16),

            // Identifiant
            _buildReadOnlyField(
              label: AppLocalizations.of(context)!.username,
              value: widget.entry.username,
              icon: Icons.person,
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  SecureClipboardService.copyWithAutoClear(widget.entry.username);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.usernameCopied)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Mot de passe principal
            _buildReadOnlyField(
              label: AppLocalizations.of(context)!.password,
              value: _obscurePassword ? '••••••••' : widget.entry.password,
              icon: Icons.lock,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      SecureClipboardService.copyWithAutoClear(widget.entry.password);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.passwordCopied)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mots de passe additionnels
            if (widget.entry.additionalPasswords.isNotEmpty) ...[
              Text(
                AppLocalizations.of(context)!.additionalPasswordsShort,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64B5F6),
                ),
              ),
              const SizedBox(height: 8),
              ...widget.entry.additionalPasswords.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isObscured = _obscureAdditionalPasswords[index] ?? true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Libellé
                        Row(
                          children: [
                            Icon(Icons.key, size: 18, color: const Color(0xFF64B5F6)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['label'] ?? 'Sans titre',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Identifiant si présent
                        if (item['username'] != null && item['username']!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['username']!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  SecureClipboardService.copyWithAutoClear(item['username']!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Identifiant copié')),
                                  );
                                },
                                tooltip: 'Copier l\'identifiant',
                              ),
                            ],
                          ),
                        ],

                        // Mot de passe
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isObscured ? '••••••••' : (item['password'] ?? ''),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isObscured ? Icons.visibility : Icons.visibility_off,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureAdditionalPasswords[index] = !isObscured;
                                });
                              },
                              tooltip: isObscured ? 'Afficher' : 'Masquer',
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                SecureClipboardService.copyWithAutoClear(item['password']!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mot de passe copié')),
                                );
                              },
                              tooltip: 'Copier le mot de passe',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // URL
            if (widget.entry.url != null && widget.entry.url!.isNotEmpty) ...[
              _buildReadOnlyField(
                label: AppLocalizations.of(context)!.url,
                value: widget.entry.url!,
                icon: Icons.link,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        SecureClipboardService.copyWithAutoClear(widget.entry.url!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.urlCopied)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () async {
                        final uri = Uri.parse(widget.entry.url!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) ...[
              _buildReadOnlyField(
                label: AppLocalizations.of(context)!.notes,
                value: widget.entry.notes!,
                icon: Icons.notes,
                maxLines: 5,
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    SecureClipboardService.copyWithAutoClear(widget.entry.notes!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.notes)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Catégorie
            if (widget.entry.category != null) ...[
              _buildReadOnlyField(
                label: AppLocalizations.of(context)!.category,
                value: widget.entry.category!,
                icon: Icons.folder,
              ),
              const SizedBox(height: 16),
            ],

            // Tags
            if (widget.entry.tags.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.tags,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64B5F6)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      final allTags = widget.entry.tags.join(', ');
                      SecureClipboardService.copyWithAutoClear(allTags);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.tags)),
                      );
                    },
                    tooltip: AppLocalizations.of(context)!.tags,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.entry.tags.map((tag) {
                  return InkWell(
                    onTap: () {
                      SecureClipboardService.copyWithAutoClear(tag);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tag)),
                      );
                    },
                    child: Chip(
                      label: Text(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Informations de création
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.createdAt} ${_formatDate(widget.entry.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64B5F6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    Widget? trailing,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64B5F6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: maxLines,
                  overflow: maxLines == 1 ? TextOverflow.ellipsis : TextOverflow.visible,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

