package com.stechengenharia.pdv_backend.marca.sync;


import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/sync/marcas")
@RequiredArgsConstructor
public class CloudMarcaController {

    private final MarcaSyncCloudService service;

    @PostMapping
    public ResponseEntity<Void> receber(@RequestBody List<MarcaSyncDTO> dtos) {
        service.aplicarLote(dtos);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<List<MarcaSyncDTO>> listar(
            @RequestParam(defaultValue = "1970-01-01T00:00:00Z") Instant since) {
        return ResponseEntity.ok(service.listarDesde(since));
    }
}