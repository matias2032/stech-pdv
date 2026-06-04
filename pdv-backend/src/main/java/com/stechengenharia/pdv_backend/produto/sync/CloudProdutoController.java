package com.stechengenharia.pdv_backend.produto.sync;

import com.stechengenharia.pdv_backend.produto.sync.ProdutoSyncDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync/produtos")
@RequiredArgsConstructor
public class CloudProdutoController {

    private final ProdutoSyncCloudService service;

    @PostMapping
    public ResponseEntity<Void> receber(@RequestBody List<ProdutoSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<List<ProdutoSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarDesde(since));
    }
}