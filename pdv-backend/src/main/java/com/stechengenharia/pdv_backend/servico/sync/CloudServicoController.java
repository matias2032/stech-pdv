package com.stechengenharia.pdv_backend.servico.sync;

import com.stechengenharia.pdv_backend.servico.sync.ServicoSyncDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync/servicos")
@RequiredArgsConstructor
public class CloudServicoController {

    private final ServicoSyncCloudService service;

    @PostMapping
    public ResponseEntity<Void> receber(@RequestBody List<ServicoSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<List<ServicoSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarDesde(since));
    }
}