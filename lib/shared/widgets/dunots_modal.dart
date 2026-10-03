import 'package:flutter/material.dart';

/// Abre uma folha inferior do Dunots, ampla e fechável por gesto.
///
/// Diferentemente de um [showDialog], a rota é um [showModalBottomSheet]: ela
/// ocupa toda a largura disponível, acompanha o teclado e o gesto vertical na
/// alça/superfície permite arrastá-la para baixo para fechar.
Future<T?> showDunotsDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
}) {
  final width = MediaQuery.sizeOf(context).width;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    enableDrag: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    // O limite de 640 dp do Material 3 cria margens artificiais em tablets e
    // landscape. O drawer do Dunots é uma superfície de ponta a ponta.
    constraints: BoxConstraints.tightFor(width: width),
    builder: builder,
  );
}

/// Folha inferior base para formulários e fluxos de edição do Dunots.
///
/// O nome é mantido para compatibilidade com os formulários existentes. Ele
/// deve ser aberto com [showDunotsDrawer] para preservar o gesto de arrastar.
class DunotsModal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final List<Widget> actions;
  final bool scrollable;

  const DunotsModal({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.subtitle,
    this.icon,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = (screen.height - keyboardInset - 12)
        .clamp(160.0, screen.height * 0.94)
        .toDouble();

    return Semantics(
      namesRoute: true,
      label: 'Painel: $title. Arraste para baixo para fechar.',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: availableHeight),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _DrawerHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 12, 0),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar painel',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    physics: scrollable
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      keyboardInset > 0 ? 32 : 8,
                    ),
                    child: _buildContent(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 8,
                    children: actions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
        ],
        child,
      ],
    );
  }
}

class _DrawerHandle extends StatelessWidget {
  const _DrawerHandle();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('dunots-drawer-handle'),
      label: 'Alça do painel. Arraste para baixo para fechar.',
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

/// Coluna de formulário com espaçamento consistente entre campos.
class DunotsFormColumn extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const DunotsFormColumn({
    super.key,
    required this.children,
    this.spacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

/// Confirmação visual padronizada para ações destrutivas ou irreversíveis.
class DunotsConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final IconData icon;

  const DunotsConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.icon = Icons.warning_amber_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return DunotsModal(
      title: title,
      icon: icon,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
      child: Text(message),
    );
  }
}
