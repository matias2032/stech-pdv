package com.stechengenharia.pdv_backend.cliente.sync;

import com.stechengenharia.pdv_backend.cliente.sync.ClienteSyncDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync/clientes")
@RequiredArgsConstructor
public class CloudClienteController {

    private final ClienteSyncCloudService service;

    @PostMapping
    public ResponseEntity<Void> receber(@RequestBody List<ClienteSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<List<ClienteSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarDesde(since));
    }
}