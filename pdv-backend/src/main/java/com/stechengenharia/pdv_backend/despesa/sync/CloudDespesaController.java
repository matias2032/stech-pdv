package com.stechengenharia.pdv_backend.despesa.sync;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync/despesas")
@RequiredArgsConstructor
public class CloudDespesaController {

    private final DespesaSyncCloudService service;

    @PostMapping
    public ResponseEntity<Void> receber(@RequestBody List<DespesaSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<List<DespesaSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since
    ) {
        return ResponseEntity.ok(service.listarDesde(since));
    }
}