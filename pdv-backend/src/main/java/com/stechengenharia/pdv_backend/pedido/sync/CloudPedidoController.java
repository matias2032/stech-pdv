package com.stechengenharia.pdv_backend.pedido.sync;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync")
@RequiredArgsConstructor
public class CloudPedidoController {

    private final PedidoSyncCloudService service;

    // ════════════════════════════════════════════════════════════════
    // PEDIDOS
    // Mantém os endpoints antigos:
    // POST /sync/pedidos
    // GET  /sync/pedidos
    // ════════════════════════════════════════════════════════════════

    @PostMapping("/pedidos")
    public ResponseEntity<Void> receber(@RequestBody List<PedidoSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/pedidos")
    public ResponseEntity<List<PedidoSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarDesde(since));
    }

    // ════════════════════════════════════════════════════════════════
    // PARCELAS DE CRÉDITO
    // POST /sync/parcelas
    // GET  /sync/parcelas
    // ════════════════════════════════════════════════════════════════

    @PostMapping("/parcelas")
    public ResponseEntity<Void> receberParcelas(@RequestBody List<ParcelaSyncDTO> dtos) {
        service.aplicarLoteParcelas(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/parcelas")
    public ResponseEntity<List<ParcelaSyncDTO>> listarParcelas(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarParcelasDesde(since));
    }

    // ════════════════════════════════════════════════════════════════
    // PAGAMENTOS DE CRÉDITO
    // POST /sync/pagamentos-credito
    // GET  /sync/pagamentos-credito
    // ════════════════════════════════════════════════════════════════

    @PostMapping("/pagamentos-credito")
    public ResponseEntity<Void> receberPagamentosCredito(
            @RequestBody List<PagamentoCreditoSyncDTO> dtos) {
        service.aplicarLotePagamentosCredito(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/pagamentos-credito")
    public ResponseEntity<List<PagamentoCreditoSyncDTO>> listarPagamentosCredito(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarPagamentosCreditoDesde(since));
    }
}