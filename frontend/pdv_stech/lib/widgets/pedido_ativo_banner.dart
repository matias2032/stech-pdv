// import 'package:flutter/material.dart';
// import '../controllers/pedido_ativo_controller.dart';
// import 'package:api_compartilhado/api_compartilhado.dart';


// /// Banner flutuante que mostra o pedido activo com botão "x" para desactivar.
// /// Usar no Stack de MenuScreen e PedidosPorFinalizarScreen.
// class PedidoAtivoBanner extends StatelessWidget {
//   final VoidCallback? onDesativado;

//   const PedidoAtivoBanner({Key? key, this.onDesativado}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<Pedido?>(
//       valueListenable: PedidoAtivoController.instance.pedidoAtivo,
//       builder: (context, pedido, _) {
//         if (pedido == null) return const SizedBox.shrink();

//         return Positioned(
//           bottom: 16,
//           left: 16,
//           right: 16,
//           child: Material(
//             elevation: 8,
//             borderRadius: BorderRadius.circular(14),
//             color: const Color(0xFF1A1A2E),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: Colors.green.withOpacity(0.2),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(Icons.shopping_cart,
//                         color: Colors.green, size: 18),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           'Pedido activo: ${pedido.reference ?? '—'}',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                           ),
//                         ),
//                         Text(
//                           'MZN ${pedido.total.toStringAsFixed(2)} · '
//                           '${pedido.totalItens} item(ns)',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.6),
//                             fontSize: 11,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Botão desactivar
//                   GestureDetector(
//                     onTap: () async {
//                       await PedidoAtivoController.instance.desativar();
//                       onDesativado?.call();
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         color: Colors.red.withOpacity(0.2),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(Icons.close,
//                           color: Colors.red, size: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }