package com.stechengenharia.pdv_backend.pedido.sync;

import com.stechengenharia.pdv_backend.pedido.sync.PedidoSyncDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync/pedidos")
@RequiredArgsConstructor
public class CloudPedidoController {

    private final PedidoSyncCloudService service;

    @PostMapping
    public ResponseEntity<Void> receber(@RequestBody List<PedidoSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<List<PedidoSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarDesde(since));
    }
}