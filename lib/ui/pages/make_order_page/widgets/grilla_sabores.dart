import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/utils/variable_particionada.dart';

// Grilla de sabores del kiosco (ClickUp 86e3qauf1): la misma de la Opción A del POS (izi-pos,
// flavor_grid_sheet.dart), dentro del modal de opciones. Los sabores se numeran por orden de
// selección, muestran su porción y al llegar al límite del tamaño los demás quedan bloqueados.
// Tocar un sabor elegido lo quita y renumera los demás.

// Tinta del texto sobre el amarillo claro, la misma de la maqueta de la Opción A.
const _tintaAmarilla = Color(0xFF8A6216);

class GrillaSabores extends StatelessWidget {
  final Modifier variable;
  final bool conError;
  final VoidCallback onCambio;

  const GrillaSabores({super.key, required this.variable, required this.onCambio, this.conError = false});

  @override
  Widget build(BuildContext context) {
    final partes = variable.partes ?? 0;
    final lleno = variable.seleccionOrdenada.length >= partes;
    final reparto = variable.reparto;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              IziText.titleSmall(
                  color: conError ? context.iziColors.red : context.iziColors.dark,
                  text: "${variable.nombre}*"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                decoration: BoxDecoration(
                  color: context.iziColors.yellowLighten60,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IziText.label(
                  color: _tintaAmarilla,
                  text: 'Elige hasta $partes ${partes == 1 ? 'sabor' : 'sabores'}',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: variable.caracteristicas.length,
            itemBuilder: (context, i) {
              final sabor = variable.caracteristicas[i];
              final partesSabor = reparto[sabor];
              return _SaborTile(
                sabor: sabor,
                numero: sabor.check ? sabor.orden : null,
                porcion: partesSabor == null ? null : etiquetaPorciones(partesSabor, partes),
                bloqueado: !sabor.check && lleno,
                onTap: () {
                  variable.alternarSabor(sabor);
                  onCambio();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SaborTile extends StatelessWidget {
  final ModifierItem sabor;
  final int? numero;
  final String? porcion;
  final bool bloqueado;
  final VoidCallback onTap;

  const _SaborTile({
    required this.sabor,
    required this.numero,
    required this.porcion,
    required this.bloqueado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.iziColors;
    final elegido = numero != null;
    final sinImagen = Center(
      child: FractionallySizedBox(
        widthFactor: 0.45,
        child: FittedBox(child: Icon(IziIcons.dish, color: colores.warmLighten)),
      ),
    );
    return Opacity(
      opacity: bloqueado ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: bloqueado ? null : onTap,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colores.white,
                  border: Border.all(color: elegido ? colores.primary : colores.grey25, width: elegido ? 2 : 1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: elegido
                      ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 2))]
                      : null,
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: colores.grey25,
                        child: (sabor.imagen ?? '').isEmpty
                            ? sinImagen
                            : CachedNetworkImage(
                                imageUrl: sabor.imagen!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Center(
                                    child: CircularProgressIndicator(strokeWidth: 2, color: colores.dark)),
                                errorWidget: (_, __, ___) => sinImagen,
                              ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(8, 8, 8, porcion == null ? 10 : 0),
                      child: IziText.titleSmall(
                        color: colores.dark,
                        text: sabor.nombre,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (porcion != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 1, 8, 8),
                        child: IziText.label(
                          color: colores.grey,
                          text: porcion!,
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              if (elegido)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colores.primary, shape: BoxShape.circle),
                    child: IziText.label(color: colores.white, text: '$numero', fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
