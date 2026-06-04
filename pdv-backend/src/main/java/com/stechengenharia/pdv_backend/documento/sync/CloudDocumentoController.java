package com.stechengenharia.pdv_backend.documento.sync;

import com.stechengenharia.pdv_backend.documento.sync.DocumentoSyncDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync/documentos")
@RequiredArgsConstructor
public class CloudDocumentoController {

    private final DocumentoSyncCloudService service;

    @PostMapping
    public ResponseEntity<Void> receber(@RequestBody List<DocumentoSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<List<DocumentoSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarDesde(since));
    }
}