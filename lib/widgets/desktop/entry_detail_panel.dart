import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app.dart';
import '../../l10n/app_localizations.dart';
import '../../models/password_entry.dart';
import '../../services/secure_clipboard_service.dart';

class EntryDetailPanel extends StatefulWidget {
  const EntryDetailPanel({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    this.onClose,
  });

  final PasswordEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onClose;

  @override
  State<EntryDetailPanel> createState() => _EntryDetailPanelState();
}

class _EntryDetailPanelState extends State<EntryDetailPanel> {
  bool _obscurePassword = true;
  final Map<int, bool> _obscureAdditionalPasswords = {};

  @override
  void didUpdateWidget(covariant EntryDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _obscurePassword = true;
      _obscureAdditionalPasswords.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = widget.entry;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // En-tete avec nom + actions
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: PassKeyraColors.divider),
            ),
          ),
          child: Row(
            children: [
              if (e.emoji != null)
                Text(e.emoji!, style: const TextStyle(fontSize: 20))
              else
                Icon(Icons.lock_outline, color: primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: widget.onEdit,
                tooltip: l10n.edit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: PassKeyraColors.error),
                onPressed: widget.onDelete,
                tooltip: l10n.delete,
                visualDensity: VisualDensity.compact,
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        // Corps scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Categorie
                if (e.category != null) ...[
                  _buildField(
                    label: l10n.category,
                    value: e.category!,
                    icon: Icons.folder_outlined,
                  ),
                  const SizedBox(height: 14),
                ],

                // Identifiant
                _buildField(
                  label: l10n.username,
                  value: e.username,
                  icon: Icons.person_outline,
                  trailing: _copyButton(e.username, l10n.usernameCopied),
                ),
                const SizedBox(height: 14),

                // Mot de passe
                _buildField(
                  label: l10n.password,
                  value: _obscurePassword ? '••••••••' : e.password,
                  icon: Icons.lock_outline,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        visualDensity: VisualDensity.compact,
                      ),
                      _copyButton(e.password, l10n.passwordCopied),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Mots de passe additionnels
                if (e.additionalPasswords.isNotEmpty) ...[
                  Text(
                    l10n.additionalPasswordsShort,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...e.additionalPasswords.asMap().entries.map(_buildAdditionalPassword),
                  const SizedBox(height: 14),
                ],

                // URL
                if (e.url != null && e.url!.isNotEmpty) ...[
                  _buildField(
                    label: l10n.url,
                    value: e.url!,
                    icon: Icons.link,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _copyButton(e.url!, l10n.urlCopied),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          onPressed: () async {
                            final uri = Uri.parse(e.url!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Notes
                if (e.notes != null && e.notes!.isNotEmpty) ...[
                  _buildField(
                    label: l10n.notes,
                    value: e.notes!,
                    icon: Icons.notes,
                    maxLines: 8,
                    trailing: _copyButton(e.notes!, l10n.notes),
                  ),
                  const SizedBox(height: 14),
                ],

                // Tags
                if (e.tags.isNotEmpty) ...[
                  Text(
                    l10n.tags,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: e.tags.map((tag) => InkWell(
                      onTap: () {
                        SecureClipboardService.copyWithAutoClear(tag);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tag)),
                        );
                      },
                      child: Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Dates
                const Divider(),
                const SizedBox(height: 6),
                Text(
                  '${l10n.createdAt} ${_formatDate(e.createdAt)}',
                  style: TextStyle(fontSize: 11, color: PassKeyraColors.textTertiary),
                ),
                if (e.updatedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Modifie le ${_formatDate(e.updatedAt!)}',
                    style: TextStyle(fontSize: 11, color: PassKeyraColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required IconData icon,
    Widget? trailing,
    int maxLines = 1,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 13),
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

  Widget _buildAdditionalPassword(MapEntry<int, Map<String, String>> entry) {
    final index = entry.key;
    final item = entry.value;
    final isObscured = _obscureAdditionalPasswords[index] ?? true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item['label'] ?? 'Sans titre',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (item['username'] != null && item['username']!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: PassKeyraColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item['username']!, style: const TextStyle(fontSize: 12))),
                  _copyButton(item['username']!, 'Identifiant copie'),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: PassKeyraColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isObscured ? '••••••••' : (item['password'] ?? ''),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: Icon(isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16),
                  onPressed: () => setState(() => _obscureAdditionalPasswords[index] = !isObscured),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                _copyButton(item['password'] ?? '', 'Mot de passe copie'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _copyButton(String value, String feedback) {
    return IconButton(
      icon: const Icon(Icons.copy, size: 16),
      onPressed: () {
        SecureClipboardService.copyWithAutoClear(value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(feedback)),
        );
      },
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
